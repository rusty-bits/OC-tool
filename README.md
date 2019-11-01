# OC-tool
Command line tool that builds an OpenCore EFI folder from an OpenCore config.plist

Note: This tool has certain requirements:  
- `git` is installed  
- `xcodebuild`, `nasm`, and `mtoc` are installed and configured to run from the command line  
  
- if you want the tool to compile .dsl files into .aml on the fly, `iasl` needs to be installed, but I recommend you compile them yourself and place them in the extras directory. The tool will copy what's needed to the EFI directory.  

---

**Installation**:

`git clone https://github.com/rusty-bits/OC-tool`   
`cd OC-tool`  

then place your config.plist file in the appropriate directory, or copy and edit one of the sample plist files. eg.    
`cp Docs/SampleFull.plist RELEASE/config.plist` for making a release version

`cp Docs/SampleFull.plist DEBUG/config.plist` for making a debug version

see the [OC-tool wiki pages](https://github.com/rusty-bits/OC-tool/wiki) for more information  

### Note:  
The tool can be double clicked in the Finder if you would rather use it that way.  
It will function as if you had run `./OC-tool -uo build release` from the command line.  
More detailed instructions can be found [here in the OC-tool wiki pages.](https://github.com/rusty-bits/OC-tool/wiki/OC-tool-from-the-Finder)  

---

**Credits**  

The folks at [acidanthera](https://github.com/acidanthera) for making OpenCore possible such as [vit9696](https://github.com/vit9696) [vandroiy2013](https://github.com/vandroiy2013) [Download-Fritz](https://github.com/Download-Fritz) [Andrey1970AppleLife](https://github.com/Andrey1970AppleLife) [PMheart](https://github.com/PMheart) [RehabMan](https://github.com/RehabMan) and on and on, too many to list.  

