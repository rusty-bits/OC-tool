#!/bin/sh -e

while read -r line
do
#	section=$(echo $line|cut -f1 -d '|')
	case "${line%%|*}" in
		"ACPI")
			echo "ACPI"
			;;
		"Booter")
			echo "Booter"
			;;
		"DeviceProperties")
			echo "DeviceProperties"
			;;
		"Kernel")
			echo "Kernel"
			;;
		"Misc")
			echo "Misc"
			;;
		"NVRAM")
			echo "NVRAM"
			;;
		"PlatformInfo")
			echo "PlatformInfo"
			;;
		"UEFI")
			echo "UEFI"
			;;
		*)
			echo "$line"
			;;
	esac
done < config.plist.txt
