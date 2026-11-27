# Troubleshooting

## Linux not booting

If you have troubles booting the Arch Linux OS, the first action to take is to use a "live" [USB media](https://wiki.archlinux.org/title/USB_flash_installation_medium) and boot from such media.

### Accessing encrypted disk when booting from live media

If you have followed [installation instructions](INSTALLATION.md) and you have a BTRFS setup with the proposed layout and an encrypted root partition, you can follow along this section in order to mount your encrypted file system. If you made changes to the proposed layout, you should reflect those changes into the following commands.

All the programs you need to decrypt and mount the partitions are already installed in the Arch Live USB distribution, so you don't need an Internet connection to install them.

```shell
export UEFI_PARTITION=/dev/nvme0n1p1
export ROOT_PARTITION=/dev/nvme0n1p2
export SWAP_PARTITION=/dev/nvme0n1p3
export LUKS_PARTITION=/dev/mapper/cryptroot
```

Lets's decrypt the data and mount all the available partitions.

```shell
# Access the encrypted partition, your encryption password will be asked
cryptsetup open ${ROOT_PARTITION} cryptroot

umount /mnt

# Mount root and create default directories.
mount -o noatime,compress=zstd,subvol=@ ${LUKS_PARTITION} /mnt

# Mount boot partition.
mkdir -p /mnt/boot
mount ${UEFI_PARTITION} /mnt/boot

# Mount boot partition like this when using this provisioner without encryption.
# mkdir -p /mnt/boot/efi
# mount ${UEFI_PARTITION} /mnt/boot/efi

# Mount home.
mkdir -p /mnt/home
mount -o noatime,compress=zstd,subvol=@home ${LUKS_PARTITION} /mnt/home

# Mount all subvolumes just for convenience.
mkdir -p /mnt/mnt/allvolumes
mount -o noatime,compress=zstd,subvol=/ ${LUKS_PARTITION} /mnt/mnt/allvolumes
```

Now you can access your root partition at `/mnt`

### Reinstall GRUB

Sometimes, booting troubles come from a corrupted GRUB installation or configuration. Once you have gained access to you root partition, use these commands to reinstall grub, then try to restart the PC.

```shell
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Archlinux
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
```
