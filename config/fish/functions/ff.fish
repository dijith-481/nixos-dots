function ff
    set -l width (tput cols)
    set -l height (tput lines)
    set -l term (basename "/"(ps -o cmd -f -p (cat /proc/(echo %self)/stat | cut -d \  -f 4) | tail -1 | sed 's/ .*$//'))
    # echo $term
    if test $term = foot
        if test $width -ge 70 -a $height -ge 8
            eval fastfetch
            # else if test $width -ge 30 -a $height -ge  10 
            # eval fastfetch -c ~/.config/fastfetch/small.jsonc
        end
    else if test $term = ghostty
        if test $width -ge 70 -a $height -ge 8
            eval fastfetch -c ~/.config/fastfetch/ghostty.jsonc
        end
    end
end
