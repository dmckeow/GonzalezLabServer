#!/bin/bash

THREADS="${SLURM_CPUS_PER_TASK:-8}"
echo "Using ${THREADS} cores"

# This script needs TEtools container

# Parse command-line options
while getopts ":g:h" option; do
    case "${option}" in
        g) genome_fasta=${OPTARG} ;;
        h) echo "Usage: $0 -g genome.fa [-- args for RepeatMasker]"; exit 0 ;;
        \?) echo "Invalid option: -$OPTARG"; exit 1 ;;
        :) echo "Option -$OPTARG requires an argument."; exit 1 ;;
    esac
done

if [[ -z "${genome_fasta}" ]]; then
    echo "Error: -g genome fasta is required"
    exit 1
fi


# Remove parsed options and get the extra ones
shift $((OPTIND - 1))
extra_args=("$@")

# Build RepeatModeler command
run_cmd="/opt/RepeatMasker/RepeatMasker -dir . -pa ${THREADS} ${extra_args[*]} ${genome_fasta}"

dfam-tetools.sh -- ${run_cmd}