FROM ubuntu:focal-20250404 AS build-stage 

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
# openjdk-11-jdk
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
    openjdk-11-jdk \
    sudo \
    tzdata \
    unzip \
    wget \
    xvfb \
    zip \
    ffmpeg \
    android-sdk \
    android-sdk-build-tools \
    android-sdk-platform-tools-common \
  && rm -rf /var/lib/apt/lists/*

#===============
# Set JAVA_HOME
#===============
ARG TARGETARCH
# TARGETARCH is automatically set by the Docker build process based on the --platform flag used during the build. If no platform is specified, it defaults to the architecture of the build host.
ENV ARCH="${TARGETARCH}"
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-${TARGETARCH}" \
    PATH=$PATH:$JAVA_HOME/bin

#===============================
# Set Timezone (UTC as default)
#===============================
ENV TZ "UTC"
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
  && echo 'androidusr ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /home/androidusr

#=====================
# Install Android SDK
#=====================
ENV ANDROID_BUILD_TOOLS_VERSION=34.0.0
ENV ANDROID_HOME=/usr/lib/android-sdk 
ENV PATH=$PATH:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin
ENV PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools


#====================================
# Install latest nodejs, npm, appium, mjpeg-consumer
# Using this workaround to install Appium -> https://github.com/appium/appium/issues/10020 -> Please remove this workaround asap
#====================================
ENV NODE_VERSION=22
ENV APPIUM_VERSION=2.18.0
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash && \
    apt-get -qqy install nodejs && \
    npm install -g appium@${APPIUM_VERSION} && \
    exit 0 && \
    npm cache clean && \
    apt-get remove --purge -y npm && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get clean
RUN npm i -g mjpeg-consumer

#====================================================
# Fix permission issue to download e.g. chromedriver
#====================================================
RUN chown -R ${UID}:${GID} /usr/lib/node_modules/appium

FROM build-stage AS final-stage
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
ENV APPIUM_DRIVER_ESPRESSO_VERSION="4.1.5"
ENV APPIUM_DRIVER_FLUTTER_VERSION="2.15.0"
ENV APPIUM_DRIVER_FLUTTER_INTEGRATION_VERSION="1.1.4"
ENV APPIUM_DRIVER_GECKO_VERSION="1.4.3"
ENV APPIUM_DRIVER_UIAUTOMATOR2_VERSION="4.2.3"
RUN appium driver install --source=npm appium-espresso-driver@${APPIUM_DRIVER_ESPRESSO_VERSION} && \
    appium driver install --source=npm appium-flutter-driver@${APPIUM_DRIVER_FLUTTER_VERSION} && \
    appium driver install --source=npm appium-flutter-integration-driver@${APPIUM_DRIVER_FLUTTER_INTEGRATION_VERSION} && \
    appium driver install --source=npm appium-geckodriver@${APPIUM_DRIVER_GECKO_VERSION} && \
    appium driver install --source=npm appium-uiautomator2-driver@${APPIUM_DRIVER_UIAUTOMATOR2_VERSION}

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
CMD ./${SCRIPT_PATH}/start.sh
