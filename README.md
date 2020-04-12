# OC-tool  
POSIX shell script that builds an OpenCore EFI folder from an OpenCore config.plist  

Can also be double-clicked in macOS Finder which will run as `./OC-tool -o` 

see either the [OC-tool wiki pages](https://github.com/rusty-bits/OC-tool/wiki) for more detailed information  
or the [Docs/tool-changelog.md](https://github.com/rusty-bits/OC-tool/blob/master/Docs/tool-changelog.md) for ver 2.0 info  

---

**Installation**  

`git clone https://github.com/rusty-bits/OC-tool`   
`cd OC-tool`  

copy your `config.plist` file into the `INPUT` folder, or copy and edit one of the sample plist files.  

e.g. `cp Docs/Sample.plist INPUT/config.plist`  

NOTE: If you use the `Clone or download` button OC-tool's files will be downloaded, but it won't be a repo and will error out when run since it can't update itself from github  

---

**Requirements**  

- access to a POSIX shell such as `sh`, `bash`, `ksh`, `ash`, or `dash` should all work. I myself use `zsh` with no problems, even though it's not strictly POSIX compliant.  

It will also run on Windows under [WSL](https://docs.microsoft.com/en-us/windows/wsl) or by using [Git for Windows](https://gitforwindows.org)

That's it. Nothing more is needed to have `OC-tool` make a working EFI folder from the prebuilt releases on [Acidanthera's github](https://github.com/acidanthera). `git`, `grep`, `curl`, `cp`, `cut`, `tr`, etc used by OC-tool should already exist on those shells.  

Now, if you want the latest build made yourself from source you will need additional tools/dependencies, and as far as I know will have to use macOS as well.  If there is a good way to run Xcode on Linux let me know ...  

- To build from source `Xcode` with `xcodebuild`, `nasm`, and `mtoc` need to be installed and configured to run from the command line.  You can build/install these yourself, or you can run the get-deps.sh in the .tool-files folder which uses code from acidanthera to get prebuilt dependencies.    
`.tool-files/get-deps.sh` while in the `OC-tool` directory  
  
- Also, if you want the tool to compile .dsl files into .aml on the fly, `iasl` needs to be installed, but I recommend you compile them yourself and place them in the extras directory. The tool will copy what's needed to the EFI directory.  

~- Lastly, if you use OpenCore vault signing, you will need the `libcrypto.1.0.0.dylib` library in `/usr/local/opt/openssl/lib`.  This library is part of OpenSSL v1.0.  If you have a newer version of OpenSSL then the vault build may fail.  You can use `brew switch openssl 1.0.2t` if you have OpenSSL installed via [homebrew](https://brew.sh/)  If you don't have OpenSSL and have LibreSSL, which comes as part of Catalina, or you want to stay on version 1.1 or later of OpenSSL, you can copy the included `libcrypto.1.0.0.dylib` into `/usr/local/opt/openssl/lib`~

  ~`mkdir -p /usr/local/opt/openssl/lib` to make the directory if it doesn't exist~  
  ~`cp ./extras/libcrypto.1.0.0.dylib /usr/local/opt/openssl/lib/.` copy from the extras folder~    
  
  This no longer seems to be an issue with the vault signing  
  
---

**Credits**

[vit9696](https://github.com/vit9696), [PMheart](https://github.com/PMheart), and [cattyhouse](https://github.com/cattyhouse)  
for parts of [macbuild.tool](https://github.com/acidanthera/OpenCoreShell/blob/master/macbuild.tool) used in .tool-files/get-deps.sh  

elliptic-shiho for the [parse_json.sh gist](https://gist.github.com/elliptic-shiho/45698491e1f3a0ba51f4c2e81d0fcfa4) on github  

---

**Acknowledgements**  

The folks at [r/hackintosh](https://www.reddit.com/r/hackintosh/) such as [dracoflar](https://www.reddit.com/user/dracoflar/), [midi1996](https://www.reddit.com/user/midi1996/), [Beowolve](https://www.reddit.com/user/Beowolve/), [slandeh](https://www.reddit.com/user/slandeh/), and of course [CorpNewt](https://www.reddit.com/user/corpnewt/) for help, guides and tools to get my hack up and running in the first place.  

[u/ChrisWayg](https://www.reddit.com/user/ChrisWayg) for pointing out the script for prebuilt mtoc and nasm  

[u/nyhtml](https://www.reddit.com/user/nyhtml) for making me realize the Clone button on github will cause OC-tool to error out since it won't be cloned as a repo.   aka the _nyhtml_ bug ;)

The folks at [acidanthera](https://github.com/acidanthera) for making OpenCore possible such as [vit9696](https://github.com/vit9696), [vandroiy2013](https://github.com/vandroiy2013), [Download-Fritz](https://github.com/Download-Fritz), [Andrey1970AppleLife](https://github.com/Andrey1970AppleLife), [PMheart](https://github.com/PMheart) and on and on ...



I probably forgot a number of people, sorry.
