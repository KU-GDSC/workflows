#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// import modules

include {RSEM_PREPAREREFERENCE} from "${projectDir}/modules/rsem/rsem_preparereference"
include {PICARD_CREATESEQUENCEDICTIONARY} from "${projectDir}/modules/picard/picard_createsequencedictionary"
include {UCSC_GTFTOGENEPRED} from "${projectDir}/modules/ucsc/ucsc_gtftogenepred"
include {GENERATE_RRNA_INTERVALS} from "${projectDir}/modules/utility_modules/generate_rrna_intervals"
include {KALLISTO_INDEX} from "${projectDir}/modules/kallisto/kallisto_index"

workflow RNASEQ_INDICES {
    take:
        fasta           //      file: /path/to/genome.fasta
        gff             //      file: /path/to/genome.gff
        read_length     //      value: GET_READ_LENGTH.out.read_length
    main:
        ch_fasta = Channel.value(file(fasta))
        ch_gff = Channel.value(file(gff))

        RSEM_PREPAREREFERENCE(ch_fasta, ch_gff, read_length)
        rsem_index = RSEM_PREPAREREFERENCE.out.index
        rsem_basename= RSEM_PREPAREREFERENCE.out.basename
        rsem_gtf = RSEM_PREPAREREFERENCE.out.gtf
        rsem_transcripts = RSEM_PREPAREREFERENCE.out.transcripts

        UCSC_GTFTOGENEPRED(RSEM_PREPAREREFERENCE.out.gtf)
        refFlat = UCSC_GTFTOGENEPRED.out.refFlat

        PICARD_CREATESEQUENCEDICTIONARY(ch_fasta)
        dict = PICARD_CREATESEQUENCEDICTIONARY.out.dict

        GENERATE_RRNA_INTERVALS(ch_gff, PICARD_CREATESEQUENCEDICTIONARY.out.dict)
        rRNA_intervals = GENERATE_RRNA_INTERVALS.out.rRNA_intervals

        KALLISTO_INDEX(RSEM_PREPAREREFERENCE.out.transcripts)
        kallisto_index = KALLISTO_INDEX.out.kallisto_index

    emit:
        rsem_index           //          channel: path(rsem/index)
        rsem_gtf
        rsem_transcripts
        refFlat              //          channel: path(refFlat.txt)
        rRNA_intervals       //          channel: path(rRNA_intervals.list)
        rsem_basename
        dict
        kallisto_index
       
}
