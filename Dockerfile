# syntax=docker/dockerfile:1
ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-ubuntu:v0.3.7-noble
FROM ${BUILD_FROM} 

# set version label
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_EXT_RELEASE="10.9.6+ubu2404"
LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

RUN <<DOCKER_RUN
  echo "**** install jellyfin repo*****"
  mkdir -p /etc/apt/keyrings
  DISTRO="$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release )"
  CODENAME="$( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release )"
  cat <<EOF | tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/${DISTRO}
Suites: ${CODENAME}
Components: main
Architectures: $( dpkg --print-architecture )
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
  curl -fsSL https://repo.jellyfin.org/${DISTRO}/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg
DOCKER_RUN

RUN \
  echo "**** Instaling common packages ****"  && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    at=3.2.5-2.1ubuntu3 \
    jellyfin=${BUILD_EXT_RELEASE} \
    xmlstarlet=1.6.1-4 && \
  if [ "${BUILD_ARCH}" = "aarch64" ] || [ "${BUILD_ARCH}" = "armv7" ]; then \
    echo "**** Instaling ARM packages ****"  && \
    apt-get install -y --no-install-recommends \
      libomxil-bellagio0=0.9.3-8ubuntu2 \
      libomxil-bellagio-bin=0.9.3-8ubuntu2 \
      libraspberrypi0 \
      ; \
  else \
    echo "**** Instaling AMD64 packages ****"  && \
    apt-get install -y --no-install-recommends \
      mesa-va-drivers \
      ; \
  fi && \
  echo "**** cleanup ****"  && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add local files
COPY root/ / 

# ports and volumes
EXPOSE 8096 8920 7359/udp 1090/udp

VOLUME /config

HEALTHCHECK --interval=30s --timeout=30s --start-period=2m --start-interval=5s --retries=5 CMD ["/etc/s6-overlay/s6-rc.d/svc-jellyfin/data/check"]
