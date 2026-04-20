process ROARY {
    publishDir "${params.outdir}/roary", mode: 'copy'

    input:
    path('*.gff')

    output:
    path("gene_presence_absence.csv"), emit: gene_matrix
    path("core_gene_alignment.aln"), emit: core_aln, optional: true
    path("accessory_graph.dot"), emit: graph, optional: true
    path("summary_statistics.txt"), emit: stats

    script:
    """
    # Roary's internal tools break on paths with spaces (the Nextflow work dir
    # contains "Nextflow pipeline"). Run from a space-free temp directory.
    ORIGINAL_WORKDIR=\$(pwd)
    SAFE_WORKDIR=\$(mktemp -d /tmp/roary_XXXXXX)

    for f in "\${ORIGINAL_WORKDIR}"/*.gff; do
        ln -sf "\$f" "\${SAFE_WORKDIR}/"
    done

    cd "\${SAFE_WORKDIR}"

    roary \\
        -f ./roary_output \\
        -p ${task.cpus} \\
        -i ${params.roary_min_id} \\
        -cd ${params.roary_min_coverage} \\
        *.gff

    # Copy outputs back to the Nextflow work dir for collection
    cp roary_output/gene_presence_absence.csv "\${ORIGINAL_WORKDIR}/"
    [ -f roary_output/core_gene_alignment.aln ] && cp roary_output/core_gene_alignment.aln "\${ORIGINAL_WORKDIR}/"
    [ -f roary_output/accessory_graph.dot ] && cp roary_output/accessory_graph.dot "\${ORIGINAL_WORKDIR}/"

    # Generate summary statistics
    NSAMP=\$(ls *.gff | wc -l)
    echo "Roary Pangenome Analysis Summary"                > "\${ORIGINAL_WORKDIR}/summary_statistics.txt"
    echo "================================"               >> "\${ORIGINAL_WORKDIR}/summary_statistics.txt"
    echo "Total samples: \${NSAMP}"                       >> "\${ORIGINAL_WORKDIR}/summary_statistics.txt"
    echo "Min identity threshold: ${params.roary_min_id}%"    >> "\${ORIGINAL_WORKDIR}/summary_statistics.txt"
    echo "Min coverage threshold: ${params.roary_min_coverage}%" >> "\${ORIGINAL_WORKDIR}/summary_statistics.txt"

    cd "\${ORIGINAL_WORKDIR}"
    """
}
