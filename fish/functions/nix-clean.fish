function nix-clean --description 'Delete old Nix generations (system + user) and garbage-collect the store'
    # Optional arg: an age like `nix-clean 7d` keeps generations newer than that;
    # with no arg, every generation but the current one is removed.
    if set -q argv[1]
        sudo nix-collect-garbage --delete-older-than $argv[1]
        nix-collect-garbage --delete-older-than $argv[1]
    else
        sudo nix-collect-garbage -d
        nix-collect-garbage -d
    end
end
