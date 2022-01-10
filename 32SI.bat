@ECHO OFF

SETLOCAL EnableExtensions EnableDelayedExpansion

GOTO RequirementsCheck



:RequirementsCheck

IF NOT "%OS%" == "Windows_NT" (
    ECHO This version of Windows is not supported. Requires Windows_NT
    GOTO ExitWithCode1
)

GOTO Initialization



:: EXITs on idle or PAUSE on interaction
:PressToExitOrPause
    IF %~1 EQU -1 PAUSE & EXIT /B
    CHOICE /C CP /N /T %~1 /D C /M "Press [C] to continue (or wait %~1 sec) or [P] to pause..."
    IF %ERRORLEVEL% EQU 2 PAUSE
    EXIT /B



:Initialization

SET "ProgramName=%~nx0"
SET "ProgramVersion=2022.01.10"

SET "WorkingDir=%~dp0"

IF "%~1" == "/?" GOTO Syntax
IF "%~1" == "-h" GOTO Syntax
IF "%~1" == "--help" GOTO Syntax

IF "%~1" == "" (
    ECHO No arguments specified. Try '%ProgramName% /?' for help
    GOTO ExitWithCode1
)

SET "DLURL32SI=https://gamebanana.com/mods/333654"

SET "RipEntAppName=ripent_x64.exe"

IF "%PROCESSOR_ARCHITECTURE%" == "x86" (
    IF NOT DEFINED PROCESSOR_ARCHITEW6432 (
        SET "RipEntAppName=ripent.exe"
    )
)

GOTO LoadConfig



:LoadConfig

SET "AppConfig=%WorkingDir%32SI.cfg"

IF NOT EXIST "%AppConfig%" (
    SET "WaitBeforeExitSec=3"
    SET "BackupOriginalEnt=0"
    GOTO IntegrityCheck
)

IF EXIST "%AppConfig%" (
    FOR /F "usebackq eol=# tokens=1,2 delims==" %%A IN ("%AppConfig%") DO (

        REM Ignore anything after a space or a tab
        FOR /F "usebackq tokens=1*" %%C IN ('%%A') DO SET "VariableName=%%C"
        FOR /F "usebackq tokens=1*" %%D IN ('%%B') DO SET "VariableValue=%%D"

        IF NOT "!VariableName!" == "" (
            IF NOT "!VariableValue!" == "" (
                IF !VariableValue! EQU -1 (
                    SET "!VariableName!=!VariableValue!"
                ) ELSE (
                    SET "!VariableName!=!VariableValue:~0,1!"
                )
            )
        )
    )
)

:: This is how I can tell if I have a custom value to validate
SET "CustomWaitBeforeExitSec=1"
SET "CustomBackupOriginalEnt=1"

IF NOT DEFINED WaitBeforeExitSec (
    SET "WaitBeforeExitSec=3"
    SET "CustomWaitBeforeExitSec=0"
)

IF NOT DEFINED BackupOriginalEnt (
    SET "BackupOriginalEnt=0"
    SET "CustomBackupOriginalEnt=0"
)

IF %CustomWaitBeforeExitSec% EQU 1 (
    IF %WaitBeforeExitSec% NEQ -1 (
        IF 1%WaitBeforeExitSec% NEQ +1%WaitBeforeExitSec% (
            SET "WaitBeforeExitSec=3"
        )
    )
)

IF %CustomBackupOriginalEnt% EQU 1 (
    IF %BackupOriginalEnt% NEQ 0 (
        IF %BackupOriginalEnt% NEQ 1 (
            SET "BackupOriginalEnt=0"
        )
    )
)

GOTO IntegrityCheck



:IntegrityCheck

SET "EntDir=%WorkingDir%ent\"
SET "ToolsDir=%WorkingDir%tools\"
SET "RipEntApp=%WorkingDir%tools\%RipEntAppName%"

IF NOT EXIST "%EntDir%" (
    ECHO Cannot find: %EntDir%
    GOTO ExitWithCode1
)

IF NOT EXIST "%ToolsDir%" (
    ECHO Cannot find: %ToolsDir%
    GOTO ExitWithCode1
)

IF NOT EXIST "%RipEntApp%" (
    ECHO Cannot find: %RipEntApp%
    GOTO ExitWithCode1
)

FOR /F "usebackq" %%A IN (`DIR /A-D /B "%EntDir%\*.ent" 2^>NUL ^| FIND /C /V ""`) DO (
    SET "EntFilesCount=%%A"
)

IF %EntFilesCount% EQU 0 (
    ECHO No entity files found. Entity files can be downloaded from %DLURL32SI%
    GOTO ExitWithCode1
)

GOTO HandleCLArguments



:HandleCLArguments

IF EXIST "%~f1" (
    SET "InputObjType=File"
)

IF EXIST "%~f1\" (
    SET "InputObjType=Folder"
)

IF "%InputObjType%" == "File" GOTO HandleInputFile

IF "%InputObjType%" == "Folder" GOTO HandleInputFolder



:HandleInputFile

IF NOT "%~x1" == ".bsp" (
    ECHO Cannot process %~nx1 - not a BSP file
    GOTO ExitWithCode1
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
    GOTO ExitWithCode1
)

IF %BackupOriginalEnt% EQU 1 (
    ECHO:
    ECHO Creating a backup of %BspFileName% entities
    ECHO:

    "%RipEntApp%" -export "%BspFile%" && MOVE "%EntFileNextToBsp%" "%EntFileNextToBsp%.bak" >NUL
)

COPY /V "%NewEntFile%" "%EntFileNextToBsp%" >NUL

ECHO:
ECHO Processing %BspFileName%
ECHO:
"%RipEntApp%" -import "%BspFile%" &&^
DEL %EntFileNextToBsp%

GOTO ExitWithCode0



:HandleInputFolder

FOR /F "usebackq" %%A IN (`DIR /A-D /B "%~f1\*.bsp" 2^>NUL ^| FIND /C /V ""`) DO (
    SET "BspFilesCount=%%A"
)

IF %BspFilesCount% EQU 0 (
    ECHO No BSP files found in %~f1
    GOTO ExitWithCode1
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
        IF !BackupOriginalEnt! EQU 1 (
            ECHO:
            ECHO Creating a backup of !BspFileName! entities
            ECHO:

            "!RipEntApp!" -export "!BspFile!" && MOVE "!EntFileNextToBsp!" "!EntFileNextToBsp!.bak" >NUL
        )

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

GOTO ExitWithCode0



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
ECHO   https://github.com/s0nought/32si/blob/master/README.md

PAUSE
ENDLOCAL
EXIT /B



:ExitWithCode0
CALL :PressToExitOrPause "%WaitBeforeExitSec%"
ENDLOCAL
EXIT /B 0



:ExitWithCode1
PAUSE
ENDLOCAL
EXIT /B 1
