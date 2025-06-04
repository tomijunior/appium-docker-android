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
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-${TARGETARCH}" \
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
ENV SDK_VERSION=commandlinetools-linux-11076708_latest
ENV ANDROID_BUILD_TOOLS_VERSION=34.0.4
ENV ANDROID_FOLDER_NAME=cmdline-tools
ENV ANDROID_DOWNLOAD_PATH=/home/androidusr/${ANDROID_FOLDER_NAME} \
    ANDROID_HOME=/opt/android \
    ANDROID_TOOL_HOME=/opt/android/${ANDROID_FOLDER_NAME}

RUN wget -O tools.zip https://dl.google.com/android/repository/${SDK_VERSION}.zip && \
    unzip tools.zip && rm tools.zip && \
    chmod a+x -R ${ANDROID_DOWNLOAD_PATH} && \
    chown -R ${UID}:${GID} ${ANDROID_DOWNLOAD_PATH} && \
    mkdir -p ${ANDROID_TOOL_HOME} && \
    mv ${ANDROID_DOWNLOAD_PATH} ${ANDROID_TOOL_HOME}/tools
ENV PATH=$PATH:${ANDROID_TOOL_HOME}/tools:${ANDROID_TOOL_HOME}/tools/bin

# https://askubuntu.com/questions/885658/android-sdk-repositories-cfg-could-not-be-loaded
RUN mkdir -p ~/.android && \
    touch ~/.android/repositories.cfg && \
    yes | sdkmanager --licenses && \
    mv ~/.android .android && \
    chown -R ${UID}:${GID} .android

#build-tools
RUN wget -O build-tools.tar.xz https://github.com/AndroidIDEOfficial/androidide-tools/releases/download/v34.0.4/build-tools-34.0.4-aarch64.tar.xz && \
    tar xf build-tools.tar.xz && rm build-tools.tar.xz && \
    chmod a+x -R build-tools && \
    mv build-tools ${ANDROID_HOME}/
ENV PATH=$PATH:${ANDROID_HOME}/build-tools/34.0.4

#platform-tools
RUN wget -O platform-tools.tar.xz https://github.com/AndroidIDEOfficial/androidide-tools/releases/download/v34.0.4/platform-tools-34.0.4-aarch64.tar.xz && \
    tar xf platform-tools.tar.xz && rm platform-tools.tar.xz && \
    chmod a+x -R platform-tools && \
    mv platform-tools ${ANDROID_HOME}/
ENV PATH=$PATH:${ANDROID_HOME}/platform-tools

RUN wget -O emulator.zip https://github.com/tomijunior/sdk-repo-linux_aarch64/releases/download/emulator/sdk-repo-linux_aarch64-emulator-13288691.zip && \
    unzip -qq emulator.zip -d ${ANDROID_HOME}/ && rm emulator.zip 
ENV PATH=$PATH:${ANDROID_HOME}/emulator

# Edit the XML <revision> tag at the end with your emulator version
RUN curl 'https://chromium.googlesource.com/android_tools/+/refs/heads/main/sdk/emulator/package.xml?format=TEXT' | base64 -d > ${ANDROID_HOME}/emulator/package.xml

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
