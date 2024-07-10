process BCFTOOLS_CONCAT {
    tag "MERGE_VARIANTS"

    cpus = 1
    memory = 60.GB
    time = '6:00:00'
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

    publishDir "${params.pubdir}/", pattern: "${outprefix}_variants_bcftools_raw.vcf", mode:'copy'
    
    container 'quay.io/biocontainers/bcftools:1.15--h0ea216a_2'
    
    input:
        path(vcfs) 

    output:
        path "${outprefix}_variants_bcftools_raw.vcf", emit: vcf

    script:
    
    if (params.workflow == "wgs") {
        outprefix="wgs_cohort"
    }
    else if (params.workflow == "rad_variants") {
        outprefix="rad_cohort"
    }
    else {
        exit 1, "ERROR: '--workflow ${params.workflow}' is not supported by this module."
    }
    """
    ls *.vcf | sort > vcf_list.txt

    bcftools concat \
        -f vcf_list.txt \
        --threads ${task.cpus} \
        -Ov \
        -o ${outprefix}_variants_bcftools_raw.vcf
    """
}
