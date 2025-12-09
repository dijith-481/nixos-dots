function print_osc7 --on-variable=PWD
    printf "\033]7;file://$HOSTNAME/$PWD\033\\"
end
