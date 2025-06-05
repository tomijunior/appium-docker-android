FROM ubuntu:jammy-20250530 AS build-base 

ENV DEBIAN_FRONTEND=noninteractive
ARG UID=1300
ARG GID=1301

#==================
# General Packages
#------------------
# ca-certificates
#   SSL client
# curl
#   Transfer data from or to a server
# gnupg
#   Encryption software. It is needed for nodejs
# libgconf-2-4
#   Required package for chrome and chromedriver to run on Linux
# libqt5webkit5
#   Web content engine (Fix issue in Android)
# openjdk-17-jdk
#   Java
# sudo
#   Sudo user
# tzdata
#   Timezone
# unzip
#   Unzip zip file
# wget
#   Network downloader
# xvfb
#   X virtual framebuffer
# zip
#   Make a zip file
#==================
RUN apt-get -qqy update && \
    apt dist-upgrade -y && \
    apt-get -qqy --no-install-recommends install \
    ca-certificates \
    curl \
    gnupg \
    libgconf-2-4 \
    libqt5webkit5 \
    openjdk-17-jdk \
    sudo \
    tzdata \
    unzip \
    wget \
    xvfb \
    zip \
    ffmpeg \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

#===============
# Set JAVA_HOME
#===============
ARG TARGETARCH
# TARGETARCH is automatically set by the Docker build process based on the --platform flag used during the build. If no platform is specified, it defaults to the architecture of the build host.
ENV ARCH="${TARGETARCH}"
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-${TARGETARCH}" 
ENV PATH=$PATH:$JAVA_HOME/bin
ENV ANDROID_HOME=/home/androidusr/android-sdk

#===============================
# Set Timezone (UTC as default)
#===============================
ENV TZ="UTC"
RUN echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

#===============
# Create a user
#===============
ARG USER_PASS=secret
RUN groupadd androidusr \
         --gid ${GID} \
  && useradd androidusr \
         --uid ${UID} \
         --gid ${GID} \
         --create-home \
         --shell /bin/bash \
  && usermod -aG sudo androidusr \
  && echo androidusr:${USER_PASS} | chpasswd \
  && echo 'androidusr ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && mkdir -p ${ANDROID_HOME}  \
  && chown -R ${UID}:${GID} ${ANDROID_HOME} 

WORKDIR /home/androidusr

FROM build-base AS second-stage

#==================
# Use created user
#==================
USER ${UID}:${GID}

#=====================
# Install Android SDK
#=====================

#build-tools
RUN cd ${ANDROID_HOME} && \
    wget -q -O build-tools.tar.xz https://github.com/AndroidIDEOfficial/androidide-tools/releases/download/v34.0.4/build-tools-34.0.4-aarch64.tar.xz && \
    tar xf build-tools.tar.xz && rm build-tools.tar.xz && \
    chmod a+x -R build-tools 

#platform-tools
RUN wget -q -O platform-tools.tar.xz https://github.com/AndroidIDEOfficial/androidide-tools/releases/download/v34.0.4/platform-tools-34.0.4-aarch64.tar.xz && \
    tar xf platform-tools.tar.xz && rm platform-tools.tar.xz && \
    chmod a+x -R platform-tools 

FROM build-base AS final-stage

COPY --from=second-stage ${ANDROID_HOME} ${ANDROID_HOME}
ENV PATH=$PATH:${ANDROID_HOME}/build-tools/34.0.4:${ANDROID_HOME}/platform-tools

# https://askubuntu.com/questions/885658/android-sdk-repositories-cfg-could-not-be-loaded
RUN mkdir -p ~/.android && \
    touch ~/.android/repositories.cfg && \
    mv ~/.android .android && \
    chown -R ${UID}:${GID} .android

#====================================
# Install latest nodejs, npm, appium, mjpeg-consumer
# Using this workaround to install Appium -> https://github.com/appium/appium/issues/10020 -> Please remove this workaround asap
#====================================
ENV NODE_VERSION=22
ENV APPIUM_VERSION=2.18.0
RUN cd /home/androidusr && \
    curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash && \
    apt-get -qqy install nodejs && \
    npm install -g appium@${APPIUM_VERSION} && \
    npm install -g mjpeg-consumer && \
    exit 0 && \
    npm cache clean && \
    apt-get remove --purge -y npm curl wget unzip && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get clean

#====================================================
# Fix permission issue to download e.g. chromedriver
#====================================================
RUN chown -R ${UID}:${GID} /usr/lib/node_modules/appium

#==============
# Copy scripts
#==============
ENV SCRIPT_PATH="appium-docker-android"
RUN mkdir -p ${SCRIPT_PATH}
COPY start.sh \
     generate_selenium_config.sh \
     wireless_autoconnect.sh \
     wireless_connect.sh \
     ${SCRIPT_PATH}/
RUN chown -R ${UID}:${GID} ${SCRIPT_PATH}
ENV APP_PATH=/home/androidusr/${SCRIPT_PATH}

#==================
# Use created user
#==================
USER ${UID}:${GID}

#===============================
# Install basic Android drivers
#===============================
ENV APPIUM_DRIVER_UIAUTOMATOR2_VERSION="4.2.3"
RUN appium driver install --source=npm appium-uiautomator2-driver@${APPIUM_DRIVER_UIAUTOMATOR2_VERSION}

#===============
# Expose Port
#---------------
# 4723
#   Appium port
#===============
EXPOSE 4723

#==============
# Start script
#==============
CMD ["/bin/bash", "-c", "./${SCRIPT_PATH}/start.sh"]
