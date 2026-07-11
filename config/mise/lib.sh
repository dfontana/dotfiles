# Sourced by mise tasks; not executable, not a bin script.
# Tasks run with cwd=$HOME and set -e, so helpers must not leak nonzero exits.

# Repo root, resolved through the ~/.config/mise symlink.
REPO="$(dirname "$(dirname "$(realpath "${XDG_CONFIG_HOME:-$HOME/.config}/mise")")")"

# Idempotently link $REPO/$1 to $2. Pass 0 as $3 to force-replace.
link() {
  local item=$1
  local dest=$2
  local force=${3:-1}
  local src="$REPO/$item"

  local rc=0
  if [ "$force" -eq 0 ]; then
    ln -sfnT "$src" "$dest" &>/dev/null || rc=$?
  else
    ln -snT "$src" "$dest" &>/dev/null || rc=$?
  fi

  if [ "$rc" -eq 0 ]; then
    echo -e "\t[$item] Linked to $dest"
  elif [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
    echo -e "\t[$item] Exists at $dest"
  elif [ "$force" -eq 0 ]; then
    echo -e "\t[$item] ERROR: could not replace $dest" >&2
    return "$rc"
  else
    echo -e "\t[$item] WARNING: $dest exists but does not point to $src"
  fi
}
