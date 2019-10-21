#!/usr/bin/env nextflow
/*
========================================================================================
                          GHRU AMR Pipeline
========================================================================================
*/

// DSL 2
nextflow.preview.dsl=2

version = '0.1'
include './lib/messages'
include './lib/params_parser'
 // setup params
default_params = default_params()
merged_params = default_params + params
final_params = process_params(merged_params, version)
include './lib/resfinder_workflow' params(final_params)
include './lib/ariba_workflow' params(final_params)


workflow {
  //Setup input Channel from Read path
  Channel
      .fromFilePairs( final_params.reads_path )
      .ifEmpty { error "Cannot find any reads matching: ${final_params.reads_path}" }
      .set { raw_fastqs }

  // Resfinder
  resfinder(raw_fastqs)

  // Ariba
  ariba(raw_fastqs)

}

workflow.onComplete {
  complete_message(final_params, workflow, version)
}

workflow.onError {
  error_message(workflow)
}