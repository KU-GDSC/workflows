process BWA_MEM {
  tag "$sampleID"

  cpus 8
  memory 60.GB
  time 8.hour
  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container 'quay.io/biocontainers/bwa:0.7.17--hed695b0_6'

  input:
      tuple val(sampleID), path(fq_reads), path(read_group), path("index.amb"), path("index.ann"), path("index.bwt"), path("index.pac"), path("index.sa")
  output:
      tuple val(sampleID), file("${sampleID}.sam"), emit: sam
  script:
      if (params.read_type == "SE")  {
          inputfq="${fq_reads[0]}"
      }
      else {
          inputfq="${fq_reads[0]} ${fq_reads[1]}"
      }
      
      score = params.bwa_min_score ? "-T ${params.bwa_min_score}" : ''
      """
      bwa mem -R \$(cat $read_group) -t ${task.cpus} ${params.mismatch_penalty} ${score} -M index ${fq_reads} > ${sampleID}.sam
      """
}
