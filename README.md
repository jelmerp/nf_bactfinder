## Workflow to for AMR, Virulence and plasmid detection in bacterial genome assemblies

This workflow runs [`ResFinder 4.1.11`](https://bitbucket.org/genomicepidemiology/resfinder),
[`VirulenceFinder 2.0.4`](https://bitbucket.org/genomicepidemiology/virulencefinder) and
[`Plasmidfinder 2.1.6`](https://bitbucket.org/genomicepidemiology/plasmidfinder)
on bacterial genome assemblies.

Modified after an [original version](https://gitlab.com/cgps/ghru/pipelines/amr_prediction.git)
by Anthony Underwood that ran `ARIBA` and `ResFinder`.

### Workflow usage

- For usage at the Ohio Supercomputer Center (OSC),
  use the wrapper shell script (see section below) instead of calling the workflow
  directly.

- To run the workflow outside of the Ohio Supercomputer Center,
  change the Conda environments in `nextflow.config`.
  You'll also have to install Nextflow, in that case.

```
==============================================
                Bactfinder Pipeline
==============================================

REQUIRED OPTIONS:
  --indir               Path to input dir with genome assembly FASTA file(s)
  --species             Quoted name of the species, e.g. "Salmonella enterica"

OTHER OPTIONS:
  --outdir              Path to output dir                              [default: 'results/nf_bactfinder']
  --file_pattern        Glob to match FASTA files in the indir          [default: '*fasta']
  --no_point_mut        Skip ResFinder point-mutation resistance        [default: include]
  --res_cov             Minimum coverage of match for ResFinder         [default: 0.9]
  --res_id              Minimum identity of match for ResFinder         [default: 0.9]
  --virulence_cov       Minimum coverage of match for VirulenceFinder   [default: 0.6]
  --virulence_id        Minimum identity of match for VirulenceFinder   [default: 0.9]
  --plasmid_cov         Minimum coverage of match for PlasmidFinder     [default: 0.6]
  --plasmid_id          Minimum identity of match for PlasmidFinder     [default: 0.9]
```

### Wrapper script usage

If you're not part of OSC project `PAS0471`,
specify your project (account) in the `sbatch` call:
`sbatch -A PROJECT_NR nf_bactfinder.sh`

```
USAGE:
  sbatch nf_bactfinder.sh -i <indir> --species <species-name> [...]

REQUIRED OPTIONS:
  -i/--indir      <dir>   Input directory with assembly nucleotide FASTA files
  --species       <str>   Quoted string with focal species name, e.g.: --species 'Enterobacter cloacae'

OTHER KEY OPTIONS:
  -o/--outdir     <dir>   Output directory for workflow results       [default: 'results/nf_bactfinder']
  --file_pattern  <str>   Single-quoted FASTQ file pattern (glob)     [default: '*fasta']
  --more_args     <str>   Additional arguments to pass to 'nextflow run'
                            - Use any additional option of Nextflow or of the workflow itself
                            - Example (quote the entire string!): --more_args "--res_cov 0.8"

NEXTFLOW-RELATED OPTIONS:
  -no-resume              Don't attempt to resume workflow run        [default: resume workflow where it left off]
  -profile        <str>   Profile to use from one of the config files [default: 'conda']
  -work-dir       <dir>   Scratch (work) dir for the workflow         [default: '/fs/scratch/PAS0471/$USER/nf_bactfinder']
  -c/-config      <file   Additional config file                      [default: none]
  --container_dir <dir>   Singularity container dir                   [default: '/fs/project/PAS0471/containers']

UTILITY OPTIONS:
  -h                      Print this help message and exit
  --help                  Print the workflow's help message and exit

EXAMPLE COMMANDS:
  sbatch nf_bactfinder.sh -i results/assemblies --species 'Enterobacter cloacae'
  sbatch nf_bactfinder.sh -i results/assemblies --species 'Salmonella enterica' --file_pattern '*fna'
```
