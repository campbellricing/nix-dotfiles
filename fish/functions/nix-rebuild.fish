function nix-rebuild --description 'nixos-rebuild from the ~/nix-dotfiles flake (default action: switch)'
    set -l action switch
    if set -q argv[1]
        set action $argv[1]
        set argv $argv[2..-1]
    end
    sudo nixos-rebuild $action --flake "$HOME/nix-dotfiles#nixos" $argv
end
