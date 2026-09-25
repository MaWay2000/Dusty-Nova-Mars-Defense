# Dusty Nova: Mars Defense

[**Download the Windows prototype**](https://github.com/MaWay2000/Dusty-Nova-Mars-Defense/releases/tag/v0.1.0) · [Source code](https://github.com/MaWay2000/Dusty-Nova-Mars-Defense) · [Report an issue](https://github.com/MaWay2000/Dusty-Nova-Mars-Defense/issues)

A top-down survival game prototype built with Godot, GDScript, and 2D nodes. Survive increasingly difficult enemy waves on Mars, collect experience crystals, and choose upgrades as you level up.

This repository provides a desktop prototype and the Godot project. There is currently no GitHub Pages browser build linked for this project.

## Play the Windows release

1. Open the [v0.1.0 release page](https://github.com/MaWay2000/Dusty-Nova-Mars-Defense/releases/tag/v0.1.0).
2. Download `Dusty-Nova-Mars-Defense-Windows-v0.1.0.zip`.
3. Extract the complete archive to a folder.
4. Launch the included game executable.

The release also includes `DustyNova-Portable-v0.1.0.exe`. The source repository may contain changes newer than that release.

## Gameplay

A run contains four waves and lasts approximately **4 minutes 55 seconds**, including intermissions. Defeat enemies, collect green experience crystals, and select one of three upgrades at each level-up.

The upgrade pool contains 18 options across Common, Rare, and Legendary rarities, with upgrade level caps, guaranteed rarity choices, and one free reroll per run.

## Controls

| Action | Control |
| --- | --- |
| Move | WASD or arrow keys |
| Aim | Mouse |
| Fire | Automatic, toward the cursor |
| Pause | Escape or the on-screen Pause button |
| Debug overlay | F3 |

## Run from source

The project is configured for **Godot 4.7**.

```bash
git clone https://github.com/MaWay2000/Dusty-Nova-Mars-Defense.git
cd Dusty-Nova-Mars-Defense
```

1. Open Godot and import `project.godot`.
2. Allow the editor to import the project resources.
3. Press **F5** or choose **Run Project**.

The prototype uses generated placeholder shapes rather than an external visual asset pack. No npm or browser build pipeline is required.

## Project layout

- `project.godot`: project configuration and main-scene selection.
- `scenes/`: Godot scenes, including the main game scene.
- `scripts/`: gameplay and supporting logic.
- `data/`: game data.
- `tests/`: prototype checks.
- `export_presets.cfg`: export configuration.

## Prototype details

- The 1920×1080 reference layout uses `canvas_items` and `expand` stretch settings.
- Enemy and projectile counts are capped and cleaned up.
- Mouse aiming does not scan the entire enemy list every frame.
- Audio calls go through `AudioHooks`; missing audio files are tolerated.
- `InputController.set_mobile_direction()` is an extension point for a future virtual joystick, not a claim of a finished mobile control scheme.

## Feedback

[Report bugs or suggestions](https://github.com/MaWay2000/Dusty-Nova-Mars-Defense/issues) with the release version or commit, operating system, reproduction steps, and a screenshot or error output when available. Mention whether you used the downloadable build or ran the project in Godot.
