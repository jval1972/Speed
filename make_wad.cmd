make_speeddef -o SCRIPT\actordef.inc -i WADSRC\SPEED\BASEDECORATIONS.txt -i WADSRC\SPEED\CAMERA.txt -i WADSRC\SPEED\PARTICLES.txt -i WADSRC\SPEED\PATH.txt -i WADSRC\SPEED\SPEEDALIAS.txt
cd .\WADSRC
"C:\Program Files\7-Zip\7z.exe" a -r ..\..\bin\SPEED.zip *.*
move ..\..\bin\SPEED.zip ..\..\bin\SPEED.pk3
dir ..\..\bin\SPEED.pk3
pause