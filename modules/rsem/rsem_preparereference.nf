process RSEM_PREPAREREFERENCE {
  cpus 12
  memory 128.GB
  time 12.h
  
  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container "quay.io/jaxcompsci/rsem_bowtie2_star:0.1.0"

  publishDir "${params.pubdir}/index", pattern: "rsem", mode:'copy'

  input:
    path(fasta), stageAs: "rsem/*"
    path(gff), stageAs: "rsem/*"
    val(read_length)

  output:
    path("rsem"), emit: index
    path("rsem/${fasta.baseName}.gtf"), emit: gtf
    val("${fasta.baseName}"), emit: basename

  script:

    if (params.workflow == "microbial_rnaseq") {
        """
        rsem-prepare-reference \
            --gff3 ${gff} \
            --gff3-genes-as-transcripts \
            --bowtie2 \
            ${fasta} \
            rsem/${fasta.baseName}

        rm ${fasta}
        rm ${gff}
        """
        }

    else if (params.workflow == "rnaseq" & params.rsem_aligner == "bowtie2") {
        """
        rsem-prepare-reference \
            --gff3 ${gff} \
            --bowtie2 \
            ${fasta} \
            rsem/${fasta.baseName}

        rm ${fasta}
        rm ${gff}
        """
    }

    else if (params.workflow == "rnaseq" & params.rsem_aligner == "star") {
       
        """
        rsem-prepare-reference \
            --gff3 ${gff} \
            --star \
            --star-sjdboverhang ${read_length} \
            ${fasta} \
            rsem/${fasta.baseName}
        """
    }
    else {
        error("The workflow " $params.workflow " or the aligner " $params.rsem_aligner " is not currently supported")
        }
}
