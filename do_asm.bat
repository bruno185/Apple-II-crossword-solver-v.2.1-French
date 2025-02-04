@echo off

rem Compile assembly language program using Merlin32
rem Copy binany code to disk image.
rem Then start Applewin emulator and boot on image disk.

if %errorlevel% neq 0 exit /b %errorlevel%
echo --------------- Variables ---------------
rem name of program. Change it to your own program name
Set PRG=cw
rem current folder
Set ProjectFolder=.

Set MyAppleFolder=F:\Bruno\Dev\AppleWin
Set APPLEWIN=%MyAppleFolder%\AppleWin\Applewin.exe
Set MERLIN32ROOT=%MyAppleFolder%\Merlin32_v1.0
Set MERLIN32LIBS=%MERLIN32ROOT%\Library
Set MERLIN32WIN=%MERLIN32ROOT%\Windows
Set MERLIN32EXE=%MERLIN32WIN%\merlin32.exe
Set APPLECOMMANDER=%MyAppleFolder%\Utilitaires\AppleCommander-win64-1.6.0.jar
Set CADIUS=%MyAppleFolder%\Utilitaires\Cadius.exe
rem Set ACJAR=java.exe -jar %APPLECOMMANDER%    ; avec ""
Set ACJAR=java.exe -jar %APPLECOMMANDER%
rem echo %ACJAR%

echo --------------- debut Merlin ---------------
%MERLIN32EXE% -V %MERLIN32LIBS% %ProjectFolder%\%PRG%.s
if exist %ProjectFolder%\error_output.txt exit
echo --------------- fin Merlin ---------------

echo --------------- Debut Applecommander ---------------
rem add binary program to image disk
rem 16384 = $4000. Change it to your own ORG address.
%ACJAR% -d %PRG%.po %PRG%
%ACJAR% -p %PRG%.po %PRG% bin 4096 < %PRG%
echo --------------- fin Applecommander ---------------

echo --------------- Debut Applewin ---------------
rem launch applewin with image disk in drive
rem %APPLEWIN% -d1 %PRG%.po
rem SetBreaks.exe
python debug.py
%APPLEWIN% -h1 %PRG%.po
echo --------------- Fin Applewin ---------------
