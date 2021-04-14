-- local Job = require("plenary.job")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
-- local actions = require("telescope.actions")
-- local action_set = require("telescope.actions.set")
-- local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
-- local gwt = require("git-worktree")

-- local get_worktree_path = function(prompt_bufnr)
--     local selection = action_state.get_selected_entry(prompt_bufnr)
--     local worktree_path = nil
--     for section in selection[1]:gmatch("%[(.*)%]") do
--         worktree_path = section
--     end
--     return worktree_path
-- end

local telescope_zk_list = function(opts)
  opts = opts or {}
  pickers.new(
    {},
    {
      prompt_prefix = "zk notes ",
      finder = finders.new_oneshot_job(
        vim.tbl_flatten(
          {
            "zk",
            "list"
          }
        ),
        opts
      ),
      sorter = conf.generic_sorter({})
      -- attach_mappings = function(_, map)
      --   -- Switch to chosen worktree
      --   action_set.select:replace(
      --     function(prompt_bufnr, type)
      --       local worktree_path = get_worktree_path(prompt_bufnr)
      --       actions.close(prompt_bufnr)
      --       if worktree_path ~= nil then
      --         gwt.switch_worktree(worktree_path)
      --       end
      --     end
      --   )
      --   -- Delete chosen worktree
      --   map(
      --     "i",
      --     "<c-d>",
      --     function(prompt_bufnr)
      --       local worktree_path = get_worktree_path(prompt_bufnr)
      --       actions.close(prompt_bufnr)
      --       if worktree_path ~= nil then
      --         gwt.delete_worktree(worktree_path)
      --       end
      --     end
      --   )
      --   -- Force delete chosen worktree
      --   map(
      --     "i",
      --     "<c-D>",
      --     function(prompt_bufnr)
      --       local worktree_path = get_worktree_path(prompt_bufnr)
      --       actions.close(prompt_bufnr)
      --       if worktree_path ~= nil then
      --         gwt.delete_worktree(worktree_path, true)
      --       end
      --     end
      --   )
      --   -- TODO Create chosen worktree
      --   return true
      -- end
    }
  ):find()
end

return require("telescope").register_extension(
  {
    exports = {
      notes = telescope_zk_list
    }
  }
)
