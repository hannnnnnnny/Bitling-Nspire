# MVP delivery checkpoints

Every independent implementation/fix has its own commit. Subjects below are also the recommended messages for their respective phases.

| Phase | Completed / working | Remaining at that checkpoint | Commit subject |
|---|---|---|---|
| Feasibility / architecture | Empty repo inspected, primary sources checked, stock Lua selected | Implementation | docs: model safe Gen 1 Lua RPG architecture and delivery plan |
| Core | State isolation, named input, Lua 5.1 harness | Rendering and content | feat: add isolated Lua state input and host test harness |
| Maps | 3 connected maps, collision, reachable objects and encounters | RPG/pet/UI | feat: add three connected maps with collision and interactions |
| Items / XP | 10 items, bounded counts, level rollover/cap | Combat | feat: implement bounded inventory and RPG progression |
| Combat | 5 enemies, Boss, 5 skills, rewards, run/defeat | Campaign orchestration | feat: add patterned enemies and five calculator combat skills |
| Pet / animation | Offline reactions, mood, cooldown, active age and frames | Persistence and UI | feat: add offline pet reactions and lightweight animation states |
| Save | Validated snapshots and corrupt/missing fallback | Device save/reopen | feat: add validated document-local save snapshots and recovery |
| Campaign | Beginning, three node quest, Boss, repeat-safe ending | Screens and packaging | feat: connect RPG screens quests boss and achievable ending |
| Graphics | Original art, calculator screens, small-pane notice | TI callbacks | feat: render original pixel art and calculator-sized game screens |
| TI lifecycle | Paint/input/timer/activation/save events | Physical execution | feat: wire stock TI Lua callbacks and document persistence |
| Simulator | Same Lua in Tk/Pillow, atomic JSON, screenshots | Packaging and audit | feat: add playable desktop simulator with safe JSON persistence |
| Audit | Font compatibility, metadata IDs, huge JSON integers fixed | Physical acceptance | Separate fix commits in git log |
| Delivery | Built .tns, source bundle, docs, CI | Gen 1 hardware checklist | chore: package Bitling MVP with documented device acceptance |

The original remote LICENSE and initial commit were retained. No calculator was connected or changed during development.
