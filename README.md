# OC-tool
Command line tool for building OpenCore EFI folder

Builds a working EFI folder based on the list of drivers, kexts, acpi and options that your config.plist specifies.

Note: This tool makes certain assumptions, such as:  
- git is installed  
- xcode, nasm, and mtoc required to build EFI files are correctly installed and configured to run from the command line  
- iasl is installed if you want the tool to compile .dsl files into .aml on the fly, but I recommend you compile them yourself and place them in the extras directory. The tool will copy what's needed to the EFI directory.  

---

**Process the tool goes through**

When first run the tool will pull and build needed base files.

Next, it will clone or update any required driver packages based on the UEFI/Drivers section of `config.plist`, then build any new or changed packages. 

It then does the same for the kexts based on the Kernel/Add section of `config.plist` and then the ACPI/Add section.  

The files are then copied to an EFI folder that can be dropped right into a boot partition, and if `config.plist` has RequireVault set then `vault.plist` and `vault.sig` will be created automatically, and `OpenCore.efi` will be updated.  

---

**Installation**:

`git clone https://github.com/rusty-bits/OC-tool`   
`cd OC-tool`

then place your config.plist file in the appropriate directory, or copy and edit one of the sample plist files. eg.    
`cp Docs/SampleFull.plist RELEASE/config.plist` for making a release version

`cp Docs/SampleFull.plist DEBUG/config.plist` for making a debug version

see the [OC-tool wiki pages](https://github.com/rusty-bits/OC-tool/wiki) for more information
