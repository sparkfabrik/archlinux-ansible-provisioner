ifndef CONFIG
	$(error "You must pass a config yaml file (see ./config/*.yaml for examples")
endif

init:
	ansible-galaxy collection install -r requirements.yml

bootstrap: init
	ansible-playbook playbooks/bootstrap.yml -i localhost, -c local --extra-vars "@$(CONFIG)"

system: bootstrap
	mkdir -p /mnt/root/provisioner
	cp -aR . /mnt/root/provisioner
	arch-chroot /mnt ansible-galaxy collection install -r /root/provisioner/requirements.yml
	arch-chroot /mnt ansible-playbook /root/provisioner/playbooks/system.yml -i localhost, -c local --extra-vars "@/root/provisioner/$(CONFIG)"

install-grub-with-encryption:
	arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Archlinux
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

install-grub-no-encryption:
	arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Archlinux
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

local-install:
	sudo ansible-galaxy collection install -r ./requirements.yml
	sudo ansible-playbook ./playbooks/system.yml -i localhost, -c local 

# Example of usage: sudo TAGS=your-tags CONFIG=./config/your-config.yaml make local-install-tags
local-install-tags:
	sudo ansible-playbook ./playbooks/system.yml -i localhost, -c local --tags $(TAGS) --extra-vars "@$(CONFIG)"
