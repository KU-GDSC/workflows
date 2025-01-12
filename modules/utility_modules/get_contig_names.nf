process GET_CONTIG_NAMES {

  cpus 1
  memory 5.GB
  time '00:05:00'

  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container "quay.io/jaxcompsci/perl:0.1.0"

  input:
    path(fasta)

  output:
    path("contig_names.list"), emit: contig_names

  script:
  """
  grep ">" ${fasta} | sed -e 's/>//g' | tr -s [:blank:] | cut -f 1 | cut -f 1 -d ' ' | sort | uniq > contig_names.list
  """
}
