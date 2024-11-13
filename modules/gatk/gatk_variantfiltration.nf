process GATK_VARIANTFILTRATION {

    cpus = 1
    memory = 6.GB
    time = '03:00:00'
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

    container 'broadinstitute/gatk:4.2.2.0'

    publishDir "${params.pubdir}/", pattern: "${outprefix}_variants_bcftools_filtered.vcf", mode:'copy'
    publishDir "${params.pubdir}/", pattern: "${outprefix}_variants_bcftools_filtered.vcf.idx", mode:'copy'

    input:
        path(vcf)
        path(idx)
        tuple path(fasta), path(fasta_fai)
        path(dict)

    output:
        path("${outprefix}_variants_bcftools_filtered.vcf"), emit: vcf
        path("${outprefix}_variants_bcftools_filtered.vcf.idx"), emit: idx

    script:
        String my_mem = (task.memory-1.GB).toString()
        my_mem =  my_mem[0..-4]
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
    mkdir -p tmp
    gatk --java-options "-Xmx${my_mem}G -Djava.io.tmpdir=`pwd`/tmp" VariantFiltration \
    -R ${fasta} \
    -V ${vcf} \
    -O ${outprefix}_variants_bcftools_filtered.vcf \
    --cluster-window-size 10 \
    --filter-name "LowCoverage" --filter-expression \"${params.filter_dp}\" \
    --filter-name "VeryLowQual" --filter-expression \"${params.filter_very_low_qual}\" \
    --filter-name "LowQual" --filter-expression \"${params.filter_low_qual}\" \
    --filter-name "LowQD" --filter-expression \"${params.filter_qd}\" \
    --filter-name "StrandBias" --filter-expression \"${params.filter_fs}\"
    """
}
