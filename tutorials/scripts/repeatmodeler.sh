#!/bin/bash

#SBATCH --mem-per-cpu=4GB
#SBATCH --cpus-per-task=16
#SBATCH --partition=long

THREADS="${SLURM_CPUS_PER_TASK:-8}"
echo "Using ${THREADS} cores"

# Parse command-line options
while getopts ":g:n:l:h" option; do
    case "${option}" in
        g) genome_fasta=${OPTARG} ;;
        n) genome_name=${OPTARG} ;;
        l) library=${OPTARG} ;;
        h) echo "Usage: $0 -g genome.fa -n genome_name [-l library]"; exit 0 ;;
        \?) echo "Invalid option: -$OPTARG"; exit 1 ;;
        :) echo "Option -$OPTARG requires an argument."; exit 1 ;;
    esac
done

# Loads the TEtools software that contains repeatmodeler2
module load Dfam_TEtools/1.94

# BuildDatabase for RepeatModeler2
dfam-tetools.sh -- /opt/RepeatModeler/BuildDatabase -name "${genome_name}" "${genome_fasta}"

# Run RepeatModeler2
repeatmodeler_cmd="/opt/RepeatModeler/RepeatModeler -database ${genome_name} -threads ${THREADS} -LTRStruct"

# Run RepeatModeler via dfam-tetools.sh, optionally with --library
if [[ -n "${library}" ]]; then
    echo "Running with library specified"
    dfam-tetools.sh --library "${library}" -- ${repeatmodeler_cmd}
else
    echo "Running with default library path in tetools"
    dfam-tetools.sh -- ${repeatmodeler_cmd}
fi