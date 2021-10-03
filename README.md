# Archlinux ansible provisioner

This is a guide and a set of ansible roles to provision an Ansible
installation, this is made for personal use, use it at your own risk.

## Pre-requisites (manual steps)


#### Activate SSH

I like to install Archlinux using SSH, you can use this guide: https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH

#### Install ansible and git

In order to use the provisioner we need to install `ansible` and `git`, as we are going 
to use the provisioner to bootstrap the entire system.

```
mount -o remount,size=1G /run/archiso/cowspace
pacman -Sy --noconfirm ansible git
```

The first command is needed because the root partition from live USB is just
256M which is not enough to install other dependencies.

### Disk layout and partitioning

I want to use a BTRFS filesystem with the following layout:

```
nvme0n1 (Volume)
|
|
- _active (Subvolume)
|    |
|    - root (Subvolume - It will be the current /)
|    - home (Subvolume - it will be the current /home)
|
- _snapshots (Subvolume -  It will contain all the snapshots which are subvolumes too)
```
This is the most flexible way to keep the things well separated and giving me the chance
to automatically snapshot the root or home volumes separately and using `grub-btrfs` 
to automatically from snapshots (we'll see that later).

This is my current disk layout (using `cfdisk`):

```
                                                      Disk: /dev/nvme0n1
                                   Size: 931.51 GiB, 1000204886016 bytes, 1953525168 sectors
                                 Label: gpt, identifier: 4BAEBBEA-64DB-4DE6-A7F2-04E8972BF153

    Device                                Start                 End             Sectors           Size Type
>>  /dev/nvme0n1p1                         2048              487423              485376           237M EFI System              
    /dev/nvme0n1p2                       487424          1139156991          1138669568           543G Linux filesystem
    /dev/nvme0n1p3                   1139156992          1206265855            67108864            32G Linux swap
    /dev/nvme0n1p4                   1206265856          1881548799           675282944           322G Linux filesystem
    /dev/nvme0n1p5                   1881548800          1953525134            71976335          34.3G Linux swap
```

I will use `/dev/nvme0n1p4` and `/dev/nvme0n1p5` respectively for `/` and `swap` partitions.
The rest is a Ubuntu 20.04 LTS installation. I'll share the EFI partition too between the two distros.

#### BTRFS installation

We are going to create btrfs volumes and subvolumes:

```
mkfs.btrfs -L arch /dev/nvme0n1p4
mount /dev/nvme0n1p4 /mnt
cd /mnt
btrfs subvolume create _active
btrfs subvolume create _active/root
btrfs subvolume create _active/home
btrfs subvolume create _snapshots
```

Next, create all the directories needed and mount all the partitions (/boot/efi included) in order to start the installation:

```
cd ..
umount /mnt
mount -o compress=zstd,subvol=_active/root /dev/nvme0n1p4 /mnt
mkdir /mnt/{home,boot}
mkdir /mnt/boot/efi
mkdir -p /mnt/mnt/defvol
mount /dev/nvme0n1p1 /mnt/boot/efi
mount -o compress=zstd,subvol=_active/home /dev/nvme0n1p4 /mnt/home
mount -o compress=zstd,subvol=/ /dev/nvme0n1p4 /mnt/mnt/defvol
```
> Please note that we are mounting btrfs with compression enabled to reduce writes (and ssd lifespan) 
and performance [here](https://wiki.archlinux.org/title/btrfs#Compression) and [here](https://fedoraproject.org/wiki/Changes/BtrfsByDefault#Compression) some refs.

### 


