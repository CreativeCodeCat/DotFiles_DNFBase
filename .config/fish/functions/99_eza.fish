#list comamnds
function l
    eza $argv --icons=always
end

function ls
    eza $argv --icons=always
end

function la
    ls -a
end

function ll
    ls -l
end

function lla
    ls -la
end

function lt
    ls --tree
end

function lg
    ls -a | grep -E $argv
end
