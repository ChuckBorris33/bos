# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
#Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

plugins=(zsh-autosuggestions zsh-syntax-highlighting fzf-tab)

source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"
eval "$(zoxide init zsh --cmd cd)"
eval "$(fnm env --use-on-cd --shell zsh)"
DIRENV_LOG_FORMAT="" 
eval "$(direnv hook zsh)"

