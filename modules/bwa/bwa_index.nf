process BWA_INDEX {
  tag "${fasta}"

  cpus 1
  memory 8.GB
  time '06:00:00'
  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}
  
  container 'quay.io/biocontainers/bwa:0.7.17--hed695b0_6'

  publishDir "${params.pubdir}/index", mode: 'copy', pattern: "${fasta}.*", enabled: params.keep_reference

  input:
    path(fasta)

  output:
    tuple path("${fasta}.amb"), path("${fasta}.ann"), path("${fasta}.bwt"), path("${fasta}.pac"), path("${fasta}.sa"), emit: bwa_index

  script:
    """
    bwa index ${fasta}
    """
}
