# OC-tool
command line tool for building OpenCore EFI folder

Builds a working EFI folder based on the list of drivers, kexts , acpi and options that your config.plist specifies.

Note: This tool makes certain assumptions, such as:  
-git is installed
-xcode, nasm, and mtoc required to build EFI files are correctly installed and configured to run from the command line  
-iasl is installed if you want the tool to compile .dsl files into .aml on the fly, but I recommend you compile them yourself and place them in the extras directory. The tool will copy whats needed to the EFI directory.  

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

---

**Usage**: (*for building release configuration*)

edit `RELEASE/config.plist` as appropriate.  

`./OpenCore-tool build release`

This will create a `RELEASE/EFI` directory with all the required files, this can be copied to an EFI partition

---

**Usage**: (*for building debug configuration*)

edit `DEBUG/config.plist` as needed.  

`./OpenCore-tool build debug`

This will create a `DEBUG/EFI` directory with all the required files, this can be copied to an EFI partition

---

**Vault files:**

The tool will automatically build the required vault files based on the setting of the `RequireVault` field in `config.plist` and place them in the `EFI/OC` directory

---

**Description of files in `Docs` directory:**
`Sample.plist` and `SampleFull.plist` are from acidanthera/OpenCorePkg/Docs and will also be found locally in `OC-tool/resources/UDK/OpenCorePkg/Docs` they are updated when the update command is used, there is a notification if they have been updated, check the `OpenCorePkg/Docs/Configuration.pdf` document and update `RELEASE/config.plist` or `DEBUG/config.plist` when needed  

---

**Descriprion of files in `DEBUG` and `RELEASE` directories:**

`config.plist` is the config file that is used to see which drivers and kexts will be built, it is then copied to `EFI/OC/config.plist`  

---

**Description of files in `tool-files` directory:**  

`repo.plist` is a plist linking efi and kext files to their repositories  

`usage.msg` usage message  

`help.msg` message shown with the -h option  

---

**Description of `extras` directory:**  

Kexts, Drivers, and ACPI files that OpenCore-tool can not build or that you want built in a certain way are placed in the `extras` directory.  They will then be copied to the appropriate place in the new `EFI` if needed.  

The build command first builds what it can, and then will check the extras directory for any files needed in the EFI directory.  
The copy command first checks the extras directory for needed files, and uses those if they are found, then it will build any remaining files neede for the EFI directory.  

The one exception is ACPI files, the tool will always use an ACPI file found in the extras directory before trying to compile a .dsl file (if one exists) for both the build and copy commands.  

---

**Notes:**

-code needs cleaning, I'm working on it   
-unsure if macOS Catalina will support bash commands right out of the box  
....rewrote code to be POSIX compliant so it will run without issue in sh  
....this may break on the fly Shell.efi building if edksetup.sh is not POSIX compliant  
