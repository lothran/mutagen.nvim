local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values

local M = {}

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
  local mut = require("mutagen")
  local sync = mut.sync_list()
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

