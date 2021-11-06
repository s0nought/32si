# 32 Spawns Initiative

## Summary
A collection of telefrag-free-32-spawns entity files and means to install them (`32SI.bat`).

## Description
> entities define all aspects of a map that make a map playable and interactive
[Wiki: Entity - TWHL: Half-Life and Source Mapping Tutorials and Resources](https://twhl.info/wiki/page/entity)

Entity file is a plain text file storing a list of entities. It can be exported from and imported into the map (BSP file) using ripent.

Spawn is an entity placed in the map to tell the game engine where to teleport the player in the start of the round.

    CT     info_player_start
    T      info_player_deathmatch
    VIP    info_vip_start

Spawns might be placed too close to each other or world objects causing telefrag (being killed "landing" a teleport). There might not be enough spawns for 32 players.

## 32SI.bat
Update entities in a single file or a collection of files.

    C:\> 32SI.bat mapname.bsp
    C:\> 32SI.bat folder

## Requirements
ripent.exe (x86) or ripent_x64.exe (x64) saved to the `tools` folder.
