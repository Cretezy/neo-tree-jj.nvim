local vim = vim
local utils = require("neo-tree.utils")
local highlights = require("neo-tree.ui.highlights")
local log = require("neo-tree.log")
local Job = require("plenary.job")

---@param cmd table
---@param cwd string|nil
---@return table, number, table
local function get_os_command_output(cmd, cwd)
	if type(cmd) ~= "table" then
		error("get_os_command_output: cmd has to be a table")
	end

	local command = table.remove(cmd, 1)
	local stderr = {}
	local stdout, ret = Job:new({
		command = command,
		args = cmd,
		cwd = cwd,
		on_stderr = function(_, data)
			table.insert(stderr, data)
		end,
	}):sync()

	return stdout, ret, stderr
end

local M = {
	wrap = utils.wrap,
	is_real_file = utils.is_real_file,
}

--- Get jj repository root
---@param path string|nil
---@return string|nil
function M.get_repository_root(path)
	local jj_root, ret = get_os_command_output({ "jj", "root" }, path)
	if ret ~= 0 or not utils.truthy(jj_root) then
		log.trace("JJ ROOT ERROR")
		return nil
	end
	jj_root = jj_root[1]

	log.trace("JJ ROOT for '", path, "' is '", jj_root, "'")
	return jj_root
end

--- Get table of changes and their status
---@param root string
---@return { [string]: 'A' | 'M' | 'D'}|nil
function M.get_changes(root)
	local cmd_result, ret = get_os_command_output({ "jj", "diff", "--summary", "--no-pager" }, root)

	if ret ~= 0 then
		log.trace("JJ DIFF ERROR ", cmd_result)
		return nil
	end

	if not utils.truthy(cmd_result) then
		return {}
	end

	local results = {}
	for _, str in ipairs(cmd_result) do
		local status, result_path = string.match(str, "^(.) (.*)")
		results[utils.path_join(root, result_path)] = status
	end

	log.trace("JJ DIFF for '", root, "' is ", vim.inspect(results))

	return results
end

--- Get hightlight/symbol for changes
function M.get_jj_status(config, node, state)
	local jj_status_lookup = state.jj_status_lookup
	if config.hide_when_expanded and node.type == "directory" and node:is_expanded() then
		return {}
	end
	if not jj_status_lookup then
		return {}
	end
	local jj_status = jj_status_lookup[node.path]
	if not jj_status then
		return {}
	end

	local symbols = config.symbols or {}
	local change_symbol
	local change_highlt = highlights.FILE_NAME
	local status_symbol = symbols.staged
	local status_highlt = highlights.GIT_STAGED
	if node.type == "directory" and jj_status:len() == 1 then
		status_symbol = nil
	end

	if jj_status:match("M") then
		change_symbol = symbols.modified
		change_highlt = highlights.GIT_MODIFIED
	elseif jj_status:match("A") then
		change_symbol = symbols.added
		change_highlt = highlights.GIT_ADDED
	elseif jj_status:match("D") then
		change_symbol = symbols.deleted
		change_highlt = highlights.GIT_DELETED
	end

	if change_symbol or status_symbol then
		local components = {}
		if type(change_symbol) == "string" and #change_symbol > 0 then
			table.insert(components, {
				text = change_symbol,
				highlight = change_highlt,
			})
		end
		if type(status_symbol) == "string" and #status_symbol > 0 then
			table.insert(components, {
				text = status_symbol,
				highlight = status_highlt,
			})
		end
		return components
	else
		return {
			text = jj_status,
			highlight = config.highlight or change_highlt,
		}
	end
end

return M
