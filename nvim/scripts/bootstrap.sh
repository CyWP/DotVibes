#!/usr/bin/env bash
# bootstrap.sh — verify a machine is ready for this nvim config.
# Check-only: installs nothing. Missing LSP tools are warnings, not failures
# (that language simply gets no LSP per the config's design).

set -u

fail=0       # hard requirements that break the config
warn=0       # optional tools / cosmetics

ok()   { printf '  [ok]   %s\n' "$1"; }
bad()  { printf '  [FAIL] %s\n' "$1"; fail=$((fail+1)); }
warn() { printf '  [warn] %s\n' "$1"; warn=$((warn+1)); }

ver_ok() { # ver_ok <version> <minimum>  e.g. ver_ok 0.12.6 0.12
    local low
    low=$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)
    [ "$low" = "$2" ]
}

echo "== hard requirements =="

if command -v nvim > /dev/null; then
  nv=$(nvim --version | awk 'NR==1 {gsub("NVIM v","");print}')
  if ver_ok "$nv" "0.12"; then ok "nvim $nv (needs >= 0.12)"
  else bad "nvim $nv — needs >= 0.12 (treesitter rewrite + vim.lsp.enable)"; fi
else
  bad "nvim not found"
fi

for t in git make tar curl; do
  if command -v "$t" > /dev/null; then ok "$t"; else bad "$t missing"; fi
done

for c in cc gcc clang; do
  if command -v "$c" > /dev/null; then ok "C compiler ($c)"; comp=1; break; fi
done
[ "${comp:-0}" = 0 ] && bad "no C compiler (cc/gcc/clang) — treesitter parser builds need one"
unset c comp

if command -v tree-sitter > /dev/null; then
  ts=$(tree-sitter --version | awk '{print $2}')
  if ver_ok "$ts" "0.26.1"; then ok "tree-sitter $ts (needs >= 0.26.1)"
  else bad "tree-sitter $ts — needs >= 0.26.1 (see README row 2)"; fi
else
  bad "tree-sitter missing — parsers can't install (see README: binary into ~/.local/bin)"
fi

echo "== LSP / formatter tools (optional; warn only) =="
pip_hint="pip install --user ruff basedpyright clang-format  # Debian/Ubuntu: add --break-system-packages"
for t in ruff basedpyright-langserver clang-format clangd stylua; do
  if command -v "$t" > /dev/null; then
    ok "$t ($(command -v "$t"))"
  else
    case "$t" in
      stylua)         hint="brew/cargo install stylua, or copy the release binary" ;;
      clangd)         hint="apt install clangd | brew install llvm | clangd GH release" ;;
      *)              hint="$pip_hint" ;;
    esac
    warn "$t missing — $hint"
  fi
done

echo "== cosmetics =="
if command -v fc-list > /dev/null && fc-list 2>/dev/null | grep -qi "nerd"; then
  ok "a Nerd Font is installed"
else
  warn "no Nerd Font found — icons render as boxes until you add one + select it in the terminal"
fi

echo
echo "== summary: $fail hard failure(s), $warn suggestion(s) =="
case $fail in
  0)
    echo "Run nvim — first launch bootstraps lazy.nvim and all plugins automatically."
    [ "$warn" -gt 0 ] && echo "Warnings above are optional; install later as needed."
    ;;
  *) echo "Fix the [FAIL] items first, then run nvim." ;;
esac
exit $((fail > 0))
