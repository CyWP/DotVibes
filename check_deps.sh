#!/usr/bin/env bash
# check_deps.sh — report-only: show what this machine is still missing for the
# DotVibes components to fully work. Checks the same binaries (and version
# floors) the various install.sh scripts skip on or warn about; installs
# nothing, changes nothing. Missing hard requirements set exit code 1 so you
# can wire this into CI or a setup script; missing optional tools are noted
# only. Idempotent and side-effect free: run any time.
#
# Separation of concerns by design: the configs never install tools themselves,
# so this script is the one place that tells you which ones to add by hand.
#
# Source-safe by design: `. ./check_deps.sh` also works (used to fatal on
# sourced runs — see _check_deps_run). Prefer plain execution for the exit
# code (`./check_deps.sh`); sourcing still gives you the report plus $?.

_check_deps_run() {
  (
    set -u

    hard=0   # missing requirements that break a component
    soft=0   # missing optional tools (some feature degrades)

    have()   { command -v "$1" > /dev/null 2>&1; }
    bucket() { # bucket <hard|soft> <newline-free description>
      if [ "$1" = hard ]; then
        echo "  [missing — required] $2"; hard=$((hard+1))
      else
        echo "  [missing — optional] $2"; soft=$((soft+1))
      fi
    }
    ver_ok() { # ver_ok <version> <minimum>  e.g. ver_ok 0.12.6 0.12
      local low
      low=$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)
      [ "$low" = "$2" ]
    }

    have_group() { # have_group <binary>...  ; true if any one of them is present
      local t
      for t in "$@"; do
        have "$t" && return 0
      done
      return 1
    }

    # --- nvim ---------------------------------------------------------------------
    echo "== nvim (config: nvim/) =="
    any=0   # anything missing in this section?
    if have nvim; then
      nv=$(nvim --version | awk 'NR==1 {gsub("NVIM v","");print}')
      if ! ver_ok "$nv" "0.12"; then
        any=1; bucket hard "nvim $nv — needs >= 0.12 (treesitter rewrite + vim.lsp.enable)"
      fi
    else
      any=1; bucket hard "nvim not found (needs >= 0.12)"
    fi
    for t in git make tar curl; do
      if ! have "$t"; then any=1; bucket hard "$t not found (plugin cloning / parser builds)"; fi
    done
    if ! have_group cc gcc clang; then
      any=1; bucket hard "no C compiler (cc/gcc/clang) — treesitter parser builds need one"
    fi
    if have tree-sitter; then
      ts=$(tree-sitter --version | awk '{print $2}')
      if ! ver_ok "$ts" "0.26.1"; then
        any=1; bucket hard "tree-sitter $ts — needs >= 0.26.1 (binary into ~/.local/bin; see README)"
      fi
    else
      any=1; bucket hard "tree-sitter not found — parsers can't install (see README: binary into ~/.local/bin)"
    fi
    pip_hint="pip install --user ruff basedpyright clang-format  # Debian/Ubuntu: add --break-system-packages"
    for t in ruff basedpyright-langserver clang-format clangd stylua; do
      if ! have "$t"; then any=1; bucket soft "$t not found — $pip_hint"; fi
    done
    if ! have rg; then
      any=1; bucket soft "rg (ripgrep) not found — <Space>fg telescope live_grep needs it (apt install ripgrep)"
    fi
    if ! have magick && ! have convert; then
      any=1; bucket soft "ImageMagick not found — snacks.image previews render only PNG without it (apt install imagemagick)"
    fi
    if ! { have fc-list && fc-list 2>/dev/null | grep -qi "nerd"; }; then
      any=1; bucket soft "no Nerd Font found — icons render as boxes until you add one"
    fi
    [ "$any" = 0 ] && echo "  [ok] nothing missing"

    correct() { echo "  [ok] $1"; }

    # --- ghostty ------------------------------------------------------------------
    echo
    echo "== ghostty (config: ghostty/) =="
    if have ghostty; then correct "ghostty"
    else bucket hard "ghostty not found — config can be installed but there'd be no terminal to use it"
    fi

    # --- herdr --------------------------------------------------------------------
    echo
    echo "== herdr (config: herdr/) =="
    if have herdr; then correct "herdr"
    else bucket hard "herdr not found — config can be installed but the tool would be unusable"
    fi

    # --- claude/agents ---------------------------------------------------------------
    echo
    echo "== claude (config: agents/) =="
    if have claude; then correct "claude"
    else bucket hard "claude not found — configs can be installed but the CLI would be unusable"
    fi

    # --- tmux --------------------------------------------------------------------
    echo
    echo "== tmux (config: tmux/) =="
    if have tmux; then correct "tmux"
    else bucket hard "tmux not found — config can be installed but the tool would be unusable"
    fi
    have xsel || bucket soft "xsel not found — tmux clipboard bindings need it; copies stay inside tmux until it's installed"

    # --- fonts --------------------------------------------------------------------
    echo
    echo "== fonts (config: fonts/) =="
    if have fc-cache; then correct "fontconfig (fc-cache)"
    else bucket hard "fontconfig (fc-cache) not found — font files install but the system can't index them"
    fi

    # --- bash ---------------------------------------------------------------------
    echo
    echo "== bash (config: bash/) =="
    if have bash; then correct "bash"
    else bucket hard "bash not found (you are somehow running this script without it)"
    fi
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) correct "~/.local/bin on PATH (bin/ scripts use bash/.paths)" ;;
      *) bucket hard "~/.local/bin not on PATH — bin/ scripts are on PATH via bash/.paths, so install that component" ;;
    esac

    # --- bin (scripts' own external tools) ----------------------------------------
    echo
    echo "== bin scripts (config: bin/) =="
    any=0
    for t in ffmpeg; do
      case "$t" in
        ffmpeg) desc="mkvid + rec" ;;
      esac
      if ! have "$t"; then any=1; bucket soft "$t not found — needed by the $desc"; fi
    done
    [ "$any" = 0 ] && echo "  [ok] nothing missing"

    # --- summary ------------------------------------------------------------------
    echo
    if [ "$hard" -gt 0 ] || [ "$soft" -gt 0 ]; then
      echo "summary: $hard missing requirement(s), $soft missing optional(s) — install the [required] items before running ./install.sh"
    else
      echo "summary: nothing missing — every DotVibes dependency is present"
    fi

    # exits the SUBSHELL only — never your (potential) interactive shell
    exit $((hard > 0))
  )
}

# Executed: run + exit with its status (and tidy up the one function).
# Sourced: run + `return` the status — your shell stays open, options/vars
# from the script die with the subshell, nothing leaks.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  _check_deps_run
  st=$?
  unset -f _check_deps_run
  exit "$st"
fi

_check_deps_run
st=$?
unset -f _check_deps_run
return "$st"
