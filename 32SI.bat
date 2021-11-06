@ECHO OFF

SETLOCAL EnableExtensions EnableDelayedExpansion

GOTO Initialization



:: EXITs on idle or PAUSE on interaction
:PressToExitOrPause
    CHOICE /C CP /N /T %~1 /D C /M "Press [C] to continue (or wait %~1 sec) or [P] to pause..."
    IF %ERRORLEVEL% EQU 2 PAUSE
    EXIT /B



:Initialization

SET "ProgramName=%~nx0"
SET "ProgramVersion=2021.11.06"

SET "DLURL32SI=https://gamebanana.com/mods/333654"
SET "DLURLRipEnt=https://files.gamebanana.com/bitpit/ripent_from_vhltv34.zip"

SET "RipEntAppName=ripent_x64.exe"

IF "%PROCESSOR_ARCHITECTURE%"=="x86" (
    IF NOT DEFINED PROCESSOR_ARCHITEW6432 (
        SET "RipEntAppName=ripent.exe"
    )
)

GOTO RequirementsCheck



:RequirementsCheck

IF NOT "%OS%"=="Windows_NT" (
    ECHO This version of Windows is not supported. Requires Windows_NT
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

GOTO IntegrityCheck



:IntegrityCheck

SET "WorkingDir=%~dp0"

SET "EntDir=%WorkingDir%ent\"
SET "ToolsDir=%WorkingDir%tools\"
SET "RipEntApp=%WorkingDir%tools\%RipEntAppName%"

IF NOT EXIST "%EntDir%" (
    ECHO Cannot find: %EntDir%
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

IF NOT EXIST "%ToolsDir%" (
    ECHO Cannot find: %ToolsDir%
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

IF NOT EXIST "%RipEntApp%" (
    ECHO Cannot find: %RipEntApp%. ripent can be downloaded from %DLURLRipEnt%
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

FOR /F "usebackq" %%A IN (`DIR /A-D /B "%EntDir%\*.ent" 2^>NUL ^| FIND /C /V ""`) DO (
    SET "EntFilesCount=%%A"
)

IF %EntFilesCount%==0 (
    ECHO No entity files found. Entity files can be downloaded from %DLURL32SI%
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

GOTO ArgumentsParsing



:ArgumentsParsing

IF "%~1"=="/?" GOTO Syntax
IF "%~1"=="-h" GOTO Syntax
IF "%~1"=="--help" GOTO Syntax

IF "%~1"=="" (
    ECHO No arguments specified. Try '%ProgramName% /?' for help
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

IF EXIST "%~f1" (
    SET "InputObjType=File"
)

IF EXIST "%~f1\" (
    SET "InputObjType=Folder"
)

IF "%InputObjType%"=="File" GOTO HandleInputFile

IF "%InputObjType%"=="Folder" GOTO HandleInputFolder

GOTO Finalization



:HandleInputFile

IF NOT "%~x1"==".bsp" (
    ECHO Cannot process %~nx1 - not a BSP file
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

ECHO:
ECHO Working mode - File
ECHO:

SET "BspFileName=%~n1"
SET "BspFile=%~f1"

:: Full path to the ent file after -export command
:: Full path of the ent file to back up
:: Full path to copy the new ent file to (so that -import command succeeds)
:: Full path of the ent file to delete after -import command
SET "EntFileNextToBsp=%~dp1%BspFileName%.ent"

SET "NewEntFile=%EntDir%%BspFileName%.ent"

IF NOT EXIST "%NewEntFile%" (
    ECHO Cannot find: %NewEntFile%
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

ECHO:
ECHO Creating a backup of %BspFileName% entities
ECHO:
"%RipEntApp%" -export "%BspFile%" &&^
MOVE "%EntFileNextToBsp%" "%EntFileNextToBsp%.bak" >NUL

COPY /V "%NewEntFile%" "%EntFileNextToBsp%" >NUL

ECHO:
ECHO Processing %BspFileName%
ECHO:
"%RipEntApp%" -import "%BspFile%" &&^
DEL %EntFileNextToBsp%

GOTO Finalization



:HandleInputFolder

FOR /F "usebackq" %%A IN (`DIR /A-D /B "%~f1\*.bsp" 2^>NUL ^| FIND /C /V ""`) DO (
    SET "BspFilesCount=%%A"
)

IF %BspFilesCount%==0 (
    ECHO No BSP files found in %~f1
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

ECHO:
ECHO Working mode - Folder
ECHO:

PUSHD "%~f1"

SET "LoopProcessedFiles=0"

FOR %%A IN (*.bsp) DO (
    SET "BspFileName=%%~nA"
    SET "BspFile=%%~fA"

    REM See comments in the HandleInputFile
    SET "EntFileNextToBsp=%%~dpA!BspFileName!.ent"

    SET "NewEntFile=!EntDir!!BspFileName!.ent"

    IF NOT EXIST "!NewEntFile!" (
        ECHO Cannot find: !NewEntFile!
    ) ELSE (
        ECHO:
        ECHO Creating a backup of !BspFileName! entities
        ECHO:
        "!RipEntApp!" -export "!BspFile!" && MOVE "!EntFileNextToBsp!" "!EntFileNextToBsp!.bak" >NUL

        COPY /V "!NewEntFile!" "!EntFileNextToBsp!" >NUL

        ECHO:
        ECHO Processing !BspFileName!
        ECHO:
        "!RipEntApp!" -import "!BspFile!" && DEL !EntFileNextToBsp!

        SET /A "LoopProcessedFiles+=1"
    )
)

ECHO:
ECHO Processed %LoopProcessedFiles% of %BspFilesCount% files
ECHO:

POPD

GOTO Finalization



:Syntax

ECHO %ProgramName% version %ProgramVersion%
ECHO:
ECHO USAGE
ECHO   %ProgramName% mapname.bsp
ECHO   %ProgramName% folder
ECHO:
ECHO DESCRIPTION
ECHO   Update entities in a single file or a collection of files
ECHO:
ECHO ABOUT
ECHO   https://github.com/s0nought

GOTO Finalization



:Finalization
CALL :PressToExitOrPause "5"
ENDLOCAL
EXIT /B
