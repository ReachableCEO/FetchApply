#!/bin/bash

# We don't want to run this on the wazuh server, otherwise bad things happen...

export TSYS_NSM_CHECK
TSYS_NSM_CHECK="$(hostname |grep -c tsys-nsm ||true)"

if [ "$TSYS_NSM_CHECK" -eq 0 ]; then
echo "stub... installing agent..."
fi

if [ "$TSYS_NSM_CHECK" -ne 0 ]; then
echo "stub... NOT installing agent... NO BAD THINGS..."
fi