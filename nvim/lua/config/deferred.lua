-- Loading plugins right after the first screen is drawn (see init.lua).
--
-- A plugin loaded this late has missed the events of files that were opened
-- before it (`nvim foo.lua`): Tree-sitter highlighting, colorizer, VimTeX
-- and the Markdown filetype are all set up from FileType. So once the
-- plugins are loaded, those files get their filetype (again) and FileType is
-- run for them once more. LSP and gitsigns attach to open buffers by
-- themselves.

local M = {}

-- Give each file that was already open its filetype again, now that every
-- filetype rule (e.g. .mdx as Markdown) is known, and run its FileType
-- autocommands for the plugins that were just loaded
local function refire_filetype()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buftype == ""
      and vim.api.nvim_buf_get_name(buf) ~= ""
    then
      local ft = vim.filetype.match { buf = buf } or vim.bo[buf].filetype
      vim.api.nvim_buf_call(buf, function()
        if ft ~= vim.bo[buf].filetype then
          -- Fires FileType itself
          vim.bo[buf].filetype = ft
        elseif ft ~= "" then
          vim.api.nvim_exec_autocmds("FileType", { buffer = buf, modeline = false })
        end
      end)
    end
  end
end

-- Run `load` right after the first screen has been drawn: on UIEnter,
-- scheduled, which runs once Neovim has drawn the screen and waits for
-- input. Without a UI (nvim --headless) there is no first screen: then on
-- VimEnter.
function M.after_first_screen(load)
  local done = false
  local function run()
    if done then
      return
    end
    done = true
    load()
    refire_filetype()
    -- The welcome screen counts the plugins that are loaded: draw it again
    -- with all of them
    if vim.bo.filetype == "snacks_dashboard" and _G.Snacks then
      Snacks.dashboard.update()
    end
  end

  local group = vim.api.nvim_create_augroup("DeferredPlugins", { clear = true })
  vim.api.nvim_create_autocmd("UIEnter", {
    group = group,
    once = true,
    desc = "Load the remaining plugins after the first screen is drawn",
    callback = function()
      vim.schedule(run)
    end,
  })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    once = true,
    desc = "Load the remaining plugins (no UI)",
    callback = function()
      if #vim.api.nvim_list_uis() == 0 then
        run()
      end
    end,
  })
end

return M
