# Change log
All notable changes to the cluster setup will be documented here in this file. 
Add entries in reverse chronological order.

# Template

## contributor - yyyy-mm-dd
A general note on what was done

### Added

### Changed

### Fixed

---

# Logs

## dmckeown - 2025-09-05
Changing R and conda to allow multiple version installation

### Added

### Changed
- Removed the previous conda 25.5.1 installation, and simply reinstalled it with a subfolder for its version, allowing multiple versions to be installed in future
  - Updated the modules lua file to the new subfolder
- Rebuilding R to allow multiple versions to be [installed](https://support.posit.co/hc/en-us/articles/215488098-Compiling-R-for-Multiple-installations-of-R-on-Linux)
  - Rebuild the dependencies for R: `sudo apt-get build-dep r-base` (this seems to be a comprehensive)
    - Includes dependencies manually installed before: e.g. `libx11-dev`
  - Configure and build two versions of R, 4.1.0 and 4.5.2: [Install R with multiple versions](README.md#install-r-with-multiple-versions)
    - The previous R 4.5.1 installation remains in /usr/local, but is not accessible via modules
    - Tested conda and R as a user - can load conda envs, and install, load R packages - all good
- [QoS changes](README.md#partitions-and-qos).
  - I removed the QoS "big" `sudo sacctmgr remove qos name=big` and removed it from the slurm.conf
  - Changed QoS normal to have no memory or cpu limits


### Fixed


---

## dmckeown - 2025-08-21
Adding R dependencies, reboot 

### Added
- Installed R system dependencies:
  - `sudo apt install libfontconfig1-dev`
  - `sudo apt install libx11-dev`

### Changed
- The system gave warning that it was not running the recent kernel available, so I did `sudo reboot`, few minutes later the system was running again
### Fixed

---

## dmckeown - 2025-08-18
Second session setting up server - partitions & qos, first modules

### Added
- Added two QoS (normal was modified as it already existing) (README - Partitions, QoS)
- Installed make (README - Software)
- Installed lmod (after uninstalling modules that I installed in error)
- Installed conda 25.5.1 and added a module
- Installed R 4.5.1 and added a module
  - `sudo apt install r-base r-base-dev`
- Installed R system dependencies:
  - `sudo apt install libcurl4-openssl-dev libssl-dev pandoc`

### Changed
- The /etc/slurm/slurm.conf was edited to add different partitions and priority weighting (README - Partitions, QoS)

### Fixed

---


## dmckeown - 2025-08-14
First admin setup work for the server - user homes and quotas

### Added
- I installed acl `sudo apt install acl` (README - Setup user permissions)
- Installed quota `sudo apt install quota` (README - User storage quota)

### Changed
- I moved the home directories permissions and folders for all non-admin users to /hddraid5/home: dmckeown, fradest, gabmm, gsabaris, mcoronado (README - Setup user location)
- I set all user permissions with acl so that everything in their home folders inherits the permissions of their home folder (README - Setup user permissions)
- I set soft storage quotas of 2 TB for all users: dmckeown, fradest, gabmm, gsabaris, mcoronado (README - User storage quota)
- I changed #AccountingStorageType=accounting_storage/none to AccountingStorageType=accounting_storage/slurmdbd in /etc/slurm/slurm.conf

### Fixed