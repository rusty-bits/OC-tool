#!/bin/bash

prompt() {
  echo "$1"
  if [ "$FORCE_INSTALL" != "1" ]; then
    read -rp "Enter [Y]es to continue: " v
    if [ "$v" != "Y" ] && [ "$v" != "y" ]; then
      exit 1
    fi
  fi
}

unamer() {
  NAME="$(uname)"

  if [ "$(echo "${NAME}" | grep MINGW)" != "" ] || [ "$(echo "${NAME}" | grep MSYS)" != "" ]; then
    echo "Windows"
  else
    echo "${NAME}"
  fi
}

echo "Building on $(unamer)"

if [ "$(unamer)" = "Windows" ]; then
  cmd <<< 'chcp 437'
  export PYTHON_COMMAND="python"
fi

if [ "$(which git)" = "" ]; then
  echo "Missing git, please install it!"
  exit 1
else
  echo "Found git"
fi

if [ "$(which zip)" = "" ]; then
  echo "Missing zip, please install it!"
  exit 1
else
  echo "Found zip"
fi

if [ "$(unamer)" = "Darwin" ]; then
  if [ "$(which clang)" = "" ] || [ "$(clang -v 2>&1 | grep "no developer")" != "" ] || [ "$(git -v 2>&1 | grep "no developer")" != "" ]; then
    echo "Missing Xcode tools, please install them!"
    exit 1
  fi
else
  echo "Found Xcode tools"
fi

# On Windows nasm and python may not be in PATH.
if [ "$(unamer)" = "Windows" ]; then
  export PATH="/c/Python38:$PATH:/c/Program Files/NASM"
fi

if [ "$(nasm -v)" = "" ] || [ "$(nasm -v | grep Apple)" != "" ]; then
  echo "Missing or incompatible nasm!"
  echo "Download the latest nasm from http://www.nasm.us/pub/nasm/releasebuilds/"
  echo "Current PATH: $PATH -- $(which nasm)"
  # On Darwin we can install prebuilt nasm. On Linux let users handle it.
  if [ "$(uname)" = "Darwin" ]; then
    prompt "Install last tested version automatically?"
  else
    exit 1
  fi
  pushd /tmp >/dev/null || exit 1
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
  popd >/dev/null || exit 1
else
  echo "Found nasm"
fi

echo "Getting latest mtoc hash"
mtoc_hash=$(curl -L "https://github.com/acidanthera/ocbuild/raw/master/external/mtoc-mac64.sha256") || exit 1

if [ "${mtoc_hash}" = "" ]; then
  echo "Cannot obtain the latest compatible mtoc hash!"
  exit 1
fi

# On Darwin we need mtoc. Only for XCODE5, but do not care for now.
if [ "$(unamer)" = "Darwin" ]; then
  valid_mtoc=false
else
  valid_mtoc=true
fi

if [ "$(which mtoc)" != "" ]; then
  mtoc_path=$(which mtoc)
  mtoc_hash_user=$(shasum -a 256 "${mtoc_path}" | cut -d' ' -f1)
  if [ "${mtoc_hash}" = "${mtoc_hash_user}" ]; then
    valid_mtoc=true
  elif [ "${IGNORE_MTOC_VERSION}" = "1" ]; then
    echo "Forcing the use of UNKNOWN mtoc version due to IGNORE_MTOC_VERSION=1"
    valid_mtoc=true
  elif [ "${mtoc_path}" != "/usr/local/bin/mtoc" ]; then
    echo "Custom UNKNOWN mtoc is installed to ${mtoc_path}!"
    echo "Hint: Remove this mtoc or use IGNORE_MTOC_VERSION=1 at your own risk."
    exit 1
  else
    echo "Found incompatible mtoc installed to ${mtoc_path}!"
    echo "Expected SHA-256: ${mtoc_hash}"
    echo "Found SHA-256:    ${mtoc_hash_user}"
    echo "Hint: Reinstall this mtoc or use IGNORE_MTOC_VERSION=1 at your own risk."
  fi
fi

if ! $valid_mtoc; then
  echo "Missing or incompatible mtoc!"
  echo "To build mtoc follow: https://github.com/tianocore/tianocore.github.io/wiki/Xcode#mac-os-x-xcode"
  prompt "Install prebuilt mtoc automatically?"
  pushd /tmp >/dev/null || exit 1
  rm -f mtoc mtoc-mac64.zip
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/mtoc-mac64.zip" || exit 1
  mtoczip=$(cat mtoc-mac64.zip)
  rm -rf mtoc-*
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/${mtoczip}" || exit 1
  unzip -q "${mtoczip}" mtoc || exit 1
  sudo mkdir -p /usr/local/bin || exit 1
  sudo rm -f /usr/local/bin/mtoc /usr/local/bin/mtoc.NEW || exit 1
  sudo cp mtoc /usr/local/bin/mtoc || exit 1
  popd >/dev/null || exit 1

  mtoc_path=$(which mtoc)
  mtoc_hash_user=$(shasum -a 256 "${mtoc_path}" | cut -d' ' -f1)
  if [ "${mtoc_hash}" != "${mtoc_hash_user}" ]; then
    echo "Failed to install a compatible version of mtoc!"
    echo "Expected SHA-256: ${mtoc_hash}"
    echo "Found SHA-256:    ${mtoc_hash_user}"
    exit 1
  fi
else
  echo "Found mtoc"
fi
