-- init.lua
-- by Briar Schreiber <briarrose@mailbox.org>
--
-- Adds basic note taking features inspired by Obsidian Notes
-- This depends on 'ibhagwan/fzf-lua'.

local M = {}

-- =============================================================================
-- Module-level Variables
-- =============================================================================
local SCRIPT_PATH = nil
local REPO_ROOT = nil

-- =============================================================================
-- Private Helper Functions
-- =============================================================================

--- Finds the plugin's root directory and sets the absolute path to the script.
local function find_script_path()
	if SCRIPT_PATH then
		return SCRIPT_PATH
	end

	-- Get the path of the currently running Lua file
	local plugin_file_path = vim.api.nvim_get_runtime_file("lua/charcoal/init.lua", false)[1]
	if not plugin_file_path then
		vim.notify("Could not determine charcoal-notes plugin path." .. plugin_file_path, vim.log.levels.ERROR)
		return nil
	end

	local plugin_root = vim.fn.fnamemodify(plugin_file_path, ":h:h:h")
	local script_path = plugin_root .. "/bin/charcoal-notes"

	if vim.fn.filereadable(script_path) == 1 and vim.fn.executable(script_path) == 1 then
		SCRIPT_PATH = script_path
		return SCRIPT_PATH
	else
		vim.notify("charcoal-notes script not found or not executable at: " .. script_path, vim.log.levels.ERROR)
		return nil
	end
end

--- Finds the root of the notes repository by searching for the .notes directory.
local function find_repo_root()
	if REPO_ROOT then
		return REPO_ROOT
	end
	if not find_script_path() then
		return nil
	end

	REPO_ROOT = vim.fn.trim(vim.fn.system(SCRIPT_PATH .. " repo-root"))
	if vim.v.shell_error ~= 0 then
		REPO_ROOT = nil
		return nil
	end
	return REPO_ROOT
end

--- Gets the relative path of the current file to the repo root.
-- @return (string|nil) The relative path, or nil if not in a repo.
local function get_current_note_relative_path()
	local root = find_repo_root()
	if not root then
		return nil
	end
	local file_path = vim.fn.expand("%:p")
	return string.gsub(file_path, root .. "/", "", 1)
end

--- Generic fzf picker to show command output using fzf-lua
-- @param opts (table) A table containing:
--   - cmd (string): The shell command to execute.
--   - fzf_opts (table): A table of options to pass directly to fzf-lua.
local function fzf_picker(opts)
	local fzf = require("fzf-lua")
	if not find_script_path() then
		return
	end

	local full_command = SCRIPT_PATH .. " " .. opts.cmd
	fzf.fzf_exec(full_command, opts.fzf_opts)
end

-- =============================================================================
-- Public API Functions (called by commands and keymaps)
-- =============================================================================

--- Shows backlinks for the current note in the quickfix list.
function M.show_backlinks()
	local note_path = get_current_note_relative_path()
	if not note_path then
		vim.notify("Not in a charcoal-notes repository.", vim.log.levels.WARN)
		return
	end

	local root = find_repo_root()
	if not root then
		return
	end

	fzf_picker({
		cmd = 'backlinks "' .. note_path .. '"',
		fzf_opts = {
			prompt = "Backlinks> ",
			actions = {
				["default"] = function(selected)
					if #selected > 0 then
						vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. selected[1] .. ".md"))
					end
				end,
			},
		},
	})
end

--- Shows outgoing links for the current note in the quickfix list.
function M.show_links()
	local note_path = get_current_note_relative_path()
	if not note_path then
		vim.notify("Not in a charcoal-notes repository.", vim.log.levels.WARN)
		return
	end

	local root = find_repo_root()
	if not root then
		return
	end

	fzf_picker({
		cmd = 'links "' .. note_path .. '"',
		fzf_opts = {
			prompt = "Links> ",
			actions = {
				["default"] = function(selected)
					if #selected > 0 then
						vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. selected[1] .. ".md"))
					end
				end,
			},
		},
	})
end

function M.show_notes()
	local root = find_repo_root()
	if not root then
		vim.notify("Not in a charcoal-notes repository.", vim.log.levels.WARN)
		return
	end

	fzf_picker({
		cmd = "list",
		fzf_opts = {
			prompt = "Notes> ",
			actions = {
				["default"] = function(selected, fzf_input)
					if #selected > 0 then
						vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. selected[1] .. ".md"))
					elseif fzf_input and fzf_input.query and fzf_input.query ~= "" then
						local new_note_path = root .. "/" .. fzf_input.query .. ".md"
						vim.cmd("edit " .. vim.fn.fnameescape(new_note_path))
					end
				end,
			},
		},
	})
end

--- Shows all notes with a specific tag.
function M.show_tagged_notes(tag)
	local root = find_repo_root()
	if not root then
		vim.notify("Not in a charcoal-notes repository.", vim.log.levels.WARN)
		return
	end

	fzf_picker({
		cmd = 'find "' .. tag .. '"',
		fzf_opts = {
			prompt = "Notes> ",
			actions = {
				["default"] = function(selected)
					if #selected > 0 then
						vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. selected[1] .. ".md"))
					end
				end,
			},
		},
	})
end

--- Shows all tags, and on selection, shows notes with that tag.
function M.show_tags()
	fzf_picker({
		cmd = "tags",
		fzf_opts = {
			prompt = "Tag> ",
			actions = {
				["default"] = function(selected)
					if #selected > 0 then
						M.show_tagged_notes(selected[1])
					end
				end,
			},
		},
	})
end

--- Inserts a wikilink, respecting the current mode.
function M.insert_link()
	local initial_mode = vim.api.nvim_get_mode().mode

	fzf_picker({
		cmd = "list",
		fzf_opts = {
			prompt = "Note to link> ",
			actions = {
				["default"] = function(selected)
					if #selected > 0 then
						local link = "[[" .. selected[1] .. "]]"

						vim.api.nvim_put({ link }, "c", true, true)

						if initial_mode == "i" then
							vim.api.nvim_feedkeys("a", "n", false)
						end
					end
				end,
			},
		},
	})
end

--- Overrides 'gf' to handle [[wikilinks]].
function M.goto_file_wikilink()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]

	-- Find the text within [[...]] under the cursor
	local link_match = nil
	for match in string.gmatch(line, "%[%[([^%]]+)%]%]") do
		local start_pos = string.find(line, match, 1, true) - 2 -- account for [[
		local end_pos = start_pos + #match + 3 -- account for ]]
		if col >= start_pos and col <= end_pos then
			link_match = match
			break
		end
	end

	if link_match then
		local root = find_repo_root()
		if not root then
			vim.notify("Not in a charcoal-notes repository.", vim.log.levels.WARN)
			return
		end

		local target_path = root .. "/" .. link_match
		if not target_path:find("%.md$") then
			target_path = target_path .. ".md"
		end

		if vim.fn.filereadable(target_path) == 1 then
			vim.cmd("edit " .. vim.fn.fnameescape(target_path))
		else
			vim.notify("Note not found: " .. link_match .. ".md", vim.log.levels.WARN)
		end
	else
		local success, err = pcall(vim.cmd.normal, "gf", { silent = true })
		if not success then
			vim.notify("No file name under cursor.", vim.log.levels.WARN)
		end
	end
end

-- =============================================================================
-- Setup Function
-- =============================================================================

--- The main setup function to create commands and keymaps.
function M.setup()
	-- User Commands
	vim.api.nvim_create_user_command("CharcoalBacklinks", M.show_backlinks, {})
	vim.api.nvim_create_user_command("CharcoalLinks", M.show_links, {})
	vim.api.nvim_create_user_command("CharcoalEdit", M.show_notes, {})
	vim.api.nvim_create_user_command("CharcoalTags", M.show_tags, {})
	vim.api.nvim_create_user_command("CharcoalInsertLink", M.insert_link, {})
	vim.api.nvim_create_user_command("CharcoalGotoLink", M.goto_file_wikilink, {})

	vim.api.nvim_create_user_command("CharcoalIndex", function()
		if find_script_path() then
			vim.cmd("silent !" .. SCRIPT_PATH .. " index")
		end
	end, {})

	-- Autocommands
	local note_cli_group = vim.api.nvim_create_augroup("CharcoalCliAu", { clear = true })
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = note_cli_group,
		pattern = "*.md", -- Only run for markdown files
		callback = function(args)
			if find_script_path() and find_repo_root() then
				vim.fn.jobstart(SCRIPT_PATH .. ' index-file "' .. args.file .. '"', { detach = true })
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = note_cli_group,
		pattern = "*.md",
		callback = function(args)
			if find_script_path() and find_repo_root() and vim.loop.fs_stat(args.file) == nil then
				vim.fn.jobstart(SCRIPT_PATH .. ' index-file "' .. args.file .. '"', { detach = true })
			end
		end,
	})

	vim.notify("Charcoal-Notes integration loaded.", vim.log.levels.INFO)
end

return M
