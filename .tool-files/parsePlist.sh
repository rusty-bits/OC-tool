#!/bin/sh -e

# turn config.plist into config.plist.txt for fast grep selection and editing
# make edit_text.txt from config.plist.txt for fast plist edit screen drawing

section=""
array=""
item=""
ds="" # can dict being zero at end of dict be used instead?
line_num=0
dict=0
L0=0
C0=""
P=0

get_next() {
	next=""
	while [ -z "$next" ]
	do
		case $P in
			0)
				if [ -n "$sub1" ]; then next=$sub1; fi
				P=1;;
			1)
				if [ -n "$sub2" ]; then next="$sub2"; fi
				P=2;;
			2)
				if [ -n "$array" ]; then next="$array"; fi
				P=3;;
			3)
				if [ -n "$item" ]; then next="${C0}_${C1}_$item"; fi
				if [ -z "$key" ]; then next="$val"; fi
				P=4;;
			4)
				next="$key"
				if [ -z "$next" ]; then next="error"; fi
				if [ "$key" = "Path" ] && [ "$C0$C1" != "MiscEntries" ]; then echo "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "BundlePath" ]; then echo "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "Comment" ] && [ "$C0$C1" = "ACPIBlock" ]; then echo "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "Comment" ] && [ "$C1" = "Patch" ]; then echo "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "Address" ] && [ "$C0$C1" = "BooterMmioWhitelist" ]; then echo "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "Identifier" ] && [ "$C0$C1" = "KernelBlock" ]; then echo "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "Name" ] && [ "$C0$C1" = "MiscEntries" ]; then echo "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				P=5
				;;
			5)
				next="error 5"
				;;
		esac
	done
}

write_out() {
	if [ "$P" -eq "4" ] && [ -z "$key" ]; then P=5; fi
	if [ "$P" -lt "5" ]; then
		echo "$L0|$L1|$L2|$L3|||$1 " >> edit_text.tmp
	else
		echo "$L0|$L1|$L2|$L3|$type|$val|$1" >> edit_text.tmp
	fi
}

msg() {
	echo "$section|$sub1|$sub2|$array|$item|$type|$key| \"$val\"" >> config.plist.txt
	P=0
	if [ "$C0" != "$section" ]; then # reset level
		C0=$section; C1=""; C2=""; C3=""
		L0=$((L0+1)); L1=0; L2=0; L3=0
		write_out "$C0"
	fi
	get_next
	if [ "$next" != "$C1" ] && [ "$next" != "error" ]; then
		C1="$next"; C2=""; C3=""
		L1=$((L1+1)); L2=0; L3=0
		write_out "$C1"
	fi
	if [ "$P" -lt "5" ]; then
		get_next
		if [ "$next" != "$C2" ] && [ "$next" != "error" ]; then
			C2="$next"; C3=""
			L2=$((L2+1)); L3=0
			write_out "$C2"
		fi
	fi
	if [ "$P" -lt "5" ]; then
		get_next
		if [ "$next" != "$C3" ] && [ "$next" != "error" ]; then
			C3="$next"
			L3=$((L3+1))
			write_out "$C3"
		fi
	fi
}

found_split() {
	echo "Line number $line_num" >> errors.txt
	echo "Found split <$1> in $section $sub1 $sub2 $item $key" >> errors.txt
	echo "" >> errors.txt
}

found_empty_dict() {
	echo "Line number $line_num" >> errors.txt
	echo "Found empty <dict/> in $section $sub1 $sub2 $item $key" >> errors.txt
	echo "It is recommended that all sections be complete" >> errors.txt
	echo "" >> errors.txt
	type=""
	val=""
	msg
	key=""
}

rm -rf config.plist.txt
rm -rf edit_text.txt
rm -rf edit_text.tmp
rm -rf edit_subs.txt
rm -rf errors.txt

while read -r line; do
	line_num=$((line_num+1))
	case "${line%%>*}" in
		"<dict")
			if [ -z "$section" ]; then
				if [ -n "$key" ]; then
					section=$key
					key=""
				else
					echo "PLIST|$line" >> config.plist.txt # no key just echo the line
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
					echo "PLIST|$line" >> config.plist.txt
				fi
			else
				if [ "$dict" -gt "0" ]; then dict=$((dict-1)); fi
				found_empty_dict
			fi
			;;
		"<dict/")
			found_empty_dict
#			echo "PLIST|<key>$key</key>" >> config.plist.txt
#			echo "PLIST|$line" >> config.plist.txt
			;;
		"<array")
			ds=""
			array=$key
			if [ -z "$item" ]; then item="0"; fi
			key=""
			;;
		"</array")
			if [ "$item" -eq "0" ]; then
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
			key=${line#<key>}
			while [ "${line#*</}" != "key>" ]
			do
				read -r line
				line_num=$((line_num+1))
				key=$key$line
			done
			key=${key%</key>}
			;;
		"<string")
			ds=""
			string=${line#<string>}
			while [ "${line#*</}" != "string>" ]
			do
				read -r line
				line_num=$((line_num+1))
				key=$string$line
			done
			string=${string%</string>}
			type="string"
			val="$string"
			msg
			if [ -z "$key" ]; then item=$((item+1)); fi
			key="";;
		"<integer")
			ds=""
			integer=${line#<integer>}
			while [ "${line#*</}" != "integer>" ]
			do
				read -r line
				line_num=$((line_num+1))
				integer=$integer$line
			done
			val=${integer%</integer>}
			type="integer"
			msg
			key="";;
		"<real")
			ds=""
			echo "Line number $line_num" >> errors.txt
			echo "Found value of type <real> for $section $key" >> errors.txt
			echo "converted it to type <integer>" >> errors.txt
			echo "" >> errors.txt
			integer=${line#<real>}
			while [ "${line#*</}" != "real>" ]
			do
				read -r line
				line_num=$((line_num+1))
				integer=$integer$line
			done
			val=${integer%</real>}
			type="integer"
			msg
			key="";;
		*)
			echo "PLIST|$line" >> config.plist.txt
			;;
	esac
done < $1

com=""
while read -r line
do
	old="${line%|*}"
	new="${line#*|}"
	s1="${line%%_*}"; line="${line#*_}"
	s2="${line%%_*}"; line="${line#*_}"
	s3="${line%|*}"
	en=$(grep "$s1|*$s2|$s3|bool|Enabled|" config.plist.txt|cut -f2 -d'"')
	if [ "$en" = "true" ]; then new="$new\ +"; fi
	if [ "$en" = "false" ]; then new="$new\ -"; fi
	com="$com -e s/'$old '/'$new'/"
done < edit_subs.txt
# echo $com > com1.txt

eval sed $com edit_text.tmp > edit_text.txt
