
init:
	ansible-galaxy collection install -r requirements.yml

bootstrap: init
	ansible-playbook playbooks/bootstrap.yml -i localhost, -c local

base: bootstrap
	mkdir -p /mnt/root/provisioner
	cp -aR . /mnt/root/provisioner
	arch-chroot /mnt ansible-galaxy collection install -r /root/provisioner/requirements.yml
	arch-chroot /mnt ansible-playbook /root/provisioner/playbooks/system.yml -i localhost, -c local

install-grub:
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
	arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Archlinux

local-packages:
	sudo ansible-galaxy collection install -r ./requirements.yml
	sudo ansible-playbook ./playbooks/system.yml -i localhost, -c local