_agy_statusline() {
    local cur prev opts themes glyphs seps timefmts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="-h --help -v --version -p --preview --setup --uninstall --update"
    themes="tokyo-night catppuccin nord solarized light"
    glyphs="nerd unicode ascii none"
    seps="bar pipe slant bubble slash minimal"
    timefmts="relative absolute both"

    case "${prev}" in
        --theme)
            COMPREPLY=( $(compgen -W "${themes}" -- "${cur}") )
            return 0
            ;;
        --glyphs)
            COMPREPLY=( $(compgen -W "${glyphs}" -- "${cur}") )
            return 0
            ;;
        --separator)
            COMPREPLY=( $(compgen -W "${seps}" -- "${cur}") )
            return 0
            ;;
        --time-format)
            COMPREPLY=( $(compgen -W "${timefmts}" -- "${cur}") )
            return 0
            ;;
        --setup)
            COMPREPLY=( $(compgen -W "-y --yes --theme --glyphs --separator --time-format" -- "${cur}") )
            return 0
            ;;
        *)
            ;;
    esac

    if [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
        return 0
    fi
}
complete -F _agy_statusline agy-statusline
complete -F _agy_statusline agy-statusline-setup
