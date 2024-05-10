-- This file contains the built-in components. Each componment is a function
-- that takes the following arguments:
--      config: A table containing the configuration provided by the user
--              when declaring this component in their renderer config.
--      node:   A NuiNode object for the currently focused node.
--      state:  The current state of the source providing the items.
--
-- The function should return either a table, or a list of tables, each of which
-- contains the following keys:
--    text:      The text to display for this item.
--    highlight: The highlight group to apply to this text.

local vim = vim
local utils = require("neo-tree.sources.jj.utils")

local highlights = require("neo-tree.ui.highlights")
local common = require("neo-tree.sources.common.components")

local M = {}

function M.name(config, node, state)
	local highlight = config.highlight or highlights.FILE_NAME_OPENED
	local name = node.name
	if node.type == "directory" then
		if node:get_depth() == 1 then
			highlight = highlights.ROOT_NAME
			if node:has_children() then
				name = "JJ STATUS for " .. name
			else
				name = "JJ STATUS (working tree clean) for " .. name
			end
		else
			highlight = highlights.DIRECTORY_NAME
		end
		-- TODO: use config
	elseif true or config.use_git_status_colors then
		local jj_status = utils.get_jj_status({}, node, state)
		if jj_status and jj_status.highlight then
			highlight = jj_status.highlight
		end
	end
	return {
		text = name,
		highlight = highlight,
	}
end

return vim.tbl_deep_extend("force", common, M)
