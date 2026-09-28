local M = {}

---@return (LazyKeys|{has?:string})[]
function M.get()
  M._keys = {
    { "<leader>cd", vim.diagnostic.open_float, desc = "Line Diagnostics" },
    { "<leader>cl", "<cmd>LspInfo<cr>", desc = "Lsp Info" },
    { "gd", "<cmd>Telescope lsp_definitions<cr>", desc = "Goto Definition", has = "definition" },
    { "gr", "<cmd>Telescope lsp_references<cr>", desc = "References" },
    { "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
    { "gI", "<cmd>Telescope lsp_implementations<cr>", desc = "Goto Implementation" },
    { "gy", "<cmd>Telescope lsp_type_definitions<cr>", desc = "Goto T[y]pe Definition" },
    { "K", vim.lsp.buf.hover, desc = "Hover" },
    { "gK", vim.lsp.buf.signature_help, desc = "Signature Help", has = "signatureHelp" },
    { "<c-k>", vim.lsp.buf.signature_help, mode = "i", desc = "Signature Help", has = "signatureHelp" },
    { "]d", M.diagnostic_goto(true), desc = "Next Diagnostic" },
    { "[d", M.diagnostic_goto(false), desc = "Prev Diagnostic" },
    { "]e", M.diagnostic_goto(true, "ERROR"), desc = "Next Error" },
    { "[e", M.diagnostic_goto(false, "ERROR"), desc = "Prev Error" },
    { "]w", M.diagnostic_goto(true, "WARN"), desc = "Next Warning" },
    { "[w", M.diagnostic_goto(false, "WARN"), desc = "Prev Warning" },
    { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "v" }, has = "codeAction" },
    { "<leader>rn", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
    {
      "<leader>cA",
      function()
        vim.lsp.buf.code_action {
          context = {
            only = {
              "source",
            },
            diagnostics = {},
          },
        }
      end,
      desc = "Source Action",
      has = "codeAction",
    },
  }
  return M._keys
end

function M.on_attach(client, buffer)
  for _, keys in ipairs(M.get()) do
    if not keys.has or client:supports_method("textDocument/" .. keys.has, buffer) then
      vim.keymap.set(keys.mode or "n", keys[1], keys[2], {
        desc = keys.desc,
        silent = true,
        buf = buffer,
      })
    end
  end
end

function M.diagnostic_goto(next, severity)
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    vim.diagnostic.jump {
      count = next and 1 or -1,
      severity = severity,
      on_jump = function(diagnostic, bufnr)
        if diagnostic then
          vim.diagnostic.open_float { bufnr = bufnr, scope = "cursor" }
        end
      end,
    }
  end
end

return M
