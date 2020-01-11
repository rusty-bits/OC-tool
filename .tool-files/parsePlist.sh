#!/bin/sh -e

# turn config.plist into config.plist.txt for fast grep selection and editing

section=""
array=""
item=""
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
	if [ "$next" != "$C1" ]; then
		C1="$next"; C2=""; C3=""
		L1=$((L1+1)); L2=0; L3=0
		write_out "$C1"
	fi
	if [ "$P" -lt "5" ]; then
		get_next
		if [ "$next" != "$C2" ]; then
			C2="$next"; C3=""
			L2=$((L2+1)); L3=0
			write_out "$C2"
		fi
	fi
	if [ "$P" -lt "5" ]; then
		get_next
		if [ "$next" != "$C3" ]; then
			C3="$next"
			L3=$((L3+1))
			write_out "$C3"
		fi
	fi
}

rm -rf config.plist.txt
rm -rf edit_text.txt
rm -rf edit_text.tmp
rm -rf edit_subs.txt

while read -r line; do
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
				echo "PLIST|$line" >> config.plist.txt
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
			val=""
			msg
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
			type="data"
			val="$data"
			msg
			key=""
			;;
		"<true/")
			type="bool"
			val="true"
			msg
			key="";;
		"<false/")
			type="bool"
			val="false"
			msg
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
			type="string"
			val="$string"
			msg
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
			type="integer"
			val="$integer"
			msg
			key="";;
		*)
			echo "PLIST|$line" >> config.plist.txt
			;;
	esac
done < config.plist

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
echo $com > com1.txt

eval sed $com edit_text.tmp > edit_text.txt
