def HELP(){
  println '''
Parameter | Default | Description

--fasta | null | The path to the reference genome FASTA. Required with a GFF for mapping unless pre-generated indices are provided with --rsem_index.

--gff | null | The path to the reference genome annotation in GFF3 format. Required with a FASTA for mapping until pre-generated indices are provided with --rsem_index.

--rsem_index | null | The path to a directory containing pre-generated RSEM indices prepared by this workflow. An error will occur if any files are missing.

--rsem_aligner | bowtie2 | The program used by RSEM to align reads prior to count quantification. At present only bowtie2 is supported by this workflow.

--sample_folder | /<PATH> | The path to the folder that contains all the samples to be run by the pipeline. The files in this path can also be symbolic links. 

--extension | .fastq.gz | The expected extension for the input read files.

--pattern | '*_R{1,2}*' | The expected R1 / R2 matching pattern. The default value will match reads with names like this READ_NAME_R1_MoreText.fastq.gz or READ_NAME_R1.fastq.gz

--read_type | PE | Options: PE and SE. Default: PE. Type of reads: paired end (PE) or single end (SE).

--concat_lanes | false | Options: false and true. Default: false. If this boolean is specified, FASTQ files will be concatenated by sample. This option is used in cases where samples are divided across individual sequencing lanes.

--strandedness     | null | Library strandedness override. Supported options are "reverse_stranded" or "forward_stranded" or "non_stranded". This override parameter is only used when the tool `check_strandedness` fails to classify the strandedness of a sample. If the tool provides a strand direction, that determination is used." 

--organize_by | sample | How to organize the output folder structure. Options: sample or analysis

--pubdir | /<PATH> | The directory that the saved outputs will be stored.

-w | /<PATH> | The directory that Nextflow processes use to stage files and intermediate output. This directory can become quite large. This should be a location on scratch space or other directory with ample storage.

--quality_phred | 15 | fastp quality score threshold

--unqualified_perc | 45 | fastp threshold for percent of unqualified bases to pass reads

--seed_length | 25 | Seed length used by the read aligner. Providing the correct value is important for RSEM. If RSEM runs Bowtie, it uses this value for Bowtie's seed length parameter.

--keep_intermediate | false | If true workflow will output intermediate alignment files (unsorted BAMs, etc).

--keep_reference | false | If true workflow will save a copy of the RSEM indices to the output directory.
'''
}
