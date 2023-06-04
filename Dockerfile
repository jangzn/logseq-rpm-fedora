ARG ARCH
ARG FEDORA_VERSION
FROM docker.io/${ARCH}/fedora:${FEDORA_VERSION}
ENV ARCH ${ARCH}

# Install build dependencies
RUN dnf update -y && \
    dnf install -y make gcc g++ npm git rpm-build patch java && \
    dnf clean all

# Install Yarn
RUN npm install --global yarn

# Install Clojure
RUN curl -O https://download.clojure.org/install/linux-install-1.11.1.1273.sh && \
    chmod +x linux-install-1.11.1.1273.sh && \
    sudo ./linux-install-1.11.1.1273.sh

# Copy Patch File
COPY change_build.patch /root/logseq.patch

# Add entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]