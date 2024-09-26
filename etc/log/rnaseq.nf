def PARAM_LOG(){

log.info """
RNASEQ PARAMETER LOG

--comment: ${params.comment}

Results Published to: ${params.pubdir}
______________________________________________________
--workflow                   ${params.workflow}
--read_type                  ${params.read_type}
--concat_lanes               ${params.concat_lanes}
--sample_folder              ${params.sample_folder}
--extension                  ${params.extension}
--pattern                    ${params.pattern}
--organize_by                ${params.organize_by}
--pubdir                     ${params.pubdir}
-w                           ${workDir}
--keep_intermediate          ${params.keep_intermediate}
--keep_reference             ${params.keep_reference}
-c                           ${params.config}
--quality_phred              ${params.quality_phred}
--unqualified_perc           ${params.unqualified_perc}
--strandedness               ${params.strandedness}
--seed_length                ${params.seed_length}
--fasta                      ${params.fasta}
--gtf                        ${params.gtf}
--rsem_index                 ${params.rsem_index}
--rsem_aligner               ${params.rsem_aligner}

Project Directory: ${projectDir}

Command line call: 
${workflow.commandLine}
______________________________________________________

"""
}
