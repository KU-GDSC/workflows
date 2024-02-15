// Adapted from nf-core RNA-seq pipeline https://github.com/nf-core/rnaseq/blob/3.14.0/modules/local/rsem_merge_counts/main.nf

process MERGE_RSEM_COUNTS {
  tag "MERGED_COUNTS"

  cpus 1
  memory 5.GB
  time '01:00:00'
  errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.mem} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

  container "quay.io/gdsc/debian-utility:bookworm-slim"

  publishDir "${params.pubdir}", pattern: "rsem.merged.*.tsv", mode:'copy'

  input:
    path ch_genes
    path ch_isoforms

  output:
    path "rsem.merged.gene_counts.tsv", emit: gene_counts
    path "rsem.merged.gene_tpm.tsv", emit: gene_tpm
    path "rsem.merged.isoform_counts.tsv", emit: isoform_counts
    path "rsem.merged.isoform_tpm.tsv", emit: isoform_tpm

  script:
      """
      mkdir -p tmp/genes
      cut -f 1,2 `ls *.genes.results | head -n 1` > gene_ids.tsv
      for FILE in `ls *.genes.results`; do
          SAMPLE=`basename \${FILE} | sed s/\\.genes.results\$//g`
          echo \${SAMPLE} > tmp/genes/\${SAMPLE}.counts.tsv
          cut -f 5 \${FILE} | tail -n +2 >> tmp/genes/\${SAMPLE}.counts.tsv
          echo \${SAMPLE} > tmp/genes/\${SAMPLE}.tpm.tsv
          cut -f 6 \${FILE} | tail -n +2 >> tmp/genes/\${SAMPLE}.tpm.tsv
      done

      mkdir -p tmp/isoforms
      cut -f 1,2 `ls *.isoforms.results | head -n 1` > transcript_ids.tsv
      for FILE in `ls *.isoforms.results`; do
          SAMPLE=`basename \${FILE} | sed s/\\.genes.results\$//g`
          echo \${SAMPLE} > tmp/isoforms/\${SAMPLE}.counts.tsv
          cut -f 5 \${FILE} | tail -n +2 >> tmp/isoforms/\${SAMPLE}.counts.tsv
          echo \${SAMPLE} > tmp/isoforms/\${SAMPLE}.tpm.tsv
          cut -f 6 \${FILE} | tail -n +2 >> tmp/isoforms/\${SAMPLE}.tpm.tsv
      done

      paste gene_ids.tsv tmp/genes/*.counts.tsv > rsem.merged.gene_counts.tsv
      paste gene_ids.tsv tmp/genes/*.tpm.tsv > rsem.merged.gene_tpm.tsv
      paste transcript_ids.tsv tmp/isoforms/*.counts.tsv > rsem.merged.isoform_counts.tsv
      paste transcript_ids.tsv tmp/isoforms/*.tpm.tsv > rsem.merged.isoform_tpm.tsv
      """
  }
