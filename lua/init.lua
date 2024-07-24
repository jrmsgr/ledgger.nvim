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

	ledgger.configure_gitlab_ls(opts)
end

function ledgger.configure_gitlab_ls(opts)
	local opts = opts or {}
	local cmp = require("cmp")
	cmp.event:on("confirm_done", function(evt)
		if evt.entry.source.name == "nvim_lsp" then
			if evt.entry.source.source.client.name == "gitlab-ls" then
				local line = evt.entry.source_insert_range.start.line
				local start_col = evt.entry.source_insert_range.start.character - 1
				local end_col = start_col + string.len(evt.entry.completion_item.label)
				local text = string.match(evt.entry.completion_item.label, "^[^ ]+")
				local prefix = string.sub(text, 1, 1)
				vim.api.nvim_buf_set_text(0, line, start_col, line, end_col, {
					evt.entry.source.source.client.config.init_options.url
						.. "/"
						.. evt.entry.completion_item.labelDetails.detail
						.. "/-/"
						.. ((prefix == "!") and "merge_requests/" or "issues/")
						.. string.sub(text, 2, -1),
				})
			end
		end
	end)
	vim.api.nvim_create_autocmd("BufReadPost", {
		pattern = ledgger.note_dir.filename .. "/*",
		callback = function()
			if not ledgger.gitlab_ls_client then
				ledgger.gitlab_ls_client = vim.lsp.start_client(opts)
				if not ledgger.gitlab_ls_client then
					vim.notify("Failed to start gitlab-ls", vim.log.levels.ERROR, {})
				end
				vim.api.nvim_set_hl(0, "CmpItemKindText", { link = "DiagnosticError" })
				vim.api.nvim_set_hl(0, "CmpItemKindMethod", { link = "DiagnosticOk" })
			end
			vim.lsp.buf_attach_client(0, ledgger.gitlab_ls_client)
			cmp.setup.buffer({
				formatting = {
					format = function(_, vim_item)
						local prefix = (vim_item.kind == "Method") and "" or ""
						if string.len(vim_item.word) > ledgger.max_txt_len then
							vim_item.abbr = string.sub(vim_item.word, 1, ledgger.max_txt_len) .. "..."
						end
						vim_item.kind = string.format("%s %s", prefix, vim_item.menu) -- This concatenates the icons with the name of the item kind
						vim_item.menu = ""
						return vim_item
					end,
				},
			})
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
