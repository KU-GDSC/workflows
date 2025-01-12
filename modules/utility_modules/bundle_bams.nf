process BUNDLE_BAMS {

  cpus 1
  memory 5.GB
  time '00:05:00'

  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container "quay.io/jaxcompsci/perl:0.1.0"

  input:
    path(bams), stageAs: "bam_dir/*"
    path(bais), stageAs: "bam_dir/*"

  output:
    path("bam_dir"), emit: bam_dir

  script:
  """
  touch testing
  """
}
