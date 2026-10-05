# Roadmap

## First device validation

Complete the INSTALL checklist on an actual Gen 1 CX CAS. Record exact OS, timing, save/reopen and document compatibility. Tune repaint regions or timer rate only from measurements. The current timer requests 10 FPS; this is not a measured performance claim.

## Content expansion

Add Cache Ruins and Kernel Tower through the reusable maps/objects/enemies model. Extend quests and NPC lines, improve area-specific tiles, add optional sleep/level-up frames. Retain small integer systems and the original art identity.

## Persistence evolution

If a future schema is needed, write explicit version migration. Keep document-local ownership and safe defaults. Introduce a trusted clock adapter only after verifying the intended OS API; current age/inactivity are active-session time.

## Optional external AI

The controller depends on dialogueProvider.lines(npcId, state). systems/dialogue.lua supplies the deterministic local provider today. A future remote adapter may use an external computer/ESP32/Raspberry Pi, but USB transport and stock-Lua capabilities require a separate feasibility study.

Remote output must be bounded plain text, sanitized and optional. It cannot mutate inventory, quests or player state. Keys belong to environment variables on the external host. Timeout/error/offline paths return local dialogue. Do not promise direct network or Python support on Gen 1, and do not install Ndless just to enable AI dialogue.
