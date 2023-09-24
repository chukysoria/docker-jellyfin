# syntax=docker/dockerfile:1
ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-ubuntu:jammy-v0.1.0

FROM ${BUILD_FROM} 

# set version label
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
  curl -s https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | apt-key add - && \
  echo 'deb [arch=armhf] https://repo.jellyfin.org/ubuntu jammy main' > /etc/apt/sources.list.d/jellyfin.list && \
  if [ -z ${BUILD_EXT_RELEASE+x} ]; then \
    BUILD_EXT_RELEASE=$(curl -sX GET https://repo.jellyfin.org/ubuntu/dists/jammy/main/binary-armhf/Packages |grep -A 7 -m 1 'Package: jellyfin-server' | awk -F ': ' '/Version/{print $2;exit}'); \
  fi && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    at \
    jellyfin-server=${BUILD_EXT_RELEASE} \
    jellyfin-ffmpeg6 \
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
EXPOSE 8096 8920 7359/udp 1090/udp
VOLUME /config
