#!/bin/bash

#Script to set performance.



cpufreq-set -r -g performance
cpupower frequency-set --governor performance


