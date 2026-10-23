# RAID SuperBLT
An open-source Lua hook for RAID World War II, designed and created for ease of use for players and modders.  
This repository is for the Lua base that controls and loads mods into RAID and the options and save files associated with the BLT. The DLL hook code can be found in its own [repository](https://github.com/RAIDModding/RAID-SuperBLT).

This developer repository should only be used if you know what you're doing. If you don't, visit https://modworkshop.net/mod/49744 to get information regarding the installation of SuperBLT.

## Download
Visit https://modworkshop.net/mod/49744 to get the latest stable download.  

## Lua functions of the DLL
Besides the classes of this base mod, the DLL provides global functions for mods. The ones that came with newer DLL versions are documented in the [DLL repository](https://github.com/RAIDModding/RAID-SuperBLT):

- [`dohttpreq` and `clearhttpcookies`](https://github.com/RAIDModding/RAID-SuperBLT/blob/master/doc/dohttpreq.md): HTTP requests. Besides a plain GET they take methods, request headers, a body (so logins and APIs with tokens work), cookies and named cookie jars, and they speak http, https, ftp and ftps. These options need a DLL version that has them, older ones don't know them, so check the DLL version (`blt.blt_version()`) first.
