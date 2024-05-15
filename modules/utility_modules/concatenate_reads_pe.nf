// Adapted from JAX Nextflow pipelines https://github.com/TheJacksonLaboratory/cs-nf-pipelines/blob/main/modules/utility_modules/concatenate_reads_PE.nf 

process CONCATENATE_READS_PE {
  tag "${sampleID}"

  cpus 1
  memory 5.GB
  time '01:00:00'

  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container "quay.io/gdsc/debian-utility:bookworm-slim"

  input:
    tuple val(sampleID), path(R1), path(R2)

  output:
    tuple val(sampleID), path("${sampleID}_R1${params.extension}"), path("${sampleID}_R2${params.extension}"), emit: concat_fastq

  script:
    """
    cat ${R1} > ${sampleID}_R1${params.extension}
    cat ${R2} > ${sampleID}_R2${params.extension}
    """
  }
