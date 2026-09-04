set -gx EDITOR nvim
set -gx VISUAL nvim

if status is-interactive
    # Starship custom prompt
    command -v starship &>/dev/null && starship init fish | source

    # Direnv + Zoxide
    command -v direnv &>/dev/null && direnv hook fish | source
    command -v zoxide &>/dev/null && zoxide init fish --cmd cd | source

    # fnm (Node version manager)
    command -v fnm &>/dev/null && fnm env --use-on-cd --shell fish | source

    # Claude
    fish_add_path ~/.local/bin

    # Better ls
    command -v eza &>/dev/null && alias ls='eza --icons --group-directories-first -1'

    # Suppress "The system will reboot/power off now!" wall message on console
    alias reboot='systemctl reboot --no-wall'
    alias poweroff='systemctl poweroff --no-wall'

    # Abbrs
    abbr gd 'git diff'
    abbr ga 'git add'
    abbr gaa 'git add .'
    abbr gcm 'git commit -m'
    abbr gf 'git fetch'
    abbr gl 'git log'
    abbr gll 'git log --oneline -n 10'
    abbr gs 'git status'
    abbr gst 'git stash -u'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch master'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gc 'git checkout'

    abbr yf 'yarn format'
    abbr yl 'yarn lint'
    abbr ylf 'yarn lint --fix'
    abbr yb 'yarn build'
    abbr ylb 'yarn lint && yarn build'

    abbr l ls
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    abbr ff fastfetch

    # Custom colours (strip OSC 11 inside tmux — tmux turns it into an opaque pane background)
    # Skip when the scheme is light so foot keeps its own dark palette
    if grep -q '"mode": "dark"' ~/.local/state/caelestia/scheme.json 2>/dev/null
        if set -q TMUX
            sed 's/\x1b]11;[^\x1b]*\x1b\\\\//g' ~/.local/state/caelestia/sequences.txt 2>/dev/null
        else
            cat ~/.local/state/caelestia/sequences.txt 2>/dev/null
        end
    end

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    # Custom fish config
    set -q XDG_CONFIG_HOME && set -l cConf $XDG_CONFIG_HOME/caelestia || set -l cConf $HOME/.config/caelestia
    source $cConf/user-config.fish 2>/dev/null
end
