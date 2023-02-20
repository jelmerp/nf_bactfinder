class Helper {

    static def complete_message(Map params, nextflow.script.WorkflowMetadata workflow, String version){
        // Display complete message
        println ""
        println "Ran the workflow: ${workflow.scriptName} ${version}"
        println "Command line    : ${workflow.commandLine}"
        println "Completed at    : ${workflow.complete}"
        println "Duration        : ${workflow.duration}"
        println "Success         : ${workflow.success}"
        println "Exit status     : ${workflow.exitStatus}"
        println "Work directory  : ${workflow.workDir}"
        println ""
        println "Parameters used:"
        println "----------------"
        params.each{ k, v ->
            if (v){
                println "${k}: ${v}"
            }
        }
        println "====================================================="
    }

    static def success_message() {
        println ""
        println "====================================================="
        println "            WORKFLOW SUCCESSFULLY COMPLETED"
        println "====================================================="
    }

    static def error_message(nextflow.script.WorkflowMetadata workflow){
        // Display error message
        println ""
        println "====================================================="
        println "            WORKFLOW FAILED"
        println "====================================================="
        println "Workflow execution stopped with the following message:"
        println "  " + workflow.errorMessage
    }

}
