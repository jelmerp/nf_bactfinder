include './messages.nf'
def default_params(){
    /***************** Setup inputs and channels ************************/
    def params = [:]
    params.help = false
    params.version = false

    params.input_dir = false
    params.fastq_pattern = false
    params.output_dir = false

    params.ariba_database_dir = false
    params.ariba_get_database = false
                    
    params.ariba_extra_summary_arguments = false

    params.resfinder_min_cov = false
    params.resfinder_identity_threshold = false
    params.resfinder_species = false
    params.resfinder_point_mutation = false
    params.resfinder_db_resfinder = false
    params.resfinder_db_pointfinder = false

    return params
}

def process_params(Map params, String version) { 
    // Show help message
    if (params.help){
        version_message(version)
        help_message()
        System.exit(0)
    }

    // Show version number
    if (params.version){
        version_message(version)
        System.exit(0)
    }


    // set up input directory
    def final_params = [:]
    def input_dir = check_mandatory_parameter(params, 'input_dir') - ~/\/$/

    //  check a pattern has been specified
    def fastq_pattern = check_mandatory_parameter(params, 'fastq_pattern')

    //
    final_params.reads_path = input_dir + "/" + fastq_pattern

    // set up output directory
    final_params.output_dir = check_mandatory_parameter(params, 'output_dir') - ~/\/$/

    // assign Minimum coverage
    if ( params.resfinder_min_cov ) {
        final_params.resfinder_min_cov = params.resfinder_min_cov
    } else {
        final_params.resfinder_min_cov = 0.9
    }

    // assign Identity threshold
    if ( params.resfinder_identity_threshold ) {
        final_params.resfinder_identity_threshold = params.resfinder_identity_threshold
    } else {
        final_params.resfinder_identity_threshold = 0.9
    }

    // species to be used
    if ( params.resfinder_species ) {
        final_params.resfinder_species = params.resfinder_species
    } else {
        final_params.resfinder_species = false
    }

    // resfinder_database to be used
    if ( params.resfinder_db_resfinder ) {
        final_params.resfinder_db_resfinder = params.resfinder_db_resfinder
    } else {
        final_params.resfinder_db_resfinder = "/resfinder/db_resfinder"
    }

    // pointfinder_database to be used
    if ( params.resfinder_db_pointfinder ) {
        final_params.resfinder_db_pointfinder = params.resfinder_db_pointfinder
    } else {
        final_params.resfinder_db_pointfinder = "/resfinder/db_pointfinder"
    }

    // check species is set if pointfinder required
    if (params.resfinder_point_mutation) {
        if (!params.resfinder_species){
            println "The point_mutation option must be used only with --species"
            System.exit(1)
        }else {
            final_params.resfinder_point_mutation=true
        }
    }

    // ariba database - default is in container at /resfinder_database.17.10.2019
    if (params.ariba_database_dir){
        final_params.ariba_database_dir = file(params.ariba_database_dir)
    } else {
        final_params.ariba_database_dir = file('/resfinder_database.17.10.2019')
    }

    // ariba summary columns (default --preset cluster_all)
    if (params.ariba_extra_summary_arguments){
        final_params.ariba_extra_summary_arguments = params.ariba_extra_summary_arguments
    } else {
        final_params.ariba_extra_summary_arguments = '--preset cluster_all'
    }

    return final_params

}

def check_mandatory_parameter(Map params, String parameter_name){
    if ( !params[parameter_name]){
        println "You must specifiy a " + parameter_name
        System.exit(1)
    } else {
        return params[parameter_name]
    }
}

def check_optional_parameters(Map params, List parameter_names){
    if (parameter_names.collect{name -> params[name]}.every{param_value -> param_value == false}){
        println "You must specifiy at least one of these options: " + parameter_names.join(", ")
        System.exit(1)
    }
}

def check_parameter_value(String parameter_name, String value, List value_options){
    if (value_options.any{ it == value }){
        return value
    } else {
        println "The value for " + parameter_name + " must be one of " + value_options.join(", ")
        System.exit(1)
    }
}

