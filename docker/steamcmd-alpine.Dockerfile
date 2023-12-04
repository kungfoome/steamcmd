ARG BASE_IMAGE="ghcr.io/linuxserver/baseimage-alpine:3.18"
ARG BUILDER_IMAGE="ubuntu:22.04"
ARG RCON_VERSION="latest"

######## BUILDER ########

# Set the base image
FROM ${BUILDER_IMAGE} as builder

ENV WORKDIR=/app
RUN mkdir -p "${WORKDIR}"

# Set working directory
WORKDIR ${WORKDIR}

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
    && apt-get remove --purge --auto-remove -y \
    && rm -rf /var/lib/apt/lists/*

# Add unicode support
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8'
ENV LANGUAGE='en_US:en'

RUN curl -sL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zx

# Update SteamCMD and verify latest version
RUN ${WORKDIR}/steamcmd.sh +quit

COPY build_files /build_files

ARG RCON_VERSION
RUN /build_files/get_rcon.sh

######## INSTALL ########

FROM ${BASE_IMAGE}

RUN apk add -U --upgrade --no-cache bash musl musl-utils musl-locales tzdata \
 && rm -rf /var/cache/apk/*

# Copy required files from builder
COPY --from=builder /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /app/linux32/libstdc++.so.6 /lib/
COPY --from=builder /usr/lib32 /lib/

ENV STEAMROOT="/app/steam"
ENV PATH="${STEAMROOT}:${PATH}"

# Copy steamcmd files from builder
COPY --from=builder --chown=abc:abc /app/steamcmd.sh  /app/steam/
COPY --from=builder --chown=abc:abc /app/linux32/steamcmd /app/steam/linux32/

COPY --from=builder --chown=abc:abc /app/rcon/rcon /app/rcon/rcon.yaml /app/rcon/

RUN chmod -R 777 /app
