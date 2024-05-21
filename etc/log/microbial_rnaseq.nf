def PARAM_LOG(){

log.info """
MICROBIAL RNASEQ PARAMETER LOG

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
-c                           ${params.config}
--quality_phred              ${params.quality_phred}
--unqualified_perc           ${params.unqualified_perc}
--strandedness               ${params.strandedness}
--seed_length                ${params.seed_length}

Project Directory: ${projectDir}

Command line call: 
${workflow.commandLine}
______________________________________________________

"""
}
