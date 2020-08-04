## VER 3.6.0(040820)  
I haven't been keeping up on the changelog, sorry.  Hopefully I remember all the relevant changes.  
- **release build updated to OpenCore 0.6.0  

- **source/daily version is now OpenCore 0.6.1  

- **`ConfigFull.plist` changed to `ConfigCustom.plist`  

- **`OpenCanopy` resources will now be looked for in either `INPUT` or `extras` folders  

- **will now ignore blank sections (e.g. empty `Misc > Tools` section)  

- **now build without error with Xcode 12 beta 3  

- **VoodooPS2 now handled correctly  
PlugIns now copied into parent kext `PlugIns` folder  
`VoodooInput.kext` all alone will be distinguished from `PlugIns/VoodooInput.kext`  

- **OC-tool will now update itself properly if interim changes have been made on the users end  

- **`OpenCanopy` Resources will only be copied if `OpenCanopy` is enabled  

- **`HfsPlus.efi` will now be automatically extracted from the `OcBinaryData` repo  

- **`.tool-files/get-deps` command updated to get current `nasm` + `mtoc`  

## VER 3.5.7(270420)  
- **auto create EFI\OC\Bootstrap if needed**  
if `Misc > Security > BootProtect` is set to `Bootstrap` then OC-tool will create the needed `EFI\OC\Bootstrap` directory and copy `BOOTx64.efi` into it as `Bootstrap.efi`

## VER 3.5.7(140420)  
- **default behavior will now build Release version**  
-r option will still build Release version for now, but is no longer needed  
-D option is now required to build Debug versions  

## VER 3.5(060420)  
- **updated release sources to OpenCore 0.5.7**  
lots of changes in the Sample.config  

- **prebuilt daily and build from source now build OpenCore 0.5.8**  

- **Driver section now accepts # at start of name to disable**  

## VER 3.5(260320)  
- **extras folder will be checked first for all resources now, not just ACPI files**  
any resources copied from extras will be noted in the output command line text  

## VER 3.5(080320)  
- **added initial support for OcBinaryData**  
to have OcBinaryData files included in the EFI/OC/Resources folder place the desired resources in the corresponding INPUT/Resources folder  

`INPUT/Resources/Audio`  
`INPUT/Resources/Font`  
`INPUT/Resources/Image`  

OC-tool will check these folders and copy any files into the OUTPUT/EFI/EC/Resources before building the vault files  

## VER 3.5(030320)  
~~- **added support for .wav files**  
.wav files that are placed in the `extras` folder will be copied into `EFI/OC/Resources/Audio`  
for example, `OCEFIAudio_VoiceOver_Boot.wav`  for the startup chime  
Any .wav files will be copied before the vault files are built allowing `Misc>Security>Vault Secure`  
and `Misc>Security>Vault Basic` to work as expected~~  
changed by 3.5(080320)

## VER 3.4(030320)  
- **updated prebuilt release to OpenCore version 0.5.6**  
`./OC-tool` and `./OC-tool -r` will now build version 0.5.6 from the prebuilt release  
`./OC-tool -d` and `./OC-tool -dr` will now build version 0.5.7 from the prebuilt daily  
`./OC-tool -s` and `./OC-tool -sr` will now build version 0.5.7 from current source  

- **pulldown lists for Kexts and Tools has been added**  

## VER 3.3(250220)  
- **added add item command to config.plist editor**  
Can now add field of type bool, data, integer or string into plist by pressing a.  The new field will be inserted before the currently highlightd item.  

Can now add new Driver from pulldown list by pressing   

Pulldown list to add Kexts and Tools should be coming soon  

- **added rename command to config.plist editor**  
Can now rename the key of the highlighted item by pressing n  

## VER 3.3(220220)  
- **added delete field/section to config.plist editor**  
While in config.plist editor mode, pressing d 2 times will delete the highlighted field or section.  

- **missing/extra picker still a work in progress**  
Yes, it works, but it's still ugly and not intuitive.  
I need to work on the add a field/section to config.plist code first, then hopefully I can fix the ugly missing/extra picker.  

## VER 3.2(090220)  
- **added missing/extra picker**  
When run, if OC-tool finds fields missing from config.plist it will display a picker window to select and add them automatically.  

## VER 3.1(050220)  
- **scan config.plist for missing or extra quirks at startup**  

## ver 3.0(241220)  
- **enabled prebuilt daily option -d**  

- **config.plist is checked for errors at run**  

## ver 2.6(150120)  
- **added config.plist editor**  
changes will be saved to Docs/config.plist leaving the original plist unchanged  

## ver 2.4(010120)  
- **added support for NVMeFix.kext**  

- **added support for DebugEnhancer.kext**  

- **fixed more typos and made small performance improvements**  

## ver 2.3(271219)  
- **changed echo to printf in msg command**  
some platforms, such as git bash for Windows, use a version of echo that needs -e for escape characters, switched to using printf which should be more consistent on all platforms  

- **strip \r character from config.plist if it exists**  
git bash for Windows may use CRLF or just LF depending on configuration, strip off the extra character for compatibility  

- **added check for unzip command**  
unzip command not installed by default on all systems, try using tar command instead  

- **added support for acidanthera/BrcmPatchRAM**  
parts may need to be installed to /Library/Extensions, but that onus will be placed on the end user  

- **added support for ReddestDream's fork of USBInjectAll.kext**  
includes support for later machines, such as iMac19,1  

## ver 2.1(021219)  
- **begin adding edit mode in TUI for whole config.plist**  

## ver 2.0(231119)  
- **Oc-tool no longer downloads `HFSPlus.efi` when it is not requested in config.plist**  
and the `HFSPlus.efi` will now be placed in the `resources` folder instead of `extras`  

- **changed wording of release/debug options in -h help and -t TUI**  
wording reflects that debug means debug symbols are included in the code to make debugging easier, not that it isn't as up to date as the release version of code  

- **fixed more typos, always finding typos**  

## ver 2.0(221119)  
- **added `.tool-files/get-deps.sh`**  
`get-deps.sh` will install prebuilt `nasm` and `mtoc` for those who don't want to build/install them themselves  

- **cleaned up error messages and program flow**  

## ver 2.0(191119)  
- **removed the requirement for the jshon command**  
found a small POSIX sh that takes care of it  
[elliptic-shiho parse_json.sh](https://gist.github.com/elliptic-shiho/45698491e1f3a0ba51f4c2e81d0fcfa4)  

- **removed -T option, no need since -t option is the same**  

- **fixed a "few" typos**  


## ver 2.0(171119)  
- **removed -c option**  
but ACPI files will still be copied from `extras` first  

- **removed -u and -U options**  
prebuilts will be using the json file  
latest source builds will check for git updates before building  
in either case tool will check itself for updates first  

- **changed -l to -s**  
-s seemed a little clearer to request latestSource  

- **the -X option will only remove local resources for current build type**  
e.g. `./OC-tool -Xs` will remove `resources/latestSource`  
`./OC-tool -X` will remove `resources/prebuiltRelease`  


## ver 2.0(151119)  
**removed `command` and `type` arguments when running tool**  
- `./OC-tool` with no options will now use prebuilt releases  
it should be able to build an EFI folder on any platform that can run a POSIX shell script  

- **`./OC-tool -l` will build an EFI from latest sources**  

- **`./OC-tool -d` will build an EFI from daily prebuilts**  
(not yet implemented)  

- **added -r option for release version instead of debug version**  
not recommended if you need help with certain issues  


## ver 1.7pt(281019)  
- **added -i option to ignore missing files**  
used with the -T option will provide a nice visual for problem solving  
e.g. `./OC-tool -iT ...` will highlight missing files in yellow  

- **save modified `config.plist` if changes were made**  
OC can fail on boot if `config.plist` doesn't match certain files in the EFI  
this should prevent some of that  


