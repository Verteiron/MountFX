@echo off
SET SOURCEDIR=C:\Games\ModOrganizer\mods\MountFX
SET TARGETDIR=%USERPROFILE%\Dropbox\SkyrimMod\Mountfx\dist\Data

xcopy /E /U /Y "%SOURCEDIR%\*" "%TARGETDIR%\"
