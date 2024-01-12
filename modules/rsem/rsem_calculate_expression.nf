process RSEM_CALCULATE_EXPRESSION {
  tag "$sampleID"

  cpus 12
  memory 70.GB
  time 24.h
  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.mem} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container "quay.io/jaxcompsci/rsem_bowtie2_star:0.1.0"

  publishDir "${params.pubdir}/${ params.organize_by=='sample' ? sampleID+'/stats' : 'rsem' }", pattern: "*stats", mode:'copy', enabled: params.rsem_aligner == "bowtie2"
  publishDir "${params.pubdir}/${ params.organize_by=='sample' ? sampleID : 'rsem' }", pattern: "*results*", mode:'copy'
  publishDir "${params.pubdir}/${ params.organize_by=='sample' ? sampleID+'/bam' : 'rsem' }", pattern: "*genome.sorted.ba*", mode:'copy'
  publishDir "${params.pubdir}/${ params.organize_by=='sample' ? sampleID+'/bam' : 'rsem' }", pattern: "*transcript.sorted.ba*", mode:'copy'

  input:
    tuple val(sampleID), path(reads), val(read_length)
    path(rsem_index)
    val(rsem_basename)

  output:
    path "*stats"
    path "*results*"
    tuple val(sampleID), path("rsem_aln_*.stats"), emit: rsem_stats
    tuple val(sampleID), path("*.stat/*.cnt"), emit: rsem_cnt
    tuple val(sampleID), path("*genes.results"), emit: rsem_genes
    tuple val(sampleID), path("*isoforms.results"), emit: rsem_isoforms
    tuple val(sampleID), path("*.genome.bam"), emit: bam
    tuple val(sampleID), path("*.transcript.bam"), emit: transcript_bam
    tuple val(sampleID), path("*.genome.sorted.bam"), path("*.genome.sorted.bam.bai"), emit: sorted_genomic_bam
    tuple val(sampleID), path("*.transcript.sorted.bam"), path("*.transcript.sorted.bam.bai"), emit: sorted_transcript_bam
 
  script:

    if (params.strandedness == "reverse_stranded") {
      prob="--forward-prob 0"
    }

    if (params.strandedness == "forward_stranded") {
      prob="--forward-prob 1"
    }

    if (params.strandedness == "non_stranded") {
      prob="--forward-prob 0.5"
    }

    if (params.read_type == "PE"){
      frag=""
      stype="--paired-end"
      trimmedfq="${reads[0]} ${reads[1]}"
    }
    if (params.read_type == "SE"){
      frag="--fragment-length-mean 280 --fragment-length-sd 50"
      stype=""
      trimmedfq="${reads[0]}"
    }
    outbam="--output-genome-bam --sort-bam-by-coordinate"
    seed_length="--seed-length ${params.seed_length}"
    sort_command=''
    index_command=''
    read_length = read_length.toInteger()

    """

    rsem-calculate-expression -p $task.cpus \
        ${prob} \
        ${stype} \
        ${frag} \
        --${params.rsem_aligner} \
        --append-names \
        ${seed_length} \
        ${outbam} \
        ${trimmedfq} \
        rsem/${rsem_basename} \
        ${sampleID} \
        2> rsem_aln_${sampleID}.stats

        ${sort_command}

        ${index_command}
  """
}
