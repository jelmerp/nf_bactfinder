## Workflow to process samples through AMR pipelines

This workflow runs `ResFinder`, `VirulenceFinder` and `Plasmidfinder`
on bacterial genome assemblies.

Modified after an [original version](https://gitlab.com/cgps/ghru/pipelines/amr_prediction.git)
by Anthony Underwood that ran `ARIBA` and `ResFinder`.

### Usage

```
==============================================
Bactfinder Pipeline
==============================================

REQUIRED OPTIONS:
  --indir               Path to input dir with genome assembly FASTA file(s)
  --species             Quoted name of the species, e.g. "Salmonella enterica"

OTHER OPTIONS:
  --outdir              Path to output dir                              [default: 'results/ghru_finder']
  --file_pattern        The globbing pattern to match FASTA files in the indir [default: '*fasta']
  --no_point_mut        Skip ResFinder point-mutation resistance        [default: include]
  --res_cov             Minimum coverage of match for Resfinder         [default: 0.9]
  --res_id              Minimum identity of match for Resfinder         [default: 0.9]
  --virulence_cov       Minimum coverage of match for Virulencefinder   [default: 0.9]
  --virulence_id        Minimum identity of match for Virulencefinder   [default: 0.9]
  --plasmid_cov         Minimum coverage of match for Plasmidfinder     [default: 0.9]
  --plasmid_id          Minimum identity of match for Plasmidfinder     [default: 0.9]
```
