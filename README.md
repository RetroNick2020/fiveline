# fiveline
RetroNick's version the classic puzzle/logic game. 

![Try the online version]https://retronick.neocities.org/fiveline/game.html)

Current version is portable and with little modifications can be ported to other platforms. Source code can be compiled for DOS using freepascal GO32 and 8086 compilers without any achanges. The code can also be compiled in turbo pascal without any changes.

Windows users just need to replace Crt with WinCrt - change gm,gd to VGA and VGAHI. For some reason EGA modes don't work on Windows. Windows users will also need to adjust constants to make the game board much bigger. I may get to this later on.

For those who want to study the code the most interesting aspect of this is the path finding part of the code. This can be gutted and used in other games.


![](https://github.com/retronick2020/fiveline/wiki/images/fiveline.png)
