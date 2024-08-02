# Set CDPATH to include $HOME/.config and retain existing $CDPATH
set -gx CDPATH $HOME/.config $CDPATH

# Add `~/.local/bin` to CDPATH if it exists
if test -d $HOME/.local/bin
    set -gx CDPATH $HOME/.local/bin $CDPATH
end

# Remove duplicates from CDPATH
set -gx CDPATH (string split ':' -- $CDPATH | sort | uniq | string join ':')
