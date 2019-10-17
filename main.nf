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

  // Resfinder
  resfinder_outputs = resfinder(raw_fastqs)
  all_resfinder_outputs = resfinder_outputs.collect { it }
  resfinder_summary(all_resfinder_outputs)

  // Ariba
  database_dir = file(final_params.ariba_database_dir)
  ariba_reports = ariba(raw_fastqs, database_dir)
  all_ariba_reports = ariba_reports.collect { it }

  ariba_summary(all_ariba_reports, final_params.ariba_database_dir)
}

workflow.onComplete {
  complete_message(final_params, workflow, version)
}

workflow.onError {
  error_message(workflow)
}