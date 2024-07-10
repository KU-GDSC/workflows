def PARAM_LOG(){

if (!params.fasta) {
  error "Reference FASTA file must be provided with argument '--fasta'" 
}

log.info """
WGS VARIANTS PARAMETER LOG

--comment: ${params.comment}

Results Published to: ${params.pubdir}
______________________________________________________
--workflow                   ${params.workflow}
--read_type                  ${params.read_type}
--sample_folder              ${params.sample_folder}
--extension                  ${params.extension}
--pattern                    ${params.pattern}
--organize_by                ${params.organize_by}
--pubdir                     ${params.pubdir}
-w                           ${workDir}
--keep_intermediate          ${params.keep_intermediate}
--save_references            ${params.save_references}
-c                           ${params.config}

--quality_phred              ${params.quality_phred}
--unqualified_perc           ${params.unqualified_perc}

--fasta                      ${params.fasta}

Project Directory: ${projectDir}

Command line call: 
${workflow.commandLine}
______________________________________________________

"""
}
