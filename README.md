# OC-tool  
POSIX shell script that builds an OpenCore EFI folder from an OpenCore config.plist  

Can also be double-clicked in macOS Finder which will run as `./OC-tool -ou build release` 

see the [OC-tool wiki pages](https://github.com/rusty-bits/OC-tool/wiki) for more detailed information  

---

**Installation**  

`git clone https://github.com/rusty-bits/OC-tool`   
`cd OC-tool`  

place your config.plist file in the appropriate directory, or copy and edit one of the sample plist files. eg.  

`cp Docs/SampleFull.plist RELEASE/config.plist` for building a release version  

`cp Docs/SampleFull.plist DEBUG/config.plist` for building a debug version  

---

**Requirements**  

- `git` is installed  

- `xcodebuild`, `nasm`, and `mtoc` are installed and configured to run from the command line  
  
- if you want the tool to compile .dsl files into .aml on the fly, `iasl` needs to be installed, but I recommend you compile them yourself and place them in the extras directory. The tool will copy what's needed to the EFI directory.  

---

**Acknowledgements**  

The folks at [r/hackintosh](https://www.reddit.com/r/hackintosh/) such as [dracoflar](https://www.reddit.com/user/dracoflar/) [midi1996](https://www.reddit.com/user/midi1996/) [Beowolve](https://www.reddit.com/user/Beowolve/) [slandeh](https://www.reddit.com/user/slandeh/) and of course [CorpNewt](https://www.reddit.com/user/corpnewt/) for help guides and tools to get my hack up and running in the first place.  

The folks at [acidanthera](https://github.com/acidanthera) for making OpenCore possible such as [vit9696](https://github.com/vit9696) [vandroiy2013](https://github.com/vandroiy2013) [Download-Fritz](https://github.com/Download-Fritz) [Andrey1970AppleLife](https://github.com/Andrey1970AppleLife) [PMheart](https://github.com/PMheart) and on and on, too many to list.  

And folks like [Pavo](https://www.insanelymac.com/forum/profile/685502-pavo/) for the inspiration for this tool and [errorexists](https://www.insanelymac.com/forum/profile/2047226-errorexists/) for basically asking "Why bother making this? People can already do that in other ways" Um, because it's fun? Because I want to see if I can? So, why not?  

I probably forgot a number of people, sorry.
