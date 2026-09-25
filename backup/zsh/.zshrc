# ==============================================================================
# Hyprdark - Zsh & Oh My Zsh Configuration
# High-contrast cyber prompt, cybersecurity workflow aliases, and auto-completions.
# ==============================================================================

# Oh My Zsh Path
export ZSH="${HOME}/.oh-my-zsh"
export PATH="${HOME}/.local/bin:${PATH}"

# Set Theme (Minimalist cyber two-line prompt, zero emojis)
ZSH_THEME=""

# Plugins definition
plugins=(git sudo history)

# Load Oh My Zsh if installed
if [ -f "${ZSH}/oh-my-zsh.sh" ]; then
    source "${ZSH}/oh-my-zsh.sh"
fi

# Completion System & Case-Insensitive Tab Completion
if ! type compdef >/dev/null 2>&1; then
    autoload -Uz compinit
    compinit -d "${HOME}/.zcompdump"
fi

# Case-insensitive tab completion (capital characters do not affect tab)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Load Arch Linux packaged zsh plugins if present
[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- Keybindings (Word navigation with Ctrl+Arrow and Alt+Arrow) ---
bindkey "^[[1;5D" backward-word         # Ctrl+Left
bindkey "^[[1;5C" forward-word          # Ctrl+Right
bindkey "^[[5D"   backward-word         # Alternative Ctrl+Left
bindkey "^[[5C"   forward-word          # Alternative Ctrl+Right
bindkey "^[[1;3D" backward-word         # Alt+Left
bindkey "^[[1;3C" forward-word          # Alt+Right
bindkey "^[b"     backward-word         # Alt+Left (Kitty default)
bindkey "^[f"     forward-word          # Alt+Right (Kitty default)
bindkey "^[[1;5A" up-line-or-history     # Ctrl+Up
bindkey "^[[1;5B" down-line-or-history   # Ctrl+Down

# Path & subpath deletion with Alt+Backspace and Ctrl+Backspace
# Removing '/' from WORDCHARS ensures backward-kill-word stops at path delimiters
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
bindkey "^[^?"    backward-kill-word     # Alt+Backspace
bindkey "^[^H"    backward-kill-word     # Alt+Backspace (alternative)
bindkey "^H"      backward-kill-word     # Ctrl+Backspace
bindkey "^W"      backward-kill-word     # Ctrl+W
bindkey "^[[3;5~" kill-word              # Ctrl+Delete

# --- Modern Cyber Prompt with Hairlines, Execution Timer & Line Fill ---
zmodload zsh/datetime
setopt PROMPT_SUBST

_first_prompt=1
_cmd_start_time=""
_last_dur_str=""

preexec() {
    _cmd_start_time=$EPOCHREALTIME
}

_build_prompt() {
    # 1. Execution time calculation
    if [[ -n "$_cmd_start_time" ]]; then
        local dur=$(( EPOCHREALTIME - _cmd_start_time ))
        _cmd_start_time=""
        if (( dur >= 60 )); then
            local sec_int=${dur%.*}
            _last_dur_str="$(( sec_int / 60 ))m $(( sec_int % 60 ))s"
        elif (( dur >= 1 )); then
            _last_dur_str=$(printf "%.2fs" $dur)
        elif (( dur >= 0.05 )); then
            _last_dur_str=$(printf "%.0fms" $(( dur * 1000 )))
        else
            _last_dur_str=""
        fi
    fi

    local pad=""
    integer term_width=${COLUMNS:-80}

    # 2. Line break before prompt (clean spacing after commands, Ctrl+C, or blank lines)
    if [[ -z "$_first_prompt" ]]; then
        print ""
    else
        _first_prompt=""
    fi

    # 3. Directory path
    local path_disp="${PWD/#$HOME/~}"
    local left_display="%F{045}${path_disp}%f"
    integer left_len=${#path_disp}

    # 4. Git status
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
        local dirty=""
        [[ -n $(git status --porcelain 2>/dev/null) ]] && dirty="*"

        local upstream
        upstream=$(git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null)
        local sync=""
        local sync_plain=""
        if [[ -n "$upstream" ]]; then
            local ahead behind
            ahead=$(git rev-list --count "@{upstream}..HEAD" 2>/dev/null)
            behind=$(git rev-list --count "HEAD..@{upstream}" 2>/dev/null)
            if (( ahead > 0 )); then
                sync+="%F{045}⇡${ahead}%f"
                sync_plain+="⇡${ahead}"
            fi
            if (( behind > 0 )); then
                sync+="%F{214}⇣${behind}%f"
                sync_plain+="⇣${behind}"
            fi
            if [[ -n "$sync" ]]; then
                sync=" ${sync}"
                sync_plain=" ${sync_plain}"
            fi
        fi

        left_display+=" %F{242}on%f %F{039}󰘬 ${branch}%F{196}${dirty}%f${sync}"
        (( left_len += 4 + 2 + ${#branch} + ${#dirty} + ${#sync_plain} ))
    fi

    # 5. Python virtual environment
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_name=$(basename "$VIRTUAL_ENV")
        left_display+=" %F{242}via%f %F{214} ${venv_name}%f"
        (( left_len += 5 + 2 + ${#venv_name} ))
    fi

    # 6. Hairline fill extending to the end of the directory line
    local line=""
    if [[ -n "$_last_dur_str" ]]; then
        local right_display="%F{214}󱎫 ${_last_dur_str}%f"
        integer right_len=$(( 2 + 1 + ${#_last_dur_str} ))
        integer fill_len=$(( term_width - left_len - right_len - 2 ))
        if (( fill_len > 0 )); then
            local fill="%F{238}${(l:fill_len::─:)pad}%f"
            line="$left_display $fill $right_display"
        else
            line="$left_display $right_display"
        fi
        _last_dur_str=""
    else
        integer fill_len=$(( term_width - left_len - 1 ))
        if (( fill_len > 0 )); then
            local fill="%F{238}${(l:fill_len::─:)pad}%f"
            line="$left_display $fill"
        else
            line="$left_display"
        fi
    fi

    PROMPT="${line}
%(?:%F{045}❯%f:%F{196}❯%f) "
}

precmd_functions+=(_build_prompt)

# --- History Configuration ---
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="${HOME}/.zsh_history"
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY

# --- Cybersecurity & Workflow Aliases ---
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto --group-directories-first'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
clear() {
    _first_prompt=1
    _cmd_start_time=""
    _last_dur_str=""
    command clear "$@"
}
alias cls='clear'

# Reset prompt newline when clearing via Ctrl+L
clear-screen-and-reset() {
    _first_prompt=1
    zle .clear-screen
}
zle -N clear-screen clear-screen-and-reset

# Quick Pentest Helpers
alias serve='python3 -m http.server 8000'
alias ports='ss -tulpn'
alias myip='echo -n "LAN: "; ip -4 addr show scope global | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n 1 ; echo -n "VPN (tun0): "; ip -4 addr show tun0 2>/dev/null | grep -oP "(?<=inet\s)\d+(\.\d+){3}" || echo "Disconnected"'

# Target IP & Domains Controller
set-target() {
    local script_path="${HOME}/Desktop/Github/Hyprdark/scripts/set-target.sh"
    if [ -f "${script_path}" ]; then
        bash "${script_path}" "$@"
    elif [ -f "${HOME}/.config/hyprdark/scripts/set-target.sh" ]; then
        bash "${HOME}/.config/hyprdark/scripts/set-target.sh" "$@"
    else
        echo "$1" > "${HOME}/.local/share/hyprdark/target_ip"
        echo "[OK] Target set to: $1"
    fi
}

target() {
    if [ $# -gt 0 ]; then
        set-target "$@"
        return $?
    fi

    local target_file="${HOME}/.local/share/hyprdark/target_ip"
    if [ -f "${target_file}" ] && [ -s "${target_file}" ]; then
        local ip
        ip="$(cat "${target_file}")"
        echo "${ip}"
        if command -v wl-copy >/dev/null 2>&1; then
            echo -n "${ip}" | wl-copy
            echo "(Copied to clipboard)"
        fi
    else
        echo "No target currently set. Use: target <IP> or set-target <IP>"
    fi
}

# Package Management Shortcuts
alias update='sudo pacman -Syu && yay -Sua'
alias update-shell='bash ~/Desktop/Github/shell/update.sh'
alias p-in='sudo pacman -S'
alias p-rm='sudo pacman -Rns'
alias y-in='yay -S'

# Fast CLI File Manager
alias y='yazi'
