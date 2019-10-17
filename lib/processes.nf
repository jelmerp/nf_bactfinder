process run_resfinder {
  tag { sample_id }
  publishDir "${params.output_dir}/resfinder",
  mode:"copy"

  container 'bioinformant/ghru-resfinder4'

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

 process run_ariba {
   tag {sample_id}
   publishDir "${params.output_dir}/ariba",
    mode: 'copy',
    pattern: "${sample_id}.report.tsv"

   container 'bioinformant/ghru-ariba'

   input:
   tuple sample_id, file(reads)
   file(database_dir)

   output:
   tuple sample_id, file("${sample_id}.ariba")
   file "${sample_id}.report.tsv"

   """
   ariba run ${database_dir} ${reads[0]} ${reads[1]} ${sample_id}.ariba
   cp ${sample_id}.ariba/report.tsv ${sample_id}.report.tsv
   """
 }