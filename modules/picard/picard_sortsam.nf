process PICARD_SORTSAM {
  tag "$sampleID"

  cpus 1
  memory { sam.size() < 60.GB ? 24.GB : 48.GB }
  time { sam.size() < 60.GB ? '03:00:00' : '12:00:00' }

  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container "broadinstitute/gatk:4.2.2.0"

  publishDir "${params.pubdir}/${ params.organize_by=='sample' ? sampleID+'/bam' : 'picard' }", pattern: "*_sortsam.bam", mode:'copy', enabled: params.keep_intermediate && params.workflow == 'rnaseq' || params.workflow == 'microbial_rnaseq'

  input:
    tuple val(sampleID), file(sam)

  output:
    tuple val(sampleID), file("*_sortsam.bam"), emit: bam
    tuple val(sampleID), file("*_sortsam.bai"), emit: bai

  script:
    String my_mem = (task.memory-1.GB).toString()
    my_mem =  my_mem[0..-4]

    """
    gatk --java-options "-Xmx${my_mem}G -Djava.io.tmpdir=`pwd`/tmp" SortSam \
      SO=coordinate \
      INPUT=${sam} \
      OUTPUT=${sampleID}_sortsam.bam  \
      TMP_DIR=`pwd`/tmp \
      VALIDATION_STRINGENCY=SILENT \
      CREATE_INDEX=true
    """
}
