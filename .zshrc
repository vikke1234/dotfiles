# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh/"
export EDITOR=nvim
export PATH="$HOME/.cargo/bin/:$HOME/bin:$HOME/bin/oss-cad-suite/bin:$PATH"
export FZF_DEFAULT_COMMAND='rg --files --'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export QT_LOGGING_RULES="*=false"

if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    export DISPLAY=$(grep nameserver /etc/resolv.conf | awk '{print $2}'):0.0
    export WINHOME="/mnt/c/Users/$USER"
    export LIBGL_ALWAYS_INDIRECT=1
fi

if [ -r /etc/profile.d/debuginfod.sh ]; then
    source /etc/profile.d/debuginfod.sh
fi
alias ls="ls -lh --color=auto --group-directories-first"
alias vimrc="$EDITOR $HOME/.config/nvim/init.vim"
alias zshrc="$EDITOR $HOME/.zshrc"
alias gdb='gdb --quiet'
alias vim="$EDITOR"
alias pastebinit='pastebinit -a '' -b dpaste.com'

autoload -Uz compinit
compinit

# Emacs keybindings
bindkey -e

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Git branch in prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b)%f'
setopt PROMPT_SUBST

# PS1: user@host:directory (git branch) with colored prompt symbol
PS1='%F{green}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_} %(?..%F{red})%(!.#.$)%f '

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH="$HOME/.local/bin:$PATH"
[ -f ~/.work.bash ] && source ~/.work.bash
