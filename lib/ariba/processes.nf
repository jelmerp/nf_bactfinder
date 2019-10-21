 process run_ariba {
   tag {sample_id}
   publishDir "${params.output_dir}/ariba",
    mode: 'copy',
    saveAs: { file -> file + ".report.tsv" }

   input:
   tuple sample_id, file(reads)
   file(database_dir)

   output:
   file("${sample_id}")

   """
   ariba run ${database_dir} ${reads[0]} ${reads[1]} ${sample_id}.ariba
   mv ${sample_id}.ariba/report.tsv ${sample_id}
   """
 }

 process ariba_summary {
  tag {'ariba summary'}
  publishDir "${params.output_dir}/ariba", mode: 'copy'

  input:
  file(report_tsvs)
  file(database_dir)

  output:
  file "ariba_${database_dir}_summary.*"

  script:
  """
  ariba summary ${params.ariba_extra_summary_arguments} ariba_${database_dir}_summary ${report_tsvs}
  """
}