# syntax=docker/dockerfile:1

FROM ghcr.io/chukysoria/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG JELLYFIN_RELEASE
LABEL build_version="chukyserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

RUN \
  echo "**** install jellyfin *****" && \
  DISTRO="$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release )" && \
  CODENAME="$( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release )" && \
  curl -fsSL https://repo.jellyfin.org/${DISTRO}/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg \
  echo " \
  Types: deb \
  URIs: https://repo.jellyfin.org/${DISTRO} \
  Suites: ${CODENAME} \
  Components: main \
  Architectures: $( dpkg --print-architecture ) \
  Signed-By: /etc/apt/keyrings/jellyfin.gpg \
  " >> /etc/apt/sources.list.d/jellyfin.sources && \
  if [ -z ${JELLYFIN_RELEASE+x} ]; then \
    JELLYFIN_RELEASE=$(curl -sX GET https://repo.jellyfin.org/ubuntu/dists/jammy/main/binary-armhf/Packages |grep -A 7 -m 1 'Package: jellyfin-server' | awk -F ': ' '/Version/{print $2;exit}'); \
  fi && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    at \
    jellyfin-server=${JELLYFIN_RELEASE} \
    jellyfin-ffmpeg5 \
    jellyfin-web \
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
EXPOSE 8096 8920
VOLUME /config
