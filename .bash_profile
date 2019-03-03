# 起動時に自動で .bashrc を読み込む
if [ -f ~/.bashrc ] ; then
  . ~/.bashrc
fi


# 初回シェル時のみ tmux 実行
if [ $SHLVL = 1 ]; then
  tmux
fi
