process CHECK_STRANDEDNESS {
    tag "$sampleID"

    cpus 1
    memory 10.GB
    time '1:00:00'

    errorStrategy {(task.exitStatus == 140) ? {log.info "\n\nError code: ${task.exitStatus} for task: ${task.name}. Likely caused by the task wall clock: ${task.time} or memory: ${task.memory} being exceeded.\nAttempting orderly shutdown.\nSee .command.log in: ${task.workDir} for more info.\n\n"; return 'finish'}.call() : 'finish'}

    container 'quay.io/jaxcompsci/how-are-we-stranded-here:v1.0.1-e6ce74d'

    publishDir "${params.pubdir}/${ params.organize_by=='sample' ? sampleID + '/stats' : 'python' }", pattern:"*_strandedness.txt", mode:'copy'

    input:
        tuple val(sampleID), path(reads)
        path(rsem_gtf)
        path(kallisto_index)

    output:
        tuple val(sampleID), env(STRAND), emit: strand_setting
        tuple val(sampleID), path('*_strandedness.txt'), emit: strandedness_report

    script:
        paired = params.read_type == 'PE' ? "-r2 ${reads[1]}" : ''

        if (params.workflow == "rnaseq")
        """
        check_strandedness -g ${rsem_gtf} -k ${kallisto_index} -r1 ${reads[0]} ${paired} > ${sampleID}_strandedness.txt 2>&1


        if grep -q "Data is likely" ${sampleID}_strandedness.txt; then
            
            data_type=`grep "Data is likely" ${sampleID}_strandedness.txt`
            
            if  [[ \$data_type == *RF* ]] ; then
                STRAND='reverse_stranded'
            elif [[ \$data_type == *FR* ]] ; then
                STRAND='forward_stranded'
            elif [[ \$data_type == *unstranded* ]] ; then
                STRAND='non_stranded'
            else
                echo "RNA Seq data does not fall into a likely stranded (max percent explained > 0.9) or unstranded layout (max percent explained < 0.6). Please check your data for low quality and contaminating reads before proceeding."; exit 42;
            fi
        
        else
        
            if [[ ${params.strandedness} == "reverse_stranded" || ${params.strandedness} == "forward_stranded" || ${params.strandedness} == "non_stranded" ]] ; then
                STRAND='${params.strandedness}'
            else
                echo "RNA Seq data does not fall into a likely stranded (max percent explained > 0.9) or unstranded layout (max percent explained < 0.6), and the parameter to override this: '--strandedness' is not set. Please check your data for low quality and contaminating reads"; exit 42;
            fi
        
        fi
        """
        else if (params.workflow == "microbial_rnaseq")
        """
        if [[ ${params.strandedness} == "reverse_stranded" || ${params.strandedness} == "forward_stranded" || ${params.strandedness} == "non_stranded" ]] ; then
            STRAND='${params.strandedness}'
            printf "Automatic strand determination not implemented for microbial data, specified ${params.strandedness} at runtime" > ${sampleID}_strandedness.txt
        else
            echo "Automatic strand determination is not implemented for microbial data. You must specify strandedness with the parameter '--strandedness' and one of the values 'forward_stranded', 'reverse_stranded', or 'non_stranded'; exit 42;
        fi
        """
}