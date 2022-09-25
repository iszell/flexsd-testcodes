SD2IEC test codes V1.0 for VCPU R1

These programs are designed to test the functions of the VCPU extension.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Subject to this warning, the code may be used in whole or in any parts
without restriction.

------------------------------------------------------------------------
Requirements for compile:

  "The Macroassembler AS" / "asl":
    http://john.ccac.rwth-aachen.de:8000/as/
  Gnu make

------------------------------------------------------------------------
Compiling:

The codes compile to four platform (In order of appearance):
  Commodore VIC20
  Commodore 64
  Commodore 16, 116, plus/4 (264 series)
  Commodore 128

For compile, try these commands:

make target_platform=vic20
make target_platform=c64
make target_platform=c264
make target_platform=c128

These commands will compile all test programs for the selected platform.
A directory is created for the platform, where all the test programs are
copied together with the necessary files. This directory should be
copied to an SD card. This SD card can be inserted into an SD2IEC drive
and load this test programs.

For cleaning after compile, try these commands:

make clean target_platform=vic20
make clean target_platform=c64
make clean target_platform=c264
make clean target_platform=c128

The above commands clean up the directories containing the source code.
However, the directories for the platforms will retain the test programs
and files copied to them. To clean them up, try these commands:

make delexec target_platform=vic20
make delexec target_platform=c64
make delexec target_platform=c264
make delexec target_platform=c128

------------------------------------------------------------------------
Changelog:

2021.Oct.11. - 1.0
  Initial release
2021.Nov.20. - 1.0.1
  "vcpumacros.asl", "q-benchmark" modified
2021.Nov.20. - 1.0.2
  "q-benchmark" modified
------------------------------------------------------------------------
