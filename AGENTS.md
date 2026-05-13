# Global Development Instructions

These instructions apply across projects under `/home/luke` unless a repository
has a more specific `AGENTS.md`.

## Editor Formatting

Manual development uses Neovim with the config at `~/.config/nvim/init.lua`.
Before finishing code edits, follow the same formatting rules configured there:

- Python: `black`
- Lua: `stylua`
- JavaScript: `prettierd`
- TypeScript: `prettierd`
- Vue: `prettierd`

Neovim formats on save through `conform.nvim` with LSP fallback enabled. When
editing from the terminal, run the matching formatter directly on changed files
so generated diffs match what Neovim would apply.

Mason-managed tools live in `~/.local/share/nvim/mason/bin`. Include that path
when checking formatter availability. If a project has its own formatter script
or config, prefer the project command while preserving these editor defaults.

## Linting And Language Servers

The global Neovim setup uses Mason for Pyright, TypeScript, and Vue language
servers. It also has `eslint_d` installed. For project verification, prefer the
project's own lint/test commands first, then use these global tools as a
fallback when no project-specific command exists.

## Testing And Verification

- PYTHON test use pytest
- TYPESCRIPT/JAVASCRIPT use Vitest
- C/C++ use Catch2
- For embedded / pure C use Unity
- For Rust use cargo test

For WEB apps use playwright to test it throughly when implementing feature, even the test pass, go with playwrithg make snapshots where the feature is implemented confirm the behaviour.

Every time we implement a new feature before even writing a single implementation line of code, we need to write unit tests for that specific feature. 
