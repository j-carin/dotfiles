function nvm --description "Run nvm-sh from fish"
    set -l nvm_dir "$HOME/.nvm"
    set -l shared_node_dir "$HOME/.local/share/nvm"
    set -l shared_node_link "$shared_node_dir/current"

    if not test -s "$nvm_dir/nvm.sh"
        echo "nvm is not installed at $nvm_dir" >&2
        return 1
    end

    bash -lc '
export NVM_DIR="$1"
shared_node_dir="$2"
shared_node_link="$3"
shift 3

. "$NVM_DIR/nvm.sh"
nvm "$@"
status=$?
default_node=$(nvm which default 2>/dev/null || true)
if [ -n "$default_node" ] && [ -x "$default_node" ]; then
    mkdir -p "$shared_node_dir"
    ln -sfn "$(dirname "$(dirname "$default_node")")" "$shared_node_link"
fi
exit $status
' bash "$nvm_dir" "$shared_node_dir" "$shared_node_link" $argv
    set -l status_code $status

    set -l node_bin "$shared_node_link/bin"
    if test $status_code -eq 0 -a -d "$node_bin"
        if not contains "$node_bin" $PATH
            set -gx PATH "$node_bin" $PATH
        end
    end

    return $status_code
end
