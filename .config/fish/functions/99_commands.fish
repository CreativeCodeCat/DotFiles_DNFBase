# DotFiles_APTBase
function dotfiles
    /usr/bin/git --git-dir=$HOME/.DotFiles_APTBase/ --work-tree=$HOME $argv
end


# Unlock user from passwords
function ulock
    command faillock --reset
end

# Check ports for current user
function ports
    command sudo netstat -tulanp
end

# Set permissions for user
function setperm
    command sudo chown $USER:$USER $argv
end

# Fixed bluetooth
function fixbt
    command sudo rmmod btusb
    command sudo modprobe btusb 
end

# Clear command
function clear
    command reset && fastfetch
end

# free
function free
    command free -mt
end

# continue download
function wget
    command wget -c $argv
end

# grub update
function update-grub
    command sudo grub-mkconfig -o /boot/grub/grub.cfg
end

# add new fonts
function update-fonts
    command fc-cache -fv
end

function reload
    source ~/.config/fish/config.fish
end
