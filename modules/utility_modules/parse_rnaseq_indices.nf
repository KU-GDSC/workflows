process PARSE_RNASEQ_INDICES {
  tag "index"

  cpus 1
  memory 5.GB
  time '00:05:00'

  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container "quay.io/jaxcompsci/perl:0.1.0"

  input:
    path(rsem_bundle)
    path(rsem_chrlist), stageAs: "avoid_collision/*"

  output:
    path("rsem_${params.rsem_aligner}/*.dict"), emit: dict
    path("rsem_${params.rsem_aligner}/*.refFlat.txt"), emit: refFlat
    path("rsem_${params.rsem_aligner}/*.rRNA_intervals.list"), emit: rRNA_intervals
    path("rsem_${params.rsem_aligner}"), emit: rsem_index
    path("rsem_${params.rsem_aligner}/${rsem_chrlist.baseName}.gtf"), emit: rsem_gtf
    path("rsem_${params.rsem_aligner}/${rsem_chrlist.baseName}.transcripts.fa"), emit: rsem_transcripts
    val("${rsem_chrlist.baseName}"), emit: rsem_basename
    path("rsem_${params.rsem_aligner}/kallisto_index"), emit: kallisto_index

  script:
  if (params.rsem_aligner == "bowtie2") {
      """
      rsem_basename=${rsem_chrlist.baseName}
      mkdir rsem_${params.rsem_aligner}
      mv kallisto_index rsem_${params.rsem_aligner}/
      mv *.refFlat.txt rsem_${params.rsem_aligner}/
      mv *.rRNA_intervals.list rsem_${params.rsem_aligner}/
      mv *.dict rsem_${params.rsem_aligner}/
      mv ${rsem_chrlist.baseName}.* rsem_${params.rsem_aligner}/
      """
  } else if (params.rsem_aligner == "star") {
      """
      rsem_basename=${rsem_chrlist.baseName}
      mkdir rsem_${params.rsem_aligner}
      mv kallisto_index rsem_${params.rsem_aligner}/
      mv *.refFlat.txt rsem_${params.rsem_aligner}/
      mv *.rRNA_intervals.list rsem_${params.rsem_aligner}/
      mv *.dict rsem_${params.rsem_aligner}/
      mv ${rsem_chrlist.baseName}.* rsem_${params.rsem_aligner}/
      mv chrLength.txt rsem_${params.rsem_aligner}/
      mv exonGeTrInfo.tab rsem_${params.rsem_aligner}/
      mv chrNameLength.txt rsem_${params.rsem_aligner}/
      mv exonInfo.tab rsem_${params.rsem_aligner}/
      mv chrName.txt rsem_${params.rsem_aligner}/
      mv geneInfo.tab rsem_${params.rsem_aligner}/
      mv chrStart.txt rsem_${params.rsem_aligner}/
      mv Genome rsem_${params.rsem_aligner}/
      mv genomeParameters.txt rsem_${params.rsem_aligner}/
      mv Log.out rsem_${params.rsem_aligner}/
      mv SA rsem_${params.rsem_aligner}/
      mv SAindex rsem_${params.rsem_aligner}/
      mv sjdbInfo.txt rsem_${params.rsem_aligner}/
      mv sjdbList.fromGTF.out.tab rsem_${params.rsem_aligner}/
      mv sjdbList.out.tab rsem_${params.rsem_aligner}/
      mv transcriptInfo.tab rsem_${params.rsem_aligner}/
      """
  } else {
    error("The workflow " ${params.workflow} " or the aligner " ${params.rsem_aligner} " is not currently supported")
  }
}
