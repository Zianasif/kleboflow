process AMRFINDER {
    tag "${sample_id}"
    publishDir "${params.outdir}/amrfinder/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(faa)

    output:
    path("${sample_id}_amrfinder.tsv"), emit: tsv

    script:
    """
    amrfinder \\
        --protein ${faa} \\
        --organism ${params.amrfinder_organism} \\
        --plus \\
        --output ${sample_id}_amrfinder.tsv \\
        --threads ${task.cpus}
    """
}

process AMRFINDER_SUMMARY {
    publishDir "${params.outdir}/amrfinder", mode: 'copy'

    input:
    path(tsvs)

    output:
    path("amrfinder_summary.tsv"), emit: summary

    script:
    """
    # Add sample name column and merge all results
    files=(${tsvs})
    # Write header with Sample column
    echo -e "Sample\\t\$(head -1 \${files[0]})" > amrfinder_summary.tsv
    for f in \${files[@]}; do
        sample=\$(basename "\$f" _amrfinder.tsv)
        tail -n +2 "\$f" | awk -v s="\$sample" 'OFS="\\t" {print s, \$0}' >> amrfinder_summary.tsv
    done
    """
}
