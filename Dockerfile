# syntax=docker/dockerfile:1
ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-ubuntu:jammy-v0.1.0

FROM ${BUILD_FROM} 

# set version label
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_EXT_RELEASE="10.8.11-1"
LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

RUN \
  echo "**** install jellyfin *****" && \
  mkdir -p /etc/apt/keyrings && \
  DISTRO="$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release )" && \
  CODENAME="$( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release )" && \
  curl -fsSL https://repo.jellyfin.org/${DISTRO}/jellyfin_team.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg && \
cat <<EOF | sudo tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/${DISTRO}
Suites: ${CODENAME}
Components: main
Architectures: $( dpkg --print-architecture )
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    at \
    jellyfin \
    jellyfin-ffmpeg5 \
    libfontconfig1 \
    libfreetype6 \
    libssl3 \
    mesa-va-drivers \
    xmlstarlet && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add local files
COPY root/ / 

# ports and volumes
EXPOSE 8096 8920 7359/udp 1090/udp
VOLUME /config
