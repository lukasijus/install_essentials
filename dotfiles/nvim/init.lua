-----------------------------------------------------------
-- 1. Global Options & Leader
-----------------------------------------------------------
vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"
vim.opt.guicursor = {
	"n-v-c:block100-Cursor-blinkwait700-blinkon700-blinkoff700",
	"i-ci-ve:block-iCursor-blinkwait70-blinkon70-blinkoff70",
	"r-cr-o:hor20-Cursor-blinkwait700-blinkon700-blinkoff700",
}

local function apply_cursor_highlights()
	vim.api.nvim_set_hl(0, "Cursor", { fg = "#ffffff", bg = "#d80040" })
	vim.api.nvim_set_hl(0, "iCursor", { fg = "#ffffff", bg = "#0099DD" })
	vim.api.nvim_set_hl(0, "lCursor", { fg = "#ffffff", bg = "#0057d8" })
end

apply_cursor_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = apply_cursor_highlights,
})

-----------------------------------------------------------
-- 2. Plugin Manager (lazy.nvim)
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

vim.filetype.add({
	extension = {
		plantuml = "plantuml",
		pu = "plantuml",
		puml = "plantuml",
	},
})

require("lazy").setup({
	{ "aklt/plantuml-syntax", ft = { "plantuml" } },
	{
		"goropikari/plantuml.nvim",
		dependencies = {
			"goropikari/LibDeflate.nvim",
		},
		opts = {
			-- default opts
			base_url = "https://www.plantuml.com/plantuml",
			reload_events = { "BufWritePre" },
			viewer = "xdg-open", -- Image viewer for non-ASCII exports
			docker_image = "plantuml/plantuml-server:tomcat",
		},
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {},
	},
	-- cyberdream Theme
	{
		"scottmckendry/cyberdream.nvim",
		lazy = false,
		priority = 1000,
		opts = { theme = "auto", variant = "light" },
		config = function(_, opts)
			require("cyberdream").setup(opts)
			vim.cmd.colorscheme("cyberdream")
		end,
	},
	-- Oldschool Theme
	-- {
	-- 	"L-Colombo/oldschool.nvim",
	-- 	lazy = false,
	-- 	priority = 1000,
	-- 	opts = {},
	-- 	config = function(_, opts)
	-- 		require("oldschool").setup(opts)
	-- 		vim.cmd.colorscheme("oldschool")
	-- 	end,
	-- },

	-- Lualine matching Oldschool
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				theme = "cyberdream",
				icons_enabled = true,
				component_separators = "|",
				section_separators = "",
			},
		},
	},
	{ "nvim-tree/nvim-web-devicons", opts = { default = true } },

	-- TREESITTER: FIXED for v1.0+ (No deprecated require calls)
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {},
	},

	{ "nvim-tree/nvim-tree.lua", opts = { view = { width = 60 } } },
	{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

	-- LSP Management
	{ "neovim/nvim-lspconfig" },
	{ "williamboman/mason.nvim", opts = {} },
	{
		"williamboman/mason-lspconfig.nvim",
		opts = { ensure_installed = { "pyright", "ts_ls", "vue_ls", "lua_ls", "eslint" } },
	},

	-- Autocomplete (no Copilot, just LSP-driven)
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			vim.opt.completeopt = { "menu", "menuone", "noselect" }

			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				completion = {
					autocomplete = { cmp.TriggerEvent.TextChanged },
				},
				sources = {
					{
						name = "nvim_lsp",
						entry_filter = function(entry, ctx)
							local kind = entry:get_kind()
							local line = vim.api.nvim_buf_get_lines(
								ctx.bufnr,
								ctx.cursor.line - 1,
								ctx.cursor.line,
								false
							)[1] or ""
							local before_cursor = line:sub(1, ctx.cursor.col)

							-- When typing after "except", only show classes
							if before_cursor:match("except%s+$") then
								return kind == vim.lsp.protocol.CompletionItemKind.Class
							end

							return true
						end,
					},
					{ name = "path" },
					{ name = "luasnip" },
					{ name = "buffer", keyword_length = 3 },
				},
				sorting = {
					priority_weight = 2,
					comparators = {
						require("cmp.config.compare").offset,
						require("cmp.config.compare").exact,
						require("cmp.config.compare").score,

						-- THIS LINE is the magic
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
					["<C-e>"] = cmp.mapping.abort(),
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
				javascriptreact = { "prettierd" },
				typescript = { "prettierd" },
				typescriptreact = { "prettierd" },
				vue = { "prettierd" },
				markdown = { "prettierd" },
				plantuml = { "puml_format" },
			},
			formatters = {
				puml_format = {
					command = "/home/luke/.local/bin/puml-format",
					stdin = true,
				},
			},
			format_on_save = { timeout_ms = 500, lsp_fallback = true },
		},
	},
}, {
	rocks = { enabled = false },
})

-----------------------------------------------------------
-- 2.1 Oldschool Highlight Refinements
-----------------------------------------------------------
-- local function apply_oldschool_refinements()
-- 	local palette = {
-- 		bg = "#000000",
-- 		fg = "#d8d8e8",
-- 		muted = "#8f98a8",
-- 		green = "#00d084",
-- 		teal = "#22d3ee",
-- 		blue = "#7aa2ff",
-- 		yellow = "#ffd166",
-- 		orange = "#ff9f43",
-- 		pink = "#ff6fd8",
-- 		red = "#ff5c8a",
-- 	}
--
-- 	local highlights = {
-- 		Normal = { fg = palette.fg, bg = palette.bg },
-- 		LineNr = { fg = palette.muted },
-- 		CursorLineNr = { fg = palette.yellow, bold = true },
--
-- 		["@keyword"] = { fg = palette.pink, bold = true },
-- 		["@keyword.import"] = { fg = palette.green, bold = true },
-- 		["@keyword.return"] = { fg = palette.red, bold = true },
-- 		["@module"] = { fg = palette.blue },
-- 		["@type"] = { fg = palette.teal },
-- 		["@type.builtin"] = { fg = palette.teal, italic = true },
-- 		["@function"] = { fg = palette.yellow, bold = true },
-- 		["@function.call"] = { fg = palette.yellow },
-- 		["@constructor"] = { fg = palette.teal },
-- 		["@variable"] = { fg = palette.fg },
-- 		["@variable.builtin"] = { fg = palette.orange, italic = true },
-- 		["@variable.member"] = { fg = palette.blue },
-- 		["@variable.parameter"] = { fg = palette.orange },
-- 		["@constant"] = { fg = palette.orange },
-- 		["@constant.builtin"] = { fg = palette.orange, bold = true },
-- 		["@string"] = { fg = palette.green },
-- 		["@number"] = { fg = palette.orange },
-- 		["@boolean"] = { fg = palette.orange, bold = true },
-- 		["@operator"] = { fg = palette.pink },
-- 		["@punctuation"] = { fg = palette.muted },
--
-- 		["@lsp.type.namespace.python"] = { fg = palette.blue },
-- 		["@lsp.type.class.python"] = { fg = palette.teal, bold = true },
-- 		["@lsp.type.function.python"] = { fg = palette.yellow },
-- 		["@lsp.type.method.python"] = { fg = palette.yellow, bold = true },
-- 		["@lsp.type.variable.python"] = { fg = palette.fg },
-- 		["@lsp.type.parameter.python"] = { fg = palette.orange },
-- 	}
--
-- 	for group, opts in pairs(highlights) do
-- 		vim.api.nvim_set_hl(0, group, opts)
-- 	end
-- end
--
-- vim.api.nvim_create_autocmd("ColorScheme", {
-- 	pattern = "oldschool",
-- 	callback = apply_oldschool_refinements,
-- })
-- apply_oldschool_refinements()
--
-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = { "lua", "python", "javascript", "typescript", "vue", "json" },
-- 	callback = function()
-- 		pcall(vim.treesitter.start)
-- 	end,
-- })

-----------------------------------------------------------
-- 3. Native LSP Configuration (Neovim 0.11 API)
-----------------------------------------------------------

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local function python_path_for_workspace(workspace)
	local virtual_env = os.getenv("VIRTUAL_ENV")

	if virtual_env and vim.fn.executable(virtual_env .. "/bin/python") == 1 then
		return virtual_env .. "/bin/python"
	end

	for _, name in ipairs({ ".venv", "venv" }) do
		local path = workspace .. "/" .. name .. "/bin/python"
		if vim.fn.executable(path) == 1 then
			return path
		end
	end

	return nil
end

local function lua_root_dir(bufnr, on_dir)
	local file = vim.api.nvim_buf_get_name(bufnr)
	local nvim_config = vim.fn.stdpath("config")

	if file:sub(1, #nvim_config) == nvim_config then
		on_dir(nvim_config)
		return
	end

	on_dir(vim.fs.root(bufnr, { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" }))
end

vim.lsp.config("pyright", {
	capabilities = capabilities,
	before_init = function(_, config)
		local python_path = python_path_for_workspace(config.root_dir or vim.fn.getcwd())

		if python_path then
			config.settings = config.settings or {}
			config.settings.python = config.settings.python or {}
			config.settings.python.pythonPath = python_path
		end
	end,
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				diagnosticMode = "openFilesOnly",
				typeCheckingMode = "basic",
				useLibraryCodeForTypes = true,
			},
		},
	},
})

vim.lsp.config("lua_ls", {
	capabilities = capabilities,
	root_dir = lua_root_dir,
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			runtime = { version = "LuaJIT" },
			workspace = {
				checkThirdParty = false,
				library = vim.api.nvim_get_runtime_file("", true),
			},
			telemetry = { enable = false },
		},
	},
})

vim.lsp.config("vue_ls", {
	capabilities = capabilities,
	filetypes = { "vue" },
})

local vue_plugin = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
vim.lsp.config("ts_ls", {
	capabilities = capabilities,
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
	init_options = {
		plugins = { { name = "@vue/typescript-plugin", location = vue_plugin, languages = { "vue" } } },
	},
})

vim.lsp.config("eslint", {
	capabilities = capabilities,
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
})
vim.lsp.enable({ "pyright", "lua_ls", "vue_ls", "ts_ls", "eslint" })

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
end, { desc = "Grep (search text in files)" })

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
	pattern = { "python", "lua", "vue", "javascript", "javascriptreact", "typescript", "typescriptreact" },
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})
-- Buffer navigation
vim.keymap.set("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprev<CR>", { desc = "Previous buffer" })
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99
vim.opt.foldenable = true
