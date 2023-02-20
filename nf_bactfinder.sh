#!/bin/bash

#SBATCH --account=PAS0471
#SBATCH --time=1:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mail-type=FAIL
#SBATCH --job-name=ghru_finder
#SBATCH --output=slurm-ghru_finder-%j.out

# ==============================================================================
#                          CONSTANTS AND DEFAULTS
# ==============================================================================
# Constants
readonly SCRIPT_NAME=ghru_finder.sh
readonly SCRIPT_VERSION="1.0"
readonly SCRIPT_AUTHOR="Jelmer Poelstra"
readonly CONDA_ENV=/fs/project/PAS0471/jelmer/conda/nextflow

# URL to OSC Nextflow config file
OSC_CONFIG_URL=https://raw.githubusercontent.com/mcic-osu/mcic-scripts/main/nextflow/osc.config
osc_config=mcic-scripts/nextflow/osc.config  # Will be downloaded if not present here

# Option defaults
nf_file="/fs/project/PAS0471/jelmer/assist/2022-09_alejandra/workflows/ghru_finder/main.nf"
container_dir=/fs/project/PAS0471/containers
work_dir=/fs/scratch/PAS0471/$USER/nf_resfinder
profile="conda"
outdir=results/ghru_finder
resume=true && resume_arg="-resume"

# ==============================================================================
#                                   FUNCTIONS
# ==============================================================================
# Help function
script_help() {
    echo
    echo "======================================================================"
    echo "                     $0"
    echo "             Run the BactFinder nextflow workflow"
    echo "======================================================================"
    echo
    echo "DESCRIPTION:"
    echo "  This will run the BactFinder Nextflow workflow to examine bacterial"
    echo "  genome assemblies with ResFinder, VirulenceFinder and PlasmidFinder"
    echo
    echo "REQUIRED OPTIONS:"
    echo "  -i/--indir      <dir>   Input directory with assembly nucleotide FASTA files"
    echo "  --species       <str>   Quoted string with focal species name, e.g.: --species 'Enterobacter cloacae'"
    echo
    echo "OTHER KEY OPTIONS:"
    echo "  -o/--outdir     <dir>   Output directory for workflow results       [default: 'results/ghru_finder']"
    echo "  --file_pattern  <str>   Single-quoted FASTQ file pattern (glob)     [default: '*fasta']"
    echo "  --no_resume             Start workflow from beginning               [default: resume where it left off]"
    echo "  --more_args     <str>   Additional arguments to pass to 'nextflow run'"
    echo "                            - You can use any additional option of Nextflow and of the Nextflow workflow itself"
    echo "                            - Use as follows (quote the entire string!): '$0 --more_args \"--res_cov 0.8\"'"
    echo
    echo "NEXTFLOW-RELATED OPTIONS:"
    echo "  --nf_file       <file>  Main .nf workflow definition file           [default: 'workflows/nfcore-rnaseq/workflow/main.nf']"
    echo "  -no-resume              Don't attempt to resume workflow run        [default: resume workflow where it left off]"
    echo "  -profile        <str>   Profile to use from one of the config files [default: 'singularity']"
    echo "  -work-dir       <dir>   Scratch (work) dir for the workflow         [default: '/fs/scratch/PAS0471/\$USER/nfc_rnaseq']"
    echo "  -c/-config      <file   Additional config file                      [default: none]"
    echo "  --container_dir <dir>   Singularity container dir                   [default: '/fs/project/PAS0471/containers']"
    echo
    echo "UTILITY OPTIONS:"
    echo "  -h / --help             Print this help message and exit"
    echo
    echo "EXAMPLE COMMANDS:"
    echo "  sbatch $0 -i results/assemblies --species 'Enterobacter cloacae'"
    echo "  sbatch $0 -i results/assemblies --species 'Salmonella enterica' --file_pattern '*fna'"
    echo
    echo "DOCUMENTATION:"
    echo "- This script runs a workflow based on the GHRU <https://gitlab.com/cgps/ghru/pipelines/amr_prediction>"
    echo "- ResFinder documentation: https://bitbucket.org/genomicepidemiology/resfinder/src/master/"
    echo
}

# Load the software
load_tool_conda() {
    set +u
    module load miniconda3/4.12.0-py39
    [[ -n "$CONDA_SHLVL" ]] && for i in $(seq "${CONDA_SHLVL}"); do source deactivate 2>/dev/null; done
    source activate "$CONDA_ENV"
    set -u

    # Singularity container dir - any downloaded containers will be stored here;
    # if the required container is already there, it won't be re-downloaded
    export NXF_SINGULARITY_CACHEDIR="$container_dir"
    mkdir -p "$NXF_SINGULARITY_CACHEDIR"

    # Limit memory for Nextflow main process - see https://www.nextflow.io/blog/2021/5_tips_for_hpc_users.html
    export NXF_OPTS='-Xms1g -Xmx4g'
}

# Print the tool's help
tool_help() {
    load_tool_conda
    nextflow run "$nf_file" --help
}

# Exit upon error with a message
die() {
    local error_message=${1}
    local error_args=${2-none}
    log_time "$0: ERROR: $error_message" >&2
    log_time "For help, run this script with the '-h' option" >&2
    if [[ "$error_args" != "none" ]]; then
        log_time "Arguments passed to the script:" >&2
        echo "$error_args" >&2
    fi
    log_time "EXITING..." >&2
    exit 1
}

# Log messages that include the time
log_time() { echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')]" ${1-""}; }

# Print the script version
script_version() {
    echo "Run using $SCRIPT_NAME by $SCRIPT_AUTHOR, version $SCRIPT_VERSION (https://github.com/mcic-osu/mcic-scripts)"
}

# Print SLURM job resource usage info
resource_usage() {
    sacct -j "$SLURM_JOB_ID" -o JobID,AllocTRES%60,Elapsed,CPUTime | grep -Ev "ba|ex"
}

# Resource usage information for any process
runstats() {
    /usr/bin/time -f \
        "\n# Ran the command: \n%C
        \n# Run stats by /usr/bin/time:
        Time: %E   CPU: %P    Max mem: %M K    Exit status: %x \n" \
        "$@"
}

# ==============================================================================
#                          PARSE COMMAND-LINE ARGS
# ==============================================================================
# Initiate variables
indir=
species=
config_file=
file_pattern= && file_pattern_arg=
more_args=

# Parse command-line args
all_args="$*"
while [ "$1" != "" ]; do
    case "$1" in
        -i | --indir )      shift && indir=$1 ;;
        -o | --outdir )     shift && outdir=$1 ;;
        --species )         shift && species=$1 ;;
        --file_pattern )    shift && file_pattern=$1 ;;
        --nf_file )         shift && nf_file=$1 ;;
        --container_dir )   shift && container_dir=$1 ;;
        -work-dir )         shift && work_dir=$1 ;;
        -profile )          shift && profile=$1 ;;
        -config )           shift && config_file=$1 ;;
        --more_args )       shift && more_args=$1 ;;
        -no-resume )        resume=false ;;
        -h | --help )       Help && exit ;;
        * )                 die "Invalid option $1" && exit 1 ;;
    esac
    shift
done

# Check input
[[ "$indir" = "" ]] && die "Please specify an input dir with -i/--indir"
[[ "$species" = "" ]] && die "Please specify a species with -s/--species"
[[ ! -d "$indir" ]] && die "Input dir $indir does not exist"
[[ ! -f "$nf_file" ]] && die "Nextflow file $nf_file does not exist"

# ==============================================================================
#                          INFRASTRUCTURE SETUP
# ==============================================================================
# Check if this is a SLURM job
if [[ -z "$SLURM_JOB_ID" ]]; then is_slurm=false; else is_slurm=true; fi

# Strict bash settings
set -euo pipefail

# Load software
load_tool_conda

# ==============================================================================
#              DEFINE OUTPUTS AND DERIVED INPUTS, BUILD ARGS
# ==============================================================================
# Define outputs based on script parameters
readonly version_file="$outdir"/logs/version.txt
readonly log_dir="$outdir"/logs

# Get the OSC config file
if [[ ! -f "$osc_config" ]]; then
    wget -q "$OSC_CONFIG_URL"
    osc_config=$(basename "$OSC_CONFIG_URL")
fi

# Build the config argument
[[ ! -f "$osc_config" ]] && osc_config="$outdir"/$(basename "$OSC_CONFIG_URL")
config_arg="-c $osc_config"
[[ "$config_file" != "" ]] && config_arg="$config_arg -c ${config_file/,/ -c }"

# Build other args
[[ "$resume" == false ]] && resume_arg=""
[[ -n "$file_pattern" ]] && file_pattern_arg="--file_pattern $file_pattern"

# Define trace output dir
trace_dir="$outdir"/pipeline_info

# ==============================================================================
#                               REPORT
# ==============================================================================
log_time "Starting script $SCRIPT_NAME, version $SCRIPT_VERSION"
echo "=========================================================================="
echo "All arguments to this script:    $all_args"
echo "Input dir:                       $indir"
echo "Output dir:                      $outdir"
echo "Species:                         $species"
[[ -n "$file_pattern" ]] && echo "Input file pattern:              $file_pattern"
echo
echo "Resume previous run:             $resume"
echo "Nextflow workflow file:          $nf_file"
echo "Container dir:                   $container_dir"
echo "Scratch (work) dir:              $work_dir"
echo "Config file argument:            $config_arg"
[[ -n "$config_file" ]] && echo "Additional config file:          $config_file"
echo

# ==============================================================================
#                               RUN
# ==============================================================================
# Create the output directories
log_time "Creating the output directories..."
mkdir -pv "$work_dir" "$container_dir" "$log_dir" "$trace_dir"

# Remove old trace files
[[ -f "$trace_dir"/report.html ]] && rm "$trace_dir"/report.html
[[ -f "$trace_dir"/trace.txt ]] && rm "$trace_dir"/trace.txt
[[ -f "$trace_dir"/timeline.html ]] && rm "$trace_dir"/timeline.html
[[ -f "$trace_dir"/dag.png ]] && rm "$trace_dir"/dag.png

# Download the OSC config file
[[ ! -f "$osc_config" ]] && wget -q -O "$osc_config" "$OSC_CONFIG_URL"

# Run the workflow run command
log_time "Starting the workflow...\n"
runstats nextflow run "$nf_file" \
    --indir "$indir" \
    --outdir "$outdir" \
    --species "$species" \
    $file_pattern_arg \
    -work-dir "$work_dir" \
    -with-report "$trace_dir"/report.html \
    -with-trace "$trace_dir"/trace.txt \
    -with-timeline "$trace_dir"/timeline.html \
    -with-dag "$trace_dir"/dag.png \
    -ansi-log false \
    -profile "$profile" \
    $config_arg \
    $resume_arg \
    $more_args

# ==============================================================================
#                               WRAP-UP
# ==============================================================================
printf "\n======================================================================"
log_time "Versions used:"
script_version | tee -a "$version_file" 
log_time "Listing files in the output dir:"
ls -lhd "$(realpath "$outdir")"/*
[[ "$is_slurm" = true ]] && echo && resource_usage
log_time "Done with script $SCRIPT_NAME"
echo
