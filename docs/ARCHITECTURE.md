# Architecture

Mote is a stock TI Lua app and an offline game. The pet **Mote** is an original cyan seed of memory with two antenna pixels, a pale face and a trailing checksum spark. Deep ink, muted violet, mint and amber define the calculator palette.

## Source boundaries

* src/core: state defaults, input actions, safe saves, game controller and TI callbacks.
* src/data: map, enemy, item, skill, sprite definitions; no runtime UI dependencies.
* src/systems: inventory, progression, combat, pet, local dialogue, animation.
* src/world: collision, movement, transitions, interactions, encounter pacing.
* src/ui: graphics adapter, reusable widgets, separate home/world/battle/menu screens.
* tools: deterministic bundler, desktop simulator, API adapter and packaging.
* tests: Lua 5.1 host logic and actual callback/render integration.

Build registers module factories in a local require registry. Each factory closes over its dependencies and returns its interface. One local Game object owns all mutable state. Only platform/on event hooks cross the TI boundary; do not leak game globals.

## State flow

BOOT → HOME. HOME → PET / WORLD / INVENTORY / MENU / SAVE.
WORLD → DIALOGUE / BATTLE / MENU. MENU → STATUS / INVENTORY / PET / SAVE / HOME / WORLD.
BATTLE → WORLD on victory/run; BATTLE → GAME_OVER on defeat.
GAME_OVER → HOME after safe recovery. DIALOGUE → previous state on completion.
SAVE → previous state. STATUS → previous state.

MENU/STATUS/SAVE extend the required state list. Every screen has a single action router; Input translates callbacks to UP/DOWN/LEFT/RIGHT/ENTER/BACK/MENU. Arrow events are discrete presses, with OS repeat handled through the same route. No held-key polling assumption.

## Data and interfaces

State.new() creates player, pet, world location, inventory, flags, RNG seed, ticks.
Inventory.add/use validate item IDs/counts. Progression.addXP levels and refreshes stats.
Combat.new(state, enemyId), Combat.act(battle, action, id), Combat.reward(state, battle).
World.move(state, dx, dy), World.interact(state), World.encounter(state).
Pet.tick(state, dt), Pet.react(state, event), Pet.interact(state, action).
Save.encode(state), Save.decode(raw) return fresh plain state and recovery notice.
LocalDialogueProvider.lines(npcId, state) is the offline implementation behind a provider seam. Remote AI is outside MVP: any future adapter must validate bounded text and cannot grant items or mutate quests.

## Validation and safety

Save data is hostile input: bound numeric values, reject nonfinite numbers and unknown identifiers, repair blocked positions, limit item quantities, sanitize booleans. The simulator bounds JSON file size and rejects malformed files. Content is local and fixed. No network or SQL endpoints exist.

Combat and world systems are pure apart from state mutation and deterministic RNG. Renderer never resolves combat, rolls encounters or changes inventory. Save snapshots omit UI, combat objects, callbacks and sprite caches.
