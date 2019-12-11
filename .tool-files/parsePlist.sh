#!/bin/sh -e

section=""
array=""
item=""
dict=0
item1=""

msg() {
	echo "$section/$sub1/$item1/$sub2/$array/$item/$1/ \"$2\""
	if [ -n "$item1" ]; then item1=$((item1+1)); fi
}

#while IFS='' read -r line; do
while read -r line; do
	case "${line%%>*}" in
		"<dict")
			if [ -z "$section" ]; then
				if [ -n "$key" ]; then
					section=$key
					key=""
				else
					echo "$line" # no key just echo the line
				fi
			elif [ -z "$array" ]; then
				dict=$((dict+1))
				case $dict in
					"1")
						sub1="$key"
						item1="0"
						;;
					"2")
						sub2="$key"
						item2="0"
						;;
				esac
				key=""
			fi
			;;
		"</dict")
			if [ -n "$array" ]; then
				item=$((item+1)) # prepare for next item
			elif [ "$dict" -gt "0" ]; then
				case $dict in
					"2")
						item2=""
						sub2=""
						;;
					"1")
						item1=""
						sub1=""
						;;
				esac
				dict=$((dict-1))
			elif [ -n "$section" ];then
				section=""
			else
				echo "$line"
			fi
			;;
		"<array")
			array=$key
			if [ -z "$item" ]; then item="0"; fi
			key=""
			;;
		"</array")
			array=""
			item="" # reset item count
			;;
		"<array/")
			array="$key"
			msg "null/" ""
			array=""
			key=""
			;;
		"<data")
			data="${line#<data>}"
			while [ "${line#*</}" != "data>" ]
			do
				read -r line
				data=$data$line
			done
			data=${data%</data>}
			msg "data/$key" "$data"
			key=""
			;;
		"<true/")
			msg "bool/$key" "true"
			key="";;
		"<false/")
			msg "bool/$key" "false"
			key=""
			;;
		"<key")
			key=${line#<key>}
			while [ "${line#*</}" != "key>" ]
			do
				read -r line
				key=$key$line
			done
			key=${key%</key>}
			;;
		"<string")
			string=${line#<string>}
			while [ "${line#*</}" != "string>" ]
			do
				read -r line
				key=$string$line
			done
			string=${string%</string>}
			msg "string/$key" "$string"
			if [ -z "$key" ]; then item=$((item+1)); fi
			key="";;
		"<integer")
			integer=${line#<integer>}
			while [ "${line#*</}" != "integer>" ]
			do
				read -r line
				integer=$integer$line
			done
			integer=${integer%</integer>}
			msg "integer/$key" "$integer"
			key="";;
		*)
			echo "$line"
			;;
	esac
done < config.plist
