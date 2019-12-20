#!/bin/sh -e

# turn config.plist.txt back into config.plist for EFI folder

current_section=""
current_sub1=""
current_sub2=""
current_array=""
current_num=""

while read -r line
do
#	section=$(echo $line|cut -f1 -d '/')
	section="${line%%/*}"
	line="${line#*/}"
	if [ "$section" = "PLIST" ]; then
		echo "$line"
	else
		sub1="${line%%/*}"
		line="${line#*/}"
		sub1_num="${line%%/*}"
		line="${line#*/}"
		sub2="${line%%/*}"
		line="${line#*/}"
		array="${line%%/*}"
		line="${line#*/}"
		array_num="${line%%/*}"
		line="${line#*/}"
		type="${line%%/*}"
		line="${line#*/}"
		key="${line%%/*}"
		val="${line#*\"}"
		val="${val%\"*}"
		if [ "$section" = "$current_section" ]; then
			if [ "$sub1" = "$current_sub1" ]; then
				if [ "$sub2" = "$current_sub2" ]; then
					if [ "$array" = "$current_array" ]; then
						if [ "$array_num" != "$current_num" ]; then
							echo "</array>"
							current_num=$array_num
						fi
					fi
				fi
			fi
		fi
		echo "<key>$key</key>"
		if [ "$type" = "bool" ]; then
			echo "<$val/>"
		else
			echo "<$type>$val</$type>"
		fi
	fi
done < $1
