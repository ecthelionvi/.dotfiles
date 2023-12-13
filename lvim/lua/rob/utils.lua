-- |||||||||||||||||||||||||||||||||| Utils ||||||||||||||||||||||||||||||||||| --

local M = {}

local fn = vim.fn
local api = vim.api
local cmd = vim.cmd
local map = vim.keymap.set
local opts = { noremap = true, silent = true, buffer = 0 }

-- Select-All
function M.select_all()
  cmd("normal! VGo1G | gg0")
end

-- Trim
function M.trim()
  local save = fn.winsaveview()
  cmd("keeppatterns %s/\\s\\+$//e")
  fn.winrestview(save)
end

-- Toggle-Hover
function M.toggle_lsp_buf_hover()
  if M.close_hover_windows() then return end
  vim.lsp.buf.hover()
end

-- Toggle-Diagnostic-Float
function M.toggle_diagnostic_hover()
  if M.close_hover_windows() then return end
  -- local config = lvim.lsp.diagnostics.float
  -- config.scope = "line"
  vim.diagnostic.open_float()
end

-- Relative Number
function M.toggle_relative_number()
  vim.o.relativenumber = not vim.o.relativenumber
end

-- Hide_Filetype
function M.hide_filetype()
  local ft = { "lazy", "harpoon", "noice",
    --[[ "NvimTree", ]] "toggleterm", "TelescopePrompt" }
  if vim.tbl_contains(ft, vim.bo.filetype)
  then
    api.nvim_buf_set_option(0, 'filetype', '')
  end
end

-- Dashboard
function M.dashboard()
  local bt = vim.bo.buftype
  local ft = vim.bo.filetype
  if M.count_buffers() == 0 and ft == "alpha" then
    return
  end
  if bt == "terminal" then
    cmd("ToggleTerm")
  end
  cmd("Alpha")
end

-- Close-All-Hidden
function M.close_all_hidden()
  local bufnums = vim.api.nvim_list_bufs()
  for _, bufnr in ipairs(bufnums) do
    local bufname = vim.fn.bufname(bufnr)
    local is_term = bufname:match('^term://')
    if is_term and vim.fn.bufwinnr(bufnr) == -1 then
      vim.cmd('bwipeout ' .. bufnr)
    end
  end
end

-- Count-Buffers
function M.count_buffers()
  return vim.tbl_count(vim.tbl_filter(function(bufnr)
    return fn.buflisted(bufnr) == 1
  end, api.nvim_list_bufs()))
end

-- Close
function M.close_buffer()
  local bufnr = fn.bufnr("%")
  return M.count_buffers() == 1 and
      cmd('Alpha | bd ' .. bufnr) or cmd('BufferKill')
end

-- Cwd-Set-Options
function M.cwd_set_options()
  local ft = vim.bo.filetype
  local dir = fn.expand('%:h')
  vim.g.copilot_no_tab_map = true
  vim.o.fo = vim.o.fo:gsub("[cro]", "")
  if ft == "alpha" and M.count_buffers() > 0 then return end
  if fn.isdirectory(dir) and ft ~= "" then fn.chdir(dir) end
end

-- Close-Hover-Windows
function M.close_hover_windows()
  local win_ids = api.nvim_list_wins()
  local floating_wins = vim.tbl_filter(function(win_id)
    local win_config = api.nvim_win_get_config(win_id)
    return win_config.relative ~= ''
  end, win_ids)
  if vim.tbl_isempty(floating_wins) then return false end
  vim.tbl_map(function(bufnr)
    local buftype = api.nvim_buf_get_option(bufnr, 'buftype')
    local filetype = api.nvim_buf_get_option(bufnr, 'filetype')
    if buftype == 'nofile' and filetype ~= 'alpha' then
      api.nvim_buf_delete(bufnr, { force = true })
    end
  end, api.nvim_list_bufs())
  return true
end

-- Special-Keymaps
function M.special_keymaps()
  local bt = vim.bo.buftype
  local ft = vim.bo.filetype
  local bn = fn.bufname("%")
  if bt:match("acwrite") then
    map("n", "|", "<nop>", opts)
  end
  if ft == "alpha" then return end
  if bn:match("lazygit") then
    map("t", "<esc>", "<esc>", opts)
  end
  if bn:match("ranger") then
    map("t", "<esc>", "<cmd>clo!<cr>", opts)
  end
  if bt:match("nofile") then
    map("n", "<esc>", "<cmd>clo!<cr>", opts)
  end
  if bn:match("crunner_") then
    map("n", "<leader>q", "<cmd>RunClose<cr>", opts)
  end
  if bn:match("NvimTree_") then
    map("n", "<leader>;", "<Nop>", opts)
    map("n", "<leader>k", "<cmd>NvimTreeToggle<cr>", opts)
    map("n", "<leader>q", "<cmd>NvimTreeToggle<cr>", opts)
  end
  if vim.tbl_contains({ "qf", "help", "man", "noice" }, ft) then
    map("n", "q", "<cmd>clo!<cr>", opts)
  end
end

-- Jump-Brackets
function M.jump_brackets(dir)
  local pattern = [[(\|)\|\[\|\]\|{\|}\|"\|`\|''\|<\|>]]
  dir = dir == "prev" and "b" or "n"
  local result = fn.eval("searchpos('" .. pattern .. "', '" .. dir .. "')")
  local lnum, col = result[1], result[2]
  fn.setpos('.', { 0, lnum, col, 0 })
end

-- Toggle-Diagnostics
function M.toggle_lsp_diagnostics()
  local bufnr = api.nvim_get_current_buf()
  local diagnostics_hidden = pcall(api.nvim_buf_get_var, bufnr, 'diagnostics_hidden')
      and api.nvim_buf_get_var(bufnr, 'diagnostics_hidden')
  api.nvim_buf_set_var(bufnr, 'diagnostics_hidden', not diagnostics_hidden)
  if diagnostics_hidden then
    vim.diagnostic.show()
    return
  end
  vim.diagnostic.hide()
end

-- Close-Nvim-Tree
function M.close_nvim_tree()
  if M.count_buffers() == 0 and vim.tbl_count(vim.tbl_filter(function(win_id)
        return api.nvim_buf_get_name(api.nvim_win_get_buf(win_id)):match('NvimTree_')
      end, api.nvim_list_wins())) > 0 then
    cmd('NvimTreeToggle')
  end
end

-- Clear-History
function M.clear_history()
  local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-\"*+#"
  for char in chars:gmatch(".") do fn.setreg(char, {}) end
  vim.cmd("messages clear")
  fn.histdel(":")
end

-- Cursor-Column
function M.toggle_cursor_column()
  local success, column_active = pcall(vim.api.nvim_buf_get_var, 0, 'color_column_active')

  if not success then
    column_active = false
  end

  if column_active then
    fn.clearmatches()
    vim.api.nvim_buf_set_var(0, 'color_column_active', false)
  else
    local fg_color = fn.synIDattr(fn.hlID("IncSearch"), "fg#")
    local bg_color = fn.synIDattr(fn.hlID("IncSearch"), "bg#")

    cmd("silent! highlight ColorColumn guifg=" .. fg_color .. " guibg=" .. bg_color)

    local col = fn.col('.')

    fn.matchadd("ColorColumn", "\\%" .. col .. "v.", 100)

    vim.api.nvim_buf_set_var(0, 'color_column_active', true)
  end
end

-- Code-Runner
function M.code_runner()
  local crunner_bufs = vim.tbl_filter(function(buffer)
    return string.match(vim.fn.bufname(buffer), 'crunner_')
  end, vim.api.nvim_list_bufs())
  return #crunner_bufs > 0 and "<cmd>silent! bd " .. crunner_bufs[1] .. "<cr>" or "<cmd>silent! RunCode<cr>"
end

return M
