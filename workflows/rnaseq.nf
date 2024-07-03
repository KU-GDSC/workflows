#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// import modules
include {HELP} from "${projectDir}/etc/help/rnaseq"
include {PARAM_LOG} from "${projectDir}/etc/log/rnaseq"
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
    // Initialize or generate RSEM indices

    // If pre-generated indices provided, map to channels
    if (params.rsem_index) {
        rnaseq_indices_dict = file("${params.rsem_index}/rsem_bowtie2.dict")
        rnaseq_indices_refFlat = file("${params.rsem_index}/rsem_bowtie2.refFlat.txt")
        rnaseq_indices_rRNA_intervals = file("${params.rsem_index}/rsem_bowtie2.rRNA_intervals.list")
        rnaseq_indices_rsem = file("${params.rsem_index}/rsem_bowtie2.*").collect { "$it" }
        rnaseq_indices_basename = Channel.value("rsem_bowtie2")

    // Otherwise, if FASTA and GTF provided, generate indices
    } else if (params.fasta && params.gtf) {

        RNASEQ_INDICES(params.fasta, params.gtf)
        rnaseq_indices_dict = RNASEQ_INDICES.out.dict
        rnaseq_indices_refFlat = RNASEQ_INDICES.out.refFlat
        rnaseq_indices_rRNA_intervals = RNASEQ_INDICES.out.rRNA_intervals
        rnaseq_indices_rsem = RNASEQ_INDICES.out.rsem_index
        rnaseq_indices_basename = RNASEQ_INDICES.out.rsem_basename
    // If neither, throw error
    } else {
        error "Must provide either --rsem_index or both --fasta and --gtf to generate the RSEM index"
    }

    if (params.concat_lanes){
        if (params.read_type == 'PE'){
            CONCATENATE_READS_PE(read_ch)
            read_ch = CONCATENATE_READS_PE.out.concat_fastq
        } else if (params.read_type == 'SE'){
            CONCATENATE_READS_SE(read_ch)
            read_ch = CONCATENATE_READS_SE.out.concat_fastq
        }
    }

    GET_READ_LENGTH(read_ch)
    FASTP(read_ch)
    FASTQC(FASTP.out.trimmed_fastq)
    READ_GROUPS(FASTP.out.trimmed_fastq, "picard")

    rsem_input = FASTP.out.trimmed_fastq.join(GET_READ_LENGTH.out.read_length)
    RSEM_CALCULATE_EXPRESSION(rsem_input, rnaseq_indices_rsem, rnaseq_indices_basename)

    // Merge RSEM results across samples
    ch_genes = Channel.empty()
    ch_genes = ch_genes.mix(RSEM_CALCULATE_EXPRESSION.out.rsem_genes.collect{it[1]}.ifEmpty([]))
    ch_isoforms = Channel.empty()
    ch_isoforms = ch_isoforms.mix(RSEM_CALCULATE_EXPRESSION.out.rsem_isoforms.collect{it[1]}.ifEmpty([]))

    MERGE_RSEM_COUNTS(ch_genes, ch_isoforms)

    // Picard Alignment Metrics
    add_replace_groups = READ_GROUPS.out.read_groups.join(RSEM_CALCULATE_EXPRESSION.out.bam)
    PICARD_ADDORREPLACEREADGROUPS(add_replace_groups)
    PICARD_REORDERSAM(PICARD_ADDORREPLACEREADGROUPS.out.bam, rnaseq_indices_dict)
    PICARD_SORTSAM(PICARD_REORDERSAM.out.bam)
    PICARD_COLLECTRNASEQMETRICS(PICARD_SORTSAM.out.bam, rnaseq_indices_refFlat, rnaseq_indices_rRNA_intervals)
    
    // Summary report generation
    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.quality_json.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.quality_stats.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(RSEM_CALCULATE_EXPRESSION.out.rsem_cnt.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(PICARD_COLLECTRNASEQMETRICS.out.picard_metrics.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect()
    )
}
