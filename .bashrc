##################################
# 追加しているコマンド
# alias ll='ls -alF'
# alias la='ls -A'
# alias l='ls -CF'
# peco setting history
#  command : ctrl + r
# peco setting ssh
#  command : s
# peco cd
#  command : sd
# peco ghq
#  command: ctrl + i
##################################

##################################
# If not running interactively, don't do anything
##################################
case $- in
    *i*) ;;
      *) return;;
esac

##################################
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
##################################
HISTCONTROL=ignoreboth

##################################
# append to the history file, don't overwrite it
##################################
shopt -s histappend

##################################
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
##################################
HISTSIZE=1000
HISTFILESIZE=2000

##################################
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
##################################
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

##################################
# make less more friendly for non-text input files, see lesspipe(1)
##################################
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

##################################
# set variable identifying the chroot you work in (used in the prompt below)
##################################
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi
##################################
# set a fancy prompt (non-color, unless we know we "want" color)
##################################
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

##################################
# If this is an xterm set the title to user@host:dir
##################################
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

##################################
# enable color support of ls and also add handy aliases
##################################
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

##################################
# some more ls aliases
##################################
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

##################################
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
##################################
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

##################################
# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
##################################
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

##################################
# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
##################################
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

##################################
# peco setting history
# command : ctrl + r
##################################
export HISTCONTROL="ignoredups"
peco-history() {
  local NUM=$(history | wc -l)
  local FIRST=$((-1*(NUM-1)))

  if [ $FIRST -eq 0 ] ; then
    history -d $((HISTCMD-1))
    echo "No history" >&2
    return
  fi

  local CMD=$(fc -l $FIRST | sort -k 2 -k 1nr | uniq -f 1 | sort -nr | sed -E 's/^[0-9]+[[:blank:]]+//' | peco | head -n 1)

  if [ -n "$CMD" ] ; then
    history -s $CMD
    if type osascript > /dev/null 2>&1 ; then
      (osascript -e 'tell application "System Events" to keystroke (ASCII character 30)' &)
    fi

    # Directory selected command execute
    echo $CMD >&2
    eval $CMD
  else
    history -d $((HISTCMD-1))
  fi
}
bind -x '"\C-r":peco-history'

##################################
# peco setting ssh
# command : s
##################################
function peco-ssh () {
  local selected_host=$(awk '
  tolower($1)=="host" {
    for (i=2; i<=NF; i++) {
      if ($i !~ "[*?]") {
        print $i
      }
    }
  }
  ' ~/.ssh/config | sort | peco --query "$LBUFFER")
  if [ -n "$selected_host" ]; then
    ssh ${selected_host}
  fi
}
alias s='peco-ssh'

##################################
# pyenv path setting
##################################
export PATH=~/.pyenv/bin:$PATH
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

##################################
# pip path setting
##################################
export PATH=$HOME/.local/bin:$PATH

##################################
# peco cd
# command : sd
##################################
function peco-cd {
  local sw="1"
  while [ "$sw" != "0" ]
  do
		if [ "$sw" = "1" ];then
			local list=$(echo -e "---$PWD\n../\n$( ls -F | grep / )\n---Show hidden directory\n---Show files, $(echo $(ls -F | grep -v / ))\n---HOME DIRECTORY")
		elif [ "$sw" = "2" ];then
			local list=$(echo -e "---$PWD\n$( ls -a -F | grep / | sed 1d )\n---Hide hidden directory\n---Show files, $(echo $(ls -F | grep -v / ))\n---HOME DIRECTORY")
		else
			local list=$(echo -e "---BACK\n$( ls -F | grep -v / )")
		fi

		local slct=$(echo -e "$list" | peco )

		if [ "$slct" = "---$PWD" ];then
			local sw="0"
		elif [ "$slct" = "---Hide hidden directory" ];then
			local sw="1"
		elif [ "$slct" = "---Show hidden directory" ];then
			local sw="2"
		elif [ "$slct" = "---Show files, $(echo $(ls -F | grep -v / ))" ];then
			local sw=$(($sw+2))
		elif [ "$slct" = "---HOME DIRECTORY" ];then
			cd "$HOME"
		elif [[ "$slct" =~ / ]];then
			cd "$slct"
		elif [ "$slct" = "" ];then
			:
		else
			local sw=$(($sw-2))
		fi
  done
}
alias sd='peco-cd'

##################################
# peco ghq
##################################
function ghql() {
  local selected_file=$(ghq list --full-path | peco --query "$LBUFFER")
  if [ -n "$selected_file" ]; then
    if [ -t 1 ]; then
      echo ${selected_file}
      cd ${selected_file}
      pwd
    fi
  fi
}
bind -x '"\201": ghql'
bind '"\C-g":"\201\C-m"'

##################################
# Golang ver 1.10
# go path set
##################################
export GOPATH=~/go
export PATH=$PATH:/usr/lib/go-1.10/bin
export PATH=$PATH:$GOPATH/bin

##################################
# less の設定
##################################
export LESS='-g -i -M -R -S -W -z-4 -x4 -gj10 --no-init --quit-if-one-screen -N'
export LESSOPEN='| /usr/share/source-highlight/src-hilite-lesspipe.sh %s'

# PAGER に less を設定
export PAGER=less

# man したときの less に色をつける
export LESS_TERMCAP_mb=$'\E[01;31m'      # Begins blinking.
export LESS_TERMCAP_md=$'\E[01;31m'      # Begins bold.
export LESS_TERMCAP_me=$'\E[0m'          # Ends mode.
export LESS_TERMCAP_se=$'\E[0m'          # Ends standout-mode.
export LESS_TERMCAP_so=$'\E[00;47;30m'   # Begins standout-mode.
export LESS_TERMCAP_ue=$'\E[0m'          # Ends underline.
export LESS_TERMCAP_us=$'\E[01;32m'      # Begins underline.