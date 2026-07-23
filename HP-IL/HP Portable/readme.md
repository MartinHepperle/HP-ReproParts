
These files demonstrate how to use the HP-IL interface of the HP 110 and the Portable Plus from Microsoft BASIC.
The module works with the ROM-based BASIC interpreter and should also be usable with the disk-based GWBASIC interpreter for the HP Portable.
A binary module with several functions is loaded and can be used to interact with HP-IL devices on the loop.

Assemble on a PC with e.g. DOS-BOX
--------------------
The assembler source in HPIL.ASM can be assembled with a batch file like GO.BAT and the resulting binary file can be converted into a BASIC program in an ASCII format by using the Python script.
This script creates code to load the binary and adds an example program for talking to a digital voltmeter. The loader saves the machine code as a binary file whichj can later be loaded with BLOAD to speed the loading proces up.

Transfer to the Portable
--------------------
For transferring the ASCII file to the portable a serial interface and the bult in or one of the ROM-based terminal programs can be used.
