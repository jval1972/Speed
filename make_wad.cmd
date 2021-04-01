make_speeddef -o SCRIPT\actordef.inc -i WADSRC\SPEED\BASEACTORS.txt -i WADSRC\SPEED\BASEDECORATIONS.txt -i WADSRC\SPEED\CAMERA.txt  -i WADSRC\SPEED\CAR.txt -i WADSRC\SPEED\EASYSLOPE.txt -i WADSRC\SPEED\MODELDECORATIONS.txt -i WADSRC\SPEED\PARTICLES.txt -i WADSRC\SPEED\PATH.txt -i WADSRC\SPEED\RACE.txt -i WADSRC\SPEED\SPEEDALIAS.txt
cd .\WADSRC
"C:\Program Files\7-Zip\7z.exe" a -r ..\..\bin\SPEED.zip *.*
move ..\..\bin\SPEED.zip ..\..\bin\Speed.pk3
dir ..\..\bin\Speed.pk3
pause