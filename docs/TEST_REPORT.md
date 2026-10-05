# MVP verification — 2026-10-06 (Pacific/Auckland)

## Verified on the development computer

Command: "./tools/dev.ps1 -Task test" using bundled Python 3.12.14, Lupa 2.6 **Lua 5.1**, Pillow.

**33 tests passed**, including:

* Isolated default state and input mapping.
* Three maps: collision, NPC blocking, reversible portals, all interactive objects reachable, encounter data.
* All ten items, bounds, invalid IDs and catalogue metadata rejection.
* XP rollover, multiple levels, maximum level, invalid XP.
* All five skills, turn-cost validation, all six enemies defeatable, one-time rewards, run restriction and loss.
* Offline pet events, active inactivity/age, care cooldown and required animation frames.
* Save roundtrip and independent snapshots, absent/unsupported/corrupt data, nonfinite numbers, blocked spawns, bogus items and inconsistent quest flags.
* Huge JSON integers, corrupt/oversize JSON, atomic host save/reopen, paused timer.
* Full campaign: beginning → all nodes → Boss → Ada ending, with repeat-safe rewards.
* TI entrypoint lifecycle/save callbacks on the host adapter.
* Every screen under a strict Gen 1 font whitelist, normal and narrow viewport rendering.
* Text bounds at 318×212 and 320×240.
* Deterministic source bundle, non-ASCII Windows build paths, relative converter paths.
* Prebuilt source matches modules, checksums match, TNS document container has Document.xml and Problem1.xml with valid directory offsets.

The TNS check verifies container structure and artifact integrity. It does **not** certify that TI's OS will open or execute the document.

The Tk simulator window was also opened, redrawn and sent gameplay input successfully in a local smoke check. Nine callback-driven screen captures are in docs/screenshots/. HOME, WORLD, BATTLE, STATUS and SAVE captures were visually inspected at native size.

## Host measurement

Command: "./tools/dev.ps1 -Task benchmark", 200 world paints.

| Metric | Measurement |
|---|---|
| Bundled source | 48,870 bytes |
| Generated .tns | 14,634 bytes |
| Compact JSON state | 418 bytes at default world state |
| Lua heap after collection, before / after | 292.34 / 292.34 KiB |
| Median / max host paint | 2.916 / 4.555 ms |
| Requested timer interval | 0.1 seconds |

These numbers describe the **host adapter**, not handheld memory or FPS. TI graphics/font overhead and OS scheduling are unmeasured. The source targets 10 updates/sec; no physical performance result is claimed.

All production Lua functions are below 40 lines (largest: 34, AST checked). Host production and test functions are also below 40 lines. No CAS evaluation, OS calls, file operations, variable stores, executable save loading or network requests exist in the generated device source.

## Independent review

A read-only review of the implementation found three issues: unsupported 8-point Gen 1 fonts, overflow in host JSON-to-Lua conversion, and catalogue metadata accepted as gameplay IDs. Each was fixed in a separate commit with regressions. The reviewer inspected and reproduced the fixes, including revealed battle rendering and very large integers, and found no outstanding actionable code issues.

## Pending device evidence

No physical calculator or TI desktop emulator was available during implementation. Exact OS compatibility, transferred document opening, real input repeat, font metrics, Ctrl+S/reopen persistence, battery use and preserved ordinary CAS operation must be verified using [INSTALL.md](INSTALL.md#device-acceptance-checklist).

The deliverable is a playable host-verified MVP plus a desktop-built stock Lua .tns and source fallback. It is **not yet a hardware-certified release**.
