# Original pixel asset pipeline

All sprites are code-defined original placeholders in src/data/sprites.lua: 12 rows × 12 columns. The controlled character and virtual pet are the same creature, Mote. No external bitmap, copyrighted character or downloaded art is used.

| Pixel | Meaning |
|---|---|
| . | Transparent |
| 1 | Mint body |
| 2 | Pale face/light |
| 3 | Dark detail |
| 4 | Amber charge |
| 5 | Violet memory |
| 6 | Rose damage |

ui/widgets.lua compiles rows into horizontal colored runs once at module load. Rendering uses integer fillRect calls; scale 1 on maps, 3 in combat and 6 on pet/home screens. No table is allocated per pixel while drawing.

Required frames: idle, blink, walk1, walk2, happy, hurt, attack. Optional pet expressions select existing frames. Five enemies and the sentinel have distinct original silhouettes; enemy animation uses a one-pixel pulse/bob. NPC, node, terminal, cache and portal icons use the same palette. Tiles are procedural primitives in ui/world.lua.

To replace art:

1. Edit a 12×12 string grid with the existing pixel alphabet; retain transparent margins.
2. Add a sprite key and reference it in the enemy data or animation table.
3. Run "python tools/test.py", "python tools/gallery.py", then inspect 1× views.
4. Rebuild the Lua/.tns; run the physical device checklist before publishing as handheld-tested.

Gen 1 fonts must be **7, 9, 10, 11, 12 or 24 points**. This is enforced by the host adapter; see [TI setFont documentation](https://education.ti.com/html/eguides/nspire/EG_Nspire/EN/content/eg_lua/m_libraries/graphicslib/setfont.HTML). Body text uses 9–11 points. Font metrics still need physical comparison.
