#compdef agy-statusline agy-statusline-setup

_agy_statusline() {
    local -a options
    options=(
        '(-h --help)'{-h,--help}'[Show help message and exit]'
        '(-v --version)'{-v,--version}'[Show version information and exit]'
        '(-p --preview)'{-p,--preview}'[Render a sample statusline preview]'
        '--setup[Run configuration setup wizard for Antigravity CLI]'
        '--uninstall[Uninstall statusline configuration and restore backup]'
        '--update[Update agy-statusline to the latest release]'
        '--theme[Specify color theme]:theme:(tokyo-night catppuccin nord solarized light)'
        '--glyphs[Specify glyph mode]:glyphs:(nerd unicode ascii none)'
        '--separator[Specify separator style]:separator:(bar pipe slant bubble slash minimal)'
        '--time-format[Specify time format]:time_format:(relative absolute both)'
        '(-y --yes)'{-y,--yes}'[Run in unattended non-interactive mode]'
    )

    _arguments -s -w : $options
}

_agy_statusline "$@"
