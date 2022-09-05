local present, lspconfig = pcall(require, "lspconfig")

if not present then return end

local M = {}

require("plugins.configs.others").lsp_handlers()

function M.on_attach(client, _)
    client.resolved_capabilities.document_formatting = false
    client.resolved_capabilities.document_range_formatting = false

    require("core.mappings").lspconfig()
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.documentationFormat = {"markdown", "plaintext"}
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.preselectSupport = true
capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
capabilities.textDocument.completion.completionItem.deprecatedSupport = true
capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
capabilities.textDocument.completion.completionItem.tagSupport = {valueSet = {1}}
capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {"documentation", "detail", "additionalTextEdits"}
}

local servers = {"tsserver", "eslint", "gopls", "graphql", "pyright", "clangd", "jsonls"}

for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup {
        on_attach = M.on_attach,
        capabilities = capabilities,
        flags = {debounce_text_changes = 100}
    }
end

-- Lua
lspconfig.sumneko_lua.setup {
    on_attach = M.on_attach,
    capabilities = capabilities,

    settings = {
        Lua = {
            diagnostics = {globals = {"vim"}},
            workspace = {
                library = {
                    [vim.fn.expand "$VIMRUNTIME/lua"] = true,
                    [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true
                },
                maxPreload = 100000,
                preloadFileSize = 10000
            }
        }
    }
}

-- Ruby
lspconfig.solargraph.setup {
    on_attach = M.on_attach,
    capabilities = capabilities,

    flags = {debounce_text_changes = 100},
    cmd = {"solargraph", "stdio"},
    init_options = {formatting = false},
    settings = {solargraph = {diagnostics = false}},
    root_dir = lspconfig.util.root_pattern('Gemfile', '.git')
    -- root_dir = lspconfig.util.root_pattern('Gemfile', '.git', 'package.yml')
}
lspconfig.sorbet.setup {on_attach = M.on_attach, capabilities = capabilities}

-- Rust
lspconfig.rust_analyzer.setup({
    capabilities = capabilities,
    on_attach = M.on_attach,
    settings = {
        ["rust-analyzer"] = {
            assist = {importGranularity = "module", importPrefix = "by_self"},
            cargo = {loadOutDirsFromCheck = true},
            procMacro = {enable = true}
        }
    }
})

-- requires a file containing user's lspconfigs
local addlsp_confs = require("core.utils").load_config().plugins.options.lspconfig.setup_lspconf

if #addlsp_confs ~= 0 then require(addlsp_confs).setup_lsp(M.on_attach, capabilities) end

return M
