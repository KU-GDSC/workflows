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
--keep_reference             ${params.keep_reference}
-c                           ${params.config}

--quality_phred              ${params.quality_phred}
--unqualified_perc           ${params.unqualified_perc}

--fasta                      ${params.fasta}
--filter_dp                  ${params.filter_dp}
--filter_very_low_qual       ${params.filter_very_low_qual}
--filter_low_qual            ${params.filter_low_qual}
--filter_qd                  ${params.filter_qd}
--filter_fs                  ${params.filter_fs}

Project Directory: ${projectDir}

Command line call: 
${workflow.commandLine}
______________________________________________________

"""
}
