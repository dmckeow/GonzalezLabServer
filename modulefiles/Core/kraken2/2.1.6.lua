-- kraken2/2.1.6 modulefile

whatis("Name: Kraken2")
whatis("Version: 2.1.6")
whatis("Category: Read binning")
whatis("Short Description: Kraken2")

help([[
    kraken2 --help
]])

local conda_env = "/opt/conda/envs/kraken2"

prepend_path("PATH", pathJoin(conda_env, "bin"))