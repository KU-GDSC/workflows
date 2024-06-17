#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// import modules
include {HELP} from "${projectDir}/etc/help/microbial_rnaseq"
include {PARAM_LOG} from "${projectDir}/etc/log/microbial_rnaseq"
include {CONCATENATE_READS_PE} from "${projectDir}/modules/utility_modules/concatenate_reads_pe"
include {CONCATENATE_READS_SE} from "${projectDir}/modules/utility_modules/concatenate_reads_se"
include {GET_LIBRARY_ID} from "${projectDir}/etc/scripts/shared/getLibraryId.nf"
include {GET_READ_LENGTH} from "${projectDir}/modules/utility_modules/get_read_length"
include {RNASEQ_INDICES} from "${projectDir}/subworkflows/indices/rnaseq"
include {FASTP} from "${projectDir}/modules/fastp/fastp"
include {FASTQC} from "${projectDir}/modules/fastqc/fastqc"
include {READ_GROUPS} from "${projectDir}/modules/utility_modules/read_groups"
include {RSEM_CALCULATE_EXPRESSION} from "${projectDir}/modules/rsem/rsem_calculate_expression"
include {MERGE_RSEM_COUNTS} from "${projectDir}/modules/utility_modules/merge_rsem_counts"
include {PICARD_ADDORREPLACEREADGROUPS} from "${projectDir}/modules/picard/picard_addorreplacereadgroups"
include {PICARD_REORDERSAM} from "${projectDir}/modules/picard/picard_reordersam"
include {PICARD_SORTSAM} from "${projectDir}/modules/picard/picard_sortsam"
include {PICARD_COLLECTRNASEQMETRICS} from "${projectDir}/modules/picard/picard_collectrnaseqmetrics"
include {MULTIQC} from "${projectDir}/modules/multiqc/multiqc"

// help if needed
if (params.help){
    HELP()
    exit 0
}

// log parameter info
PARAM_LOG()

if (params.concat_lanes){
  
if (params.read_type == 'PE'){
    read_ch = Channel
            .fromFilePairs("${params.sample_folder}/${params.pattern}${params.extension}",checkExists:true, flat:true )
            .map { file, file1, file2 -> tuple(GET_LIBRARY_ID(file), file1, file2) }
            .groupTuple()
  }
  else if (params.read_type == 'SE'){
    read_ch = Channel.fromFilePairs("${params.sample_folder}/*${params.extension}", checkExists:true, size:1 )
                .map { file, file1 -> tuple(GET_LIBRARY_ID(file), file1) }
                .groupTuple()
                .map{t-> [t[0], t[1].flatten()]}
  }
    // if channel is empty give error message and exit
    read_ch.ifEmpty{ exit 1, "ERROR: No Files Found in Path: ${params.sample_folder} Matching Pattern: ${params.pattern} and file extension: ${params.extension}"}

} else {
  
  if (params.read_type == 'PE'){
    read_ch = Channel.fromFilePairs("${params.sample_folder}/${params.pattern}${params.extension}",checkExists:true )
  }
  else if (params.read_type == 'SE'){
    read_ch = Channel.fromFilePairs("${params.sample_folder}/*${params.extension}",checkExists:true, size:1 )
  }
    // if channel is empty give error message and exit
    read_ch.ifEmpty{ exit 1, "ERROR: No Files Found in Path: ${params.sample_folder} Matching Pattern: ${params.pattern} and file extension: ${params.extension}"}
}

workflow RNASEQ {

    if (params.concat_lanes){
        if (params.read_type == 'PE'){
            CONCATENATE_READS_PE(read_ch)
            read_ch = CONCATENATE_READS_PE.out.concat_fastq
        } else if (params.read_type == 'SE'){
            CONCATENATE_READS_SE(read_ch)
            read_ch = CONCATENATE_READS_SE.out.concat_fastq
        }
    }
    // Get read lenghts from FASTQs
    GET_READ_LENGTH(read_ch)
    ch_read_lengths = GET_READ_LENGTH.out.read_length.collect { it[1].toInteger() - 1 }
    ch_rsem_read_length = ch_read_lengths.flatten().unique()
    FASTP(read_ch)
    FASTQC(FASTP.out.trimmed_fastq)
    READ_GROUPS(FASTP.out.trimmed_fastq, "picard")

    // Generate RSEM indices
    RNASEQ_INDICES(params.fasta, params.gff, ch_rsem_read_length)

    rsem_input = FASTP.out.trimmed_fastq.join(GET_READ_LENGTH.out.read_length)
    RSEM_CALCULATE_EXPRESSION(rsem_input, RNASEQ_INDICES.out.rsem_index, RNASEQ_INDICES.out.rsem_basename)

    // Merge RSEM results across samples
    ch_genes = Channel.empty()
    ch_genes = ch_genes.mix(RSEM_CALCULATE_EXPRESSION.out.rsem_genes.collect{it[1]}.ifEmpty([]))
    ch_isoforms = Channel.empty()
    ch_isoforms = ch_isoforms.mix(RSEM_CALCULATE_EXPRESSION.out.rsem_isoforms.collect{it[1]}.ifEmpty([]))

    MERGE_RSEM_COUNTS(ch_genes, ch_isoforms)

    // Picard Alignment Metrics
    add_replace_groups = READ_GROUPS.out.read_groups.join(RSEM_CALCULATE_EXPRESSION.out.bam)
    PICARD_ADDORREPLACEREADGROUPS(add_replace_groups)
    PICARD_REORDERSAM(PICARD_ADDORREPLACEREADGROUPS.out.bam, RNASEQ_INDICES.out.dict)
    PICARD_SORTSAM(PICARD_REORDERSAM.out.bam)
    PICARD_COLLECTRNASEQMETRICS(PICARD_SORTSAM.out.bam, RNASEQ_INDICES.out.refFlat, RNASEQ_INDICES.out.rRNA_intervals)
    
    // Summary report generation
    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.quality_json.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.quality_stats.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(RSEM_CALCULATE_EXPRESSION.out.rsem_cnt.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(RSEM_CALCULATE_EXPRESSION.out.star_log.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(PICARD_COLLECTRNASEQMETRICS.out.picard_metrics.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect()
    )
}
