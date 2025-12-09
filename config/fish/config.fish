if status is-interactive
    # Commands to run in interactive sessions can go here
    # set -g fish_key_bindings fish_vi_key_bindings
end
# if status is-login
#     if test (tty) = /dev/tty1
#         systemctl --user start niri.service
#     end
#
#     if test (tty) = /dev/tty2
#         hyprland &>/dev/null
#     end
# end
set -g fish_greeting
starship init fish | source
zoxide init fish | source
fzf --fish | source
kdlfmt completions fish | source
# ng completion script | source

# thefuck --alias | source
# fastfetch
ff

bind -M insert ctrl-y accept-autosuggestion
function ll
    ls -al $argv
end
function la
    ls -a $argv
end

function vi
    nvim $argv
end

#function hx
#    helix $argv
#end

# bun
# set --export BUN_INSTALL "$HOME/.bun"
# set --export PATH $BUN_INSTALL/bin $PATH
#
# set --export PATH $HOME/.local/share/nvim/mason/bin $PATH
# #go
# set --export PATH $HOME/go/bin $PATH
# set --export PATH $HOME/.local/bin $PATH
# # set -gx JAVA_HOME /opt/android-studio/jbr
# set --export JAVA_HOME /opt/android-studio/jbr
# set --export ANDROID_HOME ~/Android/Sdk/
# set --export ANDROID_NDK_HOME ~/Android/Sdk/ndk/29.0.13113456/
# set --export PATH ~/Android/Sdk/emulator/ $PATH
# set --export PATH $HOME/.pub-cache/bin $PATH
# fish_add_path -g -p ~/development/flutter/bin
# # vars
# set -gx PYENV_ROOT $HOME/.pyenv
# set -gx PATH $PYENV_ROOT/bin $PATH
# pyenv init - | source
