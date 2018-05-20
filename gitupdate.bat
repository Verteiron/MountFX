@echo off
SET SOURCEDIR=C:\Games\ModOrganizer\mods\MountFX
SET TARGETDIR=%USERPROFILE%\Dropbox\SkyrimMod\Mountfx\dist\Data

xcopy /E /D /U /Y "%SOURCEDIR%\*" "%TARGETDIR%\"
