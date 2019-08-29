#!/bin/bash

set -e
shopt -s extglob

BASE_DIR=`pwd`
RES_DIR="$BASE_DIR/resources"
BASE_TOOLS="unbuilt"

LOGFILE="tool.log"

ARG1=$1; ARG2=$2

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

print_resources() {
	for (( i = 0; i < ${#res_list[@]} ; i+=4 )); do
		echo -e "${res_list[i]}\t${res_list[i+1]}\t${res_list[i+2]}\t${res_list[i+3]}" >$(tty)
	done
}

msg() {
	echo -e -n "$1" >$(tty)
}

fin() {
	echo -e "${GREEN}done${NC}" >$(tty)
}

set_up_dest_dir() {
	if [ -d "$BUILD_DIR" ]; then
		msg "Removing old $BUILD_DIR ... "
		rm -rf $BUILD_DIR; fin
	fi
	msg "Creating new $BUILD_DIR ... "
	mkdir -p $BUILD_DIR/BOOT
	mkdir -p $BUILD_DIR/OC
	fin
}

init_res_list() {
	res_list=( \
		"0.base" "https://github.com/acidanthera/EfiPkg" "" "" \
		"0.base" "https://github.com/acidanthera/MacInfoPkg" "" "" \
		"0.base" "https://github.com/acidanthera/OcSupportPkg" "" "" \
		"BOOTx64.efi" "https://github.com/acidanthera/OpenCorePkg" "" "BOOT" \
		"OpenCore.efi" "https://github.com/acidanthera/OpenCorePkg" "" "OC" \
		"config.plist" "base/config" "$BASE_DIR/$AUDK_CONFIG" "OC"
		)
	}

clone() {
	if [ ! -d "$1" ]; then
		if [ "1" == "dummyPkg" ]; then
			mkdir dummyPkg
		else
			msg "Cloning $2 ..."
			git clone $2; fin
		fi
		echo "new" > $1/gitStatDEBUG
		echo "new" > $1/gitStatRELEASE
	fi
}

missing() {
	msg "\n${RED}ERROR:${NC} $1 not found, install it to continue\n"
	exit 1
}

check_requirements() {
	msg "\nChecking if required tools and files exist ..."
	if [ ! -f "$BASE_DIR/$CONFIG_PLIST" ]; then
		msg "\n${RED}ERROR: ${NC}$BASE_DIR/$CONFIG_PLIST does not exist\n\nPlease create this file and run the tool again.\n"
		exit 1
	fi
	which xcodebuild||missing "xcodebuild"
	which nasm||missing "nasm"
	which mtoc||missing "mtoc"
	which git||missing "git"
	fin
}

check_for_updates() {
	msg "\nChecking for updates ... "
	cd $BASE_DIR
	find . -maxdepth 4 -name .git -type d|rev|cut -c 6-|rev|xargs -I {} git -C {} pull
	fin
}

build_shell_tool() {
	if [ ! -d "$BASE_DIR/resources" ]; then
		mkdir $BASE_DIR/resources
	fi
	cd $BASE_DIR/resources
	clone "OpenCoreShell" "https//github.com/acidanthera/OpenCoreShell"
	cd OpenCoreShell
	if [ ! -d "UDK" ]; then
		msg "Cloning UDK2018 ... "
		git clone https://github.com/tianocore/edk2 -b UDK2018 --depth=1 UDK
		fin
	fi
	cd UDK
	msg "Making UDK2018 BaseTools ... "
	unset WORKSPACE
	unset EDK_TOOLS_PATH
	source edksetup.sh --reconfig
	make -C BaseTools
	fin

	msg "Patching UDK2018 ... "
	for p in ../Patches/* ; do
		git apply "$p"||echo "$p ignored, does not apply or alread done"
	done
	fin

	msg "Building Shell.efi (OpenCoreShell.efi) ... "
	build -a X64 -b DEBUG -t XCODE5 -p ShellPkg/ShellPkg.dsc
	fin
	srce="`pwd`/Build/Shell/DEBUG_XCODE5/X64"; dest="$BASE_DIR/extras"
	mkdir -p $dest && cp $srce/Shell.efi $_
}

build_kext() {
	cd $RES_DIR/Kext_builds
	git_url=${res_list[$1+1]}
	pkg_name=`echo $git_url|rev|cut -f 1 -d /|rev`
	clone "$pkg_name" "$git_url"
	cd $pkg_name
	if [ "`git rev-parse HEAD`" != "`cat gitStat$AUDK_CONFIG`" ]; then
		msg "Building $pkg_name ... "
		if [ "$pkg_name" != "Lilu" ]; then
			if [ ! -L "Lilu.kext" ]; then
				ln -s $RES_DIR/Kext_builds/Lilu/build/Debug/Lilu.kext .
			fi
		fi
		xcodebuild -config $XCODE_CONFIG build
		git rev-parse HEAD > gitStat$AUDK_CONFIG
		fin
	fi
}

make_dummy_pkg() {
	cd $RES_DIR/UDK
	if [ ! -d "dummyPkg" ]; then
		mkdir dummyPkg
	fi
	if [ ! -d "Build/dummyPkg" ]; then
		mkdir -p Build/dummyPkg
		echo "dummy" > Build/dummyPkg
		echo "dummy" > Build/dummyPkg
		built+=("dummyPkg")
	fi
}

build_driver() {
	cd $RES_DIR/UDK
	git_url=${res_list[$1+1]}
	pkg_name=`echo $git_url|rev|cut -f 1 -d /|rev`
	clone $pkg_name $git_url
	if [[ ! " ${built[@]} " =~ " ${pkg_name} " ]]; then
		cd $pkg_name
		built+=("$pkg_name")
		if [ -f "$pkg_name.dsc" ]; then
			if [ "`git rev-parse HEAD`" != "`cat gitStat$AUDK_CONFIG`" ]; then
				if [ "$BASE_TOOLS" == "unbuilt" ]; then
					msg "Making base tools ... "
					cd ..
					source edksetup.sh --reconfig
					make -C BaseTools; fin
					cd $pkg_name
					BASE_TOOLS="built"
				fi
				cd ..
				msg "Building $pkg_name ... "
				build -a X64 -b $AUDK_CONFIG -t XCODE5 -p $pkg_name/$pkg_name.dsc
				cd $pkg_name
				git rev-parse HEAD > gitStat$AUDK_CONFIG
				fin
			fi
		fi
	fi
}

build_resources() {
	cd $BASE_DIR
	built=()
	msg "\n${GREEN}Building needed resources${NC}\n"

	clone "resources/UDK" "https://github.com/acidanthera/audk resources/UDK"

	if [ ! -d "$RES_DIR/Kext_builds" ]; then
		mkdir $RES_DIR/Kext_builds
	fi

	for (( i = 0; i < ${#res_list[@]} ; i+=4 )); do
		case `echo ${res_list[i]}|rev|cut -f 1 -d .|rev` in
			"base" | "efi" )
				if [ "${res_list[i]}" == "Shell.efi" ]; then #special case
					build_shell_tool
					res_list[i+2]=$dest
				else
					build_driver "$i"
					res_list[i+2]="$RES_DIR/UDK/Build/$pkg_name/$AUDK_BUILD_DIR/X64"
				fi
				;;
			"kext" )
				build_kext "$i"
				kext_type=`echo $XCODE_CONFIG|tr A-Z a-z`
				res_list[i+2]="$RES_DIR/Kext_builds/$pkg_name/build/$kext_type"
				;;
		esac
	done
}

copy_resources() {
	msg "\n${GREEN}Moving resources into place${NC}\n"
	for (( i = 0; i < ${#res_list[@]} ; i+=4 )); do
		dest=${res_list[i+3]}
		if [ "$dest" != "" ]; then
			res_name=${res_list[i]}
			srce=${res_list[i+2]}
			msg "Copying $res_name to $dest ... "
			mkdir -p $BUILD_DIR/$dest && cp -r $srce/$res_name $_
			fin
		fi
	done
}

config_changed() {
	cp $RES_DIR/UDK/OpenCorePkg/Docs/Sample.plist $BASE_DIR/Docs/Sample.plist
	cp $RES_DIR/UDK/OpenCorePkg/Docs/SampleFull.plist $BASE_DIR/Docs/SampleFull.plist
	msg "\n${YELLOW}WARNING:${NC} Samplei$1.plist has been updated\n${YELLOW}!!!${NC} Make sure$ $BASE_DIR/$CONFIG_PLIST is up to date${NC}.\nRun the tool again if you make any changes.\n"
}


check_if_Sample_plist_updated() {
	msg "\nChecking if config.plist format has changed ... "
	cmp --silent $RES_DIR/UDK/OpenCorePkg/Docs/Sample.plist $BASE_DIR/Docs/Sample.plist||config_changed
	cmp --silent $RES_DIR/UDK/OpenCorePkg/Docs/SampleFull.plist $BASE_DIR/Docs/SampleFull.plist||config_changed "Full"
	fin
}

build_vault() {
	use_vault=`/usr/libexec/PlistBuddy -c "print :Misc:Security:RequireVault" $BASE_DIR/$CONFIG_PLIST`||use_vault="false"
	if [ "$use_vault" == "true" ]; then
		msg "\nBuilding vault files for $BUILD_DIR ... "
		cd $BUILD_DIR/OC
		if ls vault* 1> /dev/null 2>&1; then
			rm vault.*
		fi
		$RES_DIR/UDK/OcSupportPkg/Utilities/CreateVault/create_vault.sh .
		make -C $RES_DIR/UDK/OcSupportPkg/Utilities/RsaTool
		$RES_DIR/UDK/OcSupportPkg/Utilities/RsaTool/RsaTool -sign vault.plist vault.sig vault.pub
		off=$(($(strings -a -t d OpenCore.efi | grep "=BEGIN OC VAULT=" | cut -f1 -d' ')+16))
		dd of=OpenCore.efi if=vault.pub bs=1 seek=$off count=520 conv=notrunc
		rm vault.pub
		fin
	fi
}

set_build_type() {
	case $ARG2 in
		d?(ebug) )
			XCODE_CONFIG="Debug"
			;;
		r?(elease) )
			XCODE_CONFIG="Release"
			;;
		*)
			echo -e "usage: (b)uild (r)elease, (b)uild (d)ebug" >$(tty)
			exit 1
			;;
	esac
	AUDK_CONFIG=`echo $XCODE_CONFIG|tr a-z A-Z`
	BUILD_DIR="$BASE_DIR/$AUDK_CONFIG/EFI"
	CONFIG_PLIST="$AUDK_CONFIG/config.plist"
	AUDK_BUILD_DIR="$AUDK_CONFIG""_XCODE5"
	echo -e "\n${GREEN}Setting up ${YELLOW}$AUDK_CONFIG${GREEN} environment${NC}" >$(tty)
}

add_drivers_res_list() {
	count=0
	Driver="start"
	while [ "$Driver" != "" ]
	do
		Driver=`/usr/libexec/PlistBuddy -c "print :UEFI:Drivers:$count" $BASE_DIR/$CONFIG_PLIST`||Driver=""
		if [ "$Driver" != "" ]; then
			git_url=`/usr/libexec/PlistBuddy -c "print :$Driver" $BASE_DIR/Docs/repo.plist`||git_url=""
			if [ "$git_url" != "" ]; then
				res_list+=("$Driver" "$git_url" "" "OC/Drivers")
			elif [ -f "$BASE_DIR/extras/$Driver" ]; then
				res_list+=("$Driver.extras" "extras/dummyPkg" "$BASE_DIR/extras" "OC/Drivers")
			else
				msg "\n${RED}ERROR:${NC} $Driver - repo was not found in Docs/repo.plist or extras\n"
				exit 1
			fi
		fi
		let "count += 1"
	done
}

add_kexts_res_list() {
	count=0
	BundlePath="start"
	while [ "$BundlePath" != "" ]
	do
		BundlePath=`/usr/libexec/PlistBuddy -c "print :Kernel:Add:$count:BundlePath" $BASE_DIR/$CONFIG_PLIST`||BundlePath=""
		if [ "$BundlePath" != "" ]; then
			Enabled=`/usr/libexec/PlistBuddy -c "print :Kernel:Add:$count:Enabled" $BASE_DIR/$CONFIG_PLIST`
			if [ "$Enabled" == "true" ]; then
				git_url=`/usr/libexec/PlistBuddy -c "print :$BundlePath" $BASE_DIR/Docs/repo.plist`||git_url=""
				if [ "$git_url" != "" ]; then
					res_list+=("$BundlePath" "$git_url" "" "OC/Kexts")
				else
					msg "\n${RED}ERROR:${NC} $BundlePath - repo was not found in Docs/repo.plist\n"
					exit 1
				fi
			fi
		fi
		let "count += 1"
	done
}

add_tools_res_list() {
	count=0
	Path="start"
	while [ "$Path" != "" ]
	do
		Path=`/usr/libexec/PlistBuddy -c "print :Misc:Tools:$count:Path" $BASE_DIR/$CONFIG_PLIST`||Path=""
		Enabled=`/usr/libexec/PlistBuddy -c "print :Misc:Tools:$count:Enabled" $BASE_DIR/$CONFIG_PLIST`||Enabled=""
		if [ "$Enabled" == "true" ]; then
			git_url=`/usr/libexec/PlistBuddy -c "print :$Path" $BASE_DIR/Docs/repo.plist`||git_url=""
			if [ "$git_url" != "" ]; then
				res_list+=("$Path" "$git_url" "" "OC/Tools")
			elif [ -f "$BASE_DIR/extras/$Path" ]; then
					res_list+=("$Path" "extras/dummyPkg" "$BASE_DIR/extras" "OC/Tools")
			else
				msg "\n${RED}ERROR:${NC} $Name - repo was not found\n"
				exit 1
			fi
		fi
		let "count += 1"
	done
}

#parse command line arguments
case $ARG1 in
	b?(uild) ) #build first if repo exists, else copy from extras folder
		set_build_type
		;;
	c?(opy) ) #copy from extras first if exists, else build from repo
		msg "\n${YELLOW}copy mode not implemented yet${NC}\n"
		exit 0
		;;
	u?(pdate) )
		check_for_updates
		exit 0
		;;
	*)
		msg "\nusage: OpenCore-tool.sh\tcommand <option>\n\n\t\t\t(b)uild <(d)ebug,(r)elease>\n\t\t\t(c)opy  <(d)ebug,(r)elease>\n\t\t\t(u)pdate\n"
		exit 0
		;;
esac

#****** Start build ***************
exec 6>&1 #start logging
exec > $LOGFILE
exec 2>&1

check_requirements

set_up_dest_dirs

init_res_list
add_drivers_res_list
add_kexts_res_list
add_tools_res_list

#check_for_updates
msg "\n${RED}auto update check currently disabled${NC}\nrun ${YELLOW}./OpenCore-tool.sh update${NC} to update\n"

build_resources
copy_resources

check_if_Sample_plist_updated

build_vault

exec 1>&6 6>&- 2>&1 #stop logfile

msg "\n${GREEN}Finished building ${YELLOW}$BUILD_DIR${NC}\n"
