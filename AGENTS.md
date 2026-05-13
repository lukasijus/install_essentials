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

## Development Workflow

Read the existing code path before editing. Prefer the smallest correct change
that fits the repository's current patterns, especially in auth, RBAC, billing,
filesystem, deployment, and installer code.

Check `git status` before making changes. Never revert unrelated user changes.
If unrelated changes are present, leave them alone and keep the requested work
scoped to the relevant files.

## Testing And Verification

Testing is part of implementation, not a final optional step.

- For new behavior, write or update a focused test before implementation when
  practical.
- For bug fixes, add a regression test that fails against the old behavior when
  possible.
- Prefer unit tests for pure logic, validation, parsing, permissions, state
  transitions, and edge cases.
- Do not replace cheap automated tests with manual verification.
- If tests are skipped, state the concrete reason and describe what verification
  was done instead.

Default test commands by stack:

- Python: `pytest`
- TypeScript/JavaScript: `vitest`
- Rust: `cargo test`
- C/C++: Catch2 when available
- Embedded / pure C: Unity when available

For web app UI changes, use Playwright for browser-level verification and
capture screenshots for the changed workflow when practical.

Every code change should end with a short verification note: tests run, commands
run, what passed, and what was not run.
