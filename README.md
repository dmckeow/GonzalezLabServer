
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

## Partially Done

#### User storage quota

* Our volume hddraid5 is ext4, so we use `quota` for it
```{bash}
dmckeown@slurm:~$ df -T /hddraid5/
Filesystem     Type   1K-blocks   Used   Available Use% Mounted on
/dev/sdb1      ext4 70029236528 616228 66513095692   1% /hddraid5
```
* Installed `quota`

* Are there any quotas already set? **No**
```{bash}
repquota -a
```

```{bash}
sudo vim /etc/fstab
# then added ',usrquota':
# /dev/disk/by-uuid/12825e18-edf6-4a37-8f1c-74943284b5ae /hddraid5 ext4 defaults,usrquota 0 1
# /dev/disk/by-uuid/12825e18-edf6-4a37-8f1c-74943284b5ae /hddraid5 ext4 defaults 0 1


sudo mount -o remount /hddraid5

sudo quotaon /hddraid5

# Now we have turned quota on, but it is not set to anything
gonzalezlab@slurm:/$ sudo repquota -s -a
*** Report for user quotas on device /dev/sdb1
Block grace time: 7days; Inode grace time: 7days
                        Space limits                File limits
User            used    soft    hard  grace    used  soft  hard  grace
----------------------------------------------------------------------
root      --     24K      0K      0K              3     0     0       
mcoronado --     24K      0K      0K              7     0     0       
gabmm     --     24K      0K      0K              7     0     0       
dmckeown  --    602M      0K      0K           4404     0     0       
fradest   --     24K      0K      0K              7     0     0       
gsabaris  --     16K      0K      0K              4     0     0       

# Setting quotas for users
# The four numbers are limits for soft space, hard space, soft file numbers, hard file numbers
# Soft limits can be surpassed but give a warning, hard limits cannot be passed
# 0 means no limit

sudo setquota -u dmckeown 2147483647 0 0 0 /hddraid5

# You can use edquota -u dmckeown to change these later


# So the quota measures storage in Blocks, and you can check what your system block size is:
sudo tune2fs -l /dev/sdb1 | grep 'Block size'

gonzalezlab@slurm:/$ sudo repquota -s -a
*** Report for user quotas on device /dev/sdb1
Block grace time: 7days; Inode grace time: 7days
                        Space limits                File limits
User            used    soft    hard  grace    used  soft  hard  grace
----------------------------------------------------------------------
root      --     24K      0K      0K              3     0     0       
mcoronado --     24K      0K      0K              7     0     0       
gabmm     --     24K      0K      0K              7     0     0       
dmckeown  --    602M   2048G      0K           4404     0     0       
fradest   --     24K      0K      0K              7     0     0       
gsabaris  --     16K      0K      0K              4     0     0      


```
* The system block size must be changed to allow a larger quota, e.g. I cannot set a limit of 20 TB:

```{bash}
gonzalezlab@slurm:/$ sudo setquota -u dmckeown 0 5368709120 0 0 /hddraid5
setquota: Cannot set quota for user 1003 from kernel on /dev/sdb1: Numerical result out of range
setquota: Cannot write quota for 1003 on /dev/sdb1: Numerical result out of range
```

##### Issue
So for now we have soft limits of 2 TB, but I can't find a way to set limits beyond that


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

##### Adding a new user

We made our first accounts with `sudo adduser dmckeown`, but we need to specify `home`.  
I made an account like this and log in worked:

```{bash}
NewUser="guest"
HomeDir="/hddraid5/home/${NewUser}"
ScratchDir="/ssdraid0/${NewUser}"

# Setup user and home dir, make scratch directory and set permissions
sudo adduser --home "$HomeDir" "$NewUser" # Just enter any password it will be changed later
sudo setfacl -m u::rwx,g::r-x,o::--- "$HomeDir"
sudo setfacl -d -m u::rwx,g::r-x,o::--- "$HomeDir"
sudo mkdir "$ScratchDir"
sudo chown "${NewUser}:${NewUser}" "$ScratchDir"
sudo setfacl -m u::rwx,g::r-x,o::--- "$ScratchDir"
sudo setfacl -d -m u::rwx,g::r-x,o::--- "$ScratchDir"

# Check the permissions
getfacl $HomeDir
getfacl $ScratchDir

# Assign a temporary password
TempPass=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c8)
echo "${NewUser}:${TempPass}" | sudo chpasswd

echo "Temporary password for ${NewUser}: $TempPass"

```

- Send the temporary password to the new user - they can change it themselves with `passwd`

###### Notes on user setup
- I decided to go with `acl` as it is simpler to use than classic linux commands - I installed it as the admin with `sudo apt install acl`
- The `-d` (default) parameter for acl is essential as it means that when the user creates a file or folder, it will inherit the same permissions as the parent folder (their home)
- Setting up users this way achieves the following essential conditions:
  - Users do not have write permissions in the root
  - Root begins everywhere outside of the user directories
  - Users do not have read,write,execute for each other's home directories
- Checking permissions with `acl` with `getfacl <directory>`:

```{bash}
# Here we can see that root begins everywhere
getfacl /
getfacl: Removing leading '/' from absolute path names
# file: .
# owner: root
# group: root
user::rwx
group::r-x
other::r-x

getfacl ../hddraid5/
# file: ../hddraid5/
# owner: root
# group: root
user::rwx
group::r-x
other::r-x

# But a users home directory belongs to them
# Note that because user directory was setup with `-d` it has defaults

getfacl ../hddraid5/home/dmckeown/
# file: ../hddraid5/home/dmckeown/
# owner: dmckeown
# group: dmckeown
user::rwx
group::r-x
other::---
default:user::rwx
default:group::r-x
default:other::---
```

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