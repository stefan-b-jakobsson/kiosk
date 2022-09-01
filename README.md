# Building and installing

Build the program with the script in build/build.sh. It uses the cc65 tool chain.

The resulting file - kiosk.bin - is a 16 kB ROM image. It is meant to be installed
into ROM bank 9.

Build AUTOBOOT.X16 by using the build command specified in the source file autoboot.s. This results in a autoboot program that launces the menu program on startup.

# Config file

The menu program uses a config file to be stored in the root folder of the SD card, and named X16KIOSK.TXT.

In the provided config file, there are instructions on how to setup that file.

# Scrolling billboard text

At the top of the screen, there is a scrolling billboard style text.

The text is read from the file kioskmsg.txt on startup.

PETSCII chars $20 to $5f are supported. If written on a modern PC, the text should be in upper case.

The file may contain line breaks ($0a and $0d), but they are ignored.

PETSCII $68 (lower case h on a modern PC), is used as a control character that holds the scrolling text
for a moment.