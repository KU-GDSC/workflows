#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// import modules

include {SAMTOOLS_FAIDX} from "${projectDir}/modules/samtools/samtools_faidx"
include {BWA_INDEX} from "${projectDir}/modules/bwa/bwa_index"
include {PICARD_CREATESEQUENCEDICTIONARY} from "${projectDir}/modules/picard/picard_createsequencedictionary"
include {GET_CONTIG_NAMES} from "${projectDir}/modules/utility_modules/get_contig_names"

workflow WGS_INDICES {
    take:
        fasta           //      file: /path/to/genome.fasta

    main:
        ch_fasta = Channel.value(file(fasta))

        SAMTOOLS_FAIDX(ch_fasta)
        fasta_fai = SAMTOOLS_FAIDX.out.fasta_fai

        BWA_INDEX(ch_fasta)
        bwa_index = BWA_INDEX.out.bwa_index

        PICARD_CREATESEQUENCEDICTIONARY(ch_fasta)
        dict = PICARD_CREATESEQUENCEDICTIONARY.out.dict

        GET_CONTIG_NAMES(ch_fasta)
        contig_file = GET_CONTIG_NAMES.out.contig_names

        contig_list = GET_CONTIG_NAMES.out.contig_names
                          .splitText()
                          .map{it -> it.trim()}

    emit:
        fasta_fai
        bwa_index
        dict
        contig_file
        contig_list
}
