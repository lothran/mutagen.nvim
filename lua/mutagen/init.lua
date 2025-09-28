local M = {}

function M.parse_sync_list(lines)
  local name = nil
  local sessions = {}
  local url_beta = nil
  local url_alpha = nil
  local con_beta = nil
  local con_alpha = nil
  local ident = nil
  local is_beta = false

  for _, line in ipairs(lines) do
    local n = line:match("^Name: (.*)")
    if n then
      name = n
    end
    local i = line:find("^Identifier: (.*)")
    if i then
      ident = i
    end
    local b = line:find("^Beta:")
    if b then
      is_beta = true
    end
    local u = line:match("URL: (.*)")
    if u then
      if is_beta then
        url_beta = u
      else
        url_alpha = u
      end
    end
    local c = line:match("Connected: (.*)")
    if c then
      if is_beta then
        con_beta = c
      else
        con_alpha = c
      end
    end
    local s = line:match("^Status: (.*)")
    if s then
      table.insert(sessions, {
        name = name,
        identifier = ident,
        status = s,
        alpha = {
          url = url_alpha,
          connected = con_alpha,
        },
        beta = {
          url = url_beta,
          connected = con_beta,
        }
      })
      is_beta = false
    end
  end
  return sessions
end

function M.sync_list()
  local lines = vim.fn.systemlist("mutagen sync list")
  return M.parse_sync_list(lines)
end

function M.sync_connected(sync)
  return sync['beta']['connected'] == "Yes" and sync['alpha']['connected'] == "Yes"
end

function M.setup(opts)
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    callback = function(opt)
      local path = vim.fn.expand('%:p')
      local sync_done = function(res)
        local lines = vim.split(res.stdout, "\n")
        local sessions = M.parse_sync_list(lines)
        for _, session in ipairs(sessions) do
          if vim.startswith(path, session.alpha.url) or vim.startswith(path, session.beta.url) then
            vim.system({ "mutagen", "sync", "flush", session.name }, { text = true },
              function(_)
              end)
          end
        end
      end
      vim.system({ "mutagen", "sync", "list" }, {}, sync_done)
    end,
  })
end

function M.sync_find()
  local sessions = M.sync_list()
  local path = vim.fn.getcwd()
  for _, session in ipairs(sessions) do
    if vim.startswith(path, session.alpha.url) or vim.startswith(path, session.beta.url) then
      return session
    end
  end
  return nil
end

local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values


function M.sync_terminate(prompt_bufnr)
  actions.close(prompt_bufnr)
  local name = action_state.get_selected_entry().value
  vim.system({ "mutagen", "sync", "terminate", name }, {}, function() end):wait(10)
end

function M.sync_flush(prompt_bufnr)
  actions.close(prompt_bufnr)
  name = action_state.get_selected_entry().value
  vim.system({ "mutagen", "sync", "flush", name }, {}, function() end):wait(10)
end

function M.telescope_list_syncs(opts)
  local opts = {}
  local sync = M.sync_list()
  pickers.new(opts, {
    prompt_title = "syncs",
    finder = finders.new_table {
      results = sync,
      entry_maker = function(entry)
        local value = entry.name .. " status: " .. entry.status
        return {
          value = entry.name,
          display = value,
          ordinal = entry.name,
        }
      end,
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(M.sync_flush)
      modes = { "n", "i", "v" }
      map("n", "<C-t>", M.sync_terminate)
      map("i", "<C-t>", M.sync_terminate)
      return true
    end,

    sorter = conf.generic_sorter(opts),
  }):find()
end

return M
