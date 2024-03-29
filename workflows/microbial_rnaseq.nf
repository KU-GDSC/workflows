#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// import modules
include {HELP} from "${projectDir}/etc/help/microbial_rnaseq"
include {PARAM_LOG} from "${projectDir}/etc/log/microbial_rnaseq"
include {GET_LIBRARY_ID} from "${projectDir}/etc/scripts/shared/getLibraryId.nf"
include {GET_READ_LENGTH} from "${projectDir}/modules/utility_modules/get_read_length"
include {RNASEQ_INDICES} from "${projectDir}/subworkflows/indices/microbial_rnaseq"
include {FASTP} from "${projectDir}/modules/fastp/fastp"
include {FASTQC} from "${projectDir}/modules/fastqc/fastqc"
include {READ_GROUPS} from "${projectDir}/modules/utility_modules/read_groups"
include {RSEM_CALCULATE_EXPRESSION} from "${projectDir}/modules/rsem/rsem_calculate_expression"
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

workflow MICROBIAL_RNASEQ {

    // Generate RSEM indices
    RNASEQ_INDICES(params.fasta, params.gff)
    
    // Read preprocessing and QC
    // prepare reads channel
    if (params.read_type == 'PE'){
        read_ch = Channel.fromFilePairs("${params.sample_folder}/${params.pattern}${params.extension}",checkExists:true )
        }
    else if (params.read_type == 'SE'){
        read_ch = Channel.fromFilePairs("${params.sample_folder}/*${params.extension}",checkExists:true, size:1 )
        }

    // if channel is empty give error message and exit
    read_ch.ifEmpty{ exit 1, "ERROR: No Files Found in Path: ${params.sample_folder} Matching Pattern: ${params.pattern} and file extension: ${params.extension}"}


    GET_READ_LENGTH(read_ch)
    FASTP(read_ch)
    FASTQC(FASTP.out.trimmed_fastq)
    READ_GROUPS(FASTP.out.trimmed_fastq, "picard")

    rsem_input = FASTP.out.trimmed_fastq.join(GET_READ_LENGTH.out.read_length)
    RSEM_CALCULATE_EXPRESSION(rsem_input, RNASEQ_INDICES.out.rsem_index, RNASEQ_INDICES.out.rsem_basename)

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
    ch_multiqc_files = ch_multiqc_files.mix(PICARD_COLLECTRNASEQMETRICS.out.picard_metrics.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect()
    )
}
