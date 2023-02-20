#!/usr/bin/env nextflow

// Pipeline version
version = '0.2'
//TODO - Switch to containers

//==============================================================================
//                          Help and version info
//==============================================================================
def versionMessage() {
    log.info"""
    ============================================================================
                        BACTFINDER WORKFLOW - version ${version}
    ============================================================================
    """.stripIndent()
}

def help_message() {
    println(
        """
        REQUIRED OPTIONS:
          --indir               Path to input dir with genome assembly FASTA file(s)
          --species             Quoted name of the species, e.g. "Salmonella enterica"
        
        OTHER OPTIONS:
          --outdir              Path to output dir                              [default: 'results/ghru_finder']
          --file_pattern        Glob to match FASTA files in the indir          [default: '*fasta']
          --no_point_mut        Skip ResFinder point-mutation resistance        [default: include]
          --res_cov             Minimum coverage of match for ResFinder         [default: 0.9]
          --res_id              Minimum identity of match  for ResFinder        [default: 0.9]
          --virulence_cov       Minimum coverage of match for VirulenceFinder   [default: 0.6]
          --virulence_id        Minimum identity of match  for VirulenceFinder  [default: 0.9]
          --plasmid_cov         Minimum coverage of match for PlasmidFinder     [default: 0.6]
          --plasmid_id          Minimum identity of match  for PlasmidFinder    [default: 0.9]
        """.stripIndent()
    )
}

//==============================================================================
//                      Setup inputs and channels
//==============================================================================
// Set up params
infiles = params.indir + '/' + params.file_pattern

// Run info
log.info ""
log.info "======================================================================"
log.info "               RES/PLASMID/VIRULENCE-FINDER WORKFLOW"
log.info "======================================================================"
params.each { k, v -> if (v) { println "${k}: ${v}" } }
log.info "======================================================================"
log.info ""


//==============================================================================
//                            Workflow
//==============================================================================
workflow {
    
    // Get the input assembly files
    infile_ch = Channel
        .fromPath( infiles )
        .ifEmpty { error "Cannot find input files ${infiles}" }
        .map { file -> tuple(file.baseName, file) }

    println "Number of input files:"
    infile_ch.count().view()

    // ResFinder
    res_db_ch = RESFINDER_DB()
    point_db_ch = POINTFINDER_DB()
    resfinder_ch = RESFINDER(infile_ch, res_db_ch, point_db_ch)
    RESFINDER_SUMMARY(resfinder_ch.collect())

    // PlasmidFinder
    plasmid_db = PLASMIDFINDER_DB()
    PLASMIDFINDER(infile_ch, plasmid_db)

    // VirulenceFinder
    virulence_db = VIRULENCEFINDER_DB()
    VIRULENCEFINDER(infile_ch, virulence_db)
}

//==============================================================================
//                            Processes
//==============================================================================
process RESFINDER_DB {
    publishDir "${params.outdir}/dbs", mode: "copy"

    output:
    path "resfinder_db"

    script:
    """
    git clone https://bitbucket.org/genomicepidemiology/resfinder_db/
    cd resfinder_db || exit 1
    python3 INSTALL.py
    """
}

process POINTFINDER_DB {
    publishDir "${params.outdir}/dbs", mode: "copy"

    output:
    path "pointfinder_db" 

    script:
    """
    git clone https://bitbucket.org/genomicepidemiology/pointfinder_db/
    cd pointfinder_db || exit 1
    python3 INSTALL.py
    """
}

process RESFINDER {
    tag "${file_id}"
    publishDir "${params.outdir}/resfinder", mode:"copy"

    input:
    tuple val(file_id), path(infile)
    path resfinder_db
    path pointfinder_db

    output:
    path file_id

    script:
    point_arg = params.skip_point ? "" : "--point"
    """
    run_resfinder.py \
        --inputfasta "${infile}" \
        --outputPath ${file_id} \
        --db_path_res ${resfinder_db} \
        --db_path_point ${pointfinder_db} \
        --species "${params.species}" \
        --min_cov "${params.res_cov}" \
        --threshold "${params.res_id}" \
        --acquired \
        ${point_arg}
    """
}

process RESFINDER_SUMMARY {
    publishDir "${params.outdir}/resfinder", mode: 'copy'

    input:
    path resfinder_outdirs

    output:
    path 'species_specific_summary.tsv'
    path 'full_summary.tsv'

    script:
    species = params.species.toLowerCase().replaceAll(" ", "_")
    """
    parse_resfinder_4_output.py \
        '${resfinder_outdirs}' \
        . \
        ${species}
    """
}

process PLASMIDFINDER_DB {
    publishDir "${params.outdir}/dbs", mode: "copy"

    output:
    path "plasmidfinder_db"

    script:
    """
    mkdir -p plasmidfinder_db

    download-db.sh plasmidfinder_db
    """
}

process PLASMIDFINDER {
    tag "${file_id}"
    publishDir "${params.outdir}/plasmidfinder", mode:"copy"

    input:
    tuple val(file_id), path(infile)
    path db

    output:
    path file_id

    script:
    """
    mkdir -p ${file_id}

    plasmidfinder.py \
        -i "${infile}" \
        -o ${file_id} \
        --databasePath ${db} \
        --mincov "${params.plasmid_cov}" \
        --threshold "${params.plasmid_id}" \
        --extented_output
    """
}

process VIRULENCEFINDER_DB {
    publishDir "${params.outdir}/dbs", mode: "copy"

    output:
    path "virulencefinder_db"

    script:
    """
    download-virulence-db.sh
    """
}

process VIRULENCEFINDER {
    tag "${file_id}"
    publishDir "${params.outdir}/virulencefinder", mode:"copy"

    input:
    tuple val(file_id), path(infile)
    path db

    output:
    path file_id

    script:
    """
    mkdir -p ${file_id}

    virulencefinder.py \
        -i "${infile}" \
        -o ${file_id} \
        --databasePath ${db} \
        --mincov "${params.virulence_cov}" \
        --threshold "${params.virulence_id}" \
        --extented_output \
        --methodPath blastn
    """
}


//==============================================================================
//                      Completion/error messages
//==============================================================================
workflow.onComplete {
    workflow.success ? Helper.success_message() : Helper.error_message(workflow)
    Helper.complete_message(params, workflow, version)
}
