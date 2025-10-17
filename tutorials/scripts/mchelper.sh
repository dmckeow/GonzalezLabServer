#!/bin/bash

#SBATCH --mem-per-cpu=6GB
#SBATCH --cpus-per-task=8
#SBATCH --partition=long

eval "$(conda shell.bash hook)"

THREADS="${SLURM_CPUS_PER_TASK}"
echo "Using ${THREADS} cores"

# Parse command-line options
while getopts ":s:n:l:g:b:h" option; do
    case "${option}" in
        s) species=${OPTARG} ;;
        n) strain=${OPTARG} ;;
        l) library=${OPTARG} ;;
        g) genome=${OPTARG} ;;
        b) BUSCO=${OPTARG} ;;
        h) echo "Usage: sbatch script.sh -s <species> -n <strain> -l <library.fa> -g <genome.fa> -b <BUSCO.hmm>"; exit 0 ;;
        \?) echo "Invalid option: -$OPTARG"; exit 1 ;;
        :) echo "Option -$OPTARG requires an argument."; exit 1 ;;
    esac
done

if [[ -z "$species" || -z "$strain" || -z "$library" || -z "$genome" || -z "$BUSCO" ]]; then
    echo "Error: All options -s, -n, -l, -g, and -b must be provided."
    exit 1
fi

# Prepare the clean library
clean_lib=$(echo $PWD"/"$strain"-clean_families.fa")
if [ ! -f "$clean_lib" ]; then
    echo "Making clean library for MCHelper input"
    conda activate seqkit
    awk '/^>/' $library | \
    awk '!/Satellite|Simple_repeat|tRNA|rRNA|Retroposon|snRNA|scRNA/' $library | \
    sed 's/^>//g' | \
    seqkit grep --threads $THREADS -n -f - $library > $clean_lib
fi

# Run MCHelper

conda activate MCHelper

python3 ~/TEammo/mchelper-ats/MCHelper.py \
-r A  \
-a F \
--input_type fasta \
-l $clean_lib \
-g $genome \
-b $BUSCO \
-o . \
-c 1 \
-t $THREADS \
-v Y > mchelper_automatic.log


if [ ! -f ./curated_sequences_NR.fa ]; then
    echo "No auto curated library from MCHelper found in parent directory:"
    echo "Perhaps the first MCHelper step failed"
    exit 1
fi

# Run TEAid
echo "Running the TEaid step"

mkdir -p 1_MI_MCH
cd 1_MI_MCH

conda activate MCHelper
python3 ~/TEammo/mchelper-ats/MCHelper.py \
-r T \
--input_type fasta \
-l ../curated_sequences_NR.fa \
-g $genome \
-o . \
-t $THREADS \
-v Y > ../mchelper_manual.log
