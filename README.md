# OC-tool  
POSIX shell script that builds an OpenCore EFI folder from an OpenCore config.plist  

Can also be double-clicked in macOS Finder which will run as `./OC-tool -o` 

see either the [OC-tool wiki pages](https://github.com/rusty-bits/OC-tool/wiki) for more detailed information  
or the [Docs/tool-changelog.md](https://github.com/rusty-bits/OC-tool/blob/master/Docs/tool-changelog.md)  

- 0.7.4 marks the last update for this tool, if you want a tool that will be maintained going forwards, you can check out the [replacement](https://github.com/rusty-bits/octool) here [https://github.com/rusty-bits/octool](https://github.com/rusty-bits/octool)

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

That's it, nothing more is needed. `OC-tool` will make a working EFI folder by getting what it needs from the stable releases on [Acidanthera's github](https://github.com/acidanthera) or the daily build on Dortania if you so choose.  `git`, `grep`, `curl`, `cp`, `cut`, `tr`, etc used by OC-tool should already exist on those shells.  

Now, if you want OC-tool to build the latest from source you will need additional tools/dependencies, and as far as I know will have to use macOS as well.  If there is a good way to run Xcode on Linux let me know ...  

- To build from source `Xcode` with `xcodebuild`, `nasm`, and `mtoc` need to be installed and configured to run from the command line.  You can build/install these yourself, or you can run the get-deps.sh in the .tool-files folder which uses code from acidanthera to get prebuilt dependencies.    
`.tool-files/get-deps.sh` while in the `OC-tool` directory  
  
---

**Credits**

[vit9696](https://github.com/vit9696), [PMheart](https://github.com/PMheart), and [cattyhouse](https://github.com/cattyhouse)  
for parts of [macbuild.tool](https://github.com/acidanthera/OpenCoreShell/blob/master/macbuild.tool) used in .tool-files/get-deps.sh  

[DhinakG](https://github.com/dhinakg) for the [daily build repo](https://dortania.github.io/builds) that OC-tool now uses if you use the -d option  

elliptic-shiho for the [parse_json.sh gist](https://gist.github.com/elliptic-shiho/45698491e1f3a0ba51f4c2e81d0fcfa4) on github  

---

**Acknowledgements**  

The folks at [r/hackintosh](https://www.reddit.com/r/hackintosh/) such as [dracoflar](https://www.reddit.com/user/dracoflar/), [midi1996](https://www.reddit.com/user/midi1996/), [Beowolve](https://www.reddit.com/user/Beowolve/), [slandeh](https://www.reddit.com/user/slandeh/), and of course [CorpNewt](https://www.reddit.com/user/corpnewt/) for help, guides and tools to get my hack up and running in the first place.  

[u/ChrisWayg](https://www.reddit.com/user/ChrisWayg) for pointing out the script for prebuilt mtoc and nasm  

[u/nyhtml](https://www.reddit.com/user/nyhtml) for making me realize the Clone button on github will cause OC-tool to error out since it won't be cloned as a repo.   aka the _nyhtml_ bug ;)

The folks at [acidanthera](https://github.com/acidanthera) for making OpenCore possible such as [vit9696](https://github.com/vit9696), [vandroiy2013](https://github.com/vandroiy2013), [Download-Fritz](https://github.com/Download-Fritz), [Andrey1970AppleLife](https://github.com/Andrey1970AppleLife), [PMheart](https://github.com/PMheart) and on and on ...



I probably forgot a number of people, sorry.
