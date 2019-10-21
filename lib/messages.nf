def version_message(String version) {
    println(
        """
        ==============================================
        Resfinder Pipeline version ${version}
        ==============================================
        """.stripIndent()
    )
}

def help_message() {
    println(
        """
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
        """.stripIndent()
    )
}

def complete_message(Map params, nextflow.script.WorkflowMetadata workflow, String version){
    // Display complete message
    println ""
    println "Ran the workflow: ${workflow.scriptName} ${version}"
    println "Command line    : ${workflow.commandLine}"
    println "Completed at    : ${workflow.complete}"
    println "Duration        : ${workflow.duration}"
    println "Success         : ${workflow.success}"
    println "Work directory  : ${workflow.workDir}"
    println "Exit status     : ${workflow.exitStatus}"
    println ""
    println "Parameters"
    println "=========="
    params.each{ k, v ->
        if (v){
            println "${k}: ${v}"
        }
    }
}

def error_message(nextflow.script.WorkflowMetadata workflow){
    // Display error message
    println ""
    println "Workflow execution stopped with the following message:"
    println "  " + workflow.errorMessage

}