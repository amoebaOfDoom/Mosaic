# Mosaic
SMART project files for restyling vanilla Super Metroid

This project is included as a submodule in the Map Rando project https://github.com/blkerby/MapRandomizer/

## Setup

Each style has its own project folder. Common files are symlinked to the base project, so you will need to enable symlink support before checking out this repo. If you have an old copy of git, it's possible this isn't working right. You can get an updated one from here: https://git-scm.com/downloads

`git config --global core.symlinks true`

You'll also need to make sure you have permissions to create symlinks on Windows. The easiest way to do this is to enable "Developer Mode" in the Windows settings app. The setting says that it allows side loading apps, but that's pretty mino considering that it's Windows. It also enables a bunch of random things, like letting you make symlinks without being admin.

You'll need the latest SMART to open the projects: https://edit-sm.art/download.html
Some of these releases are missing the Lua dll file that makes retiling rooms much easier, oops.

Once you have SMART open, go to the config and open the a project folder. Load from XML to view and edit rooms.

## Contributing

Changes are coordinated in the Map Rando Discord. Link avialable here: https://maprando.com/

Completed projects become available for testing in the main Map Rando site using the extra options after generating a seed. Bug repors can be submitted in the Map Rando Discord.

To mark rooms as ready to use, set the room special GFX flag `$80`. This is meaningless in the engine, but is used by the tooling to detect which rooms should be loaded by the rando.

`validate_bts.py` is used to check if rooms have altered bts. Since the goal here is to leave collision unaltered, make sure that you didn't accedently edit the bts while using the room editor.

If you need to make changes to the tileset, try to get a PR for those changes up quickly as tileset files are binary and difficult to merge. If you know a good way to make GitHub merge fixed length bytewise files, that'd be neat.
