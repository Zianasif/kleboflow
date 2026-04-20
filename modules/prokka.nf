process PROKKA {
    tag "${sample_id}"
    publishDir "${params.outdir}/prokka/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    tuple val(sample_id), path("${sample_id}.gff"), emit: gff
    tuple val(sample_id), path("${sample_id}.gbk"), emit: gbk
    tuple val(sample_id), path("${sample_id}.faa"), emit: faa
    tuple val(sample_id), path("${sample_id}.ffn"), emit: ffn
    tuple val(sample_id), path("${sample_id}.txt"), emit: txt

    script:
    """
    prokka \\
        --outdir . \\
        --prefix ${sample_id} \\
        --genus ${params.prokka_genus} \\
        --species ${params.prokka_species} \\
        --strain ${sample_id} \\
        --kingdom Bacteria \\
        --cpus ${task.cpus} \\
        --force \\
        ${fasta}
    """
}
