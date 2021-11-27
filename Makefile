ifndef CONFIG
	CONFIG=./config/default.yaml
endif

DOCKER_IMAGE=paolomainardi/archlinux-provisioner-tools:latest

install-githooks:
	cp git-hooks/pre-commit .git/hooks/pre-commit

build-docker-tools:
	@docker build -q -t $(DOCKER_IMAGE) .

yaml-to-json: build-docker-tools
	docker run --rm -it -u $$UID -v $$PWD:$$PWD -w $$PWD $(DOCKER_IMAGE) js-yaml config/default.yaml.tpl

generate-json-schema-docs: build-docker-tools
	docker run --rm -it -u $$UID -v $$PWD:$$PWD -w $$PWD $(DOCKER_IMAGE) jsonschema2md -d config/schemas -o config/docs -x - -f yaml -n

validate-json-schema: build-docker-tools
	@echo "Validating configuration....."
	@docker run --rm -it -v $$PWD:$$PWD -w $$PWD $(DOCKER_IMAGE) ajv validate -s config/schemas/configuration.schema.yaml --strict false -d $(CONFIG)

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

local-install: validate-json-schema
	sudo ansible-galaxy collection install -r ./requirements.yml
	sudo ansible-playbook ./playbooks/system.yml -i localhost, -c local --extra-vars "@$(CONFIG)"

local-install-tags: validate-json-schema
	sudo ansible-playbook ./playbooks/system.yml -i localhost, -c local --tags $(TAGS) --extra-vars "@$(CONFIG)"

local-install-apps: validate-json-schema
	sudo ansible-playbook ./playbooks/system.yml -i localhost, -c local --tags packages --extra-vars "@$(CONFIG)"

regenerate-mkinitcpio-grub:
	sudo ansible-playbook ./playbooks/system.yml -i localhost, -c local --tags mkinitcpio --extra-vars "@$(CONFIG)"
	sudo mkinitcpio -P
	sudo grub-mkconfig -o /boot/grub/grub.cfg
