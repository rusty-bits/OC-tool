# OC-tool
command line tool for building OpenCore EFI folder

Builds a working EFI folder based on the list of drivers, kexts and options that your config.plist specifies.

Note: This tool makes certain assumptions, such as:
xcode, nasm, mtoc etc. required to build EFI files are correctly installed and configured to run from the command line

---

**Build Process the tool goes through**

When run, the tool will create a tool.log file, clone any needed packages, update any existing packages, and build and copy the base files

Next, it will clone or update any required driver packages based on the UEFI/Drivers section of `config.plist`, then build  and copy them to `EFI/OC/Drivers`  

It then does the same for the kexts based on the Kernel/Add section of `config.plist` and copies them to `EFI/OC/Kexts`

If config.plist file has RequireVault set then `vault.plist` and `vault.sig` will be created automatically, and `OpenCore.efi` will be updated

Lastly, if any git updates were pulled it will list them.

---

**Installation**:

`git clone https://github.com/rusty-bits/OC-tool`   
`cd OC-tool`

then place your config.plist file in the appropriate directory, eg.  
`cp Docs/SampleFull.plist RELEASE/config.plist` for making a release version

`cp Docs/SampleFull.plist DEBUG/config.plist` for making a debug version

---

**Usage**: (*release*)

edit `RELEASE/config.plist` as appropriate.  

`./OpenCore-tool.sh build release`

This will create a `RELEASE/EFI` directory with all the required files, this can be copied to an EFI partition

---

**Usage**: (*debug*)

to create a debug version...

edit `DEBUG/config.plist` as needed.  

`./OpenCore-tool.sh build debug`

This will create a `DEBUG/EFI` directory with all the required files, this can be copied to an EFI partition

---

**Vault files:**

The tool will automatically build the required vault files based on the setting of the `RequireVault` field in `config.plist` and place them in the `EFI/OC` directory

---

**Description of files in `Docs` directory:**
`Sample.plist` and `SampleFull.plist` are from acidanthera/OpenCorePkg/Docs and will also be found locally in `OC-tool/resources/UDK/OpenCorePkg/Docs` they are updated when the tool is run, there is a notification if they have been updated, check the `OpenCorePkg/Docs/Configuration.pdf` document and update `RELEASE/config.plist` or `DEBUG/config.plist` when needed

`repo.plist` is a plist linking efi and kext files to their repositories

---

**Descriprion of files in `DEBUG` and `RELEASE` directories:**

`config.plist` is the config file that is used to see which drivers and kexts will be built, it is then copied to `EFI/OC/config.plist`  

---

**Notes:**

still a work in progress, I think the code is quite cluttered, but I'm working on it   
planning to add the Tools folder and ACPI folder when I get around to it
