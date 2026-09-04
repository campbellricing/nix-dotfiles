#!/bin/sh
# Load the catppuccin palette into tmux as @ctp_<name> options.
# Sourced from tmux.conf via run-shell; reference colors as #{@ctp_red} etc.

PALETTE="${XDG_CONFIG_HOME:-$HOME/.config}/catppuccin/mocha.conf"

while IFS='=' read -r name hex; do
  case "$name" in
    ''|\#*) continue ;;
  esac
  tmux set -g "@ctp_${name}" "$hex"
done < "$PALETTE"
