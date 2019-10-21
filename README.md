## Workflow to process samples through AMR pipelines
### Usage
```
==============================================
Resfinder Pipeline version 0.1
==============================================


Mandatory arguments:
--input_dir                 Path to input dir. This must be used in conjunction with fastq_pattern
--fastq_pattern             The regular expression that will match fastq files e.g '*_{1,2}.fastq.gz'
--output_dir                Path to output dir

Optional ariba arguments:
--ariba_database_dir   Path to a local dir containing ariba resitance database (default is /resfinder_database.17.10.2019)
--ariba_extra_summary_arguments Supply the non-default options for the ariba summary command.
    Wrap these in quotes e.g '--preset minimal --min_id 95' (default is '--preset cluster_all')

Optional resfinder arguments:
--resfinder_min_cov                     Minimum breadth of coverage (default 0.9)
--resfinder_identity_threshold          Minimum identity for the match to the AMR determinant (default 0.9)
--resfinder_species                     Name of the species
--resfinder_point_mutation              Find point mutation-based resistance
--resfinder_db_resfinder                Path to the resfinder database (default is /resfinder/db_resfinder)
--resfinder_db_pointfinder              Path to the pointfinder database (default is /resfinder/db_pointfinder)
```

This pipeline will run two AMR prediction tools in parallel
### ARIBA
Samples will be processed using a resfinder database of acquired AMR genes and a summary produced in a sub-directory named ariba within the output directory set using `--output_dir`

### Resfinder4
Samples will be processed using the resfinder4 software and the predicted antimicrobial sensitivities found in the files `full_summary.tsv` and `species_specific_summary.tsv` in a sub-directory named resfinder within the output directory set using `--output_dir`

---

### Running test data
The test dataset can be run using this command
```
export NXF_VER=19.09.0-edge && nextflow run main.nf --input_dir $PWD/test_input --fastq_pattern '*{R,_}{1,2}.fastq.gz' --output_dir $PWD/test_output --resfinder_species 'Staphylococcus aureus'
```
