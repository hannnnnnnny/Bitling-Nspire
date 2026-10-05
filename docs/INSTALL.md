# Install on a first-generation TI-Nspire CX CAS

## Scope

Target: original **TI-Nspire CX CAS**, existing OS **3.2 or later**, normal document mode. This is a stock Lua API 2.0 application. The prebuilt file was generated on the computer; opening it on a physical calculator remains unverified.

Check your model label and existing OS in the handheld's normal Settings/About screen. Do not install a CX II OS. If the OS is below 3.2, stop at this compatibility boundary rather than changing firmware automatically.

## Transfer the supplied document

1. Save any open calculator work.
2. Connect the calculator by its normal USB cable.
3. Use TI-Nspire desktop software's document transfer feature, or [TI-Nspire Computer Link](https://education.ti.com/en/software/details/en/82035809F7E6474099944056CCB01C20/swticonnectce). TI lists Computer Link for the original generation; CX II uses different connectivity.
4. Create a separate Bitling document folder. Transfer only dist/bitling.tns there; choose a new filename if one already exists.
5. Open bitling.tns through My Documents. Use a single full-page view.
6. Play with arrows, Enter, Esc and letter M. Press **Ctrl+S** in the game document to persist progress. Reopen that same saved copy to continue.

No installer is run on the handheld. No OS image, downgrade, bootloader change or unrelated document write is part of this workflow.

## Official editor fallback

If the generated .tns will not open, preserve the source and use existing compatible TI-Nspire desktop software:

1. Create a **new, separate** TI-Nspire document.
2. Choose **Insert > Script Editor > Insert Script**.
3. Paste the complete dist/bitling.lua (or rebuilt build/bitling.lua).
4. Click **Set Script**. Use the full-page handheld view to check rendering.
5. Save as bitling.tns and transfer the new document.

These actions follow [TI's Script Editor guide](https://education.ti.com/html/webhelp/EG_TINspire/EN/Subsystems/EG_Lua/Content/m_scripteditor/se_inserting%20new%20scripts.HTML). A standalone .lua file renamed to .tns is not a document.

## Save behavior and removal

Game state belongs only to this Lua app through TI's on.save / on.restore document events. Ctrl+S performs the durable document save. Entering the SAVE menu alone does not guarantee disk persistence. There are no Calculator variables, file-I/O calls or CAS changes.

Saving during battle records character and quest state, not an in-progress enemy. Reopening restores the map; a defeated character gets safe HP recovery. For a reliable checkpoint, finish a fight, return to the world, then save.

To remove: close the game and remove **only its own copied document** using the normal file manager. Keep a separate copy first if you want to preserve its progress. The ordinary Calculator/CAS app continues to work.

## Packaging provenance

The supplied MVP document uses desktop Luna v0.3a, from [the maintainer's archived distribution](https://www.ticalc.org/archives/files/fileinfo/441/44113.html). Download archive SHA-256:

2c3009031d1884d31b5aba505314eed44cb0c73e55deccd3444dd7f0ac9a87a2

Luna v0.3a documents default to API 2.0 / OS 3.2 compatibility. Modern [Luna 2.1 source](https://github.com/ndless-nspire/Luna) is an alternative if you have a C compiler/zlib. No converter, DLL or Ndless resource is transferred to the calculator. Distribution checksums are in dist/SHA256SUMS.

## Device acceptance checklist

The following checks are pending until performed on a real Gen 1 device:

- [ ] Record model, exact OS version, available memory and full-page app dimensions.
- [ ] Open document without script error; inspect HOME, PET, WORLD, INVENTORY, STATUS, SAVE.
- [ ] Test directional repeat, Enter/Return, Esc, numeric alternative keys, M.
- [ ] Cross both portals in each direction; check walls, NPCs, hidden caches and terminals.
- [ ] Use each skill and usable item; test ordinary escape and Boss restriction.
- [ ] Complete three nodes, Boss and return-to-Ada ending.
- [ ] Ctrl+S, close and reopen the game; compare level, XP, HP, items, map, pet and quests.
- [ ] Switch to an ordinary Calculator/CAS document; perform normal arithmetic/CAS and return.
- [ ] Run for 10 minutes; record repaint rate, input responsiveness and battery effect.
- [ ] Confirm no unrelated document changed. Remove a disposable game copy and reopen Calculator.

If anything fails, retain source, note the exact error and stop using that game copy. Firmware changes are not a troubleshooting step for this MVP.
