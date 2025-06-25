#!/bin/bash

echo "Running apt-get update"
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes update

echo "Running apt-get dist-upgrade"
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes dist-upgrade

echo "Running apt-get upgrade"
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes upgrade


echo "Running apt-get purge"
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --purge autoremove --yes
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq autoclean --yes

