@ECHO OFF

PUSHD "%~dp0"

python "convert-to-ent.py" "%~f1" "%~n1"

CHOICE /C CP /N /T 5 /D C /M "Press [C] to continue (or wait 5 sec) or [P] to pause..."
IF %ERRORLEVEL% EQU 2 PAUSE

POPD

EXIT /B
