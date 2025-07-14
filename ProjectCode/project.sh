#!/bin/bash

#####
#Core framework functions...
#####

export FRAMEWORK_INCLUDES_FULL_PATH
FRAMEWORK_INCLUDES_FULL_PATH="$(realpath ../Framework-Includes)"

export FRAMEWORK_CONFIGS_FULL_PATH
FRAMEWORK_CONFIGS_FULL_PATH="$(realpath ../Framework-ConfigFiles)"

export PROJECT_INCLUDES_FULL_PATH
PROJECT_INCLUDES_FULL_PATH="$(realpath ../Project-Includes)"

export PROJECT_CONFIGS_FULL_PATH
PROJECT_CONFIGS_FULL_PATH="$(realpath ../Project-ConfigFiles)"


#Framework variables are read from hee
source $FRAMEWORK_CONFIGS_FULL_PATH/FrameworkVars

#Boilerplate and support functions
FrameworkIncludeFiles="$(ls -1 --color=none $FRAMEWORK_INCLUDES_FULL_PATH/*)"

IFS=$'\n\t'
for file in ${FrameworkIncludeFiles[@]}; do
	. "$file"
done
unset IFS


if [[ $ProjectIncludes = 1 ]]; then
ProjectIncludeFiles="$(ls -1 --color=none $PROJECT_INCLUDES_FULL_PATH/*)"
IFS=$'\n\t'
for file in ${ProjectIncludeFiles[@]}; do
	. "$file"
done
unset IFS
fi

PreflightCheck

echo > $LOGFILENAME

#Your custom logic here....
echo "Custom logic here..."