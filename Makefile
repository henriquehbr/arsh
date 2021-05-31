clean-iso:
	sudo rm -rf arshiso/{out,work}

update-iso-script:
	cp arsh arshiso/airootfs/root

iso: clean-iso update-iso-script
	sudo mkarchiso -v -w archiso -o archiso arshiso
