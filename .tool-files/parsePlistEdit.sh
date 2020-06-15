#!/bin/sh -e

# turn config.plist into config.plist.txt for fast grep selection and editing
# make edit_text.txt from config.plist.txt for fast plist edit screen drawing

section=""
array=""
item=""
line_num=0
L0=0
C0=""
P=0

get_next() {
	next=""
	while [ -z "$next" ]
	do
		case $P in
			0)
				if [ -n "$sub1" ]; then
					ar="D"
					next=$sub1
				fi
				P=1;;
			1)
				if [ -n "$sub2" ]; then
					ar="D"
					next="$sub2"
				fi
				P=2;;
			2)
				if [ -n "$array" ]; then
					ar="A"
					next="$array"
				fi
				P=3;;
			3)
				if [ -n "$item" ]; then
					ar="A"
					next="${C0}_${C1}_$item"
				fi
				if [ -z "$key" ]; then next="$val"; fi
				P=4;;
			4)
				next="$key"
				if [ -z "$next" ]; then next="error"; fi
				if [ -z "$ar" ]; then ar="D"; fi
				if [ "$key" = "Path" ] && [ "$C0$C1" != "MiscEntries" ]; then printf "%s\n" "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "BundlePath" ]; then printf "%s\n" "${C0}_${C1}_$item|${val}" >> edit_subs.txt; fi
#				if [ "$key" = "BundlePath" ]; then printf "%s\n" "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "Comment" ] && [ "$C0$C1" = "ACPIBlock" ]; then printf "%s\n" "Found invalid ACPI > Block section, should be changed to ACPI > Delete for OpenCore 0.5.9 and later" >> parse_error.txt; fi
				if [ "$key" = "Comment" ] && [ "$C0$C1" = "ACPIDelete" ]; then printf "%s\n" "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "Comment" ] && [ "$C1" = "Patch" ]; then printf "%s\n" "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "Comment" ] && [ "$C0$C1" = "UEFIReservedMemory" ]; then printf "%s\n" "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "Address" ] && [ "$C0$C1" = "BooterMmioWhitelist" ]; then printf "%s\n" "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "Identifier" ] && [ "$C0$C1" = "KernelBlock" ]; then printf "%s\n" "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
				if [ "$key" = "Identifier" ] && [ "$C0$C1" = "KernelDelete" ]; then printf "%s\n" "Found invalid Kernel > Delete section, perhaps you want Kernel > Block" >> parse_error.txt; fi
				if [ "$key" = "Name" ] && [ "$C0$C1" = "MiscEntries" ]; then printf "%s\n" "${C0}_${C1}_$item|${val#*/}" >> edit_subs.txt; fi
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
		printf "%s\n" "$L0|$L1|$L2|$L3|$ar|||$1 " >> edit_text.tmp
	else
		printf "%s\n" "$L0|$L1|$L2|$L3|$ar|$type|$val|$1" >> edit_text.tmp
	fi
}

msg() {
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

#rm -rf config.plist.mod
#rm -rf config.plist.txt
#rm -rf edit*
#rm -rf errors*
rm -rf comm.txt

get_res() {
	section="${line%%|*}"; val="${line#*|}"
	sub1="${val%%|*}"; val="${val#*|}"
	sub2="${val%%|*}"; val="${val#*|}"
	array="${val%%|*}"; val="${val#*|}"
	item="${val%%|*}"; val="${val#*|}"
	type="${val%%|*}"; val="${val#*|}"
	key="${val%%|*}"; val="${val#*\"}"
	val="${val%\"*}"
}

while read -r line; do
	get_res
	ar=""
	line_num=$((line_num+1))
	if [ "$section" = "PLIST" ]; then
		printf "%s\n" "0|0|0|0||||$sub1" >> edit_text.tmp
	else
		msg
	fi
done < config.plist.txt

if [ -e "edit_subs.txt" ]; then
	com=""
	while read -r line
	do
		old="${line%|*}"
		new="${line#*|}"
		s1="${line%%_*}"; line="${line#*_}"
		s2="${line%%_*}"; line="${line#*_}"
		s3="${line%|*}"
		en=$(grep "$s1|*$s2|$s3|bool|Enabled|" config.plist.txt|cut -f2 -d'"')
#		if [ "$en" = "true" ]; then new="$new\ +"; fi
		if [ "$en" = "true" ]; then new="$new +"; fi
#		if [ "$en" = "false" ]; then new="$new\ -"; fi
		if [ "$en" = "false" ]; then new="$new -"; fi
		printf "%s\n" "s|$old |$new|" >> comm.txt
#		com="$com -e s\|'$old '\|'$new'\|"
#		com="$com -e \"s/'$old '/'$new'/\""
	done < edit_subs.txt
	# printf "%s\n" $com > com1.txt

	sed -f comm.txt  edit_text.tmp > edit_text.txt
#	eval sed "$com" edit_text.tmp > edit_text.txt
else
	cp edit_text.tmp edit_text.txt
fi

# rm -rf edit_text.tmp
