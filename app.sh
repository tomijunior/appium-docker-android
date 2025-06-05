#!/bin/bash

IMAGE="appium_android_jetson"

if [ -z "$1" ]; then
	read -p "Task (test|build|push) : " TASK
else
	TASK=$1
fi

if [ -z "$2" ]; then
	read -p "Version : " VER
else
	VER=$2
fi

if [ -z "$3" ]; then
	read -s -p "User Password : " USER_PASS
	printf "\n"
	read -s -p "Retype User Password : " USER_PASS1
	if [[ "$USER_PASS" != "$USER_PASS1" ]]; then
		echo "User Password is not equal"
		exit 1
	fi
else
	USER_PASS=$3
fi

if [ -z "$4" ]; then
	CACHE=""
else
	CACHE=$4
fi

function build() {
	echo "Build docker image with version \"${VER}\""
	docker build --build-arg UID=$(id -u)  --build-arg GID=$(id -g) --build-arg USER_PASS=${USER_PASS}  ${CACHE} -t ${IMAGE}:${VER} -f Appium/Dockerfile Appium
	docker images
}

function test() {
	echo "Test docker image with version \"${VER}\""
	docker run --rm -v $PWD/Appium/tests:/home/androidusr/appium-docker-android/tests ${IMAGE}:${VER} ./appium-docker-android/tests/run-bats.sh
}

function push() {
	echo "Push docker image with version \"${VER}\""
	docker push ${IMAGE}:${VER}
	docker tag ${IMAGE}:${VER} ${IMAGE}:latest
	docker push ${IMAGE}:latest
}

case $TASK in
build)
	build
	;;
test)
	test
	;;
push)
	push
	;;
*)
	echo "Invalid environment! Valid options: test, build, push"
	;;
esac
