# 📱 Neovim Configuration (Optimized for Mobile & NetHunter Rootless)

An ultra-responsive, fully featured, and modern Neovim configuration built for developers working on **Kali NetHunter Rootless (Android / PRoot / Termux)** and mobile terminals, while retaining complete keybinding and feature parity with the desktop **`wow-neovim`** configuration.

---

## ⚡ Mobile & NetHunter Rootless Optimizations

- **Smart Clipboard Integration**: Seamless clipboard synchronization using `termux-clipboard` or built-in **OSC 52** (copies directly to Android's system clipboard without requiring an X11 server).
- **Mobile Viewport Geometry**:
  - `numberwidth = 2`: Compact line number gutter saves horizontal screen space.
  - `scrolloff = 4`: Balances cursor centering for shorter mobile terminal displays.
  - `cursorcolumn = false`: Eliminates column redraw stutter and battery drain on mobile processors.
  - `pumheight = 10`: Keeps autocomplete popups from obscuring the entire viewport.
- **Responsive Layouts**:
  - **Telescope**: Dynamically switches to vertical layout on screens narrower than 85 columns.
  - **Lualine**: Responsively collapses non-essential metadata (`encoding`, `fileformat`, `diff`) on narrow screens to protect filename and Git branch visibility.
  - **Nvim-Tree**: Compact 30-column width, line numbers disabled inside tree view, plus safe resize shortcuts.
  - **Treesitter Context**: Limited to a maximum of 2 sticky header lines with a minimum window height threshold.
- **ARM64 & PRoot Reliability**:
  - Automatically prepends `~/.local/share/nvim/mason/bin` to `PATH` for reliable tool discovery.
  - Safe, non-blocking LSP executable validation prevents spawn loops on missing binaries.
  - Dual compatibility for Treesitter (`nvim-treesitter.configs` and `main` branch rewrite).
  - Unnamed and scratch buffers are safely excluded from auto-save.

---

## 📦 Prerequisites

### 1. System Packages (Kali NetHunter / Debian / Ubuntu)

Run the following inside your NetHunter Rootless or Kali terminal:

```bash
# Update package lists
sudo apt update && sudo apt install -y \
  neovim \
  git \
  curl \
  build-essential \
  clang \
  make \
  ripgrep \
  lazygit \
  python3 \
  python3-pip \
  python3-venv
```

### 2. Node.js & npm (Required for web LSPs & Prettier)

If not already installed:

```bash
# Via NodeSource or nvm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### 3. Android Clipboard Integration (Termux)

If you are using NetHunter Rootless launched from Termux:

1. In Termux, install the Termux API package and Android companion app:
   ```bash
   pkg install termux-api
   ```
2. Inside your NetHunter PRoot container, ensure `termux-clipboard-set` and `termux-clipboard-get` are linked (or simply use a terminal supporting **OSC 52**, which works out of the box with zero external dependencies).

### 4. Nerd Font

Install any Nerd Font (e.g. **JetBrains Mono Nerd Font**, **FiraCode Nerd Font**, or **Meslo Nerd Font**) in your mobile terminal emulator (such as Termux font settings or your SSH client) to display icons cleanly.

---

## 🚀 Quick Automated Setup

You can set up your entire mobile environment automatically with the included bootstrap script:

```bash
# Run the automated mobile setup
chmod +x ./scripts/setup-mobile.sh
./scripts/setup-mobile.sh

# Launch Neovim
nvim
```

The script will automatically:
1. Detect your architecture (ARM64 / aarch64).
2. Check and prompt for any missing system tools (`clangd`, `ripgrep`, etc.).
3. Download and cache **JetBrains Mono Nerd Font** (and export a copy to `/sdcard/Download/` for Termux).
4. Verify non-blocking mobile clipboard compatibility (`OSC 52` with `/dev/tty`).
5. Run Neovim pre-flight tests to ensure plugins and LSPs launch cleanly.

---

## 🛠️ Manual Prerequisites (Optional)

If you prefer installing components manually instead of using `./scripts/setup-mobile.sh`:

Lazy.nvim will automatically install all plugins on first launch. Run `:Lazy sync` or `:checkhealth` if needed.

---

## ⌨️ Complete Keybindings Cheatsheet

Leader key: **`<Space>`**

### 1. General & Window Management

| Keybinding | Mode | Description |
| :--- | :---: | :--- |
| `<Esc>` | `n` | Clear search highlights (`:nohlsearch`) |
| `<Esc><Esc>` | `t` | Exit terminal mode to normal mode |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | `n` | Focus window left / down / up / right |
| `<leader>wv` | `n` | Split window vertically (`:vsplit`) |
| `<leader>wh` | `n` | Split window horizontally (`:split`) |
| `<A-H>` / `<A-J>` / `<A-K>` / `<A-L>` | `n` | Resize window (width / height) |
| `<leader>q` | `n` | Quit single buffer (`:q`) |
| `<leader>qa` | `n` | Quit all files (`:qa`) |
| `<leader>a` | `n` | Select all text (`ggVG`) |
| `<leader>tt` | `n` | Open compact split terminal (10 lines) |
| `<A-z>` | `n` | Toggle word wrap for current buffer |
| `<A-Z>` | `n` | Toggle word wrap globally |

### 2. Line Movement & Indentation

| Keybinding | Mode | Description |
| :--- | :---: | :--- |
| `<A-j>` | `n` | Move line down |
| `<A-k>` | `n` | Move line up |
| `<A-j>` | `v` | Move visual selection down |
| `<A-k>` | `v` | Move visual selection up |
| `<A-h>` / `<A-l>` | `n` | Indent left (`<<`) / right (`>>`) |
| `<A-h>` / `<A-l>` | `v` | Indent selection left (`<gv`) / right (`>gv`) |

### 3. File Explorer (`nvim-tree`)

| Keybinding | Mode | Description |
| :--- | :---: | :--- |
| `<leader>e` | `n` | Toggle file explorer |
| `<leader>eo` | `n` | Open file explorer & resize safely (30 cols) |
| `<leader>er` | `n` | Refocus file explorer on active buffer |
| `C` | (in tree) | Expand all folders |
| `W` | (in tree) | Collapse all folders |
| `a` / `d` / `r` | (in tree) | Create file / Delete / Rename |

### 4. Search & Navigation (`telescope`)

#### Local / Current Working Directory (`<leader>f`)
| Keybinding | Description |
| :--- | :--- |
| `<leader>ff` | Find files (cwd, including hidden) |
| `<leader>fg` | Live grep text (cwd) |
| `<leader>fc` | Find files in current buffer's directory |
| `<leader>fb` | List open buffers |
| `<leader>fr` | Resume last Telescope session |
| `<leader>fs` | Buffer LSP document symbols |
| `<leader>fd` | Buffer diagnostics |
| `<leader>f.` | Recent files (scoped to project root) |
| `<leader>fO` | Old files (unfiltered, all history) |
| `<leader>ft` | Find files by extension (prompts for `lua`, `go`, etc.) |
| `<leader>gt` | Grep in specific file extension |

#### Global / Project Root Search (`<leader>s`)
| Keybinding | Description |
| :--- | :--- |
| `<leader>sf` | Find project files (prefers `git_files`) |
| `<leader>sg` | Live grep across project root |
| `<leader>sw` | Grep word under cursor across project |
| `<leader>sb` | List all open buffers |
| `<leader>ss` | Workspace LSP symbols |
| `<leader>sd` | Workspace diagnostics |
| `<leader>sc` | Project Git commits |
| `<leader>st` | Search `TODO` / `FIXME` comments in project |

### 5. LSP & Code Intelligence

| Keybinding | Mode | Description |
| :--- | :---: | :--- |
| `<leader>ch` | `n` | Hover documentation |
| `<leader>cd` | `n` | Go to definition |
| `<leader>cD` | `n` | Go to declaration |
| `<leader>ci` | `n` | Go to implementation |
| `<leader>ct` | `n` | Go to type definition |
| `<leader>cr` | `n` | Find references |
| `<leader>cI` | `n` | Find implementations |
| `<leader>cR` | `n` | Rename symbol |
| `<leader>ca` | `n`, `v` | Code actions |
| `<leader>cf` | `n` | Format buffer via Conform / LSP |
| `<leader>fwc` | `n` | Format whole file (Prettier / LSP) |
| `<leader>fsc` | `v` | Format visual selection only |
| `<leader>cH` | `n` | Toggle Inlay Hints |

### 6. Diagnostics & Suppressions

| Keybinding | Description |
| :--- | :--- |
| `<leader>do` | Open diagnostic float |
| `<leader>dp` | Jump to previous diagnostic |
| `<leader>dn` | Jump to next diagnostic |
| `<leader>dQ` | Send diagnostics to quickfix/loclist |
| `<leader>dx` | Toggle `any`-type suppression filter |
| `<leader>di` | Insert native ignore comment (`@ts-expect-error`, `# noqa`, etc.) |
| `<leader>dI` | Session-level ignore for diagnostic code |
| `<leader>dC` | Clear all session-level ignores |
| `<leader>da` | Diagnostic actions menu |
| `<leader>dv` | Toggle virtual text (current buffer) |
| `<leader>dB` | Toggle diagnostics on/off (current buffer) |
| `<leader>dg` | Toggle diagnostics globally |

### 7. Git, GitLens & LazyGit

#### LazyGit
| Keybinding | Description |
| :--- | :--- |
| `<leader>lg` | Open full interactive LazyGit UI |

#### Gitsigns & GitLens
| Keybinding | Description |
| :--- | :--- |
| `]h` / `[h` | Jump to next / previous hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hs` | Stage hunk (normal & visual) |
| `<leader>hu` | Undo staged hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hR` | Reset entire buffer |
| `<leader>hS` | Stage entire buffer |
| `<leader>gb` | Git blame line (full commit popup) |
| `<leader>gib` | Toggle inline blame ghost text |
| `<leader>gd` | Diff against index |
| `<leader>gdl` | Diff against last commit (`HEAD~1`) |
| `<leader>gyc` | Yank commit hash of current line to clipboard |
| `<leader>gci` | Commit inspector (details + affected files) |

#### Fugitive Operations
| Keybinding | Description |
| :--- | :--- |
| `<leader>gS` | Open Git status (`-` to stage, `cc` to commit, `q` to quit) |
| `<leader>gds` | Diff split |
| `<leader>gaa` | Git add all (`git add -A`) |
| `<leader>gac` | Git add current buffer |
| `<leader>gcm` | Git commit |
| `<leader>gp` | Git push |
| `<leader>gP` | Git pull |
| `<leader>gacp` | Auto add, commit (branch name as message), push |
| `<leader>glg` | Git log oneline |
| `<leader>ghl` | Git log graph (`--graph --all`) |
| `<leader>gfl` | File commit timeline (`<CR>` opens side-by-side diff) |
| `<leader>gbl` | Full file blame |
| `<leader>gcb` | Create branch (`git checkout -b <name>`) |
| `<leader>gco` | Checkout branch |
| `<leader>gmb` | Merge branch |
| `<leader>gsf` | Sync fork (`git pull upstream main --rebase`) |
| `<leader>grc` | Revert commit prompt |
| `<leader>grs` | Reset commit prompt (`soft`/`mixed`/`hard`) |
| `<leader>gch` | Inspect arbitrary commit SHA |

### 8. Notes & Wiki (`vimwiki`)

| Keybinding | Description |
| :--- | :--- |
| `<leader>ww` | Open VimWiki index (`~/notes/wiki/`) |
| `<leader>wt` | Open VimWiki index in new tab |
| `<leader>ws` | Wiki UI selector |
| `<leader>wi` | Open diary index |
| `<leader>w<leader>w` | Create / open today's diary note |
| `<leader>m` | Toggle task checkbox `[ ]` ↔ `[X]` |

### 9. Database Management (`vim-dadbod`)

| Keybinding | Description |
| :--- | :--- |
| `<leader>du` | Toggle Database UI sidebar |
| `<leader>dc` | Add new database connection |
| `<leader>df` | Find database buffer |
| `<leader>dr` | Rename database buffer |
| `<leader>dq` | Last query info |
| `<leader>de` | Execute query (entire buffer or visual selection in SQL files) |
| `<leader>ds` | Save query |
| `<leader>dd` | Edit bind parameters |

### 10. Debugger (`nvim-dap` & `nvim-dap-ui`)

| Keybinding | Description |
| :--- | :--- |
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue / start debugging session |
| `<leader>dso` | Step over |
| `<leader>dsi` | Step into |
| `<leader>dsO` | Step out |
| `<leader>dr` | Open DAP REPL |
| `<leader>dl` | Re-run last debug session |
| `<leader>dq` | Terminate debug session |
| `<leader>du` | Toggle DAP UI layout |
| `<leader>de` | Evaluate expression under cursor (normal / visual) |
| `<leader>dE` | Prompt for expression to evaluate |
| `<leader>dw` | Floating watches window |
| `<leader>dS` | Floating scopes window |
| `<leader>df` | Floating call stack frames |
| `<leader>dR` | Floating REPL window |

### 11. Productivity & Navigation Helpers

| Keybinding | Description |
| :--- | :--- |
| `<leader>/` | Toggle comment on current line or visual selection (`Comment.nvim`) |
| `<M-e>` | Fast Wrap text under cursor with brackets/quotes (`nvim-autopairs`) |
| `]t` / `[t` | Jump to next / previous `TODO`/`FIXME` comment (`todo-comments`) |
| `<leader>tc` | Toggle sticky context line (`treesitter-context`) |
| `[c` | Jump up to sticky context function/class |
| `n` / `N` | Next / previous search match with floating counter (`hlslens`) |
| `*` / `#` | Forward / backward search word under cursor with match counter |

---

## 🔧 Language Server Protocols (LSP) Supported

Pre-configured in `lsp/<server>.lua`:
- **Web & Frontend**: `ts_ls` (TypeScript/JavaScript), `html`, `cssls`, `tailwindcss`, `angularls`, `emmet_ls`, `eslint`
- **Backend & Systems**: `pyright` & `ruff` (Python), `gopls` (Go), `clangd` (C/C++), `jdtls` (Java)
- **Configuration & Scripting**: `lua_ls` (Neovim Lua API annotations)

To install or manage language servers, formatters, and debuggers interactively:
- `:Mason` - GUI package manager for LSP servers, linters, and formatters
- `:ConformInfo` - Status of active code formatters
- `:checkhealth` - Diagnostic health report for Neovim and plugins
