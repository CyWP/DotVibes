#!/bin/sh
# Install herdr-nvim (the herdr Neovim plugin) from upstream.
#
# Kept here only as a reference: the plugin is not built or vendored in this
# repo — this just runs the project's own installer:
#
#   https://github.com/ChmaraX/herdr-nvim
#
# Run by the toplevel ./install.sh in this folder (skip it there with
# --no-nvim), or by hand when you only want the plugin.
# It follows `main`, so what runs is whatever upstream ships today.
set -eu

curl -fsSL https://raw.githubusercontent.com/ChmaraX/herdr-nvim/main/install.sh | sh -s -- --app
