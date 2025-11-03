#!/usr/bin/env bash
eval "$(conda shell.bash hook)"

# the variables
auto_mchelper_lib="$1"
species="$2"
strain="$3"
lib1="$4"
curator1="$5"
lib2="$6"
curator2="$7"
busco_lib="$8"
genome_path="$9"

# the script

startdir="$(realpath .)"
workdir="output/lib_compare/${species}/${strain}"
rm -fr ${workdir}/Missing_from_lib1 ${workdir}/Missing_from_lib2
mkdir ${workdir}/Missing_from_lib1 ${workdir}/Missing_from_lib2

conda activate seqkit
seqkit grep --threads 4 -r -n -f ${workdir}/missing_from_lib1.csv ${auto_mchelper_lib} > ${workdir}/missing_from_lib1.fa
seqkit grep --threads 4 -r -n -f ${workdir}/missing_from_lib2.csv ${auto_mchelper_lib} > ${workdir}/missing_from_lib2.fa

cd ${workdir}/Missing_from_lib1 || exit 1

conda activate MCHelper
python3 ~/tools/TEammo/mchelper-ats/MCHelper.py \
  -r T \
  --input_type fasta \
  -l ../missing_from_lib1.fa \
  -g ${genome_path} \
  -o . \
  -t ${SLURM_CPUS_PER_TASK:-4} \
  -v Y

cd $startdir


cd ${workdir}/Missing_from_lib2 || exit 1

conda activate MCHelper
python3 ~/tools/TEammo/mchelper-ats/MCHelper.py \
  -r T \
  --input_type fasta \
  -l ../missing_from_lib2.fa \
  -g ${genome_path} \
  -o . \
  -t ${SLURM_CPUS_PER_TASK:-4} \
  -v Y

cd $startdir

echo "Your TEaid figures for inspection are in: output/lib_compare/${species}/${strain}/Missing_from_lib1/te_aid and output/lib_compare/${species}/${strain}/Missing_from_lib2/te_aid"