process RSEM_PREPAREREFERENCE {
  cpus 12
  memory 64.GB
  time 12.h
  
  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container "quay.io/jaxcompsci/rsem_bowtie2_star:0.1.0"

  publishDir "${params.pubdir}/index", pattern: "rsem_${params.rsem_aligner}", mode:'copy'

  input:
    path(fasta), stageAs: "rsem_${params.rsem_aligner}/*"
    path(gff), stageAs: "rsem_${params.rsem_aligner}/*"
    val(read_length)
    val(read_unique)

  output:
    path("rsem_${params.rsem_aligner}"), emit: index
    path("rsem_${params.rsem_aligner}/${fasta.baseName}.gtf"), emit: gtf
    path("rsem_${params.rsem_aligner}/${fasta.baseName}.transcripts.fa"), emit: transcripts
    val("${fasta.baseName}"), emit: basename

  script:

    if (params.workflow == "microbial_rnaseq") {
        """
        rsem-prepare-reference \
            -p $task.cpus \
            --gff3 ${gff} \
            --gff3-genes-as-transcripts \
            --bowtie2 \
            ${fasta} \
            rsem_${params.rsem_aligner}/${fasta.baseName}

        rm ${fasta}
        rm ${gff}
        """
        }

    else if (params.workflow == "rnaseq" & params.rsem_aligner == "bowtie2") {
        """
        rsem-prepare-reference \
            -p $task.cpus \
            --gtf ${gff} \
            --bowtie2 \
            ${fasta} \
            rsem_${params.rsem_aligner}/${fasta.baseName}

        if [[ "${gff}" != "rsem_${params.rsem_aligner}/${fasta.baseName}.gtf" ]]
        then
            mv ${gff} rsem_${params.rsem_aligner}/${fasta.baseName}.gtf
        fi
        rm ${fasta}
        """
    }

    else if (params.workflow == "rnaseq" & params.rsem_aligner == "star" & read_unique == 1) {
       
        """
        rsem-prepare-reference \
            -p $task.cpus \
            --gtf ${gff} \
            --star \
            --star-sjdboverhang ${read_length} \
            ${fasta} \
            rsem_${params.rsem_aligner}/${fasta.baseName}
 
        if [[ "${gff}" != "rsem_${params.rsem_aligner}/${fasta.baseName}.gtf" ]]
        then
            mv ${gff} rsem_${params.rsem_aligner}/${fasta.baseName}.gtf
        fi
        rm ${fasta}          
        """
    }
    else if (params.workflow == "rnaseq" & params.rsem_aligner == "star" & read_unique != 1)  {
        error("Multiple read lengths detected in FASTQ data and STAR indicies requested. STAR uses read length for index generation, so either separate data into different read length groups or rerun the workflow with 'rsem_aligner bowtie2'")
    }
    else {
        error("The workflow " $params.workflow " or the aligner " $params.rsem_aligner " is not currently supported")
        }
}
