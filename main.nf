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
include './lib/processes' params(final_params)

workflow {
  //Setup input Channel from Read path
  Channel
      .fromFilePairs( final_params.reads_path )
      .ifEmpty { error "Cannot find any reads matching: ${final_params.reads_path}" }
      .set { raw_fastqs }

  run_resfinder(raw_fastqs)
  if (final_params.ariba_database_dir){
    database_dir = file(final_params.ariba_database_dir)
  }
  run_ariba(raw_fastqs, database_dir)
}

workflow.onComplete {
  complete_message(final_params, workflow, version)
}

workflow.onError {
  error_message(workflow)
}