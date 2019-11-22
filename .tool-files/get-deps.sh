#!/bin/bash

prompt() {
	echo "$1"
	if [ "$FORCE_INSTALL" != "1" ]; then
		read -p "Enter [Y]es to continue: " v
		if [ "$v" != "Y" ] && [ "$v" != "y" ]; then
			exit 1
		fi
	fi
}

if [ "$(which clang)" = "" ] || [ "$(which git)" = "" ] || [ "$(clang -v 2>&1 | grep "no developer")" != "" ] || [ "$(git -v 2>&1 | grep "no developer")" != "" ]; then
	echo "Missing Xcode tools, please install them!"
	exit 1
else
	echo "Found Xcode tools"
fi

echo "---"

if [ "$(nasm -v)" = "" ] || [ "$(nasm -v | grep Apple)" != "" ]; then
	echo "Missing or incompatible nasm!"
	echo "Download the latest nasm from http://www.nasm.us/pub/nasm/releasebuilds/"
	prompt "Install last tested version automatically?"
	pushd /tmp >/dev/null
	rm -rf nasm-mac64.zip
	curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/nasm-mac64.zip" || exit 1
	nasmzip=$(cat nasm-mac64.zip)
	rm -rf nasm-*
	curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/${nasmzip}" || exit 1
	unzip -q "${nasmzip}" nasm*/nasm nasm*/ndisasm || exit 1
	sudo mkdir -p /usr/local/bin || exit 1
	sudo mv nasm*/nasm /usr/local/bin/ || exit 1
	sudo mv nasm*/ndisasm /usr/local/bin/ || exit 1
	rm -rf "${nasmzip}" nasm-*
	popd >/dev/null
	echo "nasm installed"
else
	echo "Found nasm"
fi

echo "---"

if [ "$(which mtoc.NEW)" == "" ] || [ "$(which mtoc)" == "" ]; then
	echo "Missing mtoc or mtoc.NEW!"
	echo "To build mtoc follow: https://github.com/tianocore/tianocore.github.io/wiki/Xcode#mac-os-x-xcode"
	prompt "Install prebuilt mtoc and mtoc.NEW automatically?"
	pushd /tmp >/dev/null
	rm -f mtoc mtoc-mac64.zip
	curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/mtoc-mac64.zip" || exit 1
	unzip -q mtoc-mac64.zip mtoc || exit 1
	sudo mkdir -p /usr/local/bin || exit 1
	sudo cp mtoc /usr/local/bin/mtoc || exit 1
	sudo mv mtoc /usr/local/bin/mtoc.NEW || exit 1
	popd >/dev/null
	echo "mtoc installed"
else
	echo "Found mtoc"
fi
