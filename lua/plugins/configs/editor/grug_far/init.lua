-- grug-far: search and replace with a live preview, in one file or the whole
-- project (ripgrep). Keys: grug_far/keymaps.lua.
return function()
	require("grug-far").setup({
		-- Search from the first typed char (default 2). maxSearchMatches still
		-- caps a 1-char project search.
		minSearchChars = 1,
	})
end
