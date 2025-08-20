# Change log
All notable changes to the cluster setup will be documented here in this file. 
Add entries in reverse chronological order.

---
---

# Template

## contributor - yyyy-mm-dd
A general note on what was done

### Added

### Changed

### Fixed

---
---

## dmckeown - 2025-08-18
Second session setting up server - partitions & qos, first modules

### Added
- Added two QoS (normal was modified as it already existing) (README - Partitions, QoS)
- Installed make (README - Software)
- Installed lmod (after uninstalling modules that I installed in error)
- Installed conda 25.5.1 and added a module
- Installed R 4.5.1 and added a module
- Installed R system dependencies: `sudo apt install libcurl4-openssl-dev libssl-dev pandoc`

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