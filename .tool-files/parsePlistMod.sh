#!/bin/sh -e

# turn config.plist into config.plist.txt for fast grep selection and editing
# make edit_text.txt from config.plist.txt for fast plist edit screen drawing
IN=$1
#WROTE_KEY=""
section=""
array=""
item=""
ds="" # can dict being zero at end of dict be used instead?
line_num=0
dict=0
GRN='\033[0;32m'
NC='\033[0m'

msg() {
	echo "$section|$sub1|$sub2|$array|$item|$type|$key| \"$val\"" >> "$IN.txt"
#	if [ -z "$WROTE_KEY" ]; then
#		echo "<key>$key</key>" >> "$IN.mod"
#		WROTE_KEY="y"
#	fi
#	if [ "$type" = "bool" ]; then
#		echo "<$val/>" >> "$IN.mod"
#		WRITTEN="y"
#	elif [ -n "$type" ]; then
#		echo "<$type>$val</$type>" >> "$IN.mod"
#		WRITTEN="y"
#	fi
}

found_split() {
	echo "Line number $line_num" >> errors.txt
	echo "Found split <$1> in $section $sub1 $sub2 $item $key" >> errors.txt
	echo "${GRN}Combined to one line in modified.config.plist${NC}" >> errors.txt
	echo "" >> errors.txt
	sp=""
}

found_empty_array() {
	echo "Line number $line_num" >> errors.minor.txt
	echo "Found empty <array> in $section $sub1 $sub2 $item $key" >> errors.minor.txt
	echo "This may not be an issue for certain sections" >> errors.minor.txt
	echo "" >> errors.minor.txt
}

found_empty_dict() {
	echo "Line number $line_num" >> errors.txt
	echo "Found empty <dict> in $section $sub1 $sub2 $item $key" >> errors.txt
	echo "It is recommended that all sections be complete" >> errors.txt
	echo "" >> errors.txt
	type=""
	val=""
	msg
	key=""
}

#rm -rf config.plist.mod
#rm -rf config.plist.txt
#rm -rf edit*
#rm -rf errors*

while read -r line; do
	WRITTEN=""
	line_num=$((line_num+1))
	case "${line%%>*}" in
		"<dict")
			if [ -z "$section" ]; then
				if [ -n "$key" ]; then
					section=$key
					key=""
				else
					echo "PLIST|$line" >> "$IN.txt" # no key just echo the line
				fi
			elif [ -z "$array" ]; then
				dict=$((dict+1))
				case $dict in
					"1")
						sub1="$key"
						;;
					"2")
						sub2="$key"
						;;
				esac
				key=""
			fi
			ds="t" # found start of dict
			;;
		"</dict")
			if [ -z "$ds" ]; then
				if [ -n "$array" ]; then
					item=$((item+1)) # prepare for next item
				elif [ "$dict" -gt "0" ]; then
					case $dict in
						"2")
							sub2=""
							;;
						"1")
							sub1=""
							;;
					esac
					dict=$((dict-1))
				elif [ -n "$section" ];then
					section=""
				else
					echo "PLIST|$line" >> "$IN.txt"
				fi
			else
				if [ "$dict" -gt "0" ]; then dict=$((dict-1)); fi
				found_empty_dict
			fi
			;;
		"<dict/")
			found_empty_dict
#			echo "PLIST|<key>$key</key>" >> "config.plist.txt"
			echo "PLIST|$line" >> "$IN.txt"
			;;
		"<array")
			ds=""
			array=$key
			if [ -z "$item" ]; then item="0"; fi
			key=""
			;;
		"</array")
			if [ "$item" -eq "0" ]; then
				found_empty_array
				key=""
				val=""
				type=""
				msg
			fi
			array=""
			item="" # reset item count
			;;
		"<array/")
			ds=""
			found_empty_array
			array="$key"
			key=""
			val=""
			type=""
			msg
			array=""
			key=""
			;;
		"<data")
			ds=""
			data="${line#<data>}"
			while [ "${line#*</}" != "data>" ]
			do
				read -r line
				line_num=$((line_num+1))
				data=$data$line
			done
			type="data"
			val="${data%</data>}"
			msg
			key=""
			;;
		"<true/")
			ds=""
			type="bool"
			val="true"
			msg
			key="";;
		"<false/")
			ds=""
			type="bool"
			val="false"
			msg
			key=""
			;;
		"<key")
			ds=""
			sp=""
			WROTE_KEY=""
			key=${line#<key>}
			while [ "${line#*</}" != "key>" ]
			do
				sp="y"
				read -r line
				line_num=$((line_num+1))
				key=$key$line
			done
			key=${key%</key>}
			if [ -n "$sp" ]; then found_split "key"; fi
			;;
		"<string")
			ds=""
			sp=""
			string=${line#<string>}
			while [ "${line#*</}" != "string>" ]
			do
				sp="y"
				read -r line
				line_num=$((line_num+1))
				string=$string$line
			done
			string=${string%</string>}
			if [ -n "$sp" ]; then found_split "string"; fi
			type="string"
			val="$string"
			msg
			if [ -z "$key" ]; then item=$((item+1)); fi
			key="";;
		"<integer")
			ds=""
			sp=""
			integer=${line#<integer>}
			while [ "${line#*</}" != "integer>" ]
			do
				sp="y"
				read -r line
				line_num=$((line_num+1))
				integer=$integer$line
			done
			val=${integer%</integer>}
			if [ -n "$sp" ]; then found_split "integer"; fi
			type="integer"
			msg
			key="";;
		"<real")
			ds=""
			sp=""
			echo "Line number $line_num" >> errors.txt
			echo "Found value of type <real> for $section $key" >> errors.txt
			echo "${GRN}Converted to type <integer> in modified.config.plist${NC}" >> errors.txt
			echo "" >> errors.txt
			integer=${line#<real>}
			while [ "${line#*</}" != "real>" ]
			do
				sp="y"
				read -r line
				line_num=$((line_num+1))
				integer=$integer$line
			done
			val=${integer%</real>}
			if [ -n "$sp" ]; then found_split "real"; fi
			type="integer"
			msg
			key="";;
		*)
			echo "PLIST|$line" >> "$IN.txt"
			;;
	esac
#	if [ -z "$WRITTEN" ]; then
#		echo "$line" >> "$IN.mod"
#		if [ -n "$key" ]; then WROTE_KEY="y"; fi
#	fi
done < "$IN"
