mkdir -p ${my_data_folder} ${my_data_folder}/RM2_output ${my_data_folder}/MCH_output ${my_data_folder}/0_raw ${my_data_folder}/BUSCO_libs
mkdir -p "${my_data_folder}/0_raw/${species}/${strain}"
mkdir -p "${my_data_folder}/MCH_output/${species}/${strain}"
mkdir -p "${my_data_folder}/RM2_output/${species}/${strain}"

cp ${genome_fasta} ${my_data_folder}/0_raw/${species}/${strain}

module load conda
conda activate busco
merged_hmm=${my_data_folder}/BUSCO_libs/${busco_lineage}_ALL.hmm
if [ ! -f "$merged_hmm" ]; then
  echo "Getting busco lib ${busco_lineage}"
  busco --download ${busco_lineage}
  mv busco_downloads/lineages/${busco_lineage}/ ${my_data_folder}/BUSCO_libs/
  rm -fr busco_downloads/
  # The HMM profiles must be merged for MCHelper
  cat ${my_data_folder}/BUSCO_libs/${busco_lineage}/hmms/*.hmm > ${merged_hmm}
  rm -fr ${my_data_folder}/BUSCO_libs/${busco_lineage}
else
  echo "BUSCO lib already exists"
fi