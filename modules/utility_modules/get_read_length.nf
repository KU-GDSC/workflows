process GET_READ_LENGTH {
  tag "$sampleID"

  cpus 1
  memory 5.GB
  time '00:05:00'

  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container "quay.io/jaxcompsci/perl:0.1.0"

  input:
  tuple val(sampleID), path(reads)

  output:
  tuple val(sampleID), env(READ_LENGTH), emit: read_length

  script:
  """
  READ_LENGTH=`zcat ${reads[0]} | head -n 400 | awk 'NR%4==2{m=length(\$0)}{print m}' | sort -n | tail -1`
  """
}
