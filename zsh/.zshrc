# Zsh History
export HISTFILE=~/.zsh_history # History File Name
export HISTSIZE=1000 # How many commands zsh will load to memory.
export SAVEHIST=2000 # How many commands history will save on file.

# Enable color suppor of ls...
if [ -x /usr/bin/dircolors ]; then
	test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

	alias ls='ls --color=auto'
	
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
	alias diff='diff --color=auto'
	alias ip='ip --color=auto'
fi

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias vi='nvim'
alias vim='nvim'

# zsh plugins
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Starship
eval "$(starship init zsh)"