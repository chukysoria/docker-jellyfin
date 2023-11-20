# syntax=docker/dockerfile:1
ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-ubuntu:v0.2.1-jammy

FROM ${BUILD_FROM} 

# set version label
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_EXT_RELEASE="10.8.12-1"
LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

RUN <<DOCKER_RUN
  echo "**** install jellyfin *****"
  mkdir -p /etc/apt/keyrings
  DISTRO="$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release )"
  CODENAME="$( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release )"
  curl -fsSL https://repo.jellyfin.org/${DISTRO}/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg
  cat <<EOF | tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/${DISTRO}
Suites: ${CODENAME}
Components: main
Architectures: $( dpkg --print-architecture )
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
  apt-get update
  apt-get install -y --no-install-recommends \
    at=3.2.5-1ubuntu1 \
    jellyfin=${BUILD_EXT_RELEASE} \
    jellyfin-ffmpeg5 \
    libfontconfig1=2.13.1-4.2ubuntu5 \
    libfreetype6 \
    libssl3 \
    xmlstarlet=1.6.1-2.1 && \
  if [ "${BUILD_ARCH}" = "aarch64" ] || [ "${BUILD_ARCH}" = "armv7" ]; then
    echo "**** Instaling ARM packages ****"
    apt-get install -y --no-install-recommends \
      libomxil-bellagio0=0.9.3-7ubuntu1 \
      libomxil-bellagio-bin=0.9.3-7ubuntu1 \
      libraspberrypi0=0~20220324+gitc4fd1b8-0ubuntu1~22.04.1; \
  else \
    echo "**** Instaling AMD64 packages ****"
    apt-get install -y --no-install-recommends \
      mesa-va-drivers=23.0.4-0ubuntu1~22.04.1; \
  fi && \
  echo "**** cleanup ****"
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*
DOCKER_RUN

# add local files
COPY root/ / 

# ports and volumes
EXPOSE 8096 8920 7359/udp 1090/udp
VOLUME /config
