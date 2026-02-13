#!/bin/bash
ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f%%", s/16}'
