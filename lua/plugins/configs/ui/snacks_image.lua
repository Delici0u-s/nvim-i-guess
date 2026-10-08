-- Extensions to snacks.image inline (document) rendering. snacks has no public
-- API for these, so they wrap methods of the internal `snacks.image.inline`
-- class; if a snacks update breaks toggling or live preview, look here.
--
-- * vim.g.markdown_images_off  -- hide all inline images (<C-R>m, render_markdown.lua)
-- * vim.g.markdown_live_off    -- disable live preview (<C-R>l)
--
-- Live preview: upstream hides a concealed image while the cursor is inside
-- its source. Instead, switch that placement to non-concealed so snacks draws
-- it as virtual lines below the source, and restore it when the cursor leaves.

local M = {}

---@type table<number, snacks.image.inline>
local instances = {}

---@param img snacks.image.Placement
---@param live boolean
local function set_live(img, live)
	if (img._live or false) == live then
		return
	end
	img._live = live or nil
	img.opts.conceal = not live
	img.hidden = false
	img._state = nil -- force a re-render; conceal isn't part of the state diff
	img:update()
end

---@param buf number
---@param range? number[] 1-indexed {row, col, end_row, end_col}
local function cursor_in(buf, range)
	if not range or buf ~= vim.api.nvim_get_current_buf() then
		return false
	end
	local from, to = vim.fn.line("v"), vim.fn.line(".")
	return range[1] <= math.max(from, to) and range[3] >= math.min(from, to)
end

function M.setup()
	local inline = require("snacks.image.inline")
	local placement = require("snacks.image.placement")

	-- Editing a source (typing in a link/$math$) changes its src, so snacks
	-- creates a fresh placement on every keystroke. Start it live if the
	-- cursor is in it, otherwise it overlays the text being typed.
	-- Small images (inline $math$) render as inline virtual text anchored at
	-- the start of their source. While live, anchor it after the source so
	-- the preview reads `$x^2$ x²` instead of `x² $x^2$`.
	local placement_render = placement._render
	placement._render = function(self, extmarks)
		if self._live then
			for _, e in ipairs(extmarks) do
				if e.virt_text_pos == "inline" and e.end_row then
					e.row, e.col = e.end_row, e.end_col
					e.end_row, e.end_col = nil, nil
					e.virt_text = vim.list_extend({ { " " } }, e.virt_text or {}) -- gap after source
				end
			end
		end
		return placement_render(self, extmarks)
	end

	local placement_new = placement.new
	placement.new = function(buf, src, opts)
		local live = opts and opts.inline and opts.conceal and not vim.g.markdown_live_off and cursor_in(buf, opts.range)
		if live then
			opts.conceal = false
		end
		local img = placement_new(buf, src, opts)
		img._live = live or nil
		return img
	end

	local inline_new = inline.new
	inline.new = function(buf)
		local self = inline_new(buf)
		instances[buf] = self
		-- upstream only re-evaluates on CursorMoved/ModeChanged; keep the
		-- preview following the cursor while typing too.
		vim.api.nvim_create_autocmd({ "CursorMovedI", "TextChangedI" }, {
			group = vim.api.nvim_create_augroup("snacks.image.live." .. buf, { clear = true }),
			buffer = buf,
			callback = function()
				if buf == vim.api.nvim_get_current_buf() then
					vim.schedule(function()
						self:conceal()
					end)
				end
			end,
		})
		vim.api.nvim_create_autocmd("BufWipeout", {
			buffer = buf,
			once = true,
			callback = function()
				instances[buf] = nil
			end,
		})
		return self
	end

	local inline_update = inline.update
	inline.update = function(self)
		if vim.g.markdown_images_off then
			for _, img in pairs(self.imgs) do
				img:close()
			end
			self.imgs, self.idx = {}, {}
			return
		end
		return inline_update(self)
	end

	local inline_conceal = inline.conceal
	inline.conceal = function(self)
		if vim.g.markdown_live_off then
			for _, img in pairs(self.imgs) do
				set_live(img, false)
			end
			return inline_conceal(self)
		end

		-- Match on the source range, not on extmarks (upstream uses
		-- self:get): a live image's extmarks sit only on the source's last
		-- line, so the cursor on its first line would flip it back.
		local mode = vim.fn.mode():sub(1, 1):lower()
		local reveal = not vim.wo.concealcursor:find(mode)
		for _, img in pairs(self.imgs) do
			img:show()
			if img._live or img.opts.conceal then
				local r = img.opts.range or { img.opts.pos[1], 0, img.opts.pos[1], 0 }
				set_live(img, reveal and cursor_in(self.buf, r))
			end
		end
	end
end

--- Re-run inline rendering for every visible buffer with images attached.
function M.refresh()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.b[buf].snacks_image_attached then
			vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = buf })
			local self = instances[buf]
			if self and buf == vim.api.nvim_get_current_buf() then
				vim.schedule(function()
					self:conceal()
				end)
			end
		end
	end
end

return M
