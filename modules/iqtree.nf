process IQTREE {
    publishDir "${params.outdir}/iqtree", mode: 'copy'

    input:
    path(alignment)

    output:
    path("kp_phylogeny.treefile"),      emit: treefile
    path("kp_phylogeny.iqtree"),        emit: iqtree_log
    path("kp_phylogeny.contree"),       emit: contree
    path("kp_phylogeny.log"),           emit: log

    script:
    """
    iqtree \\
        -s ${alignment} \\
        -m ${params.iqtree_model} \\
        -B ${params.iqtree_bootstrap} \\
        -T ${task.cpus} \\
        --prefix kp_phylogeny \\
        --redo
    """
}
