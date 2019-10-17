process resfinder {
  tag { sample_id }
  publishDir "${params.output_dir}/resfinder",
  mode:"copy"

  input:
  tuple sample_id, file(reads)

  output:
  file("${sample_id}")

  script:

  if (params.resfinder_species)
     """
     python3 \$(which run_resfinder.py) -ifq *.fastq* -l 0.9 -t 0.9 --acquired --point -s "${params.resfinder_species}" -db_res ${params.resfinder_db_resfinder} -db_point ${params.resfinder_db_pointfinder} -o ${sample_id}

     """
  else

     """
     python3 \$(which run_resfinder.py) -ifq *.fastq* -l 0.9 -t 0.9 -acq -db_res ${params.resfinder_db_resfinder} -o ${sample_id}
     """
}

 process resfinder_summary {
  tag {'resfinder summary'}
  publishDir "${params.output_dir}/resfinder", mode: 'copy'

  input:
  file(resfinder_output_dirs)

  output:
  tuple file('species_specific_summary.tsv'), file('full_summary.tsv')

  script:
  species = params.resfinder_species.toLowerCase().replaceAll(" ", "_")
  """
  python3 /scripts/parse_resfinder_4_output.py '${resfinder_output_dirs}' . ${species}
  """
}

 process ariba {
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