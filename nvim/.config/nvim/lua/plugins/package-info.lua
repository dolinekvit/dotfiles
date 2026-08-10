-- package-info.nvim — shows current vs latest dependency versions as inline
-- hints in package.json, with commands to update/install/delete packages.
return {
  "vuki656/package-info.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  ft = "json",
  opts = {
    package_manager = "npm",
    hide_up_to_date = false,
  },
  config = function(_, opts)
    require("package-info").setup(opts)
    -- Handy maps, active only in package.json buffers.
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "package.json",
      callback = function(ev)
        local pi = require("package-info")
        local function map(lhs, fn, desc)
          vim.keymap.set("n", lhs, fn, { buffer = ev.buf, desc = "Package: " .. desc })
        end
        map("<leader>ns", pi.show, "Show versions")
        map("<leader>nu", pi.update, "Update package on line")
        map("<leader>ni", pi.install, "Install a package")
        map("<leader>nc", pi.change_version, "Change package version")
      end,
    })
  end,
}
