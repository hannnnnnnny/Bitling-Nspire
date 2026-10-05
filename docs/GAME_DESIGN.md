# Mote: Memory Garden

A small creature wakes behind the calculator's ordinary arithmetic. The hidden garden has lost its checksum. Three caretakers know how to reconnect it; a damaged sentinel mistakes every living memory for an error.

## Beginning and ending

New game starts at HOME with welcome text and a short goal. In Memory Forest, talk to Archivist Ada; reach the memory node and activate it. In Graph Valley, survey the graph node; in Matrix Dungeon, restore the matrix node. After all three are lit, interact with the sentinel. Win, then return to Ada for the ending and the Memory Seed keepsake. The world remains playable afterward.

Each map has walls, an NPC, a rest terminal, a hidden cache, a node, encounter tiles and two-way transitions. Graph and Matrix are available through portals; the boss is gated by all nodes. Cache Ruins and Kernel Tower are future areas, not fabricated content.

## Character and pet

HP, Energy, Logic, Focus, Curiosity, Bond, Level and XP. Logic drives Solve; Focus controls mitigation and damage; Curiosity grows with discovery; Bond improves attacks. Level starts at 1 and caps at 20. Rest terminals restore HP/energy freely so the campaign cannot be resource-locked.

Pet mood is a deterministic priority state machine: transient happy/hurt/excited/thinking/curious/angry, then sleepy at low energy, sad after active inactivity, otherwise idle. Blink and walk are animation actions. Interactions give bounded bond growth with a cooldown; active time drains energy slowly. Defeat causes hurt, never permanent death. Returning triggers a welcome response without inventing elapsed offline time.

## Combat

Discrete turn-based Attack / Skill / Item / Run. Insufficient energy, invalid items and menu browsing cost no turn. Enemy attacks use deterministic patterns; guaranteed boss escape is disabled, ordinary escape uses deterministic RNG. Defeat revives at the forest. Enemy HP, defense, logic, pattern, weakness, animation and rewards come from data.

Factor reduces defense; Solve deals logic damage; Graph reveals weakness and boosts later matching skills; Analyze primes the next damaging action; Debug clears glitch and restores some HP. Items cover heal, energy, cleanse, shield, curiosity, bond and node tokens. Consumables act both in menus and combat; key items cannot be consumed. Ten item definitions; five regular enemies and one boss, all original pixel designs.

## Presentation

Full-page calculator canvas; a compact title band, readable 9–11 point labels, contrasting selection cursor and clear footer controls. World tile scene, status meters, paginated item/skill lists, wrapped short dialogue, battle log and explicit missing/corrupt save notices. No desktop panels on the device.
