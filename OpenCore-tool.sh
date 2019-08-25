#!/bin/bash

set -e
shopt -s extglob

BASE_DIR=`pwd`
RES_DIR="$BASE_DIR/resources"

LOGFILE="tool.log"

ARG1=$1
ARG2=$2

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

fin() {
	echo -e "${GREEN}done${NC}" >$(tty)
}

set_up_dirs() {
	cd $BASE_DIR
	if [ -d "$BUILD_DIR" ]; then
		echo -e -n "Removing old $BUILD_DIR ... " >$(tty)
		rm -Rf $BUILD_DIR; fin
	fi

	echo -e -n "Creating new $BUILD_DIR ... " >$(tty)
	mkdir -p $BUILD_DIR/BOOT
	mkdir -p $BUILD_DIR/OC/Kexts
	mkdir -p $BUILD_DIR/OC/Drivers
	fin
}

check_updates() {
	echo -e -n "\nChecking${YELLOW} $BASE_DIR ${NC}for git updates ... " >$(tty)
	cd $BASE_DIR
	find . -maxdepth 4 -name .git -type d|rev|cut -c 6-|rev|xargs -I {} git -C {} pull
	fin
}

build_drivers() {
	driver_list=() #todo-have this read drivers from config.plist
	built=()
	while IFS= read -r line; do
		driver_list+=("$line")
	done < "$1/driver.list"

	echo -e -n "Making BaseTools ... " >$(tty)
	cd $RES_DIR/UDK
	source edksetup.sh --reconfig
	make -C BaseTools; fin

	for driver in "${driver_list[@]}"
	do
		git_url=`echo $driver|rev|cut -f 2- -d /|rev`
		driver_pkg=`echo $git_url|rev|cut -f 1 -d /|rev`
		if [ ! -d "$driver_pkg" ]; then
			echo -e -n "Cloning $git_url ... " >$(tty)
			git clone $git_url; fin
		fi
		if [[ ! " ${built[@]} " =~ " ${driver_pkg} " ]]; then
			built+=("$driver_pkg")
			if [ -f "$driver_pkg/$driver_pkg.dsc" ]; then
				echo -e -n "Building $driver_pkg ... " >$(tty)
				build -a X64 -b $AUDK_CONFIG -t XCODE5 -p $driver_pkg/$driver_pkg.dsc; fin
			fi
		fi
		if [ "$1" == "$BASE_DIR/config-$AUDK_CONFIG" ]; then
			driver_name=`echo $driver|rev|cut -f 1 -d/|rev`
			echo -e -n "Copying $driver_name into $BUILD_DIR/OC/Drivers ... " >$(tty)
			cp $RES_DIR/UDK/Build/$driver_pkg/$AUDK_BUILD_DIR/X64/$driver_name $BUILD_DIR/OC/Drivers; fin
		fi
	done
}

check_base() {
	if [ ! -d "resources/UDK" ];then
		echo -e -n "Cloning acidanthera/audk into UDK ... " >$(tty)
		git clone https://github.com/acidanthera/audk resources/UDK; fin
	fi
	build_drivers "$BASE_DIR/Docs/base"

	echo -e -n "Copying BOOTx64.efi into $BUILD_DIR/BOOT ... " >$(tty)
	cp $RES_DIR/UDK/Build/OpenCorePkg/$AUDK_BUILD_DIR/X64/BOOTx64.efi $BUILD_DIR/BOOT
	fin

	echo -e -n "Copying OpenCore.efi into $BUILD_DIR/OC ... " >$(tty)
	cp $RES_DIR/UDK/Build/OpenCorePkg/$AUDK_BUILD_DIR/X64/OpenCore.efi $BUILD_DIR/OC
	fin
}

config_changed() {
	cp $RES_DIR/UDK/OpenCorePkg/Docs/Sample.plist $BASE_DIR/Docs/Sample.plist
	cp $RES_DIR/UDK/OpenCorePkg/Docs/SampleFull.plist $BASE_DIR/Docs/SampleFull.plist
	echo -e "\n${YELLOW}WARNING:${NC} Sample.plist & SampleFull.plist have been updated\n${RED}Make sure${NC} $BASE_DIR/$CONFIG_PLIST ${RED}is up to date${NC}.\nRun the tool again if you make any changes." >$(tty)
}

check_config() {
	if [ -f "$BASE_DIR/$CONFIG_PLIST" ]; then
		echo -e -n "Copying $CONFIG_PLIST into $BUILD_DIR/OC ... " >$(tty)
		cp $BASE_DIR/$CONFIG_PLIST $BUILD_DIR/OC/config.plist
		fin
	else
		echo -e "\n${RED}ERROR: ${NC}$BASE_DIR/$CONFIG_PLIST does not exist\n\nPlease create this file and run the tool again." >$(tty)
		exit 1
	fi
	cmp --silent $RES_DIR/UDK/OpenCorePkg/Docs/Sample.plist $BASE_DIR/Docs/Sample.plist || config_changed
	cmp --silent $RES_DIR/UDK/OpenCorePkg/Docs/SampleFull.plist $BASE_DIR/Docs/SampleFull.plist || config_changed
}

build_vault() {
	use_vault=`/usr/libexec/PlistBuddy -c "print :Misc:Security:RequireVault" $BASE_DIR/$CONFIG_PLIST`||use_vault="false"
	if [ "$use_vault" == "true" ]; then
		echo -e -n "\nBuilding vault files for $BUILD_DIR ... " >$(tty)
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
	else
		echo -e "\nRequireVault not set in $BASE_DIR/$CONFIG_PLIST\nskipping vault" >$(tty)
	fi
}

set_build_type() {
	case $ARG2 in
		d?(ebug) )
			echo -e "\n${GREEN}Setting up ${YELLOW}DEBUG${GREEN} environment${NC}" >$(tty)
			BUILD_DIR="$BASE_DIR/EFI-debug"
			XCODE_CONFIG="Debug"
			AUDK_CONFIG="DEBUG"
			AUDK_BUILD_DIR="DEBUG_XCODE5"
			CONFIG_PLIST="config-DEBUG/config.plist"
			;;
		r?(elease) )
			echo -e "\n${GREEN}Setting up ${YELLOW}RELEASE${GREEN} environment${NC}" >$(tty)
			BUILD_DIR="$BASE_DIR/EFI-release"
			XCODE_CONFIG="Release"
			AUDK_CONFIG="RELEASE"
			AUDK_BUILD_DIR="RELEASE_XCODE5"
			CONFIG_PLIST="config-RELEASE/config.plist"
			;;
		*)
			echo -e "usage: (b)uild (r)elease, (b)uild (d)ebug" >$(tty)
			exit 1
			;;
	esac
}

link_lilu() {
	if [ ! -L "Lilu.kext" ]; then
		ln -s $RES_DIR/Kext_builds/Lilu/build/Debug/Lilu.kext .
	fi
}

build_kexts() {
#	kext_list=() #todo-read these from config.plist
#	while IFS= read -r line; do
#		kext_list+=("$line")
#	done < "$BASE_DIR/config-$AUDK_CONFIG/kext.list"
	count=0
	BundlePath="start"
	while [ "$BundlePath" != "" ]
	do
		BundlePath=`/usr/libexec/PlistBuddy -c "print :Kernel:Add:$count:BundlePath" $BASE_DIR/$CONFIG_PLIST`||BundlePath=""
		if [ "$BundlePath" != "" ]; then
			Enabled=`/usr/libexec/PlistBuddy -c "print :Kernel:Add:$count:Enabled" $BASE_DIR/$CONFIG_PLIST`
			echo -e "$BundlePath   $Enabled" >$(tty)
		fi
	count=$(( $count + 1))
	done
	fin
	exit 0


	if [ ! -d "$RES_DIR/Kext_builds" ]; then
		mkdir $RES_DIR/Kext_builds
	fi
	for kext in "${kext_list[@]}"
	do
		cd $RES_DIR/Kext_builds
		git_url=`echo $kext|rev|cut -f 2- -d /|rev`
		kext_name=`echo $kext|rev|cut -f 1 -d /|rev`
		kext_pkg=`echo $git_url|rev|cut -f 1 -d /|rev`
		if [ ! -d "$kext_pkg" ]; then
			echo -e -n "Cloning $git_url ... " >$(tty)
			git clone $git_url
			fin
		fi
		cd $kext_pkg
		echo -e -n "Building $kext_pkg ... " >$(tty)
		if [ "$kext_pkg" != "Lilu" ]; then
			link_lilu
		fi
		xcodebuild -config $XCODE_CONFIG build
		fin
		echo -e -n "Copying $kext_name into $BUILD_DIR/OC/Kexts ... " >$(tty)
		cp -r $RES_DIR/Kext_builds/$kext_pkg/build/$XCODE_CONFIG/$kext_name $BUILD_DIR/OC/Kexts
		fin
	done
}

#parse command line arguments
case $ARG1 in
	b?(uild) )
		set_build_type
		;;
	v?(ault) )
		set_build_type
		build_vault
		exit 0
		;;
	u?(pdate) )
		check_updates
		exit 0
		;;
	*)
		echo -e "usage: OpenCore-tool.sh\t(b)uild (r)elease,\n\t\t\t(b)uild (d)ebug,\n\t\t\t(v)ault (r)elease,\n\t\t\t(v)ault (d)ebug,\n\t\t\t(u)pdate" >$(tty)
		exit 0
		;;
esac

missing() {
	echo -e "${RED}ERROR:${NC} $1 not found, install it to continue"
	exit 1
}

#****** Check Build Environment ***
echo -e "\n${GREEN}Checking if required tools are available${NC} ..."
which xcodebuild||missing "xcodebuild"
which nasm||missing "nasm"
which mtoc||missing "mtoc"
fin

#****** Start build ***************
echo -e "\n${YELLOW}Writing log to $BASE_DIR/$LOGFILE${NC}\n" #start logging

exec 6>&1
exec > $LOGFILE
exec 2>&1

set_up_dirs

check_updates

echo -e "\n${GREEN}Setting up base files/drivers${NC}" >$(tty)
check_base

echo -e "\n${GREEN}Setting up user drivers${NC}" >$(tty)
build_drivers "$BASE_DIR/config-$AUDK_CONFIG"

echo -e "\n${GREEN}Setting up user kexts${NC}" >$(tty)
build_kexts

echo -e "\n${GREEN}Setting up user config${NC}" >$(tty)
check_config

build_vault

exec 1>&6 6>&- 2>&1 #stop logfile

echo -e "\n${GREEN}Finished building ${YELLOW}$BUILD_DIR${NC}"

echo -e "\n${GREEN}Any git updates will appear below ...${NC}"
cat $BASE_DIR/$LOGFILE|grep "From http"|| echo -e "No git updates were found"
fin
