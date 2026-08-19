-- lua/plugins/extract-component.lua
--
-- "Extract selection to a new React component" refactor.
--
-- This is a self-contained, dependency-free refactor. There is no external
-- plugin to install, so this file registers *buffer-local* keymaps via a
-- FileType autocmd and returns an empty spec `{}` (a valid no-op lazy import).
-- The keymaps only exist in typescriptreact / javascriptreact buffers.
--
--   <leader>rc  (visual)  -> extract the visual selection
--   <leader>rc  (normal)  -> extract the *last* visual selection ('< to '>)
--
-- Uses only Neovim 0.10+ stable APIs (vim.api, vim.fn, vim.ui, vim.treesitter).
--
-- ALGORITHM (high level):
--   1. Validate filetype + capture the selection range (charwise or linewise;
--      blockwise is rejected). Extract the exact selected text.
--   2. Bail early on empty / non-JSX selections with a friendly notify.
--   3. Treesitter analysis (guarded by pcall, with a regex fallback):
--        - free identifiers referenced in the selection but *not* bound inside
--          it and *not* imported  -> props
--        - imported names referenced in the selection -> imports to copy into a
--          new file (safe because the new file is a sibling in the same dir)
--        - whether the selection is a single JSX element (no wrap) or multiple
--          roots / a `{expr}` (wrap in a `<>...</>` fragment)
--        - the start row of the enclosing top-level component (for inline mode)
--   4. Prompt (vim.ui.input) for a name, normalize to PascalCase.
--   5. Prompt (vim.ui.select) for placement: new sibling file OR inline above.
--   6. Build the component + call site, then edit the buffer:
--        - replace the selection with `<Name .../>` (preserving indentation)
--        - new file: write <Name>.tsx, add `import Name from "./Name";`
--        - inline: insert `function Name(...) {...}` above the component
--
-- Note (React 19 + Vite automatic JSX runtime): no `import React` is emitted.

-- Guard against double-loading if lazy imports this file more than once.
if vim.g.__extract_component_loaded then
  return {}
end
vim.g.__extract_component_loaded = true

local api = vim.api
local MAXCOL = vim.v.maxcol or 2147483647

local M = {}

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

-- Identifiers that must never be treated as props (JS/DOM globals + React).
-- If any of these are actually imported they are handled by the import logic;
-- listing them here just prevents them from leaking into the props interface.
local DENY = {}
do
  local names = {
    -- JS globals / builtins
    "console", "window", "document", "globalThis", "Math", "JSON", "Object",
    "Array", "String", "Number", "Boolean", "Date", "Promise", "Symbol", "Map",
    "Set", "WeakMap", "WeakSet", "RegExp", "Error", "parseInt", "parseFloat",
    "isNaN", "isFinite", "encodeURIComponent", "decodeURIComponent",
    "setTimeout", "setInterval", "clearTimeout", "clearInterval",
    "requestAnimationFrame", "cancelAnimationFrame", "fetch", "localStorage",
    "sessionStorage", "navigator", "location", "history", "alert", "confirm",
    "prompt", "structuredClone", "NaN", "Infinity", "undefined",
    -- React
    "React", "Fragment", "useState", "useEffect", "useRef", "useMemo",
    "useCallback", "useContext", "useReducer", "useLayoutEffect",
    "useImperativeHandle", "useDebugValue", "useId", "useTransition",
    "useDeferredValue", "useSyncExternalStore", "useInsertionEffect",
    "useActionState", "useOptimistic", "use",
  }
  for _, n in ipairs(names) do
    DENY[n] = true
  end
end

-- JS keywords (used by the regex fallback only).
local KEYWORDS = {}
do
  local kw = {
    "return", "if", "else", "const", "let", "var", "function", "true", "false",
    "null", "undefined", "new", "typeof", "instanceof", "in", "of", "for",
    "while", "do", "switch", "case", "break", "continue", "default", "this",
    "super", "class", "extends", "import", "export", "from", "as", "await",
    "async", "yield", "void", "delete", "try", "catch", "finally", "throw",
  }
  for _, n in ipairs(kw) do
    KEYWORDS[n] = true
  end
end

local JSX_CONTAINER = {
  jsx_element = true,
  jsx_self_closing_element = true,
  jsx_fragment = true,
}

--------------------------------------------------------------------------------
-- Small helpers
--------------------------------------------------------------------------------

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Extract Component" })
end

-- Leave visual mode so vim.ui prompts run in a clean state.
local function feed_esc()
  local esc = api.nvim_replace_termcodes("<Esc>", true, false, true)
  api.nvim_feedkeys(esc, "nx", false)
end

-- Indentation unit for generated code, honoring buffer options.
local function indent_unit(buf)
  if vim.bo[buf].expandtab then
    local sw = vim.bo[buf].shiftwidth
    if sw == 0 then
      sw = vim.bo[buf].tabstop
    end
    return string.rep(" ", sw > 0 and sw or 2)
  end
  return "\t"
end

-- Normalize arbitrary user input into a valid PascalCase component name.
-- Returns the name, or nil if it cannot form a legal identifier.
local function to_pascal(input)
  if type(input) ~= "string" then
    return nil
  end
  local words = {}
  for w in input:gmatch("[%a%d]+") do
    words[#words + 1] = w
  end
  if #words == 0 then
    return nil
  end
  local parts = {}
  for _, w in ipairs(words) do
    -- Capitalize the first letter, keep the rest as-is (preserves internal caps
    -- like "myURL" -> "MyURL").
    parts[#parts + 1] = w:sub(1, 1):upper() .. w:sub(2)
  end
  local name = table.concat(parts)
  -- A component name/identifier must start with a letter (JSX tags cannot start
  -- with a digit).
  if not name:match("^%a[%w]*$") then
    return nil
  end
  return name
end

-- The new file's extension follows the current buffer (.tsx / .jsx).
local function buf_ext(buf)
  return vim.bo[buf].filetype == "javascriptreact" and ".jsx" or ".tsx"
end

-- Turn the user's raw input into a safe file basename, PRESERVING their casing
-- (so "test-ye" stays "test-ye", not "TestYe"). Strips a trailing .tsx/.jsx
-- extension and any path segments; returns nil if nothing usable remains.
local function sanitize_basename(input)
  local s = vim.trim(input or "")
  s = s:gsub("%.[jt]sx?$", "") -- drop a typed extension
  s = s:gsub(".*/", "")        -- keep only the last path segment
  s = s:gsub("%s+", "-")       -- spaces -> dashes
  s = s:gsub("[^%w%-_.]", "")  -- drop filesystem-unsafe chars
  if s == "" then
    return nil
  end
  return s
end

-- Collapse "." and ".." segments in a path (logical, no symlink resolution).
local function normalize_path(path)
  local abs = path:sub(1, 1) == "/"
  local parts = {}
  for seg in path:gmatch("[^/]+") do
    if seg == "." then
      -- skip
    elseif seg == ".." then
      if #parts > 0 and parts[#parts] ~= ".." then
        table.remove(parts)
      elseif not abs then
        parts[#parts + 1] = ".."
      end
    else
      parts[#parts + 1] = seg
    end
  end
  return (abs and "/" or "") .. table.concat(parts, "/")
end

-- Relative import specifier from `from_dir` to `to_path` (both absolute).
-- e.g. (/a/b/src/Ctrl, /a/b/src/components/x.tsx) -> "../components/x.tsx".
local function relative_specifier(from_dir, to_path)
  local fp, tp = {}, {}
  for s in from_dir:gmatch("[^/]+") do
    fp[#fp + 1] = s
  end
  for s in to_path:gmatch("[^/]+") do
    tp[#tp + 1] = s
  end
  local i = 1
  while i <= #fp and i <= #tp and fp[i] == tp[i] do
    i = i + 1
  end
  local rel = {}
  for _ = i, #fp do
    rel[#rel + 1] = ".."
  end
  for j = i, #tp do
    rel[#rel + 1] = tp[j]
  end
  local spec = table.concat(rel, "/")
  if spec == "" then
    spec = "."
  end
  if not spec:match("^%.") then
    spec = "./" .. spec
  end
  return spec
end

-- Cheap "is this JSX?" guard. Accepts a single/multi element (`<...>`) or a JSX
-- expression container (`{...}` containing a `<`). Anything else is rejected so
-- we never corrupt the buffer on a non-JSX selection.
local function looks_like_jsx(text)
  local t = text:gsub("^%s+", ""):gsub("%s+$", "")
  -- strip a single wrapping pair of parentheses for the check
  t = t:gsub("^%(%s*", ""):gsub("%s*%)$", "")
  local is_element = t:match("^<") ~= nil and t:match(">%s*$") ~= nil
  local is_expr = t:match("^{") ~= nil and t:match("}%s*$") ~= nil and t:find("<", 1, true) ~= nil
  return is_element or is_expr
end

--------------------------------------------------------------------------------
-- Selection range
--------------------------------------------------------------------------------

-- Returns a table { srow0, sc0, erow0, ec0, kind } using 0-based rows and 0-based
-- byte columns where ec0 is *exclusive* (ready for nvim_buf_get_text /
-- nvim_buf_set_text). Returns nil on an invalid / blockwise selection.
local function get_range(source, buf)
  local sp, ep, mode
  if source == "visual" then
    mode = vim.fn.mode()
    sp = vim.fn.getpos("v") -- start of the (live) visual selection
    ep = vim.fn.getpos(".") -- cursor = other end
  else
    mode = vim.fn.visualmode() -- kind of the *last* visual selection
    sp = vim.fn.getpos("'<")
    ep = vim.fn.getpos("'>")
  end

  local kind = "char"
  if mode == "V" then
    kind = "line"
  elseif mode == "\22" then -- <C-v>
    return nil -- blockwise is intentionally unsupported
  end

  local sl, scol = sp[2], sp[3]
  local el, ecol = ep[2], ep[3]
  if sl == 0 or el == 0 then
    return nil
  end

  -- Normalize so (sl, scol) is before (el, ecol).
  if (sl > el) or (sl == el and scol > ecol) then
    sl, el = el, sl
    scol, ecol = ecol, scol
  end

  local srow0 = sl - 1
  local erow0 = el - 1
  local line_count = api.nvim_buf_line_count(buf)
  if srow0 < 0 or erow0 >= line_count then
    return nil
  end

  local start_line = api.nvim_buf_get_lines(buf, srow0, srow0 + 1, false)[1] or ""
  local end_line = api.nvim_buf_get_lines(buf, erow0, erow0 + 1, false)[1] or ""

  local sc0, ec0
  if kind == "line" then
    sc0 = 0
    ec0 = #end_line
  else
    sc0 = scol - 1
    if vim.o.selection == "exclusive" then
      -- End position is already one past the last selected char.
      ec0 = math.min(math.max(ecol - 1, sc0), #end_line)
    elseif ecol >= MAXCOL or ecol > #end_line then
      ec0 = #end_line
    else
      -- Default 'inclusive': ecol (1-based) is the first byte of the last
      -- selected char, so the exclusive 0-based end starts at ecol. Extend past
      -- any UTF-8 continuation bytes so we never split a multibyte character.
      ec0 = ecol
      while ec0 < #end_line do
        local b = end_line:byte(ec0 + 1)
        if b and b >= 0x80 and b < 0xC0 then
          ec0 = ec0 + 1
        else
          break
        end
      end
    end
  end

  -- Clamp.
  sc0 = math.max(0, math.min(sc0, #start_line))
  ec0 = math.max(0, math.min(ec0, #end_line))

  return { srow0 = srow0, sc0 = sc0, erow0 = erow0, ec0 = ec0, kind = kind }
end

--------------------------------------------------------------------------------
-- Props detection: regex fallback (only used if treesitter is unavailable)
--------------------------------------------------------------------------------

-- Best-effort, conservative. Harvests identifiers inside `{...}` expression
-- containers, excludes member accesses, object keys, arrow-function params
-- (locals) and keywords/globals. If treesitter is available this is never used.
local function regex_props(text)
  local props, seen, locals = {}, {}, {}

  -- Local names bound by arrow params: `(a, b) =>` and `x =>`.
  for params in text:gmatch("%(([^()]*)%)%s*=>") do
    for nm in params:gmatch("[%a_$][%w_$]*") do
      locals[nm] = true
    end
  end
  for nm in text:gmatch("([%a_$][%w_$]*)%s*=>") do
    locals[nm] = true
  end

  for expr in text:gmatch("{(.-)}") do
    local i = 1
    while true do
      local s, e = expr:find("[%a_$][%w_$]*", i)
      if not s then
        break
      end
      local name = expr:sub(s, e)
      local prev = s > 1 and expr:sub(s - 1, s - 1) or ""
      local nxt = expr:sub(e + 1, e + 1)
      i = e + 1
      if prev ~= "." -- not a member access `.name`
        and nxt ~= ":" -- not an object key `name:`
        and not KEYWORDS[name]
        and not DENY[name]
        and not locals[name]
        and not seen[name]
      then
        seen[name] = true
        props[#props + 1] = name
      end
    end
  end

  table.sort(props)
  return props
end

--------------------------------------------------------------------------------
-- Props / structure detection: treesitter (primary)
--------------------------------------------------------------------------------

-- Returns a rich info table (see the fallback shape below for keys). Never
-- throws: on any treesitter problem it degrades to the regex fallback with
-- wrap=true and no import copying.
local function analyze(buf, srow0, sc0, erow0, ec0, sel_lines)
  local ft = vim.bo[buf].filetype
  local lang = (ft == "typescriptreact") and "tsx" or "javascript"

  local ok, result = pcall(function()
    local parser = vim.treesitter.get_parser(buf, lang)
    if not parser then
      error("no parser")
    end
    local tree = parser:parse()[1]
    local root = tree:root()

    local function gettext(node)
      return vim.treesitter.get_node_text(node, buf)
    end

    -- Position comparison with end-exclusive semantics.
    local function le(r1, c1, r2, c2)
      return r1 < r2 or (r1 == r2 and c1 <= c2)
    end
    local function fully_inside(node)
      local sr, sc, er, ec = node:range()
      return le(srow0, sc0, sr, sc) and le(er, ec, erow0, ec0)
    end
    local function intersects(node)
      local sr, sc, er, ec = node:range()
      local before = le(er, ec, srow0, sc0) -- node entirely before selection
      local after = le(erow0, ec0, sr, sc) -- selection entirely before node
      return not (before or after)
    end

    -- Is `node` the tag *name* of a JSX element (so NOT a value reference)?
    local function is_tag_name(node)
      local p = node:parent()
      if not p then
        return false
      end
      local pt = p:type()
      if pt == "jsx_opening_element" or pt == "jsx_closing_element" or pt == "jsx_self_closing_element" then
        for _, nm in ipairs(p:field("name")) do
          if nm:id() == node:id() then
            return true
          end
        end
      end
      return false
    end

    -- Collect binding names introduced by a pattern (params / destructuring).
    local bounds = {}
    local function collect_bound(node)
      local t = node:type()
      if t == "identifier" or t == "shorthand_property_identifier_pattern" then
        bounds[gettext(node)] = true
      else
        for c in node:iter_children() do
          collect_bound(c)
        end
      end
    end

    local reads = {} -- value references (not tag names) inside the selection
    local all_refs = {} -- every identifier (incl. tag names) inside the selection

    local function walk(node)
      local t = node:type()
      if fully_inside(node) then
        if t == "arrow_function" or t == "function_declaration" or t == "function_expression"
          or t == "function" or t == "generator_function" or t == "generator_function_declaration"
          or t == "method_definition"
        then
          for _, p in ipairs(node:field("parameter")) do
            collect_bound(p)
          end
          for _, p in ipairs(node:field("parameters")) do
            collect_bound(p)
          end
        elseif t == "variable_declarator" then
          for _, n in ipairs(node:field("name")) do
            collect_bound(n)
          end
        end

        if t == "identifier" or t == "shorthand_property_identifier" then
          local name = gettext(node)
          all_refs[name] = true
          if not is_tag_name(node) then
            reads[name] = true
          end
        end
      end
      for c in node:iter_children() do
        if intersects(c) then
          walk(c)
        end
      end
    end
    walk(root)

    -- Top-level import statements -> local names + the source line(s).
    local function import_names(node)
      local names = {}
      local function visit(n)
        if n:type() == "import_clause" then
          for c in n:iter_children() do
            local ct = c:type()
            if ct == "identifier" then
              names[#names + 1] = gettext(c) -- default import
            elseif ct == "namespace_import" then
              for cc in c:iter_children() do
                if cc:type() == "identifier" then
                  names[#names + 1] = gettext(cc)
                end
              end
            elseif ct == "named_imports" then
              for spec in c:iter_children() do
                if spec:type() == "import_specifier" then
                  local alias = spec:field("alias")[1]
                  local nm = spec:field("name")[1]
                  local localn = alias or nm
                  if localn then
                    names[#names + 1] = gettext(localn)
                  end
                end
              end
            end
          end
        end
      end
      for c in node:iter_children() do
        visit(c)
      end
      return names
    end

    local imports = {}
    local import_name_set = {}
    for c in root:iter_children() do
      if c:type() == "import_statement" then
        local names = import_names(c)
        imports[#imports + 1] = {
          lines = vim.split(gettext(c), "\n", { plain = true }),
          names = names,
        }
        for _, nm in ipairs(names) do
          import_name_set[nm] = true
        end
      end
    end

    -- Props = referenced value identifiers that are neither locally bound,
    -- nor a builtin, nor an imported (module-scope) name.
    local props = {}
    for name in pairs(reads) do
      if not bounds[name] and not DENY[name] and not import_name_set[name] then
        props[#props + 1] = name
      end
    end
    table.sort(props)

    -- Wrap decision: only skip the fragment for a confident single JSX element.
    local function decide_wrap()
      local cn = root:named_descendant_for_range(srow0, sc0, erow0, ec0)
      if not cn then
        return true
      end
      if JSX_CONTAINER[cn:type()] and fully_inside(cn) then
        return false -- selection is exactly one JSX element
      end
      -- Otherwise count the JSX-ish children of the covering node that fall
      -- inside the selection. Exactly one element -> single root.
      local kinds = {}
      for c in cn:iter_children() do
        if c:named() and intersects(c) then
          local ct = c:type()
          if JSX_CONTAINER[ct] then
            kinds[#kinds + 1] = "el"
          elseif ct == "jsx_expression" then
            kinds[#kinds + 1] = "expr"
          elseif ct == "jsx_text" and gettext(c):match("%S") then
            kinds[#kinds + 1] = "text"
          end
        end
      end
      if #kinds == 1 and kinds[1] == "el" then
        return false
      end
      return true -- multi-root, a lone {expr}, or uncertain -> wrap (always safe)
    end

    -- Enclosing top-level statement start row (for inline placement).
    local function enclosing_start()
      local n = root:named_descendant_for_range(srow0, sc0, erow0, ec0)
      while n do
        local p = n:parent()
        if not p or p:type() == "program" then
          local sr = n:range()
          return sr
        end
        n = p
      end
      return nil
    end

    return {
      props = props,
      wrap = decide_wrap(),
      comp_start_row = enclosing_start(),
      imports = imports,
      all_refs = all_refs,
      used_ts = true,
    }
  end)

  if ok and result then
    return result
  end

  -- Fallback path.
  return {
    props = regex_props(table.concat(sel_lines, "\n")),
    wrap = true,
    comp_start_row = nil,
    imports = {},
    all_refs = {},
    used_ts = false,
  }
end

--------------------------------------------------------------------------------
-- Code generation
--------------------------------------------------------------------------------

-- Re-indent the extracted selection lines to sit at `target` indentation while
-- preserving their relative nesting. `base_indent` is the leading whitespace of
-- the selection's first line (used to dedent the following lines).
local function reindent(sel_lines, base_indent, target)
  local out = {}
  local blen = #base_indent
  for i, line in ipairs(sel_lines) do
    if line:match("^%s*$") then
      out[i] = ""
    else
      local stripped
      if i == 1 then
        stripped = line:gsub("^%s+", "")
      elseif blen > 0 and line:sub(1, blen) == base_indent then
        stripped = line:sub(blen + 1)
      else
        stripped = line:gsub("^%s+", "")
      end
      out[i] = target .. stripped
    end
  end
  return out
end

-- Build the self-closing call site: `<Name foo={foo} bar={bar} />`.
local function build_callsite(name, props)
  if #props == 0 then
    return string.format("<%s />", name)
  end
  local attrs = {}
  for _, p in ipairs(props) do
    attrs[#attrs + 1] = string.format("%s={%s}", p, p)
  end
  return string.format("<%s %s />", name, table.concat(attrs, " "))
end

-- Build the full component definition as a list of lines.
-- opts = { export = bool, wrap = bool, unit = string, copy_imports = {lines}? }
local function build_component(name, props, sel_lines, base_indent, opts)
  local unit = opts.unit
  local lines = {}
  local function add(s)
    lines[#lines + 1] = s
  end

  -- Copied imports (new-file case only), verbatim, at the very top.
  if opts.copy_imports and #opts.copy_imports > 0 then
    for _, il in ipairs(opts.copy_imports) do
      add(il)
    end
    add("")
  end

  local has_props = #props > 0

  -- Props interface (types cannot be inferred without the TS server, so they
  -- default to `any` with a TODO; the LSP + rename can refine them afterwards).
  if has_props then
    add(string.format("interface %sProps {", name))
    add(unit .. "// TODO: replace 'any' with real prop types")
    for _, p in ipairs(props) do
      add(string.format("%s%s: any;", unit, p))
    end
    add("}")
    add("")
  end

  local sig = ""
  if has_props then
    sig = string.format("{ %s }: %sProps", table.concat(props, ", "), name)
  end
  local decl = opts.export and "export default function" or "function"
  add(string.format("%s %s(%s) {", decl, name, sig))
  add(unit .. "return (")

  local body_indent = unit:rep(2)
  if opts.wrap then
    add(body_indent .. "<>")
    body_indent = unit:rep(3)
  end
  for _, bl in ipairs(reindent(sel_lines, base_indent, body_indent)) do
    add(bl)
  end
  if opts.wrap then
    add(unit:rep(2) .. "</>")
  end

  add(unit .. ");")
  add("}")
  return lines
end

-- Which import lines from the original file must be copied into a new sibling
-- file (those whose bound names are referenced in the selection). Relative
-- paths stay valid because the new file lives in the same directory.
local function collect_copy_imports(info)
  local out = {}
  for _, imp in ipairs(info.imports or {}) do
    local used = false
    for _, nm in ipairs(imp.names) do
      if info.all_refs[nm] then
        used = true
        break
      end
    end
    if used then
      for _, l in ipairs(imp.lines) do
        out[#out + 1] = l
      end
    end
  end
  return out
end

--------------------------------------------------------------------------------
-- Buffer edits
--------------------------------------------------------------------------------

-- 0-based index of the LAST line of the last top-level import STATEMENT
-- (handles multi-line named imports), or -1 if there are none.
local function find_last_import_row(buf)
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
  local n = #lines
  local last = -1
  local i = 1
  while i <= n do
    local l = lines[i]
    if l:match("^%s*import[%s{*'\"]") then
      local j = i
      if l:match('^%s*import%s+["\']') then
        -- side-effect import: `import "./x";` (module string, no `from`)
        last = i - 1
      else
        -- scan forward to the module-string line (`from "..."`) that
        -- terminates the (possibly multi-line) import statement.
        while j <= n and not lines[j]:match('from%s+["\']') do
          j = j + 1
        end
        if j > n then j = i end -- malformed; don't run past EOF
        last = j - 1
      end
      i = j + 1
    else
      i = i + 1
    end
  end
  return last
end

-- Insert `import Name from "<spec>";` after the last import. Idempotent on the
-- imported IDENTIFIER, so re-running or a name clash never duplicates it.
local function insert_import(buf, name, spec)
  spec = spec or ("./" .. name)
  local importline = string.format('import %s from "%s";', name, spec)
  local pesc = vim.pesc(name)
  local default_pat = "^%s*import%s+" .. pesc .. "[%s,]" -- import Foo ... / import Foo, {...}
  local word = "%f[%w_]" .. pesc .. "%f[^%w_]"           -- the identifier as a whole word
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
  for _, l in ipairs(lines) do
    -- Idempotent on the imported IDENTIFIER across default, named, and type
    -- imports (single-line), so a name clash never adds a duplicate import.
    if l == importline
      or l:match(default_pat)
      or (l:match("^%s*import[%s{]") and l:match("from%s+[\"']") and l:match(word))
    then
      return -- this identifier is already imported
    end
  end
  local last = find_last_import_row(buf)
  if last == -1 then
    api.nvim_buf_set_lines(buf, 0, 0, false, { importline })
  else
    api.nvim_buf_set_lines(buf, last + 1, last + 1, false, { importline })
  end
end

-- Replace the selection with the call site (preserving indentation).
local function replace_with_callsite(buf, ctx, callsite)
  -- For linewise selections sc0 is 0; keep the existing indentation by starting
  -- the replacement after the leading whitespace instead.
  local replace_sc = ctx.sc0
  if ctx.kind == "line" then
    replace_sc = #ctx.base_indent
  end
  api.nvim_buf_set_text(buf, ctx.srow0, replace_sc, ctx.erow0, ctx.ec0, { callsite })
end

-- Shared writer: create target_abs (making parent dirs), replace the selection
-- with the call site, and add the import using `spec`.
local function write_component_file(buf, ctx, name, target_abs, spec)
  if vim.fn.filereadable(target_abs) == 1 then
    return notify("File already exists: " .. target_abs, vim.log.levels.ERROR)
  end
  local parent = vim.fn.fnamemodify(target_abs, ":h")
  if vim.fn.isdirectory(parent) == 0 and vim.fn.mkdir(parent, "p") == 0 then
    return notify("Could not create directory: " .. parent, vim.log.levels.ERROR)
  end

  local comp = build_component(name, ctx.props, ctx.sel_lines, ctx.base_indent, {
    export = true,
    wrap = ctx.wrap,
    unit = ctx.unit,
    copy_imports = collect_copy_imports(ctx.info),
  })

  local ok, err = pcall(vim.fn.writefile, comp, target_abs)
  if not ok then
    return notify("Failed to write " .. target_abs .. ": " .. tostring(err), vim.log.levels.ERROR)
  end

  replace_with_callsite(buf, ctx, build_callsite(name, ctx.props))
  insert_import(buf, name, spec) -- import line is above the edit, so it's safe
  notify(string.format("Created %s and inserted <%s />", vim.fn.fnamemodify(target_abs, ":~:."), name))
end

-- Sibling file in the same directory, named exactly as the user typed
-- (component identifier stays PascalCase; the FILE keeps their casing).
local function do_new_file(buf, ctx, name, file_base)
  local file = api.nvim_buf_get_name(buf)
  if file == "" then
    return notify("Current buffer has no file on disk; cannot create a sibling file.", vim.log.levels.WARN)
  end
  local dir = vim.fn.fnamemodify(file, ":h")
  local target = dir .. "/" .. file_base .. buf_ext(buf)
  write_component_file(buf, ctx, name, target, "./" .. file_base)
end

-- Arbitrary path, interpreted relative to the CURRENT file (absolute allowed).
-- e.g. "../components/test-ye.tsx". The import specifier is derived from the
-- real target location, so it's always correct even for deep/absolute paths.
local function do_custom_path(buf, ctx, name, typed)
  local file = api.nvim_buf_get_name(buf)
  if file == "" then
    return notify("Save this file first so relative paths can be resolved.", vim.log.levels.WARN)
  end
  local dir = normalize_path(vim.fn.fnamemodify(file, ":h"))
  if not typed:match("%.[jt]sx?$") then
    typed = typed .. buf_ext(buf) -- add the buffer's extension if none given
  end
  local target = typed
  if target:sub(1, 1) ~= "/" then
    target = dir .. "/" .. target -- relative to the current file's directory
  end
  target = normalize_path(target)
  local spec = relative_specifier(dir, target):gsub("%.[jt]sx?$", "")
  write_component_file(buf, ctx, name, target, spec)
end

local function do_inline(buf, ctx, name)
  local comp = build_component(name, ctx.props, ctx.sel_lines, ctx.base_indent, {
    export = false,
    wrap = ctx.wrap,
    unit = ctx.unit,
  })

  -- Component start row was computed before edits; it sits above the selection
  -- so the call-site replacement below does not shift it.
  local insert_row = ctx.info.comp_start_row
  if not insert_row then
    insert_row = find_last_import_row(buf) + 1 -- fallback: just below imports
  end

  replace_with_callsite(buf, ctx, build_callsite(name, ctx.props))

  local block = {}
  -- Keep a blank line above the new component unless one is already there.
  if insert_row > 0 then
    local prev = api.nvim_buf_get_lines(buf, insert_row - 1, insert_row, false)[1]
    if prev and not prev:match("^%s*$") then
      block[#block + 1] = ""
    end
  end
  for _, l in ipairs(comp) do
    block[#block + 1] = l
  end
  block[#block + 1] = "" -- blank separator line below
  api.nvim_buf_set_lines(buf, insert_row, insert_row, false, block)
  notify(string.format("Inserted component %s above the current component", name))
end

--------------------------------------------------------------------------------
-- Orchestration
--------------------------------------------------------------------------------

function M.extract(source)
  local buf = api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  if ft ~= "typescriptreact" and ft ~= "javascriptreact" then
    return notify("Extract component only works in .tsx/.jsx buffers.", vim.log.levels.WARN)
  end

  -- Capture the range while still in visual mode, THEN leave visual mode.
  local range = get_range(source, buf)
  feed_esc()
  if not range then
    return notify("No valid charwise/linewise selection (blockwise is unsupported).", vim.log.levels.WARN)
  end

  local sel_lines = api.nvim_buf_get_text(buf, range.srow0, range.sc0, range.erow0, range.ec0, {})
  local joined = table.concat(sel_lines, "\n")

  if joined:match("^%s*$") then
    return notify("Selection is empty.", vim.log.levels.WARN)
  end
  if not looks_like_jsx(joined) then
    return notify("Selection doesn't look like JSX; aborting.", vim.log.levels.WARN)
  end

  -- All read-only analysis is done up front (before the async prompts) so the
  -- coordinates and treesitter data reflect the selection, not a later state.
  local start_line = api.nvim_buf_get_lines(buf, range.srow0, range.srow0 + 1, false)[1] or ""
  local base_indent = start_line:match("^%s*") or ""
  local unit = indent_unit(buf)
  local info = analyze(buf, range.srow0, range.sc0, range.erow0, range.ec0, sel_lines)

  local ctx = {
    srow0 = range.srow0,
    sc0 = range.sc0,
    erow0 = range.erow0,
    ec0 = range.ec0,
    kind = range.kind,
    sel_lines = sel_lines,
    base_indent = base_indent,
    unit = unit,
    props = info.props,
    wrap = info.wrap,
    info = info,
  }

  if not info.used_ts and #info.props > 0 then
    notify("Treesitter unavailable; props were guessed by regex - please verify.", vim.log.levels.WARN)
  end

  vim.ui.input({ prompt = "New component name: " }, function(input)
    if not input or input == "" then
      return -- cancelled
    end
    local name = to_pascal(input)
    if not name then
      return notify("Invalid name: must be PascalCase and start with a letter.", vim.log.levels.WARN)
    end
    -- Filename keeps the user's casing ("test-ye" -> test-ye.tsx); the component
    -- identifier is the PascalCase form ("TestYe"), as JSX requires.
    local file_base = sanitize_basename(input) or name
    local ext = buf_ext(buf)

    -- Wrap each mutation in pcall so a surprise never leaves a half-edit.
    local function run(fn)
      local ok, err = pcall(fn)
      if not ok then
        notify("Extraction failed: " .. tostring(err), vim.log.levels.ERROR)
      end
    end

    vim.ui.select({
      "New sibling file: " .. file_base .. ext,
      "Inline above the current component",
      "Custom path…",
    }, { prompt = "Place extracted component:" }, function(choice, idx)
      if not choice then
        return -- cancelled
      end
      if idx == 1 then
        run(function() do_new_file(buf, ctx, name, file_base) end)
      elseif idx == 2 then
        run(function() do_inline(buf, ctx, name) end)
      else
        vim.ui.input({
          prompt = "Path (relative to this file): ",
          default = "../" .. file_base .. ext,
        }, function(p)
          if not p or vim.trim(p) == "" then
            return -- cancelled
          end
          run(function() do_custom_path(buf, ctx, name, vim.trim(p)) end)
        end)
      end
    end)
  end)
end

--------------------------------------------------------------------------------
-- Keymaps (buffer-local, only in JSX buffers)
--------------------------------------------------------------------------------

function M.setup()
  api.nvim_create_autocmd("FileType", {
    pattern = { "typescriptreact", "javascriptreact" },
    group = api.nvim_create_augroup("extract_component", { clear = true }),
    callback = function(args)
      local opts = { buffer = args.buf, silent = true }
      vim.keymap.set("x", "<leader>rc", function()
        M.extract("visual")
      end, vim.tbl_extend("force", opts, { desc = "Refactor: extract JSX to component" }))
      vim.keymap.set("n", "<leader>rc", function()
        M.extract("normal")
      end, vim.tbl_extend("force", opts, { desc = "Refactor: extract JSX to component (last selection)" }))
    end,
  })
end

M.setup()

-- No external plugin to install: return an empty (valid) lazy.nvim spec.
return {}
