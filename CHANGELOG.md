# Change log
All notable changes to the cluster setup will be documented here in this file. 
Add entries in reverse chronological order.

---

# Template

## contributor - yyyy-mm-dd
A general note on what was done

### Added

### Changed

### Fixed

---

# Template

## dmckeown - 2025-08-14
First admin setup work for the server

### Added
- I installed acl `sudo apt install acl` (README - Setup user permissions)
- Installed quota `sudo apt install quota` (README - User storage quota)

### Changed
- I moved the home directories permissions and folders for all non-admin users to /hddraid5/home: dmckeown, fradest, gabmm, gsabaris, mcoronado (README - Setup user location)
- I set all user permissions with acl so that everything in their home folders inherits the permissions of their home folder (README - Setup user permissions)
- I set soft storage quotas of 2 TB for all users: dmckeown, fradest, gabmm, gsabaris, mcoronado (README - User storage quota)
- I changed #AccountingStorageType=accounting_storage/none to AccountingStorageType=accounting_storage/slurmdbd in /etc/slurm/slurm.conf

### Fixed