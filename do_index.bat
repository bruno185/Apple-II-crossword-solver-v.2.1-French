rem ------------ make indexes ------------
cd python
py ./p11.py
cd ..

Set CADIUS=F:\Bruno\Dev\AppleWin\Utilitaires\CADIUS.exe
Set Prodosvol=/BIG/L
Set poimage=cw.po

for %%i in (1 2 3 4 5 6 7 8 9 A B C D E F) do (
%CADIUS%  DELETEFOLDER %poimage% %Prodosvol%%%i )

for %%i in (1 2 3 4 5 6 7 8 9 A B C D E F) do (
%CADIUS%  ADDFOLDER %poimage% %Prodosvol%%%i python\L%%i )


