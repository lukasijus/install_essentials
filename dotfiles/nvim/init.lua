-----------------------------------------------------------
-- 1. Global Options & Leader
-----------------------------------------------------------
vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"
vim.opt.guicursor = {
	"n-v-c:block-blinkon500-blinkoff500",
	"i-ci-ve:ver25-blinkon500-blinkoff500",
	"r-cr-o:hor20-blinkon500-blinkoff500",
	"a:blinkwait700",
}

-----------------------------------------------------------
-- 2. Plugin Manager (lazy.nvim)
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		"L-Colombo/oldschool.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
		config = function(_, opts)
			require("oldschool").setup(opts)
			vim.cmd.colorscheme("oldschool")
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				theme = "oldschool",
				icons_enabled = true,
				component_separators = "|",
				section_separators = "",
			},
		},
	},
	{ "nvim-tree/nvim-web-devicons", opts = { default = true } },
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			ensure_installed = { "lua", "python", "javascript", "typescript", "vue", "json" },
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
			indent = { enable = true },
		},
	},
	{ "nvim-tree/nvim-tree.lua", opts = {} },
	{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
	{ "neovim/nvim-lspconfig" },
	{ "williamboman/mason.nvim", opts = {} },
	{ "williamboman/mason-lspconfig.nvim", opts = { ensure_installed = { "pyright", "ts_ls", "vue_ls" } } },
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			vim.opt.completeopt = { "menu", "menuone", "noselect" }

			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				completion = {
					autocomplete = false,
				},
				sorting = {
					priority_weight = 2,
					comparators = {
						require("cmp.config.compare").offset,
						require("cmp.config.compare").exact,
						require("cmp.config.compare").score,
						require("cmp.config.compare").kind,
						require("cmp.config.compare").sort_text,
						require("cmp.config.compare").length,
						require("cmp.config.compare").order,
					},
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = {
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				},
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				python = { "black" },
				lua = { "stylua" },
				javascript = { "prettierd" },
				typescript = { "prettierd" },
				vue = { "prettierd" },
			},
			format_on_save = { timeout_ms = 500, lsp_fallback = true },
		},
	},
}, {
	rocks = { enabled = false },
})

-----------------------------------------------------------
-- 3. Native LSP Configuration (Neovim 0.11+ API)
-----------------------------------------------------------
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local vue_plugin = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

vim.lsp.config("pyright", {
	capabilities = capabilities,
	settings = { python = { analysis = { typeCheckingMode = "basic", diagnosticMode = "openFilesOnly" } } },
})
vim.lsp.enable("pyright")

vim.lsp.config("vue_ls", {
	capabilities = capabilities,
	filetypes = { "vue" },
})
vim.lsp.enable("vue_ls")

vim.lsp.config("ts_ls", {
	capabilities = capabilities,
	filetypes = { "javascript", "typescript", "vue" },
	init_options = {
		plugins = { { name = "@vue/typescript-plugin", location = vue_plugin, languages = { "vue" } } },
	},
})
vim.lsp.enable("ts_ls")

-----------------------------------------------------------
-- 4. Keymaps & Diagnostics
-----------------------------------------------------------
local map = vim.keymap.set
map("n", "gl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>")
map("n", "<leader>ff", function()
	require("telescope.builtin").find_files()
end)
map("n", "<leader>fg", function()
	require("telescope.builtin").live_grep()
end, { desc = "Grep text in files" })
map("n", "<leader>fw", function()
	require("telescope.builtin").grep_string()
end, { desc = "Grep word under cursor" })

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local opts = { buffer = ev.buf }
		map("n", "gd", vim.lsp.buf.definition, opts)
		map("n", "K", vim.lsp.buf.hover, opts)
		map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
		map("n", "<leader>rn", vim.lsp.buf.rename, opts)
	end,
})

vim.diagnostic.config({ virtual_text = false, underline = true, severity_sort = true })

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python", "lua", "vue", "javascript", "typescript" },
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})

vim.keymap.set("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprev<CR>", { desc = "Previous buffer" })
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99
vim.opt.foldenable = true
