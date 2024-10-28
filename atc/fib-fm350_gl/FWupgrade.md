# Firmware upgrade upgrade to 29.23.06

Upgrade is done with SP Flash Tool, v6.2124, in Windows environment.\
\
\
**Prepare FW package:**
- Go to [Microsoft update, Fibocom FM350-GL](https://www.catalog.update.microsoft.com/Search.aspx?q=Firmware%203500*)
- Download: `Fibocom Wireless Inc. - Firmware - 3500.5003.2306.7`
- Extrac `cab`-file
- Extract `FwPackage.flz`
- Copy directory `81600.0000.00.29.23.06` to a known location
- Copy directory `download_agent` to your `81600.0000.00.29.23.06` directory
- Copy `Scatter.xml` to your `81600.0000.00.29.23.06` directory
- Copy `OEM_OTA_5000.0002.018.img` and `OP_OTA_302.011.img` to your `81600.0000.00.29.23.06` directory
- Rename
  - `OEM_OTA_5000.0002.018.img` to `OEM_OTA.img`
  - `OP_OTA_302.011.img` to `OP_OTA.img`
- Copy all files in directory `FM350.F09` to your `81600.0000.00.29.23.06` directory
- Open directory `FM350.F09_preloader`
  - Copy `FM350.F09_loader_ext-verified_00.10.img` and `FM350.F09_preloader_35001CF8_00.10.bin` to your `81600.0000.00.29.23.06` directory
  - Rename
    - `FM350.F09_loader_ext-verified_00.10.img` to `loader_ext-verified.img`
    - `FM350.F09_preloader_35001CF8_00.10.bin` to `preloader_k6880v1_mdot2_datacard.bin`


Content of `81600.0000.00.29.23.06` directory\
![image](https://github.com/user-attachments/assets/f19e3d80-9d24-424c-b99b-f60871d6067f)


**Firmware upgrade**
- Launch `SP Flash Tool`

![image](https://github.com/user-attachments/assets/e4a7b80f-ebdc-4c16-89ca-06c74ce57977)



[Download SP Flash Tool v6.2124](https://spflashtools.com/windows/sp-flash-tool-v6-2124)
\
\
Sourec: https://4pda.to/forum/index.php?showtopic=1057776&st=420#entry128299931
