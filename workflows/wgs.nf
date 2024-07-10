#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// import modules
include {HELP} from "${projectDir}/etc/help/wgs.nf"
include {PARAM_LOG} from "${projectDir}/etc/log/wgs.nf"
include {WGS_INDICES} from "${projectDir}/subworkflows/indices/wgs"
include {FASTP} from "${projectDir}/modules/fastp/fastp"
include {FASTQC} from "${projectDir}/modules/fastqc/fastqc"
include {READ_GROUPS} from "${projectDir}/modules/utility_modules/read_groups"
include {BWA_MEM} from "${projectDir}/modules/bwa/bwa_mem"
include {PICARD_SORTSAM} from "${projectDir}/modules/picard/picard_sortsam"
include {PICARD_MARKDUPLICATES} from "${projectDir}/modules/picard/picard_markduplicates"
include {PICARD_COLLECTALIGNMENTSUMMARYMETRICS} from "${projectDir}/modules/picard/picard_collectalignmentsummarymetrics"
include {PICARD_COLLECTWGSMETRICS} from "${projectDir}/modules/picard/picard_collectwgsmetrics"
include {BUNDLE_BAMS} from "${projectDir}/modules/utility_modules/bundle_bams"
include {BCFTOOLS_MPILEUP_INTERVAL} from "${projectDir}/modules/bcftools/bcftools_mpileup_interval"
include {BCFTOOLS_CONCAT} from "${projectDir}/modules/bcftools/bcftools_concat"
include {GATK_VARIANTSTOTABLE} from "${projectDir}/modules/gatk/gatk_variantstotable"
include {MULTIQC} from "${projectDir}/modules/multiqc/multiqc"

// help if needed

if (params.help){
    HELP()
    exit 0
}

// log params
PARAM_LOG()

// prepare reads channel

if (params.read_type == 'PE'){
ch_reads = Channel.fromFilePairs("${params.sample_folder}/${params.pattern}${params.extension}",checkExists:true )
}
else if (params.read_type == 'SE'){
ch_reads = Channel.fromFilePairs("${params.sample_folder}/*${params.extension}",checkExists:true, size:1 )
}
// if channel is empty give error message and exit
ch_reads.ifEmpty{ exit 1, "ERROR: No Files Found in Path: ${params.sample_folder} Matching Pattern: ${params.pattern} and file extension: ${params.extension}"}


// main workflow
workflow WGS {

  // STEP 0: Prepare references as necessary

  WGS_INDICES(params.fasta)
  
  FASTP(ch_reads)

  FASTQC(FASTP.out.trimmed_fastq)

  READ_GROUPS(FASTP.out.trimmed_fastq, 'GATK')

  bwa_input = FASTP.out.trimmed_fastq.join(READ_GROUPS.out.read_groups)
                                     .combine(RAD_VARIANTS_INDICES.out.bwa_index)
  
  BWA_MEM(bwa_input)

  PICARD_SORTSAM(BWA_MEM.out.sam)

  PICARD_MARKDUPLICATES(PICARD_SORTSAM.out.bam)

  PICARD_COLLECTALIGNMENTSUMMARYMETRICS(PICARD_MARKDUPLICATES.out.dedup_bam)

  PICARD_COLLECTWGSMETRICS(PICARD_MARKDUPLICATES.out.dedup_bam)
  
  ch_bams = Channel.empty()
  ch_bams = ch_bams.mix(PICARD_MARKDUPLICATES.out.dedup_bam.collect{it[1]}.ifEmpty([]))
  ch_bais = Channel.empty()
  ch_bais = ch_bais.mix(PICARD_MARKDUPLICATES.out.dedup_bai.collect{it[1]}.ifEmpty([]))

  BUNDLE_BAMS(ch_bams, ch_bais)

  to_genotype = Channel.empty()
  to_genotype = BUNDLE_BAMS.out.bam_dir
                    .combine(WGS_INDICES.out.contig_list)
                    .combine(WGS_INDICES.out.fasta_fai)

  BCFTOOLS_MPILEUP_INTERVAL(to_genotype)

  BCFTOOLS_CONCAT(BCFTOOLS_MPILEUP_INTERVAL.out.vcf.collect())

  GATK_VARIANTSTOTABLE(BCFTOOLS_CONCAT.out.vcf)

  ch_multiqc_files = Channel.empty()
  ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.quality_json.collect{it[1]}.ifEmpty([]))
  ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.quality_stats.collect{it[1]}.ifEmpty([]))
  ch_multiqc_files = ch_multiqc_files.mix(PICARD_COLLECTALIGNMENTSUMMARYMETRICS.out.txt.collect{it[1]}.ifEmpty([]))
  ch_multiqc_files = ch_multiqc_files.mix(PICARD_COLLECTWGSMETRICS.out.txt.collect{it[1]}.ifEmpty([]))
  ch_multiqc_files = ch_multiqc_files.mix(PICARD_MARKDUPLICATES.out.dedup_metrics.collect{it[1]}.ifEmpty([]))

  MULTIQC (
      ch_multiqc_files.collect()
  )

}
