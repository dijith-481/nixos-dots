# Home Manager passes one conflicting file per invocation.
# --no-target-directory also handles a backup path that is a directory or symlink.
# GNU mv numbers the previous backup before placing the current file there.
if [ "$#" -ne 1 ]; then
  echo "usage: home-manager-backup FILE" >&2
  exit 1
fi
mv --backup=numbered --no-target-directory -- "$1" "$1.backup"
