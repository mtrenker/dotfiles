# Sourced by a mise-managed block in ~/.bashrc, not a replacement for that file.
[[ $- == *i* ]] || return
[[ ${_DOTFILES_BASH_LOADED:-} == 1 ]] && return
_DOTFILES_BASH_LOADED=1

alias ..='cd ..'
alias ...='cd ../..'
alias vi='nvim'
alias vim='nvim'
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lh --group-directories-first'
  alias la='eza -lah --group-directories-first'
  alias tree='eza --tree'
fi
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
command -v rg >/dev/null 2>&1 && alias grep='rg'
command -v fd >/dev/null 2>&1 && alias find='fd'
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gs='git status -sb'

mkcd() {
  if [[ $# != 1 || -z $1 ]]; then
    printf 'Usage: mkcd <directory>\n' >&2
    return 2
  fi
  mkdir -p -- "$1" && cd -- "$1"
}

up() {
  local count=${1:-1} i
  if [[ $# -gt 1 || ! $count =~ ^[0-9]+$ || ${#count} -gt 4 ]]; then
    printf 'Usage: up [0-9999]\n' >&2
    return 2
  fi
  for ((i = 0; i < 10#$count; i++)); do
    cd .. || return
  done
}

# These applications are pacman-managed. Missing tools must not break a shell.
command -v fzf >/dev/null 2>&1 && eval "$(fzf --bash)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# Optional private overrides. Never tracked or overwritten by bootstrap.
[[ ! -f "$HOME/.bashrc.local" ]] || source "$HOME/.bashrc.local"
return 0
