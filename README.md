# Dusty Nova: Mars Defense — First Playable Prototype

A dependency-free Godot 4 top-down survival prototype using only 2D nodes, GDScript, and generated placeholder shapes.

## Run

1. Open this folder's `project.godot` in Godot 4.
2. Press **F6/F5** or click **Run Project**.
3. Move with **WASD** or the **arrow keys**.
4. Aim with the **mouse**; the blaster fires automatically toward the cursor.
5. Press **Escape** or use the on-screen **Pause** button.
6. Press **F3** to toggle the optional debug overlay.

The round contains four increasingly difficult waves and lasts 4:55 including intermissions. Defeat enemies, collect green experience crystals, and choose one of three upgrades on each level-up. The 18-upgrade pool includes Common, Rare, and Legendary choices, level caps, guaranteed rarities, and one free reroll per run.

## Prototype notes

- The 1920×1080 reference layout scales with `canvas_items` and `expand` stretch settings.
- `InputController.set_mobile_direction()` is the future virtual-joystick entry point.
- Audio calls are routed through `AudioHooks`; missing audio files never produce load errors.
- Enemy and projectile counts are capped and cleaned; mouse aiming does not scan the enemy list every frame.
- All visuals are generated shapes, so there are no external asset dependencies.
