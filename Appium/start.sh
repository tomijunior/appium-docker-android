#!/bin/bash

#check appium is installed
echo "Check appium installation"
npm list | grep appium || npm install appium@2.18.0 && appium driver install --source=npm appium-uiautomator2-driver@4.2.3

# It is workaround to access adb from androidusr
echo "Prepare adb to have access to device"
adb devices >/dev/null
#sudo chown -R $(id -u):$(id -g) .android
echo "adb can be used now"

# Connect device via wireless
if [ "${REMOTE_ADB}" = true ]; then
	echo "Connect device via wireless"
	# Avoid lost connection
	${APP_PATH}/wireless_autoconnect.sh && \
	${APP_PATH}/wireless_connect.sh
fi

# Command to start Appium
APPIUM_LOG="${APPIUM_LOG:-/var/log/appium.log}"
command="xvfb-run appium --log $APPIUM_LOG"

# Adding Selenium configurations if needed
if [ "${CONNECT_TO_GRID}" = true ]; then
	NODE_CONFIG_JSON="${APP_PATH}/nodeconfig.json"
	if [ "${CUSTOM_NODE_CONFIG}" != true ]; then
		${APP_PATH}/generate_selenium_config.sh ${NODE_CONFIG_JSON}
	fi
	command+=" --nodeconfig ${NODE_CONFIG_JSON}"
fi

if [ "${DEFAULT_CAPABILITIES}" = true ]; then
	DEFAULT_CAPABILITIES_JSON="${APP_PATH}/defaultcapabilities.json"
	command+=" --default-capabilities ${DEFAULT_CAPABILITIES_JSON}"
fi

# Adding additional Appium configuration if needed
command+=" ${APPIUM_ADDITIONAL_PARAMS}"

# Run the whole command
pkill -x xvfb-run
rm -rf /tmp/.X99-lock
${command}
