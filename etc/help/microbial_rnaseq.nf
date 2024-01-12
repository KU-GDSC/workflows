def HELP(){
  println '''
Parameter | Default | Description

--pubdir | /<PATH> | The directory that the saved outputs will be stored.
--organize_by | sample | How to organize the output folder structure. Options: sample or analysis
--cacheDir | /panfs/pfs.local/work/sjmac/observer/containers | This is directory that contains cached Singularity containers. Containers are in publicly available repositorys and will be downloaded if not present in this directory at runtime.
-w | /<PATH> | The directory that Nextflow processes use to stage files and intermediate output. This directory can become quite large. This should be a location on scratch space or other directory with ample storage.

--sample_folder | /<PATH> | The path to the folder that contains all the samples to be run by the pipeline. The files in this path can also be symbolic links. 
--extension | .fastq.gz | The expected extension for the input read files.
--pattern | '*_R{1,2}*' | The expected R1 / R2 matching pattern. The default value will match reads with names like this READ_NAME_R1_MoreText.fastq.gz or READ_NAME_R1.fastq.gz
--read_type | PE | Options: PE and SE. Default: PE. Type of reads: paired end (PE) or single end (SE).

--quality_phred | 15 | fastp quality score threshold
--unqualified_perc | 45 | fastp threshold for percent of unqualified bases to pass reads

--strandedness     | null | Library strandedness override. Supported options are "reverse_stranded" or "forward_stranded" or "non_stranded". This override parameter is only used when the tool `check_strandedness` fails to classify the strandedness of a sample. If the tool provides a strand direction, that determination is used." 

--seed_length | 25 | Seed length used by the read aligner. Providing the correct value is important for RSEM. If RSEM runs Bowtie, it uses this value for Bowtie's seed length parameter.
'''
}
