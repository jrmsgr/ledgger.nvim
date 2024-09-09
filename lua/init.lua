local Path = require("plenary.path")
local builtin = require("telescope.builtin")
local a = vim.api
local ledgger = {}

function ledgger.init_highlight_group()
	for i = 0, 5, 1 do
		vim.cmd("syn match @markup.heading." .. (i + 1) .. ".markdown /\\(\\s\\s\\)\\{" .. i .. "\\}.*/")
	end
end

function ledgger.setup(opts)
	opts = opts or {}
	local note_dir = opts.note_dir or "~/.local/notes"
	ledgger.max_txt_len = opts.max_len or 20
	note_dir = Path:new(Path:new(note_dir):expand())
	if note_dir:is_file() then
		vim.nvim_notify(note_dir .. " is not a directory!", vim.log.levels.ERROR)
		return
	end
	note_dir:mkdir({ exists_ok = true, parents = true })
	ledgger.note_dir = note_dir

	a.nvim_create_user_command("Ledgger", ledgger.open_head_note, { desc = "Open ledgger note" })
	a.nvim_create_user_command("LedggerList", ledgger.list_notes, { desc = "List ledgger notes" })
	-- display notes with the correct highlights
	a.nvim_create_autocmd("BufReadPost", {
		pattern = note_dir.filename .. "/*",
		callback = function()
			ledgger.init_highlight_group()
		end,
	})
end

function ledgger.list_notes()
	builtin.find_files({ cwd = ledgger.note_dir.filename, search_file = "*.txt" })
end

function ledgger.open_head_note()
	local head_note = ledgger.note_dir / "head.txt"
	local daily_note = os.date("%Y_%m_%d") .. ".txt"
	daily_note = ledgger.note_dir / daily_note
	vim.cmd("noswapfile e " .. head_note.filename)
	local bufnr = a.nvim_get_current_buf()
	a.nvim_create_autocmd("BufWritePost", {
		buffer = bufnr,
		callback = function()
			vim.cmd("silent w! " .. daily_note.filename)
		end,
	})
end

return ledgger
