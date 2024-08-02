# Print to stderr
function _cnf_print
    echo 1>&2 $argv
end

set _cnf_action
set _cnf_askfirst true
set _cnf_force_su false
set _cnf_noprompt false
set _cnf_noupdate true
set _cnf_verbose true

function _cnf_asroot
    if test (id -u) -ne 0
        if $_cnf_force_su
            su -c "$argv"
        else
            sudo $argv
        end
    else
        $argv
    end
end

function _cnf_prompt_yn --argument-name prompt
    read --prompt="echo \"fish: $prompt [Y/n] \"" result
    or kill -s INT $fish_pid
    switch "$result"
        case 'y*' 'Y*' ''
            return 0
        case '*'
            return 1
    end
end

if $_cnf_noupdate
    function _cnf_need_to_update_files
        return 1
    end
else
    function _cnf_need_to_update_files
        return 0 # No need to update files for apt
    end
end

function _cnf_command_packages
    set cmd $argv[1]
    if _cnf_need_to_update_files
        _cnf_asroot apt update >&2
    end
    apt-cache search --names-only $cmd | awk '{print $1}' | sort -u
end

function _cnf_package_files
    set package $argv[1]
    apt-file list $package
end

# Don't show pre-search warning if 'quiet' option is not set
if $_cnf_verbose
    function _cnf_pre_search_warn
        set cmd $argv[1]
        _cnf_print "fish: \"$cmd\" is not found locally, searching in repositories..."
        return 0
    end
else
    function _cnf_pre_search_warn
        return 0
    end
end

if $_cnf_askfirst
    # When askfirst is given, override default verbose behavior
    function _cnf_pre_search_warn
        set cmd $argv[1]
        _cnf_prompt_yn "\"$cmd\" is not found locally, search in repositories?"
        return $status
    end
end

function _cnf_cmd_not_found
    set cmd $argv[1]
    _cnf_print "fish: command not found: \"$cmd\""
    return 127
end

function fish_command_not_found
    set cmd $argv[1]
    _cnf_pre_search_warn "$cmd" || return 127
    set packages (_cnf_command_packages $cmd)
    switch (count $packages)
        case 0
            _cnf_cmd_not_found $cmd
        case 1
            _cnf_print "fish: \"$cmd\" may be found in package: $packages"
            _cnf_print "sudo nala install $packages"
        case '*'
            _cnf_print "fish: \"$cmd\" may be found in the following packages:"
            for package in $packages
                _cnf_print "$package"
            end
    end
end

function __fish_command_not_found_handler \
    --on-event fish_command_not_found
    fish_command_not_found $argv
end

# Clean up environment
set -e opt _cnf_askfirst _cnf_noprompt _cnf_noupdate _cnf_verbose
