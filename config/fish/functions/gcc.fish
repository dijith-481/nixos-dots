function gcc
    if test (count $argv) -eq 1
        set filename (basename $argv[1] .c)
        mkdir -p output && gcc "$argv[1]" -o "output/$filename"
    else
        command gcc $argv
    end
end
