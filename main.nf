#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// import workflow of interest
if (params.workflow == "microbial_rnaseq"){
  include {MICROBIAL_RNASEQ} from './workflows/microbial_rnaseq'
}

else if (params.workflow == "wgs"){
  include {WGS} from './workflows/wgs'

}

else if (params.workflow == "rnaseq") {
  include {RNASEQ} from './workflows/rnaseq'
}

else {
  // if workflow name is not supported: 
  exit 1, "ERROR: No valid pipeline called. '--workflow ${params.workflow}' is not a valid workflow name."
}

// conditional to launch appropriate workflow
workflow{
  if (params.workflow == "microbial_rnaseq") {
    MICROBIAL_RNASEQ()
    }

  else if (params.workflow == "wgs") {
    WGS()
  }

  if (params.workflow == "rnaseq") {
    RNASEQ()

  }
}
