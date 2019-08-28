#!/bin/bash

set -e
shopt -s extglob

res_list=( \
	"0.base" "https://github.com/acidanthera/EfiPkg" "" \
	"0.base" "https://github.com/acidanthera/MacInfoPkg" "" \
	"0.base" "https://github.com/acidanthera/OcSupportPkg" "" \
	"BOOTx64.efi" "https://github.com/acidanthera/OpenCorePkg" "BOOT" \
	"OpenCore.efi" "https://github.com/acidanthera/OpenCorePkg" "OC" \
	)

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

missing() {
	echo -e "\n${RED}ERROR:${NC} $1 not found, install it to continue"
	exit 1
}

check_requirements() {
	echo -e -n "\nChecking if required tools and files exist ..." >$(tty)
	if [ ! -f "$BASE_DIR/$CONFIG_PLIST" ]; then
		echo -e "\n${RED}ERROR: ${NC}$BASE_DIR/$CONFIG_PLIST does not exist\n\nPlease create this file and run the tool again." >$(tty)
		exit 1
	fi
	which xcodebuild||missing "xcodebuild"
	which nasm||missing "nasm"
	which mtoc||missing "mtoc"
	fin
}

check_for_updates() {
	echo -e -n "\nChecking $BASE_DIR for git updates ... " >$(tty)
	cd $BASE_DIR
	find . -maxdepth 4 -name .git -type d|rev|cut -c 6-|rev|xargs -I {} git -C {} pull
	fin
}

build_kext() {
	cd $RES_DIR/Kext_builds
	git_url=${res_list[$1+1]}
	pkg_name=`echo $git_url|rev|cut -f 1 -d /|rev`
	if [ ! -d "$pkg_name" ]; then
		echo -e -n "Cloning $git_url ..." >$(tty)
		git clone $git_url
		echo "new" > $pkg_name/gitStatDEBUG
		echo "new" > $pkg_name/gitStatRELEASE
		fin
	fi
	cd $pkg_name
	if [ "`git rev-parse HEAD`" != "`cat gitStat$AUDK_CONFIG`" ]; then
		echo -e -n "Building $pkg_name ... " >$(tty)
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
	if [ "$pkg_name" == "dummyPkg" ]; then
		make_dummy_pkg
	elif [ ! -d "$pkg_name" ]; then
		echo -e -n "Cloning $git_url ... " >$(tty)
		git clone $git_url; fin
		echo "new" > $pkg_name/gitStatDEBUG
		echo "new" > $pkg_name/gitStatRELEASE
	fi
	cd $pkg_name
	if [[ ! " ${built[@]} " =~ " ${pkg_name} " ]]; then
		built+=("$pkg_name")
		if [ -f "$pkg_name.dsc" ]; then
			if [ "`git rev-parse HEAD`" != "`cat gitStat$AUDK_CONFIG`" ]; then
				cd ..
				echo -e -n "Building $pkg_name ... " >$(tty)
				build -a X64 -b $AUDK_CONFIG -t XCODE5 -p $pkg_name/$pkg_name.dsc
				cd $pkg_name
				git rev-parse HEAD > gitStat$AUDK_CONFIG
				fin
			fi
		fi
	fi
}

build_resources() {
	built=()
	echo -e "\n${GREEN}Building resources${NC}" >$(tty)

	if [ ! -d "resources/UDK" ];then
		echo -e -n "Cloning acidanthera/audk into UDK ... " >$(tty)
		git clone https://github.com/acidanthera/audk resources/UDK; fin
	fi

	if [ ! -d "$RES_DIR/Kext_builds" ]; then
		mkdir $RES_DIR/Kext_builds
	fi

	echo -e -n "Making base tools ... " >$(tty)
	cd $RES_DIR/UDK
	source edksetup.sh --reconfig
	make -C BaseTools; fin

	for (( i = 0; i < ${#res_list[@]} ; i+=3 )); do
		case `echo ${res_list[i]}|rev|cut -f 1 -d .|rev` in
			"base" | "efi" )
				build_driver i
				;;
			"kext" )
				build_kext i
				;;
		esac
	done
}

copy_resources() {
	echo -e "\n${GREEN}Moving resources into place${NC}" >$(tty)
	for (( i = 0; i < ${#res_list[@]} ; i+=3 )); do
		pkg_name=`echo ${res_list[i+1]}|rev|cut -f 1 -d /|rev`
		dest=${res_list[i+2]}
		case `echo ${res_list[i]}|rev|cut -f 1 -d .|rev` in
			"efi" )
				echo -e -n "Copying ${res_list[i]} to $dest ... " >$(tty)
				cp $RES_DIR/UDK/Build/$pkg_name/$AUDK_BUILD_DIR/X64/${res_list[i]} $BUILD_DIR/$dest
				fin
				;;
			"kext" )
				echo -e -n "Copying ${res_list[i]} to $dest ... " >$(tty)
				cp -r $RES_DIR/Kext_builds/$pkg_name/build/$XCODE_CONFIG/${res_list[i]} $BUILD_DIR/$dest
				fin
				;;
			"extras" )
				pkg_name=`echo ${res_list[i]}|cut -f -2 -d .`
				echo -e -n "Copying $pkg_name to $dest ... " >$(tty)
				cp $BASE_DIR/extras/$pkg_name $BUILD_DIR/$dest
				fin
				;;
		esac
	done
	echo -e -n "Copying $CONFIG_PLIST to EFI/OC ... " >$(tty)
	cp $BASE_DIR/$CONFIG_PLIST $BUILD_DIR/OC
	fin
}

config_changed() {
	cp $RES_DIR/UDK/OpenCorePkg/Docs/Sample.plist $BASE_DIR/Docs/Sample.plist
	cp $RES_DIR/UDK/OpenCorePkg/Docs/SampleFull.plist $BASE_DIR/Docs/SampleFull.plist
	echo -e "\n${YELLOW}WARNING:${NC} Sample.plist & SampleFull.plist have been updated\n${RED}Make sure${NC} $BASE_DIR/$CONFIG_PLIST ${RED}is up to date${NC}.\nRun the tool again if you make any changes." >$(tty)
}


check_if_Sample_plist_updated() {
	echo -e -n "\nChecking if config.plist format has changed ... " >$(tty)
	cmp --silent $RES_DIR/UDK/OpenCorePkg/Docs/Sample.plist $BASE_DIR/Docs/Sample.plist||config_changed
	cmp --silent $RES_DIR/UDK/OpenCorePkg/Docs/SampleFull.plist $BASE_DIR/Docs/SampleFull.plist||config_changed
	fin
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
			XCODE_CONFIG="Debug"
			AUDK_CONFIG="DEBUG"
			;;
		r?(elease) )
			echo -e "\n${GREEN}Setting up ${YELLOW}RELEASE${GREEN} environment${NC}" >$(tty)
			XCODE_CONFIG="Release"
			AUDK_CONFIG="RELEASE"
			;;
		*)
			echo -e "usage: (b)uild (r)elease, (b)uild (d)ebug" >$(tty)
			exit 1
			;;
	esac
	BUILD_DIR="$BASE_DIR/$AUDK_CONFIG/EFI"
	CONFIG_PLIST="$AUDK_CONFIG/config.plist"
	AUDK_BUILD_DIR="$AUDK_CONFIG""_XCODE5"
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
				res_list+=("$Driver" "$git_url" "OC/Drivers")
			elif [ -f "$BASE_DIR/extras/$Driver" ]; then
				res_list+=("$Driver.extras" "extras/dummyPkg" "OC/Drivers")
			else
				echo -e "\n${RED}ERROR:${NC} $Driver - repo was not found in Docs/repo.plist or extras" >$(tty)
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
					res_list+=("$BundlePath" "$git_url" "OC/Kexts")
				else
					echo -e "\n${RED}ERROR:${NC} $BundlePath - repo was not found in Docs/repo.plist" >$(tty)
					exit 1
				fi
			fi
		fi
	let "count += 1"
	done
}

build_shell_tool() {
	echo -e "\n${GREEN}Setting up OpenCoreShell environment${NC}" >$(tty)
	if [ ! -d "$BASE_DIR/resources" ]; then
		mkdir $BASE_DIR/resources
	fi
	cd $BASE_DIR/resources
	if [ ! -d "OpenCoreShell" ]; then
		echo -e -n "Cloning OpenCoreShell ... " >$(tty)
		git clone https://github.com/acidanthera/OpenCoreShell
		fin
	fi
	cd OpenCoreShell
	if [ ! -d "UDK" ]; then
		echo -e -n "Cloning UDK2018 ... " >$(tty)
#		git clone https://github.com/tianocore/edk2 -b UDK2018 --depth=1 UDK
		git clone https://github.com/acidanthera/audk UDK
		fin
	fi
	cd UDK
	echo -e -n "Making UDK2018 BaseTools ... " >$(tty)
	unset WORKSPACE
	unset EDK_TOOLS_PATH
	source edksetup.sh --reconfig
	make -C BaseTools
	fin

	echo -e -n "Patching UDK2018 ... " >$(tty)
	for i in ../Patches/* ; do
		git apply "$i" || echo "$i ignored"
	done
	fin

	echo -e -n "Building Shell.efi (OpenCoreShell.efi) ... " >$(tty)
	build -a X64 -b DEBUG -t XCODE5 -p ShellPkg/ShellPkg.dsc
	fin
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

#****** Start build ***************
echo -e "\n${YELLOW}Writing log to $BASE_DIR/$LOGFILE${NC}"

exec 6>&1 #start logging
exec > $LOGFILE
exec 2>&1

check_requirements

set_up_dirs

add_drivers_res_list
add_kexts_res_list

check_for_updates
build_resources
build_shell_tool

copy_resources

check_if_Sample_plist_updated

build_vault

exec 1>&6 6>&- 2>&1 #stop logfile

echo -e "\n${GREEN}Finished building ${YELLOW}$BUILD_DIR${NC}"

echo -e "\n${GREEN}Any git updates will appear below ...${NC}"
cat $BASE_DIR/$LOGFILE|grep "From http"|| echo -e "No git updates were found"
fin
