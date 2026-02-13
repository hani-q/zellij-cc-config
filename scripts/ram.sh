#!/bin/bash
vm_stat | awk '/Pages active/ {a=$3} /Pages wired/ {w=$4} /page size/ {p=$8} END {gsub(/\./,"",a); gsub(/\./,"",w); printf "%.1fG", (a+w)*p/1073741824}'
