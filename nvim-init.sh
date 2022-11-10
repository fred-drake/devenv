#!/bin/sh

# Run this twice.  It doesn't install on the first time for some reason.
# We also ignore any errors that come out from the plugin installations.
nvim --headless ~/.config/nvim/lua/user/plugins-setup.lua -c "w" -c "sleep 10" -c "qa" | exit 0
nvim --headless ~/.config/nvim/lua/user/plugins-setup.lua -c "w" -c "sleep 10" -c "qa" | exit 0

# Required to prevent tree-sitter errors during file edits
nvim --headless -c "TSUpdate" -c "sleep 10" -c "qa" | exit 0

