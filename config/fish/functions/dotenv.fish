function dotenv
    # Check if the .env file exists
    if not test -f .env
        echo "Error: .env file not found."
        return 1
    end

    # Read the .env file line by line
    while read -l line
        # Skip comments and empty lines
        if string match -q -- '#' $line || string match -q -- '^[[:space:]]*$' $line
            continue
        end

        # Split the line into a key and a value
        set -l key_val (string split -n -m 1 '=' $line)
        set -l key $key_val[1]
        set -l val $key_val[2]

        # Set the environment variable
        set -gx $key $val
        echo "Exported $key"
    end <.env
end
