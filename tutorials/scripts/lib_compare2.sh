#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 7 ]; then
    echo "Usage: $0 lib1 lib1_name lib2 lib2_name species strain <MCHelper auto curated lib>"
    exit 1
fi

lib1=$1       # e.g. dean.fa
lib1_name=$2  # e.g. dean
lib2=$3       # e.g. marta.fa
lib2_name=$4  # e.g. marta
species=$5    # e.g. D.tristis
strain=$6     # e.g. nanopore_D2
MCH_lib=$7    # e.g. path/to/mchelper_autocurated_library.fa

# Make BLAST databases
makeblastdb -in "${lib1}" -dbtype "nucl"
makeblastdb -in "${lib2}" -dbtype "nucl"

mkdir -p output/lib_compare
# BLAST the MCHelper auto library against each final lib
blastn -query "${MCH_lib}" \
  -db "${lib1}" \
  -outfmt 6 -max_hsps 1 \
  -out "output/lib_compare/lib_compare_MCHelperAuto_vs_${species}-${strain}-${lib1}.blast.out"

blastn -query "${MCH_lib}" \
  -db "${lib2}" \
  -outfmt 6 -max_hsps 1 \
  -out "output/lib_compare/lib_compare_MCHelperAuto_vs_${species}-${strain}-${lib2}.blast.out"