# GonzalezLabServer
Management of the SLURM computing cluster of the Gonzalez lab at IBB

## To do

### Short term

#### Server status reporting
* How to create an easily updated overview report that can be viewed here or in the repo

#### Security
* ssh-key login setup

#### Setup user permissions
* Users should not have /home permissions
    * Classic linux controls ok, maybe use ACL for an easier approach 

#### Setup partitions (i.e. job queues)
* Group wants an infinite queue?
* We are 1 node, X cores, X CPUs
* Default partition
    * This is where users login, and where jobs without specified qos go

#### Setup user location
* Admin acccount(s) should be in /home - the smaller volume
* The user accounts should be in the larger storage

#### Scratch setup
* We won't use an auto delete for now, but request users to keep scratch clear

---

### Medium term

#### Software management
* Commonly available software via the module system:
    * Conda
    * R

---

### Long term

---
#### Welcome message
* Key info and links to documentation
* ASCII art and server name

#### Backup setup
* Rsync - how do we confirm backup is done?
* Guidance for users to keep their own backups as well

#### Documentation for users
* Detailing the server setup, what partitions there are, how backups happen, etc

## Done 