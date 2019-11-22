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


