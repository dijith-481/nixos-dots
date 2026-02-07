function dotenv
    set -l config_file .env
    if test -n "$argv[1]"
        set config_file $argv[1]
    end

    if not test -f "$config_file"
        return 1
    end

    while read -l line
        set -l clean_line (string trim -- $line)
        if test -z "$clean_line"; or string match -q -- "#*" $clean_line
            continue
        end

        set -l kv (string split -m 1 = -- $clean_line)
        set -l key (string trim -- $kv[1])
        set -l val (string trim -- $kv[2])

        if string match -q -r "^'.*'\$" -- $val
            set val (string sub -s 2 -e -1 -- $val)
        else if string match -q -r '^".*"$' -- $val
            set val (string sub -s 2 -e -1 -- $val)
        end

        set -gx "$key" $val
        echo "Exported $key"
    end <$config_file
end
