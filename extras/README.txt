place Drivers, Kexts and ACPI files here that OC-tool can't build on the fly
for example: HfsPlus.efi
OC-tool will check this folder when it has no repo to build a resource from

---

Also, Drivers, Kexts and ACPI files that you want to use a specific version of can be placed here
and by using ./OC-tool copy ... instead of ./OC-tool build ... the tool will look here before trying to build
