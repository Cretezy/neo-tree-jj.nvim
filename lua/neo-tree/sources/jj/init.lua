local vim = vim
local utils = require("neo-tree.sources.jj.utils")

local renderer = require("neo-tree.ui.renderer")
local manager = require("neo-tree.sources.manager")
local events = require("neo-tree.events")
local file_items = require("neo-tree.sources.common.file-items")

local M = {
	name = "jj",
	display_name = "󰊢 JJ",
}

---@param path string Path to navigate to. If empty, will navigate to the cwd.
M.navigate = function(state, path, path_to_reveal, callback, _async)
	state.dirty = false
	if path_to_reveal then
		renderer.position.set(state, path_to_reveal)
	end

	if state.loading then
		return
	end
	state.loading = true

	-- Setup state
	state.path = utils.get_repository_root(path) or state.path or vim.fn.getcwd()
	local context = file_items.create_context(state)

	-- Create root folder
	local root = file_items.create_item(context, state.path, "directory")
	root.name = vim.fn.fnamemodify(root.path, ":~")
	root.loaded = true
	root.search_pattern = state.search_pattern
	context.folders[root.path] = root

	-- Create files
	local changes = utils.get_changes(state.path)
	if changes then
		for result_path, status in pairs(changes) do
			local success, item = pcall(file_items.create_item, context, result_path, "file")
			if success then
				item.extra = {
					jj_status = status,
				}
				item.status = status
			else
				error("Error creating item for " .. result_path .. ": " .. item)
			end
		end
	end

	state.jj_status_lookup = changes
	-- Default expanded state
	state.default_expanded_nodes = {}
	for id, _ in pairs(context.folders) do
		table.insert(state.default_expanded_nodes, id)
	end
	-- Sort and show
	file_items.advanced_sort(root.children, state)
	renderer.show_nodes({ root }, state)
	state.loading = false

	if type(callback) == "function" then
		vim.schedule(callback)
	end
end

M.setup = function(config, global_config)
	if config.use_libuv_file_watcher then
		manager.subscribe(M.name, {
			event = events.FS_EVENT,
			handler = M.refresh,
		})
	end

	if global_config.enable_refresh_on_write then
		manager.subscribe(M.name, {
			event = events.VIM_BUFFER_CHANGED,
			handler = function(args)
				if utils.is_real_file(args.afile) then
					M.refresh()
				end
			end,
		})
	end

	if config.bind_to_cwd then
		manager.subscribe(M.name, {
			event = events.VIM_DIR_CHANGED,
			handler = M.refresh,
		})
	end

	-- Configure event handlers for modified files
	if global_config.enable_modified_markers then
		manager.subscribe(M.name, {
			event = events.VIM_BUFFER_MODIFIED_SET,
			handler = utils.wrap(manager.opened_buffers_changed, M.name),
		})
	end
end

M.refresh = function()
	manager.refresh(M.name)
end

return M
