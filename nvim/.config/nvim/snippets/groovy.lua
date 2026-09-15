-- Jenkins declarative-pipeline snippets.
--
-- friendly-snippets ships nothing for Groovy, and the Jenkins DSL is the part
-- worth having at your fingertips — the block nesting (pipeline > stages >
-- stage > steps) is easy to get wrong by hand.
--
-- Loaded by the from_lua loader configured in lua/plugins/lsp.lua. The
-- filename must match the filetype: Jenkinsfiles are `groovy`.
--
-- fmta uses <> as its placeholder delimiter rather than {}, which keeps the
-- Groovy braces below readable instead of doubled-up escapes.
local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta

return {
  s("pipeline", fmta([[
pipeline {
    agent <>

    stages {
        stage('<>') {
            steps {
                <>
            }
        }
    }
}
]], { i(1, "any"), i(2, "Build"), i(3, "sh 'make build'") })),

  s("stage", fmta([[
stage('<>') {
    steps {
        <>
    }
}
]], { i(1, "Name"), i(2, "") })),

  s("steps", fmta([[
steps {
    <>
}
]], { i(1, "") })),

  -- post always runs, which makes it the right home for cleanup and
  -- notifications regardless of how the build ended.
  s("post", fmta([[
post {
    always {
        <>
    }
    success {
        <>
    }
    failure {
        <>
    }
}
]], { i(1, "cleanWs()"), i(2, ""), i(3, "") })),

  s("environment", fmta([[
environment {
    <> = '<>'
}
]], { i(1, "KEY"), i(2, "value") })),

  s("when", fmta([[
when {
    branch '<>'
}
]], { i(1, "main") })),

  s("parallel", fmta([[
parallel {
    stage('<>') {
        steps {
            <>
        }
    }
    stage('<>') {
        steps {
            <>
        }
    }
}
]], { i(1, "Lint"), i(2, ""), i(3, "Test"), i(4, "") })),

  s("options", fmta([[
options {
    timeout(time: <>, unit: '<>')
    buildDiscarder(logRotator(numToKeepStr: '<>'))
}
]], { i(1, "30"), i(2, "MINUTES"), i(3, "10") })),

  s("parameters", fmta([[
parameters {
    string(name: '<>', defaultValue: '<>', description: '<>')
}
]], { i(1, "NAME"), i(2, ""), i(3, "") })),

  -- Credentials are bound only inside the block and masked in the log; this is
  -- the supported way to touch a secret in a pipeline.
  s("withCredentials", fmta([[
withCredentials([string(credentialsId: '<>', variable: '<>')]) {
    <>
}
]], { i(1, "credential-id"), i(2, "SECRET"), i(3, "") })),

  s("script", fmta([[
script {
    <>
}
]], { i(1, "" ) })),
}
