#!/bin/sh
# Regenerate the [palettes.catppuccin] block in starship.toml from mocha.conf.
# Run this after changing colors in mocha.conf.

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
PALETTE="$CONFIG_DIR/catppuccin/mocha.conf"
STARSHIP="$CONFIG_DIR/starship.toml"

{
  # keep everything up to (excluding) the generated palette block
  sed '/^# BEGIN generated palette/,$d' "$STARSHIP"

  echo '# BEGIN generated palette — edit ~/.config/catppuccin/mocha.conf'
  echo '# and run ~/.config/catppuccin/sync-starship.sh instead'
  echo '[palettes.catppuccin]'
  while IFS='=' read -r name hex; do
    case "$name" in
      ''|\#*) continue ;;
    esac
    printf '%s = "%s"\n' "$name" "$hex"
  done < "$PALETTE"
} > "$STARSHIP.tmp" && mv "$STARSHIP.tmp" "$STARSHIP"

echo "Updated [palettes.catppuccin] in $STARSHIP"
