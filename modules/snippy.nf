process SNIPPY {
    tag "${sample_id}"
    publishDir "${params.outdir}/snippy/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)
    path(reference)

    output:
    tuple val(sample_id), path("${sample_id}"), emit: snippy_dir
    path("${sample_id}/${sample_id}.tab"),       emit: tab
    path("${sample_id}/${sample_id}.vcf"),        emit: vcf

    script:
    """
    snippy \\
        --outdir ${sample_id} \\
        --ref ${reference} \\
        --ctgs ${fasta} \\
        --prefix ${sample_id} \\
        --cpus ${task.cpus} \\
        --mincov ${params.snippy_mincov} \\
        --force
    """
}

process SNIPPY_CORE {
    publishDir "${params.outdir}/snippy_core", mode: 'copy'

    input:
    val(snippy_dirs)
    path(reference)

    output:
    path("core.aln"),       emit: core_aln
    path("core.full.aln"),  emit: core_full_aln
    path("core.tab"),       emit: core_tab
    path("core.txt"),       emit: core_txt
    path("core.vcf"),       emit: core_vcf

    script:
    """
    ${snippy_dirs.collect { "ln -sf '${it}' '${it.name}'" }.join('\n    ')}

    snippy-core \\
        --ref ${reference} \\
        --prefix core \\
        ${snippy_dirs.collect { it.name }.join(' ')}
    """
}
