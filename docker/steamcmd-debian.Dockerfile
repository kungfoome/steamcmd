ARG BASE_IMAGE="ghcr.io/linuxserver/baseimage-debian:amd64-bullseye-7ee3a86f-ls22"
ARG BUILDER_IMAGE="ghcr.io/linuxserver/baseimage-debian:amd64-bullseye-7ee3a86f-ls22"
ARG RCON_VERSION="latest"

######## BUILDER ########

# Set the base image
FROM ${BUILDER_IMAGE} as builder

ENV WORKDIR=/app

RUN mkdir -p "${WORKDIR}/steam"

# Set working directory
WORKDIR "${WORKDIR}/steam"

# Update the repository and install SteamCMD
ARG DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture i386 \
    && apt-get update && apt-get autoremove -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        locales \
        lib32gcc-s1 \
        curl \
        jq \
        git \
    && apt-get remove --purge --auto-remove -y \
    && rm -rf /var/lib/apt/lists/*

# Add unicode support
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8'
ENV LANGUAGE='en_US.UTF-8'

RUN curl -sL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zx

# Update SteamCMD and verify latest version
RUN ./steamcmd.sh +quit | tee steamcmd_update.log \
    && cat steamcmd_update.log | grep -wo version.* | cut -d' ' -f2 > steamcmd_version.txt

COPY build_files /build_files

WORKDIR ${WORKDIR}

ARG RCON_VERSION
RUN /build_files/get_rcon.sh

RUN git clone https://github.com/albfan/bash-ini-parser.git

######## INSTALL ########

FROM ${BASE_IMAGE}

# Copy required files from builder
COPY --from=builder /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /app/steam/linux32/libstdc++.so.6 /lib/
COPY --from=builder /usr/lib32/ /usr/lib32/
COPY --from=builder /lib32/ /lib32/
COPY --from=builder /lib/ld-linux.so.2 /lib/ld-linux.so.2

# Copy steamcmd files from builder
COPY --from=builder --chown=abc:abc /app/steam /app/steam
COPY --from=builder --chown=abc:abc /app/rcon/rcon /app/rcon/rcon.yaml /app/rcon/
COPY --from=builder --chown=abc:abc /app/bash-ini-parser/bash-ini-parser /app/includes/bash-ini-parser

ENV PATH="/app/steam:${PATH}"

RUN chmod -R 777 /app
