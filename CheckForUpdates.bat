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
SET "ProgramVersion=2021.11.11"

SET "CURLFailedErrorText=Failed to get the response from the server. Please try again later"

:: GameBanana API returns JSON

:: It is necessary to escape the equals sign in the URL for the FOR /F
SET "RequestVersionURL=https://gamebanana.com/apiv7/Mod/333654?_csvProperties^=_aAdditionalInfo"

:: The first reference of _sDownloadUrl from the array of objects it returns is going to be parsed out
SET "RequestDownloadURL=https://gamebanana.com/apiv7/Mod/333654?_csvProperties^=_aFiles"

GOTO ArgumentsParsing



:ArgumentsParsing

IF "%~1"=="/?" GOTO Syntax
IF "%~1"=="-h" GOTO Syntax
IF "%~1"=="--help" GOTO Syntax

GOTO RequirementsCheck



:RequirementsCheck

IF NOT "%OS%"=="Windows_NT" (
    ECHO This version of Windows is not supported. Requires Windows_NT
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

curl --help >NUL || (
    ECHO CURL is required but cannot be found. Please install CURL and try again
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

GOTO IntegrityCheck



:IntegrityCheck

SET "WorkingDir=%~dp0"

SET "VersionFile=%WorkingDir%version.txt"

IF NOT EXIST "%VersionFile%" (
    ECHO Cannot find: %VersionFile%
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

GOTO Main



:Main

FOR /F "usebackq tokens=*" %%A IN ("%VersionFile%") DO SET "InstalledVersion=%%A"

:: https://stackoverflow.com/a/56653132
IF 1%InstalledVersion% NEQ +1%InstalledVersion% (
    ECHO Failed to read version information from
    ECHO:%VersionFile%
    ECHO The file might be corrupted or empty
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

curl --silent --location --get --url %RequestVersionURL% >NUL 2>NUL

IF %ERRORLEVEL% NEQ 0 (
    ECHO:%CURLFailedErrorText%
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

:: token 2 is ' "X"'
FOR /F "delims=: tokens=2" %%A IN ('curl --silent --location --get --url %RequestVersionURL% ^| FIND "Version"') DO (
    SET "LatestVersionRaw=%%A"
)

:: remove ' "' and '"' so it is an integer
SET "LatestVersion=%LatestVersionRaw:~2,-1%"

IF %LatestVersion% EQU %InstalledVersion% (
    ECHO Your version is up-to-date
    GOTO Finalization
)

IF %LatestVersion% GTR %InstalledVersion% (
    ECHO An update to version %LatestVersion% is available
    GOTO HandleDownloadUpdate
)

IF %LatestVersion% LSS %InstalledVersion% (
    ECHO Have you modified version.txt manually.. hehe
    GOTO Finalization
)

ECHO:%CURLFailedErrorText%
GOTO Finalization



:HandleDownloadUpdate

CHOICE /C YN /M "Would you like to download the update now?"
IF %ERRORLEVEL% EQU 2 GOTO Finalization

curl --silent --location --get --url %RequestDownloadURL% >NUL 2>NUL

IF %ERRORLEVEL% NEQ 0 (
    ECHO:%CURLFailedErrorText%
    CALL :PressToExitOrPause "5"
    ENDLOCAL
    EXIT /B 1
)

:: token 3 is everything after 'https:'
FOR /F "delims=: tokens=3" %%A IN ('curl --silent --location --get --url %RequestDownloadURL% ^| FIND "_sDownloadUrl"') DO (
    SET "LatestDownloadRaw=%%A"
)

:: add 'https:' and remove the trailing '"'
SET "LatestDownloadMod=https:%LatestDownloadRaw:~0,-1%"

:: un-escape the slashes
SET "LatestDownload=%LatestDownloadMod:\/=/%"

:: --remote-header-name won't work
SET "OutputFileName=%WorkingDir%32si_version%LatestVersion%.zip"

curl --silent --location --output "%OutputFileName%" --get --url %LatestDownload% && (
    ECHO Writing %OutputFileName%
) || (
    ECHO:%CURLFailedErrorText%
)

GOTO Finalization



:Syntax

ECHO %ProgramName% version %ProgramVersion%
ECHO:
ECHO USAGE
ECHO   %ProgramName%
ECHO:
ECHO DESCRIPTION
ECHO   Check for updates for 32SI.
ECHO:
ECHO NOTES
ECHO   CURL is required to run this program.
ECHO:
ECHO ABOUT
ECHO   https://github.com/s0nought

GOTO Finalization



:Finalization
CALL :PressToExitOrPause "5"
ENDLOCAL
EXIT /B
