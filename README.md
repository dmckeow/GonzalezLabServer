
# To do

## Not started

### Short term

#### Security
* ssh-key login setup

---

### Long term

#### Server status reporting
* How to create an easily updated overview report that can be viewed here or in the repo

#### Welcome message when users login
* Key info and links to documentation
* ASCII art and server name

#### Backup setup
* Rsync - how do we confirm backup is done?
* Guidance for users to keep their own backups as well

---



#### Partitions and QoS

```{bash}
sudo sacctmgr modify qos normal set Description="Standard jobs" MaxTRESPerJob=cpu=32,mem=128G Flags=DenyOnLimit

# This QoS was removed later because we don't need multiple QoS right now
sudo sacctmgr add qos big Description="Big jobs" MaxTRESPerJob=cpu=64,mem=256G Flags=DenyOnLimit

# Change the normal qos to have no limits - the user settings will be used instead
sudo sacctmgr modify qos normal set Flags-=DenyOnLimit
sudo sacctmgr modify qos normal set MaxTRESPerJob=cpu=128,mem=773GB

```
* Slurm settings such as partitions are set in `/etc/slurm/slurm.conf`
* I replaced the original slurm.conf (config_files/server_og_slurm.conf) with (config_files/slurm.conf), then:

```{bash}
# Reset to active the new slurm.conf
sudo scontrol reconfigure
sudo scontrol show config
sudo systemctl restart slurmctld
sudo systemctl restart slurmd

# Check to see the partitions and qos
sacctmgr show qos
sinfo
```

##### Issue
Testing setting as user:
* Jobs submitted over resource or time limits just pend forever - user has to do scancel

## Done

#### Setup user location
* Admin acccount(s) should be in /home - the smaller volume 
* The user accounts should be in the larger storage /dev/sdb1 (/hddraid5)

* Currently the users and admin (administrator, gonzalezlab) are in the same /home as users
* The volume they are all in is /dev/sda2 the small 6.6T volume
    * Therefore the users are in the wrong volume - we need to move them to /dev/sdb1 (/hddraid5)
```{bash}
gonzalezlab@slurm:/home$ pwd
/home
gonzalezlab@slurm:/home$ ll
total 36
drwxr-xr-x  9 root          root          4096 ago  5 18:28 ./
drwxr-xr-x 22 root          root          4096 jul 22 10:38 ../
drwxr-x---  5 administrador administrador 4096 jul 30 15:13 administrador/
drwxr-x---  5 dmckeown      dmckeown      4096 jul 30 16:57 dmckeown/
drwxr-x---  3 fradest       fradest       4096 ago  5 18:15 fradest/
drwxr-x---  3 gabmm         gabmm         4096 jul 30 19:06 gabmm/
drwxr-x---  5 gonzalezlab   gonzalezlab   4096 jul 30 16:41 gonzalezlab/
drwxr-x---  2 gsabaris      gsabaris      4096 ago  5 18:28 gsabaris/
drwxr-x---  3 mcoronado     mcoronado     4096 jul 31 09:23 mcoronado/
gonzalezlab@slurm:/home$ df .
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2       7,0T   15G  6,6T   1% /
```

I made a `/hddraid5/home` for all users homes to go in

How to move an account (NOTE: this was done before anyone had actually used their accounts - with home directories containing real data we would take a more careful approach to moving and deleting the old home directories):

```{bash}
UserToMove="dmckeown"
OldHome="/hddraid5/${UserToMove}"
NewHome="/hddraid5/home/${UserToMove}"

sudo mkdir -p ${NewHome}

# Move and check the system home (does not move files)
sudo usermod --move-home --home ${NewHome} ${UserToMove}
grep ${UserToMove} /etc/passwd

# copy everything from the old home
sudo rsync -a ${OldHome}/ ${NewHome}/

# fix ownership
sudo chown -R ${UserToMove}:${UserToMove} ${NewHome}
sudo setfacl -d -m u::rwx,g::r-x,o::--- ${NewHome}
sudo getfacl ${NewHome}

# Delete the old home dir - for a user with data we would check carefully that the rsync worked
sudo rm -fr ${OldHome}

```

##### Creating a new user (moved to wiki)

---

#### Software
* Commonly available software:
    * Conda
    * R

##### Install modules
NOT this one: https://modules.readthedocs.io/en/stable/INSTALL.html
This one: https://lmod.readthedocs.io/en/latest/030_installing.html

Followed the installation instructions then the setup:
```{bash}
sudo ln -s /usr/local/Modules/init/profile.sh /etc/profile.d/modules.sh
sudo ln -s /usr/local/Modules/init/profile.csh /etc/profile.d/modules.csh

```

##### Install conda with specific version
It is **important** that all software is installed in a directory separate for each version, as this will allow us to manage multiple versions through the modules system - e.g. don't install in `/opt/conda`, install specific version in its own folder: `/opt/conda/Miniconda3-py39_25.5.1`

```{bash}
cd /tmp
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_25.5.1-1-Linux-x86_64.sh
sudo bash Miniconda3-py39_25.5.1-1-Linux-x86_64.sh -b -p /opt/conda/Miniconda3-py39_25.5.1
```

Then make the module for conda:
https://arccwiki.atlassian.net/wiki/spaces/DOCUMENTAT/pages/2181923764/Create+a+Module+File+to+Load+Your+Conda+Environment

* The module is a lua file: `/opt/apps/lmod/lmod/modulefiles/Core/conda/25.5.1.lua`
* Lmod uses any lua modules files in the module path: `echo $MODULEPATH`

```{bash}
-- Miniconda3 modulefile

whatis("Name: conda")
whatis("Version: 25.5.1")
whatis("Category: Environment")
whatis("Short Description: Conda environment management.")


help([[
Miniconda3 provides the conda package manager and Python distribution.
Usage:
   module load conda/25.5.1
   conda create -n myenv python=3.9
   conda activate myenv
]])

prepend_path("PATH","/opt/conda/Miniconda3-py39_25.5.1/bin/")
```
Check that it works
```{bash}
module avail
module load 
```
Then set up the path for modules

```{bash}
module avail # to see that it is not setup
```

##### Install R with multiple versions
https://support.posit.co/hc/en-us/articles/215488098-Compiling-R-for-Multiple-installations-of-R-on-Linux

```{bash}
Rversion="4.1.0" # Change to the version to install - check the download path for the tarball
wget https://cran.rstudio.com/src/base/R-4/R-${Rversion}.tar.gz
tar -xzf R-${Rversion}.tar.gz
cd R-${Rversion}/
sudo ./configure --prefix=/opt/R/${Rversion} --enable-R-shlib
sudo make
sudo make install
cd ..
sudo rm -fr R-${Rversion}
```

Then make the lua file for modules at `/opt/apps/lmod/lmod/modulefiles/Core/R/4.1.0.lua`:

```{bash}
-- R/4.1.0 modulefile

whatis("Name: R")
whatis("Version: 4.1.0")
whatis("Category: Environment")
whatis("Short Description: R")


help([[
R.
Usage:
   module load R/4.1.0
   R
]])

prepend_path("PATH","/opt/R/4.1.0/bin")
```


##### Install Repeatmodeler2
Using the singularity (apptainer) via TEtools
https://github.com/Dfam-consortium/TETools
- the TE databases are located in `/opt/Dfam_TEtools/1.94/Libraries`

Getting the DFAM database (3.9):

```{bash}

cd /opt/Dfam_TEtools/1.94/Libraries/famdb

# Create a file with all DFAM FamDB URLs
for i in {0..16}; do
  echo "https://www.dfam.org/releases/Dfam_3.9/families/FamDB/dfam39_full.${i}.h5.gz"
done > dfam_files.txt

aria2c -i dfam_files.txt -j 8 -x 16
# aria2c -i dfam_files.txt -j 8 -x 16 -c # rerun with c if interrupted


for f in dfam39_full.*.h5.gz; do
  gunzip $f
done


cd /opt/Dfam_TEtools/1.94/Libraries
wget https://www.dfam.org/releases/Dfam_3.9/families/Dfam-curated_only-1.embl.gz
gunzip Dfam-curated_only-1.embl.gz
aria2c -x 16 https://www.dfam.org/releases/Dfam_3.9/families/Dfam-curated_only-1.hmm.gz
gunzip Dfam-curated_only-1.hmm.gz
```

#### Issue
* Could this setup create problems in the future?

##### cgroups activation
- Do once cluster not in use

1. Backup **current** slurm.conf in (I saved it as `config_files/slurm.conf_original`)

2. Replace the current slurm.conf with the one with cgroups enabled `config_files/slurm.conf_cgroups` > `/etc/slurm/slurm.conf`

3. Put the cgroup config file in the same directory `config_files/cgroup.conf` > `/etc/slurm/cgroup.conf`

4. In terminal, do:

```{bash}
sudo tee /etc/slurm/cgroup_allowed_devices_file.conf >/dev/null <<'EOF'
/dev/null
/dev/zero
/dev/urandom
/dev/random
EOF
```
- This will need to updated later if nvidia devices are added

5. Restart the system
- Only do with no users logged in and jobs running!

```{bash}
sudo systemctl restart slurmctld slurmd
```

6. Check if it worked

- Once restarted, the system will work with cgroup. So in System > Running Processes (Webmin), you should not see any CPU process above number of cores. The 5500% use of CPU should dissapear. To fix de limits put at the script for instance --cpus-per-task=4 (4, 10, whatever) or do it by user with MaxCPUsPerUser, GrpCPUs etc.

