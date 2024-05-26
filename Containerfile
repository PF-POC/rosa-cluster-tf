FROM fedora:latest as base

# Comment below FROM to build from scratch
FROM localhost/mobb-pf:local
WORKDIR /root
RUN dnf -y update \
    && dnf -y install dnf-plugins-core git openssl openssh openssh-clients vim nano jq \
        tar wget python3 python3-pip \
        rsync make bash-completion bind-utils \
    && dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo \
    && dnf -y install terraform helm awscli2 \
    && dnf -y clean all

## FROM ocm-container ##
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /root/.fzf || /bin/true; \
      /root/.fzf/install --all

ARG BACKPLANE_TOOLS_VERSION="tags/v1.1.0"
ENV BACKPLANE_TOOLS_URL_SLUG="openshift/backplane-tools"
ENV BACKPLANE_TOOLS_URL="https://api.github.com/repos/${BACKPLANE_TOOLS_URL_SLUG}/releases/${BACKPLANE_TOOLS_VERSION}"
RUN mkdir -p /backplane-tools
WORKDIR /backplane-tools

# Download the checksum
RUN /bin/bash -c "curl -sSLf $(curl -sSLf ${BACKPLANE_TOOLS_URL} -o - | jq -r '.assets[] | select(.name|test("checksums.txt")) | .browser_download_url') -o checksums.txt"

# Download amd64 binary
RUN /bin/bash -c "curl -sSLf -O $(curl -sSLf ${BACKPLANE_TOOLS_URL} -o - | jq -r '.assets[] | select(.name|test("linux_amd64")) | .browser_download_url') "

# Extract
RUN tar --extract --gunzip --no-same-owner --directory "/usr/local/bin"  --file *.tar.gz

# Install all using backplane-tools
ENV PATH "$PATH:/root/.local/bin/backplane/latest"
RUN /usr/local/bin/backplane-tools install all
## END FROM ocm-container ##

WORKDIR /root
