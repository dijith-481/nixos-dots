tempfile=$(mktemp)
kitty -T="fzf-picker" sh -c "fzf > '$tempfile'" || exit 1
selected=$(cat "$tempfile")
rm -f "$tempfile"
wl-copy <"$selected"
