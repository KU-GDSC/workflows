process BCFTOOLS_MPILEUP_INTERVAL {
    tag "${interval}"

    cpus = 1
    memory = 60.GB
    time = '6:00:00'
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

    container 'quay.io/biocontainers/bcftools:1.15--h0ea216a_2'
    
    input:
        tuple path(bam_dir), val(interval), path(fasta), path(fai)

    output:
        path "${interval}.vcf", emit: vcf

    script:
    variants = params.variants_only ? "-v" : ''
    indels = params.skip_indels ? "-I" : '' 
    """
    ls ${bam_dir}/*.bam > bam_list.txt
    
    bcftools mpileup \
        -Ou ${indels} \
        -a FORMAT/DP,FORMAT/AD,FORMAT/ADF,FORMAT/ADR,INFO/AD,INFO/ADF,INFO/AD \
        --max-depth=${params.mpileup_depth} \
        -r ${interval} \
        -f ${fasta} \
        -b bam_list.txt | \
    bcftools call \
        --ploidy ${params.ploidy} \
        -m ${variants} \
        -O v \
        -o ${interval}.vcf
    """
}
