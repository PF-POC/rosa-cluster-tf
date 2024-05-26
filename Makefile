
.PHONY: build
build:
	podman pull fedora:latest
	podman build -t localhost/mobb-pf:local .

.PHONY: run
run:
	podman run --rm -it --privileged \
		--volume ./:/root/work:z \
		--volume ./.local/.aws:/root/.aws \
		--volume ~/.ssh:/root/.ssh \
		localhost/mobb-pf:local bash
