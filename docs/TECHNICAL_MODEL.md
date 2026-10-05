# Technical feasibility model — 2026-10-06

## Decision

Use a **stock Lua document**, API level 2.0, on the **first-generation TI-Nspire CX CAS**, targeting existing OS 3.2–4.5.x. No Python on the handheld, Ndless, firmware changes, native extensions, filesystem calls, CAS evaluation, network, or external hardware. OS compatibility is a design target, not a claim of device testing. The user's OS version is unknown.

| Criterion | Stock Lua | Ndless / native C | Hybrid |
|---|---|---|---|
| Performance | Sufficient for tile movement and turn-based combat; interpreted | Faster, direct graphics | Native performance with interface overhead |
| Installation | Ordinary .tns document | Exact OS-specific exploit/installer | Requires Ndless too |
| Animation | Timer callbacks, primitive pixels, 5–15 FPS target | Faster blitting and timing control | More complexity than needed |
| Keyboard | TI event callbacks; no portable key-up/held-key API | Direct keypad polling | Two input adapters |
| Sprites | Cached horizontal runs, fillRect; no large images | Framebuffer assets | Native asset layer |
| Save | on.save/on.restore, persisted when the document is saved | File I/O | More failure modes |
| Compatibility | Conservative API 2.0, OS 3.2+ target | Specific OS builds only | Narrower than Lua |
| Safety | Own document, reversible by removing own file | OS loader installation; not selected | Same installer risk |
| Development | Same Lua 5.1 logic tested on host | Cross compiler and hardware debugging | Two runtimes to maintain |

Lua is enough for this MVP. Ndless is unnecessary. There is no installer or downgrade step in this project.

## Hardware and budgets

TI lists the original CX family at 320×240, 16-bit color, 64 MB operating memory and 100 MB storage. Operating memory is shared with the OS; this is **not** the application's available heap. CPU speed is deliberately not assumed.

The script window is smaller than the physical screen because TI draws document chrome. Render at the actual platform.window dimensions; support a full-page 318×212 viewport and a 320×240 host view. Small split panes show an explicit full-page instruction instead of clipped controls.

* Fixed timer interval: 0.1 seconds (10 requested updates/sec). Actual hardware repaint rate must be measured; this is not a measured FPS.
* 16×11 maps, compact ASCII rows, 16 px tiles; no scrolling in MVP.
* 12×12 sprites, compiled to colored horizontal runs once; integer drawing coordinates.
* No image buffers or texture decoding, physics, audio, pathfinding, LLM, background threads.
* Budget: source under 128 KiB, game data and sprite cache under 256 KiB estimated, state under 8 KiB, total Lua heap target under 2 MiB. Host collectgarbage measures Lua heap but cannot establish TI's overhead.
* Static screens repaint on input or pet-frame change; world only visible tiles are drawn. No table construction in the sprite drawing loop.

## Persistence and time

on.save returns a versioned plain table; on.restore validates types, ranges, whitelisted identifiers, location, inventory and quest flags into fresh defaults. No loadstring, executable serialization, document variables, or file access. Battle state is not serialized: resume at the map with a safe live player and the same quest progress. Completed quests cannot duplicate rewards.

The SAVE screen explains that Ctrl+S is required for durable TI document persistence. The game cannot promise to force a disk save. Only the user's game .tns is saved. The host simulator uses its own bounded JSON file with atomic replacement.

Age and inactivity use **active play time**, excluding a deactivated app. A return event welcomes the pet; no reliable cross-session wall clock is assumed. No offline hunger damage or punishment while the calculator is off.

## Installation / development

Concatenate module factories into one distribution script (TI has no ordinary filesystem require). Source stays modular. Optional Luna packaging creates a normal .tns on the **computer**, not the calculator. Luna's repository name is associated with Ndless, but generated Lua documents do not require Ndless. Also support TI's desktop Script Editor: insert a script, paste bundle, set script, save a separate game document, transfer using TI-Nspire software.

The desktop simulator uses Lua 5.1 via Lupa and a Python/Tk/Pillow graphics adapter. Python is a **host development dependency only**. This is an API mock, not TI OS emulation.

## Risks and unverified behavior

Physical Gen 1 execution, timing, font metrics, OS-specific document open behavior, keyboard repeat and real document save/reopen remain a manual acceptance gate. Existing OS below 3.2 is outside the target; do not flash it automatically. Press-to-Test policies can restrict applications. Do not bypass them. Keep the game in its own full-page document. A broken game script can be closed using normal document controls; it has no access to bootloader, OS or unrelated files.

## Primary sources

* [TI original CX family specifications](https://education.ti.com/es/products/calculators/graphing-calculators/ti-nspire-cx) — screen, memory and document applications.
* [TI Lua API reference](https://education.ti.com/~/media/F7BE06D4635C4C739129B174C4B0CAA2) — platform.window, API levels, graphics, arrowKey, enterKey, timer, save/restore.
* [TI Python supported platforms](https://education.ti.com/html/webhelp/EG_TINspire/EN/Subsystems/EG_Python/Content/m_getstart/m_getstart.HTML) — CX II family, not original CX handheld.
* [Luna source and compatibility](https://github.com/ndless-nspire/Luna) — Lua documents OS 3.0.2+; project uses the stricter 3.2 floor for API 2.0.
* [Ndless maintainer installation matrix](https://github.com/ndless-nspire/Ndless/blob/master/README.md) — exact OS installers illustrate the native option's compatibility cost.
