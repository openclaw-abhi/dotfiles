-- ==========================================================================
--  NEOVIM CONFIGURATION (Neovim 0.11.5+ | Arch Linux)
-- ==========================================================================

-- [0] PRE-SETUP & PROVIDERS
-- --------------------------------------------------------------------------
-- Disable legacy external providers for speed
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0

-- Set Leader Key (Space)
vim.g.mapleader = " "

-- [1] GENERAL SETTINGS
-- --------------------------------------------------------------------------
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.ignorecase = true -- Ignore case when searching...
vim.opt.smartcase = true -- ...unless capital letters are used
vim.opt.updatetime = 250 -- Faster completion/updates
vim.opt.signcolumn = "yes" -- Always show sign column (prevents jumping)
vim.opt.termguicolors = true -- True color support

-- [2] CLIPBOARD (OSC 52)
-- --------------------------------------------------------------------------
-- Allows copying to system clipboard over SSH/TMUX
vim.g.clipboard = {
	name = "OSC 52",
	copy = {
		["+"] = require("vim.ui.clipboard.osc52").copy("+"),
		["*"] = require("vim.ui.clipboard.osc52").copy("*"),
	},
	paste = {
		["+"] = require("vim.ui.clipboard.osc52").paste("+"),
		["*"] = require("vim.ui.clipboard.osc52").paste("*"),
	},
}
vim.opt.clipboard = "unnamedplus"

-- [3] DIAGNOSTICS UI
-- --------------------------------------------------------------------------
-- Configures how errors/warnings are displayed in the editor
vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
		spacing = 4,
	},
	signs = true,
	underline = true,
	update_in_insert = true, -- Update errors while typing
	severity_sort = true,
})

-- [4] PACKAGE MANAGER (LAZY.NVIM)
-- --------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- [5] PLUGINS
-- --------------------------------------------------------------------------
require("lazy").setup({

	-- 5.1 THEME (Catppuccin)
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
				integrations = { cmp = true, native_lsp = true, treesitter = true },
			})
			vim.cmd.colorscheme("catppuccin")
		end,
	},

	-- 5.2 SYNTAX HIGHLIGHTING (Treesitter)
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			-- Install parsers
			require("nvim-treesitter").install({ "python", "markdown", "lua" })

			-- Enable highlighting, indentation, and folding for specific filetypes
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "python", "lua", "c", "vim" },
				callback = function()
					vim.treesitter.start()
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					vim.wo.foldmethod = "expr"
					vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				end,
			})
		end,
	},

	-- 5.3 LSP CONFIGURATION (0.11 Native)
	{
		"neovim/nvim-lspconfig",
		config = function()
			-- Configure Pylsp (Python)
			vim.lsp.config("pylsp", {
				settings = {
					pylsp = {
						plugins = {
							-- Disable standard tools to prefer Ruff
							pycodestyle = { enabled = false },
							pyflakes = { enabled = false },
							mccabe = { enabled = false },
							ruff = { enabled = true, formatEnabled = false },
						},
					},
				},
			})

			-- Enable the Server
			vim.lsp.enable("pylsp")

			-- LSP Keybindings (Attached automatically when LSP loads)
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local opts = { buffer = args.buf }
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts) -- Go to Definition
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts) -- Hover Documentation
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- Rename Symbol
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts) -- Code Action
				end,
			})
		end,
	},

	-- 5.4 AUTOCOMPLETION
	{
		"hrsh7th/nvim-cmp",
		dependencies = { "hrsh7th/cmp-nvim-lsp" },
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				sources = { { name = "nvim_lsp" } },
				mapping = cmp.mapping.preset.insert({
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping.select_next_item(),
				}),
			})
		end,
	},

	-- 5.5 FORMATTING
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		opts = {
			formatters_by_ft = {
				-- Python: Fix errors -> Organize Imports -> Format
				python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
				lua = { "stylua" },
				toml = { "taplo" },
				yaml = { "yamlfmt" },
			},
			format_on_save = { timeout_ms = 500, lsp_fallback = true },
		},
	},
}, {
	-- Lazy Options
	rocks = { enabled = false },
})

-- [6] CUSTOM KEYBINDINGS
-- --------------------------------------------------------------------------

-- Format Current Buffer (<Space>f)
vim.keymap.set("n", "<leader>f", function()
	require("conform").format({ async = false, lsp_fallback = true })
	print("Formatted!")
end, { desc = "Format current buffer" })

-- Run Python File (<Space>r)
-- Process: Save -> Open bottom split -> Run 'uv run file'
vim.keymap.set("n", "<leader>r", function()
	vim.cmd("write")
	vim.cmd("botright 15split") -- Open 15-line high horizontal split at bottom
	vim.cmd("wincmd j") -- Focus new window

	-- Run using vim.fn.expand("%") to get current filename
	vim.cmd("term uv run " .. vim.fn.expand("%"))
	vim.cmd("startinsert") -- Enter insert mode immediately
end, { desc = "Run Python file with uv" })

-- Quick Close Window (<Space>q)
vim.keymap.set("n", "<leader>q", vim.cmd.q, { desc = "Close current window" })

-- [7] AUTO-COMMANDS
-- --------------------------------------------------------------------------

-- Auto-Save on Focus Lost or Buffer Leave
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
	pattern = "*",
	command = "silent! wall",
})

-- ==========================================================================
--  ARCH LINUX SETUP INSTRUCTIONS
-- ==========================================================================
-- To ensure all tools (formatters, parsers) work correctly on this machine,
-- run the following command in your terminal once:
--
-- sudo pacman -S tree-sitter-cli stylua taplo-cli yamlfmt
--
-- Note: 'tree-sitter-cli' is required for compiling parsers.
--       The others are system-native formatters for speed.
-- ==========================================================================
