@rem                                               Example file which.bat 
@echo off

if "%1" == "" (
    echo Usage: which command
    echo Locates the file run when you type 'command'.
    exit /b
)

for %%d in (. %path%) do (
    if "%~x1" == "" (
        rem the user didn't type an extension so use the PATHEXT list
        for %%e in (%pathext%) do (
            if exist %%d\%1%%e (
                echo %%d\%1%%e
                exit /b
            )
        )
    ) else (
        rem the user typed a specific extension, so look only for that
        if exist %%d\%1 (
            echo %%d\%1
            exit /b
        )
    )
)
echo No file for %1 was found