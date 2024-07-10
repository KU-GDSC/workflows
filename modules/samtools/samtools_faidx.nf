process SAMTOOLS_FAIDX {
  tag "${fasta}"

  cpus 1
  memory 8.GB
  time '06:00:00'
  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}
  
  container 'quay.io/biocontainers/samtools:1.14--hb421002_0'

  publishDir "${params.pubdir}/reference", mode: 'copy', enabled: params.save_references

  input:
    path(fasta)

  output:
    tuple path(fasta), path("${fasta}.fai"), emit: fasta_fai

  script:
    """
    samtools faidx ${fasta}
    """
}