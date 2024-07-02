process RSEM_PREPAREREFERENCE {
  cpus 12
  memory 64.GB
  time 5.h
  
  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container "quay.io/jaxcompsci/rsem_bowtie2_star:0.1.0"

  publishDir "${params.pubdir}/index", pattern: "rsem", mode:'copy'

  input:
    path(fasta), stageAs: "rsem/*"
    path(gff), stageAs: "rsem/*"

  output:
    path("rsem"), emit: index
    path("rsem/${fasta.baseName}.gtf"), emit: gtf
    val("${fasta.baseName}"), emit: basename

  script:

    if (params.workflow == "microbial_rnaseq") {
        """
        rsem-prepare-reference \
            -p $task.cpus
            --gff3 ${gff} \
            --gff3-genes-as-transcripts \
            --bowtie2 \
            ${fasta} \
            rsem/${fasta.baseName}

        rm ${fasta}
        rm ${gff}
        """
        }

    else if (params.workflow == "rnaseq") {
        """
        rsem-prepare-reference \
            -p $task.cpus \
            --gtf ${gff} \
            --bowtie2 \
            ${fasta} \
            rsem/${fasta.baseName}

        cp ${gff} rsem/${fasta.baseName}.gtf
        rm ${fasta}
        rm ${gff}
        """
    }
    else {
        error("The workflow " $params.workflow " is not currently supported")
        }
}
