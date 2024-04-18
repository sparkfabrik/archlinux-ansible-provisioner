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
- @snapshots (Subvolume -  It will contain the root snapshots)
- @home.snapshots (Subvolume -  It will contain the home directories snapshots)
```

I don't know if this layout is the best choice, but AFAIK this is the simplest
way to start and most compatible layout with tools like snapper or timeshift.

What i've used as a reference:

- https://forum.manjaro.org/t/default-btrfs-mount-options-and-subvolume-layout/43250/33
- https://www.reddit.com/r/archlinux/comments/fkcamq/noob_btrfs_subvolume_layout_help/fks5mph/?utm_source=share&utm_medium=web2x&context=3
- https://btrfs.wiki.kernel.org/index.php/SysadminGuide#Layout
- https://www.jwillikers.com/btrfs-layout
- https://en.opensuse.org/SDB:BTRFS#Default_Subvolumes
- https://wiki.archlinux.org/title/User:M0p/LUKS_Root_on_Btrfs

This is the most flexible way to keep the things well separated and giving me the chance
to automatically snapshot the root or home volumes separately and using `grub-btrfs`
to automatically from snapshots.

This is my current disk layout (using `cfdisk`):

```
                                                      Disk: /dev/nvme0n1
                                   Size: 931.51 GiB, 1000204886016 bytes, 1953525168 sectors
                                 Label: gpt, identifier: 4BAEBBEA-64DB-4DE6-A7F2-04E8972BF153

    Device                                Start                 End             Sectors           Size Type
    /dev/nvme0n1p1                         2048              487423              485376           237M EFI System
    /dev/nvme0n1p2                       487424          1139156991          1138669568           543G Linux filesystem
    /dev/nvme0n1p3                   1139156992          1206265855            67108864            32G Linux swap
```

I will use `/dev/nvme0n1p4` and `/dev/nvme0n1p5` respectively for `/` and `swap` partitions. **The swap partition is optional**, you can use a [Swap file](https://wiki.archlinux.org/title/Swap#Swap_file) if you want the ability to vary its size on-the-fly.
The rest is a Ubuntu 20.04 LTS installation. I'll share the EFI partition too between the two distros.

Export the following variables, that we'll be used by next installation steps:

```shell
export UEFI_PARTITION=/dev/nvme0n1p1
export ROOT_PARTITION=/dev/nvme0n1p2
export SWAP_PARTITION=/dev/nvme0n1p3
export LUKS_PARTITION=/dev/mapper/cryptroot
```

> **NOTE**: the `/dev/mapper/cryptroot` is the open decrypted partition. The `cryptsetup open` command described below will create the proper device and it will link it to this path. At the moment of the execution of the export commands the device is not present yet, so the `ls /dev/mapper` command will not show it.

Just to be sure about the partitions, you can always run `lsblk` to see partitions per disk.

> **_VERY IMPORTANT_**: From now on i'll use `/dev/nvme0n1p2` for the root partition and `/dev/nvme0n1p3` for the swap one.
> Adjust them according to your setup.

### Windows dual boot

If you are going to install Archlinux beside Windows, you should shrink the Windows partition to make space for the new installation. You can do this directly from Windows 11 Disk Management tool and **without the need of disabling the BitLocker encryption**.

As described [here](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot), you must disable Secure Boot in the UEFI settings. After this process, you have to recover the Windows BitLocker encryption using the recovery key. The recovery process of the Windows BitLocker encryption has to be re-taken after the installation of Archlinux, booting into Windows using GRUB. If you bootstrap Windows using a Microsoft account, you can find the recovery key in the Microsoft account page [here](https://account.microsoft.com/devices/recoverykey).

Just for reference, the following is the disk layout of a dual boot system:

```bash
Device              Start        End    Sectors   Size Type
/dev/nvme0n1p1       2048     534527     532480   260M EFI System
/dev/nvme0n1p2     534528     567295      32768    16M Microsoft reserved
/dev/nvme0n1p3     567296  315140095  314572800   150G Microsoft basic data
/dev/nvme0n1p4 1996312576 2000408575    4096000     2G Windows recovery environment
/dev/nvme0n1p5  315140096  315652095     512000   250M EFI System
/dev/nvme0n1p6  315652096 1996312575 1680660480 801.4G Linux filesystem
```

The `/dev/nvme0n1p5` is is the EFI partition for the Archlinux installation, and the `/dev/nvme0n1p6` is the encrypted partition that hosts the btrfs filesystem and contains all the subvolumes. **In this case, the swap partition is not present, and the swap file is used instead**.

### Hibernation

Suspend to disk (aka hibernate) feature is a process where the contents of RAM are written to the swap partition (or file) before the system is powered off. It saves the machine's state into swap space and completely powers off the machine. When the machine is powered on, the state is restored. Until then, there is zero power consumption. [Here](https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation) you can find more information about hibernation.

#### Swap partition

System will be configured to use the the partition labeled as `swap` as the swap partition.
You must make sure to add this label to the swap partition, it should be like this:

```
❯ sudo gdisk -l /dev/nvme0n1
GPT fdisk (gdisk) version 1.0.9.1

Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048         2099199   1024.0 MiB  EF00
   2         2099200      1849670069   881.0 GiB   8300
   3      1849670070      1953525134   49.5 GiB    8200  swap <----- THIS IS THE LABEL
```

If you don't have it, you can add it with the following commands:

```shell
❯ sudo gdisk /dev/nvme0n1
GPT fdisk (gdisk) version 1.0.9.1

Partition table scan:
  MBR: protective
  BSD: not present
  APM: not present
  GPT: present

Found valid GPT with protective MBR; using GPT.

Command (? for help): c
Partition number (1-3): 3
Enter name: swap

Command (? for help): w

Final checks complete. About to write GPT data. THIS WILL OVERWRITE EXISTING
PARTITIONS!!

Do you want to proceed? (Y/N): y
OK; writing new GUID partition table (GPT) to /dev/nvme0n1.
Warning: The kernel is still using the old partition table.
The new table will be used at the next reboot or after you
run partprobe(8) or kpartx(8)
The operation has completed successfully.

❯ sudo partprobe

❯ blkid | grep swap
/dev/nvme0n1p3: UUID="29ddcc21-8a13-49b5-8dc1-767ff387b15a" TYPE="swap" PARTLABEL="swap" PARTUUID="30b47a33-c1b3-924d-9c1c-0adff8f018fd"
```

#### Swap file

If you decide to use a swap file instead of a swap partition, you have to configure some additional parameters to make hibernation work. You can find the information about configuring the swap file offset [here](https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Acquire_swap_file_offset).

In this provisioner, you can configure `swapfile.enabled` and `swapfile.configure_hibernate` to `true` and all the other parameters according to your needs in the `config/default.yaml` file. The ansible role will take care of creating the swap file and configuring the system to use it.

### ROOT LUKS encryption (optional)

1. Archlinux wiki: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition
2. Unofficial guide: https://blog.bespinian.io/posts/installing-arch-linux-on-uefi-with-full-disk-encryption/

We are going to encrypt the entire root filesystem:

1. Run `cryptsetup -y -v --pbkdf=pbkdf2 luksFormat ${ROOT_PARTITION}` and then type `YES` and the new encryption password to encrypt the root partition
1. Run `cryptsetup open ${ROOT_PARTITION} cryptroot` to open the encrypted partition

### UEFI Partition

> **_VERY IMPORTANT_**: This step is only required when creating a new EFI partition, if you are installing
> beside another Linux distribution or Windows and you already have an EFI partition, you can skip it.

Run this command: `mkfs.fat -F32 ${UEFI_PARTITION}`

### Swap partition

The swap partition once formatted and activated will be automatically mounted by `systemd` on the live system:

```
mkswap ${SWAP_PARTITION}
swapon ${SWAP_PARTITION}
```

### BTRFS Setup with encryption (STRONGLY RECOMMENDED)

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
mkdir -p /mnt/boot
mount ${UEFI_PARTITION} /mnt/boot

# Mount home.
mkdir -p /mnt/home
mount -o noatime,compress=zstd,subvol=@home ${LUKS_PARTITION} /mnt/home

# Mount all subvolumes just for convenience.
mkdir -p /mnt/mnt/allvolumes
mount -o noatime,compress=zstd,subvol=/ ${LUKS_PARTITION} /mnt/mnt/allvolumes
```

### BTRFS Setup without encryption (DISCOURAGED)

> **NOTE**: if you have installed the system with encryption, you can skip this step and go to [Install Archlinux using the provisioner](#install-archlinux-using-the-provisioner).

⚠️ **Please avoid this kind of configuration, it's not secure and it's not recommended. Use it only for testing purposes.** ⚠️

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
mkdir -p /mnt/boot/efi
mount ${UEFI_PARTITION} /mnt/boot/efi

# Mount home.
mkdir /mnt/home
mount -o noatime,compress=zstd,subvol=@home ${ROOT_PARTITION} /mnt/home

# Mount all subvolumes just for convenience.
mkdir -p /mnt/mnt/allvolumes
mount -o noatime,compress=zstd,subvol=/ ${ROOT_PARTITION} /mnt/mnt/allvolumes
```

> **_Please note_** that we are mounting btrfs with compression enabled to reduce writes (and ssd lifespan)
> and performance [here](https://wiki.archlinux.org/title/btrfs#Compression) and [here](https://fedoraproject.org/wiki/Changes/BtrfsByDefault#Compression) some refs.

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

- `bootstrap`: Bootstrap the base system using pacstrap, configure locales, hostname, time and create the first sudoer user.
- `system`: Configure system services (bluetooth, audio, printing) and install some system dependencies.
- `gnome`: Install and configure Gnome DE with some extra packages, extensions and some custom shortcuts.
- `logitech`: Configure Logitech MX Master 2s mices with logid+solaar.
- `nvidia`: Install Nvidia drivers with nvidia-prime autodetection in case of hybrid graphics system
- `packages`: Install all needed packages for development, multimedia, utilities and so on.

Start by cloning the repo:

```bash
cd /root
git clone https://github.com/sparkfabrik/archlinux-ansible-provisioner.git provisioner
cd provisioner
```

Now you have to prepare your configuration file, which shuold reside under `./config`,
you can start with `./config/default.yaml.tpl` as an example.

You can find [here](./config/docs/configuration.md) the schema documentation.

```
cp config/default.yaml.tpl config/default.yaml
# --- EDIT THIS FILE ACCORDING TO YOUR NEEDS ---
vim config/default.yaml
# Install the base Arch Linux system using `pacstrap` and configure some basic system settings.
CONFIG=./config/default.yaml make bootstrap
# Install all the packages and configure the system.
CONFIG=./config/default.yaml make system
```

> **_VERY IMPORTANT_**: Ansible will use the default values specified by the roles, you should change it or pass it, at the moment
> the later option is not supported by the Makefile.

### Configure GRUB for the encrypted disk (only for encrypted installations)

The following steps are needed to configure GRUB to be able to boot from an encrypted disk:

1. Run `vim /mnt/etc/mkinitcpio.conf` and, to the `HOOKS` array, add `keyboard` between `autodetect` and `modconf` and add `encrypt` between `block` and `filesystems`
   - It should look like this: `HOOKS=(base udev autodetect keyboard modconf block encrypt filesystems keyboard fsck)`
1. Run `arch-chroot /mnt mkinitcpio -P`
1. Run `blkid -s UUID -o value ${ROOT_PARTITION}` to get the `UUID` of the device
1. Run `vim /mnt/etc/default/grub` and set `GRUB_CMDLINE_LINUX="cryptdevice=UUID=xxxx:cryptroot /dev/mapper/cryptroot"` while replacing `xxxx` with the `UUID` of the `$ROOT_PARTITION` device to tell GRUB about our encrypted file system.
   - It should look like this: `GRUB_CMDLINE_LINUX="cryptdevice=UUID=1aa4277d-f942-49d1-b5b4-74641941dd9c:cryptroot /dev/mapper/cryptroot"`

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
