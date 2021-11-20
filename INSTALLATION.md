# Installation

## Pre-requisites

### Configure network

If you use an ethernet connection, you do not need to do nothing, it works.

If you want to use a WI-FI connection, you should use `iwctl`, you can find all the 
information you need here: https://wiki.archlinux.org/title/Iwd

### Activate SSH

I like to install Archlinux using SSH, you can use this guide: https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH

Basically it is just `systemctl enable sshd && passwd`.

### Install ansible and git

In order to use the provisioner we need to install `ansible` `git` and `make`, as we are going
to use the provisioner to bootstrap the entire system.

```
mount -o remount,size=1G /run/archiso/cowspace
pacman -Sy --noconfirm ansible git make
```

The first command is needed because the root partition from live USB is just
256M which is not enough to install other dependencies.

## Disk layout and partitioning

Let me start by mentioning this guide: https://github.com/egara/arch-btrfs-installation
which is definetely my main source of truth for the following steps.

I want to use a BTRFS filesystem with the following layout:

```
nvme0n1 (Volume)
|
|
- @ (Subvolume - It will be the current /)
- @home (Subvolume - it will be the current /home)
- @snapshots (Subvolume -  It will contain the root snaphosts)
- @home.snapshots (Subvolume -  It will contain the home directories snaphosts)
```

I don't know if this layout is the best choice, but AFAIK this is the simplest
way to start and most compatible layout with tools like snapper or timeshift.

What i've used as a reference:

* https://forum.manjaro.org/t/default-btrfs-mount-options-and-subvolume-layout/43250/33
* https://www.reddit.com/r/archlinux/comments/fkcamq/noob_btrfs_subvolume_layout_help/fks5mph/?utm_source=share&utm_medium=web2x&context=3
* https://btrfs.wiki.kernel.org/index.php/SysadminGuide#Layout
* https://www.jwillikers.com/btrfs-layout
* https://en.opensuse.org/SDB:BTRFS#Default_Subvolumes
* https://wiki.archlinux.org/title/User:M0p/LUKS_Root_on_Btrfs

This is the most flexible way to keep the things well separated and giving me the chance
to automatically snapshot the root or home volumes separately and using `grub-btrfs`
to automatically from snapshots (TO BE TESTED).

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

Export the following variables, that we'll be used by next installation steps:

```shell
export UEFI_PARTITION=/dev/nvme0n1p1
export ROOT_PARTITION=/dev/nvme0n1p4
export SWAP_PARTITION=/dev/nvme0n1p5
export LUKS_PARTITION=/dev/mapper/cryptroot
```

Just to be sure about the partitions, you can always run `lsblk` to see partitions per disk.

> ***VERY IMPORTANT***: From now on i'll use `/dev/nvme0n1p4` for the root partition and `/dev/nvme0n1p5` and `/dev/nvme0n1p5` for the swap one. Adjust them according to your setup.

### ROOT LUKS encryption (optional)

1. Archlinux wiki: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition
2. Unofficial guide: https://blog.bespinian.io/posts/installing-arch-linux-on-uefi-with-full-disk-encryption/

We are going to encrypt the entire root filesystem:

1. Run `cryptsetup -y -v luksFormat ${ROOT_PARTITION}` and then type `YES` and the new encryption password to encrypt the root partition
1. Run `cryptsetup open ${ROOT_PARTITION} cryptroot` to open the encrypted partition

### UEFI Partition

> ***VERY IMPORTANT***: This step is only required when creating a new EFI partition, if you are installing
beside another Linux distribution or Windows and you already have an EFI partition, you can skip it.

Run this command: `mkfs.fat -F32 ${UEFI_PARTITION}`

### Swap partition

The swap partition once formatted and activated will be automatically mounted by `systemd` on the live system:

 ```
 mkswap ${SWAP_PARTITION}
 swapon ${SWAP_PARTITION}
 ```

### BTRFS Setup with encryption

We are going to create btrfs volumes and subvolumes:

```
mkfs.btrfs -L arch ${LUKS_PARTITION}
mount ${LUKS_PARTITION} /mnt

# This is a layout made to be compatible with timeshift and similare to the Manjaro one (https://www.reddit.com/r/archlinux/comments/fkcamq/comment/fks5mph/?utm_source=share&utm_medium=web2x&context=3)
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@home.snapshots
```

Next, create all the directories needed and mount all the partitions (/boot/efi included) in order to start the installation:

```
umount /mnt

# Mount root and create default directories.
mount -o noatime,compress=zstd,subvol=@ ${LUKS_PARTITION} /mnt

# Mount boot partition.
mkdir -p /mnt/boot/uefi
mount ${UEFI_PARTITION} /mnt/boot

# Mount home.
mkdir -p /mnt/home
mount -o noatime,compress=zstd,subvol=@home ${LUKS_PARTITION} /mnt/home

# Mount all subvolumes just for convenience.
mkdir -p /mnt/mnt/allvolumes
mount -o noatime,compress=zstd,subvol=/ ${LUKS_PARTITION} /mnt/mnt/allvolumes
```

### BTRFS Setup without encryption

We are going to create btrfs volumes and subvolumes:

```
mkfs.btrfs -L arch ${ROOT_PARTITION}
mount ${ROOT_PARTITION} /mnt

# This is a layout made to be compatible with timeshift and similare to the Manjaro one (https://www.reddit.com/r/archlinux/comments/fkcamq/comment/fks5mph/?utm_source=share&utm_medium=web2x&context=3)
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@home.snapshots
```

Next, create all the directories needed and mount all the partitions (/boot/efi included) in order to start the installation:

```
umount /mnt

# Mount root and create default directories.
mount -o noatime,compress=zstd,subvol=@ ${ROOT_PARTITION} /mnt

# Mount boot partition.
mkdir -p /mnt/boot/uefi
mount ${UEFI_PARTITION} /mnt/boot/efi

# Mount home.
mkdir /mnt/home
mount -o noatime,compress=zstd,subvol=@home ${ROOT_PARTITION} /mnt/home

# Mount all subvolumes just for convenience.
mkdir -p /mnt/mnt/allvolumes
mount -o noatime,compress=zstd,subvol=/ ${ROOT_PARTITION} /mnt/mnt/allvolumes
```

> ***Please note*** that we are mounting btrfs with compression enabled to reduce writes (and ssd lifespan)
and performance [here](https://wiki.archlinux.org/title/btrfs#Compression) and [here](https://fedoraproject.org/wiki/Changes/BtrfsByDefault#Compression) some refs.

Done, we can now run the provisioner.

## Install Archlinux using the provisioner

This Archlinux provisioner is not inteded bo a replacement of the Archlinux installation wiki (https://wiki.archlinux.org/title/installation_guide),
which i higly reccomend to read it, it's a very precious source of information and best practices.

This installer is based on Ansible, and it's composed by several roles:

```
playbooks/roles
├── bootstrap
├── gnome
├── logitech
├── nvidia
├── packages
└── system
```

* `bootstrap`: Bootstrap the base system using pacstrap, configure locales, hostname, time and create the first sudoer user. 
* `system`: Configure system services (bluetooth, audio, printing) and install some system dependencies.
* `gnome`: Install and configure Gnome DE with some extra packages, extensions and some custom shortcuts.
* `logitech`: Configure Logitech MX Master 2s mices with logid+solaar.
* `nvidia`: Install Nvidia drivers with nvidia-prime autodetection in case of hybrid graphics system
* `packages`: Install all needed packages for development, multimedia, utilities and so on.

Start by cloning the repo:

```bash
cd /root
git clone https://github.com/paolomainardi/archlinux-ansible-provisioner.git provisioner
cd provisioner
```

Now you have to prepare your configuration file, which shuold reside under `./config`,
you can start with `./config/default.yaml.tpl` as an example.

You can find [here](./config/docs/configuration.md) the schema documentation.

```
cp config/default.yaml.tpl config/default.yaml
# --- EDIT THIS FILE ACCORDING TO YOUR NEEDS ---
vim config/default.yaml
CONFIG=./config/default.yaml make system
make
```

> ***VERY IMPORTANT***: Ansible will use the default values specified by the roles, you should change it or pass it, at the moment 
> the later option is not supported by the Makefile.

### Configure GRUB to the encrypted disk (only for encrypted installations)

1. Run `vim /mnt/etc/mkinitcpio.conf` and, to the `HOOKS` array, add `keyboard` between `autodetect` and `modconf` and add `encrypt` between `block` and `filesystems`
   * It should look like this: `HOOKS=(base udev autodetect keyboard modconf block encrypt filesystems keyboard fsck)`
1. Run `arch-chroot /mnt mkinitcpio -P`
1. Run `blkid -s UUID -o value ${ROOT_PARTITION}` to get the `UUID` of the device 
1. Run `vim /mnt/etc/default/grub` and set `GRUB_CMDLINE_LINUX="cryptdevice=UUID=xxxx:cryptroot /dev/mapper/cryptroot"` while replacing `xxxx` with the `UUID` of the `$ROOT_PARTITION` device to tell GRUB about our encrypted file system.
   * It should look like this: `GRUB_CMDLINE_LINUX="cryptdevice=UUID=1aa4277d-f942-49d1-b5b4-74641941dd9c:cryptroot /dev/mapper/cryptroot"`

#### Set the user password

Now that the process if finished you can setup the password for the created user:

```
arch-chroot /mnt passwd <your-user>
```

### Install GRUB with encryption

1. Run `CONFIG=./config/default.yaml make install-grub-with-encryption`

### Install GRUB without encryption

1. Run `CONFIG=./config/default.yaml make install-grub-no-encryption`

Finished, restart your system and enjoy your brand new Archlinux installation.
