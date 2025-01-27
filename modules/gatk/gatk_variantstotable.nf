process GATK_VARIANTSTOTABLE {
    tag "VARIANT SUMMARY"

    cpus = 4
    memory = 64.GB
    time = '08:00:00'
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

    publishDir "${params.pubdir}/", pattern: "*_table.tsv", mode:'copy'

    container 'broadinstitute/gatk:4.2.2.0'
    
    input:
        path(vcf)
        path(idx)
    output:
        path("*_site_table.tsv"), emit: sites
        path("*_genotype_table.tsv"), emit: genotypes

    script:
    String my_mem = (task.memory-1.GB).toString()
    my_mem =  my_mem[0..-4]

    """
    gatk --java-options '-Xmx${my_mem}G -Djava.io.tmpdir=${params.tmpdir}' \
        VariantsToTable \
            --variant ${vcf} \
            -F CHROM \
            -F POS \
            -F QUAL \
            -F DP \
            -F AD \
            -F MQ \
            -F FILTER \
            --show-filtered \
            --output `basename ${vcf} .vcf`_site_table.tsv
    
    gatk --java-options '-Xmx${my_mem}G -Djava.io.tmpdir=${params.tmpdir}' \
        VariantsToTable \
            --variant ${vcf} \
            -F CHROM \
            -F POS \
            -F FILTER \
            -GF GT \
            -GF DP \
            -GF AD \
            -GF PL \
            --show-filtered \
            --output `basename ${vcf} .vcf`_genotype_table.tsv
    """
}
