{
    whitelist_loop_variables: {
        ["."]: { 'i', 'k', 'v', 'x', 'y', '^_' },
    }
    whitelist_globals: {
        ["."]: { "arg" }
    }
    report_loop_variables: true
    report_params: true
    report_shadowing: true
    report_fndef_reassignments: true
    report_top_level_reassignments: false
}
