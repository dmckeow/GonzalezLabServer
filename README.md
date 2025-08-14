# GonzalezLabServer
Management of the SLURM computing cluster of the Gonzalez lab at IBB

## Information

**Server IP**: 161.111.135.76  
**Filesystem**:  

```{bash}
gonzalezlab@slurm:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2       7,0T   15G  6,6T   1% /
/dev/sda1       1,1G  6,1M  1,1G   1% /boot/efi
/dev/sdb1        66T   24K   62T   1% /hddraid5
/dev/sdc1        21T   24K   20T   1% /ssdraid0
```

## To do

### Short term


#### Security
* ssh-key login setup


#### Setup partitions (i.e. job queues)
* Group wants an infinite queue?
* We are 1 node, X cores, X CPUs
* Default partition
    * This is where users login, and where jobs without specified qos go

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

#### Server status reporting
* How to create an easily updated overview report that can be viewed here or in the repo

---
#### Welcome message
* Key info and links to documentation
* ASCII art and server name

#### Backup setup
* Rsync - how do we confirm backup is done?
* Guidance for users to keep their own backups as well

#### Documentation for users
* Detailing the server setup, what partitions there are, how backups happen, etc

---

## Done

#### Setup user location
* Admin acccount(s) should be in /home - the smaller volume
* The user accounts should be in the larger storage

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

How to move an account (NOTE: this was done before anyone had actually used their accounts - with home directories containing real data we would take a more careful approach to moving and deleting the old home directories):

```{bash}
UserToMove="dmckeown"
NewLocation="/hddraid5/home"

sudo mkdir -p ${NewLocation} ${NewLocation}/${UserToMove}

# Move and check the system home (does not move files)
sudo usermod --move-home --home ${NewLocation}/${UserToMove} ${UserToMove}
grep ${UserToMove} /etc/passwd

# copy everything from the old home
sudo rsync -a /home/${UserToMove}/ ${NewLocation}/${UserToMove}/

# fix ownership
sudo chown -R ${UserToMove}:${UserToMove} ${NewLocation}/${UserToMove}
sudo setfacl -d -m u::rwx,g::r-x,o::--- ${NewLocation}/${UserToMove}

# Delete the old home dir - for a user with data we would check carefully that the rsync worked
sudo rm -fr /home/${UserToMove}/

```

##### Making new users in future

We made our first accounts with `sudo adduser dmckeown`, but we need to specify `home`.  
I made an account like this and log in worked:

```{bash}
NewUser="dmckeown"
sudo adduser --home /hddraid5/${NewUser} ${NewUser}
sudo setfacl -d -m u::rwx,g::r-x,o::--- /hddraid5/${NewUser}
```

#### Setup user permissions
* Users should not have /home permissions
    * Classic linux controls ok, maybe use ACL for an easier approach

I decided to go with `acl` as it is simpler to use than classic linux commands - I installed it as the admin with `sudo apt install acl`

* Checking the current permissions - they seem right:
  * Users do not have write permissions in the root
  * Users do not have read,write,execute for each other's home directories
  * root begins everywhere outside of the user directories

```{bash}
gonzalezlab@slurm:/home$ getfacl /
getfacl: Removing leading '/' from absolute path names
# file: .
# owner: root
# group: root
user::rwx
group::r-x
other::r-x

gonzalezlab@slurm:/home$ getfacl ../hddraid5/
# file: ../hddraid5/
# owner: root
# group: root
user::rwx
group::r-x
other::r-x

gonzalezlab@slurm:/home$ getfacl ../hddraid5/dmckeown/
# file: ../hddraid5/dmckeown/
# owner: dmckeown
# group: dmckeown
user::rwx
group::r-x
other::---

```

Then I logged into my user to test:
  * Can I write outside my home folder? **Nope**
  * If I make a folder in my home, does it inherit the same permissions?
    * **No** - the subfolder has write permissions for the group, and read/execute for other

```{bash}
gonzalezlab@slurm:/$ sudo getfacl hddraid5/dmckeown
# file: hddraid5/dmckeown
# owner: dmckeown
# group: dmckeown
user::rwx
group::r-x
other::---

gonzalezlab@slurm:/$ sudo getfacl hddraid5/dmckeown/test
[sudo] password for gonzalezlab: 
# file: hddraid5/dmckeown/test
# owner: dmckeown
# group: dmckeown
user::rwx
group::rwx
other::r-x

```
This can be addressed by setting the default (-d) to the same as the top folder - we need to do this for each new user
```
sudo setfacl -d -m u::rwx,g::r-x,o::--- /hddraid5/dmckeown

# Now the recreated folder has the same permssions:

gonzalezlab@slurm:/$ sudo getfacl /hddraid5/dmckeown/test
getfacl: Removing leading '/' from absolute path names
# file: hddraid5/dmckeown/test
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