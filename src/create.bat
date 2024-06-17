IF "%~1"=="" GOTO exit

SET root=%~dp0\..

mkdir "%ROOT%\Projects\%1\Custom"
mkdir "%ROOT%\Projects\%1\Data\Collision"
mkdir "%ROOT%\Projects\%1\Data\Enemies"
mkdir "%ROOT%\Projects\%1\Data\Misc"
mkdir "%ROOT%\Projects\%1\Data\PLMs"
mkdir "%ROOT%\Projects\%1\Data\RoboTile"
mkdir "%ROOT%\Projects\%1\Data\Text"

mkdir "%ROOT%\Projects\%1\Export\Rooms"
xcopy "%ROOT%\Projects\Base\Export\Rooms\" "%ROOT%\Projects\%1\Export\Rooms\"

mklink "%ROOT%\Projects\%1\project.xml" "..\Base\project.xml"
mklink /D "%ROOT%\Projects\%1\ASM" "..\Base\ASM"
mklink /D "%ROOT%\Projects\%1\Data\Tileset" "..\..\Base\Data\Tileset"
mklink "%ROOT%\Projects\%1\Data\RoboTile\Common.lua" "..\..\..\Base\Data\RoboTile\Common.lua"
mklink "%ROOT%\Projects\%1\Data\RoboTile\%1.lua" "..\..\..\Base\Data\RoboTile\%1.lua"
mklink "%ROOT%\Projects\%1\Data\RoboTile\%1.xml" "..\..\..\Base\Data\RoboTile\%1.xml"
mklink /D "%ROOT%\Projects\%1\Export\Demos" "..\..\Base\Export\Demos"
mklink /D "%ROOT%\Projects\%1\Export\Ending" "..\..\Base\Export\Ending"
mklink /D "%ROOT%\Projects\%1\Export\Enemies" "..\..\Base\Export\Enemies"
mklink /D "%ROOT%\Projects\%1\Export\Hexmaps" "..\..\Base\Export\Hexmaps"
mklink /D "%ROOT%\Projects\%1\Export\Intro" "..\..\Base\Export\Intro"
mklink /D "%ROOT%\Projects\%1\Export\Maps" "..\..\Base\Export\Maps"
mklink /D "%ROOT%\Projects\%1\Export\Music" "..\..\Base\Export\Music"
mklink /D "%ROOT%\Projects\%1\Export\Tileset" "..\..\Base\Export\Tileset"
mklink "%ROOT%\Projects\%1\Export\MessageBoxes.xml" "..\..\Base\Export\MessageBoxes.xml"

copy "%ROOT%\Projects\Base\quickmet.xml" "%ROOT%\Projects\%1\quickmet.xml"

:exit
