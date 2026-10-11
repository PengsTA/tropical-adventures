local str_back =
[[The full name of this mod is
[Tropical Adventures | Ship of Theseus].
This mod originates from the classic 【Tropical Experience】 mod.
It retains the Shipwrecked and Hamlet portions while implementing extensive optimizations and additions.
-----------------------------------------
We would like to extend our sincere gratitude to the original "Tropical Experience" development team (represented by Vagner),
as well as Runar、momo、狼轩木林、杰杰、月下独酌、酒酒、萌新 and BBGoat、绯世行 for their invaluable technical assistance and support.
Furthermore, during the development process, we drew great inspiration and experience from several outstanding mods, including "Candy House" and "Above the cloud."
We truly appreciate the foundations laid by these talented developers.
-----------------------------------------
Given the extensive volume of this mod, the encyclopedia primarily covers original additions and optimized content.

Peng
]]

local str_progress = [[
Currently, this mod offers 【high compatibility】; however, as one of the largest mods in the Workshop, compatibility issues may arise with certain large-scale mods.
It is 【not recommended】 to enable this alongside other mods that 【contain single-player DLC content】 or mods that modify single-player DLC assets.
==========================================
2026 Latest Major Updates Summary (Continuous Refactoring & Polish):

[Solo Boat & Sailing Overhaul]
1. Architecture Unified: Solo boat durability and equipment fully transitioned to boathealth and boatequipment. Freely equip and dismantle sails, lights, nets, cannons across two slots with precise repair support.
2. Trawl Net Rewrite: Rewritten as a periodic scan system. Captures native and special ocean targets reliably without swallowing items or missing catches; drops safely when full, with boundary reset protection.
3. Loading & Dismount Safety: Thoroughly fixed players falling into deep ocean and drowning upon loading or reconnecting; clears saved boat records immediately upon disembarkation to prevent land hull clutter and duplicate item drops.
4. Bermuda Triangle Smooth Passage: Solo boats crossing or entering the Bermuda Triangle now teleport smoothly with the sailor to the exit ocean without disembarking into water; restored official DLC002 audio events.
5. Ocean Boundary Wrapping: Sailing past the map edge seamlessly wraps around to the opposite edge with local fog and camera transitions, eliminating invisible wall blocking.

[Hamlet Cave Ruins & Labyrinth Overhaul]
1. Underground Labyrinth: Hamlet ruins completely restructured into dedicated cave mazes with hallways, intersections, guard rooms, secret vaults, and the Aporkalypse clock hall.
2. Trap Fixes: Fixed spear trap collision crashes and pathing blockers, dart statue visual states and repeat triggers, and sleeping pressure plate crashes; added boundary traversal protection.
3. Ancient Herald Spawner: Added a dedicated Ancient Herald spawner near the wishing well at the ruins entrance with a 15-day respawn cooldown.

[Hamlet Interior & Architecture Standardization]
1. Room Layout & Extensions: Standardized room dimensions and doorway alignments; back walls support door placement for extensions. Mini-map precisely aligned with the HUD frame.
2. Fixture Demolition & Decor: Town house built-in furniture can now be hammered down; unified wall decor, window scales, and pillar sorting layers.
3. Chair Travel: Sky and ocean chair teleportation smoothed out with proper sanity consumption.

[World Ecology, Creatures & Balance Fixes]
1. Octopus King Deduplication: Added component deduplication to ocean population insertion to prevent dual Octopus Kings on world generation.
2. Tiger Shark Management: World-scoped Tiger Shark respawns and rewards, eliminating duplicate spawn points.
3. Creature Fixes: Fixed amphibious snake double-physics crash and missing sounds; restored dragoon den day cycles, ballphin population tracking and feeding friendship, adult ox herd mood and prey tags, doydoy gender persistence, and more.
4. Farming & Environment: Sprinklers can rejuvenate withered plants; fixed nettle soil moisture persistence; inland flooding now requires seasonal rain conditions.
5. Final-Use Execution: Staffs, flute, monkey ball, and quackering ram properly execute their full effect on their final durability use.

[Rendering, Audio & Performance]
1. Turf & Water Refinement: Redrawn high-resolution Shipwrecked and Hamlet turf textures; optimized ocean tile waves and surface blending.
2. Audio & Dynamic Music: Restored official DLC002 sound events, eliminating FMOD missing sound errors; improved rainforest and cave music transitions.
3. Dedicated server optimizations skipping client-only interior visual effects.

26.03.20 Update:
    1.Now perfectly compatible with the [Global Event Timer] mod! As long as you have that Mod enabled, you can see the countdowns for various BOSSes directly on your screen, allowing you to prepare your defenses in advance.
    2.The Aporkalypse is now perfectly adapted to the "Don't Starve Alone (DSA)" single-player mode. Fixed the issue where triggering the Aporkalypse would cause an error previously, greatly improving the stability of both multiplayer and single-player gameplay.

    3.Tiger Shark combat is now smoother. Also cleared up redundant Tiger Shark spawn points on the map.
    4.Fixed the issue where the ROC could not land normally.
    5.Optimized the issue of the Twister sucking in too many items.

    6.The Smelter and Crock Pot can now more accurately identify whether what you put in is an "ore" or an "ingredient", preventing misjudgments!
    7.Water Chest Fix: Fixed the issue where the water chest had no interactive UI.
    8.Crop Adjustment: Hidden wheat and turnips.

26.03.06 Update：
    1.update wiki UI
    2.better boat UI

26.03.03 Update:
    1.Terrain generation is now compatible with [Montfluv].
    2.Optimized the Mod Wiki UI.
    3.Adjusted the generation structure of the pigtown.


Feb 26, 2025 Update:
    1.Added Mod Wiki/Encyclopedia.
    2.Fixed an error occurring when fishing for lobsters on a boat in single-player.
    3.Fixed an issue where fog and rain would appear indoors within the Hamlet region during winter.
    4.Corrected default turf detection for different regions (e.g., the default turf for the shipwrecked is now set to Sand).
    5.Fixed missing iron ore textures when Smart Cooking is enabled.
    6.Added a recipe for the Captain to craft gold coins.


=========================================
]]

local str_preview = [[
The Ship of Theseus: Our goal is to gradually overhaul and update the original content—breathing new life into it—all while ensuring the mod remains playable throughout the process.
Want to help out? We'd love to have you! Github Page: [PengsTA/tropical-adventures] to connect and contribute.
-----------------------------------------
Donations will be converted into cold AI tokens and codes.
]]

--You can also support us through donations! Every contribution goes straight into the ongoing development and maintenance of the mod.
-- Your support means the world to us—it validates the hard work we've put in and gives us the motivation to keep the updates coming!

local str_donation = [[
Nobody yet.
]]

local WikiAbout = {
    str_back = str_back,
    str_progress = str_progress,
    str_preview = str_preview,
    str_donation = str_donation,
}

return {
    WikiAbout = WikiAbout,
}
