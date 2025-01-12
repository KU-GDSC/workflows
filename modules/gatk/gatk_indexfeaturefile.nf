process GATK_INDEXFEATUREFILE {

    cpus = 1
    memory = 6.GB
    time = '03:00:00'
    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

    publishDir "${params.pubdir}/", pattern: "*.idx", mode:'copy', enabled: params.keep_intermediate

    container 'broadinstitute/gatk:4.2.2.0'

    input:
        path(vcf)

    output:
        path("*.vcf.idx"), emit: idx

    script:
        String my_mem = (task.memory-1.GB).toString()
        my_mem =  my_mem[0..-4]
    """
    mkdir -p tmp
    gatk --java-options "-Xmx${my_mem}G -Djava.io.tmpdir=`pwd`/tmp" IndexFeatureFile \
    -I ${vcf}
    """
}
