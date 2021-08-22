lint:
	shellcheck ar.sh

clean-iso:
	doas rm -rf arshiso/out arshiso/work

update-iso-script:
	cp ar.sh arshiso/airootfs/root

iso: clean-iso update-iso-script
	doas mkarchiso -v -w arshiso/work -o arshiso/out arshiso
