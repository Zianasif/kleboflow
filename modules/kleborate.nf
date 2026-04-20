process KLEBORATE {
    tag "${sample_id}"
    publishDir "${params.outdir}/kleborate", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path("${sample_id}_kleborate.txt"), emit: results

    script:
    """
    kleborate \\
        --assemblies ${fasta} \\
        --preset kpsc \\
        --outdir ${sample_id}_kleborate_out
    cp ${sample_id}_kleborate_out/klebsiella_pneumo_complex_output.txt ${sample_id}_kleborate.txt
    """
}

process KLEBORATE_SUMMARY {
    publishDir "${params.outdir}/kleborate", mode: 'copy'

    input:
    path(results)

    output:
    path("kleborate_summary.tsv"), emit: summary

    script:
    """
    # Merge all Kleborate results - first file has header, rest skip it
    files=(${results})
    head -1 \${files[0]} > kleborate_summary.tsv
    for f in \${files[@]}; do
        tail -n +2 "\$f" >> kleborate_summary.tsv
    done
    """
}
