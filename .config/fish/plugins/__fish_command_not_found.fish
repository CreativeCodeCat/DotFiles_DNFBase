# If an old handler already exists, defer to that.
# Print to stderr
function _cnf_print
    echo 1>&2 $argv
end

set _cnf_action
set _cnf_askfirst false
set _cnf_force_su false
set _cnf_noprompt false
set _cnf_noupdate false
set _cnf_verbose true

set _cnf_actions install info "list files" "list files (paged)"

# Parse options
for opt in $argv
    switch "$opt"
        case askfirst
            set _cnf_askfirst true
        case noprompt
            set _cnf_noprompt true
        case noupdate
            set _cnf_noupdate true
        case su
            set _cnf_force_su true
        case quiet
            set _cnf_verbose false
        case install
            set _cnf_action $_cnf_actions[1]
        case info
            set _cnf_action $_cnf_actions[2]
        case list_files
            set _cnf_action $_cnf_actions[3]
        case list_files_paged
            set _cnf_action $_cnf_actions[4]
        case '*'
            _cnf_print "fish: unknown option: $opt"
    end
end

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
    apt-cache search --names-only $cmd
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

# Without installation prompt
if $_cnf_noprompt
    function fish_command_not_found
        set cmd $argv[1]
        _cnf_pre_search_warn "$cmd" || return 127
        set packages (_cnf_command_packages $cmd)
        switch (count $packages)
            case 0
                _cnf_cmd_not_found $cmd
            case 1
                _cnf_print "fish: \"$cmd\" may be found in package \"$packages\""
            case '*'
                _cnf_print "fish: \"$cmd\" may be found in the following packages:"
                for package in $packages
                    _cnf_print "\t$package"
                end
        end
    end
else
    # With installation prompt (default)
    function _cnf_check_fzf
        if ! which fzf >/dev/null 2>/dev/null
            if _cnf_prompt_yn "Gathering input requires 'fzf', install it?"
                _cnf_asroot apt install fzf
            end
            if ! which fzf >/dev/null 2>/dev/null
                return 1
            end
        end
        return 0
    end

    function fish_command_not_found
        set cmd $argv[1]
        set scroll_header "Shift up or down to scroll the preview"
        _cnf_pre_search_warn $cmd || return 127
        set packages (_cnf_command_packages $cmd)
        switch (count $packages)
            case 0
                _cnf_cmd_not_found $cmd
            case 1
                function _cnf_prompt_install
                    set packages $argv[1]
                    if _cnf_prompt_yn "Would you like to install '$packages'?"
                        _cnf_asroot apt install $packages
                    else
                        return 127
                    end
                end

                set action
                if test -z $_cnf_action
                    set may_be_found "\"$cmd\" may be found in package \"$packages\""
                    _cnf_print "fish: $may_be_found"
                    if _cnf_check_fzf
                        set package_files (_cnf_package_files $packages | string collect)
                        set package_info (apt show $packages | string collect)
                        set action (printf "%s\n" $_cnf_actions | \
                            fzf --preview "echo {} | grep -q '^list' && echo '$package_files' \
                                    || echo '$package_info'" \
                                --prompt "Action (\"esc\" to abort):" \
                                --header "$may_be_found
$scroll_header")
                    else
                        return 127
                    end
                else
                    set action $_cnf_action
                end

                switch $action
                    case install
                        _cnf_asroot apt install $packages
                    case info
                        apt show $packages
                        _cnf_prompt_install $packages
                    case 'list files'
                        _cnf_package_files $packages
                        _cnf_prompt_install $packages
                    case 'list files (paged)'
                        test -z $pager && set --local pager less
                        _cnf_package_files $packages | $pager
                        _cnf_prompt_install $packages
                    case '*'
                        return 127
                end
            case '*'
                set package
                _cnf_print "fish: \"$cmd\" may be found in the following packages:"
                for package in $packages
                    _cnf_print "\t$package"
                end
                if _cnf_check_fzf
                    set package (printf "%s\n" $packages | \
                        fzf --bind="tab:preview(type pkgfile >/dev/null 2>/dev/null && \
                                pkgfile --list {} | sed 's/[^[:space:]]*[[:space:]]*//' || \
                                apt-file list {})" \
                            --preview "apt show {}" \
                            --header "Press \"tab\" to view files
$scroll_header" \
                            --prompt "Select a package to install (\"esc\" to abort):")
                else
                    return 127
                end
                if test -n $package
                    _cnf_asroot apt install $package
                else
                    return 127
                end
        end
    end
end

function __fish_command_not_found_handler \
    --on-event fish_command_not_found
    fish_command_not_found $argv
end

# Clean up environment
set -e opt _cnf_askfirst _cnf_noprompt _cnf_noupdate _cnf_verbose
