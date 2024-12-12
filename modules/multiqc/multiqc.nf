process MULTIQC {

    cpus 1
    memory 16.GB
    time '1:00:00'

    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

    container 'quay.io/biocontainers/multiqc:1.25.2--pyhdfd78af_0'

    publishDir "${params.pubdir}/multiqc", pattern: "*multiqc_report.html", mode:'copy'
    publishDir "${params.pubdir}/multiqc", pattern: "*_data", mode:'copy'

    input:
        path multiqc_files

    output:
        path "*multiqc_report.html", emit: report
        path "*_data" , emit: data
        path "*_plots" , optional:true, emit: plots

    script:
        def custom_config = params.multiqc_config ? " --config $params.multiqc_config " : ''
    """
        multiqc . ${custom_config}
    """

}
