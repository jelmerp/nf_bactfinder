process run_resfinder {
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