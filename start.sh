#!/usr/bin/env bash

echo "Launching Alexa Hue"

if [[ ( $# == "--help") ||  $# == "-h" ||  $# -eq 0 ]]
then
  echo "Usage: runAlexaHue <timezone> <win|mac|pi>"
  exit 0
elif [[ $# -eq 1 || $# -eq 2 ]]
then
  if [ "$2" == "pi" ]
  then
  	echo "TimeZone: $1"
    echo "Starting AlexaHue for RaspberryPi platform"
    sleep 2
    docker run -e "TZ=$1" -itdP --name=docker-alexa-hue eschizoid/docker-alexa-hue-armhf
    docker run --rm -it --link docker-alexa-hue eschizoid/docker-ngrok-armhf ngrok http docker-alexa-hue:4567
  elif [[ "$2" == "win" || "$2" == "mac" ]]
  then
  	echo "TimeZone: $1"
    echo "Starting AlexaHue for Windows / OS X platform"
    sleep 2
    docker run -e "TZ=$1" -itdP --name=docker-alexa-hue sarkonovich/docker-alexa-hue
	docker run --rm -it --link docker-alexa-hue wernight/ngrok ngrok http docker-alexa-hue:4567
  else
    echo "Usage: runAlexaHue <timezone> <win|mac|pi>"
    exit 0
  fi
else
  echo "Usage: runAlexaHue <timezone> <win|mac|pi>"
  exit 0
fi