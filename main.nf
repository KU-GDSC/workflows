#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include {MICROBIAL_RNASEQ} from './workflows/microbial_rnaseq'
include {WGS} from './workflows/wgs'
include {RNASEQ} from './workflows/rnaseq'

// conditional to launch appropriate workflow
workflow{
  if (params.workflow == "microbial_rnaseq") {
    MICROBIAL_RNASEQ()
    }

  else if (params.workflow == "wgs") {
    WGS()
  }

  else if (params.workflow == "rnaseq") {
    RNASEQ()
  }

  else {
    exit 1, "ERROR: No valid pipeline called. '--workflow ${params.workflow}' is not a valid workflow name." 
  }
}
