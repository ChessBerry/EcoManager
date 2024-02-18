# EcoManager CheeseBerryTweaks

This mod helps with managing the economy by providing overlays and automatic pause-unpause features.

The mod was originally written by Crotalus. Some changes and bugfixes were made by CheeseBerry. (See Changelog below.)

## Installation

### Dependency - Common Mod Tools

This mod requires "Common Mod Tools" to be installed.  
You can find it in the vault of the FAF client. Install and activate it.

### Manual Installation Steps

1. Download zip files.
2. Unzip them.
3. Open the mods folder (use "show mods folder" in the faf client).
4. Create a new folder called "EcoManagerCBT" inside the mods folder. It needs to have this name exactly or the mod doesn't work.
5. Move the unzipped files into the EcoManagerCBT folder. The file structure should now be "mods > EcoManagerCBT > README.MD".
6. Activate the mod like any other mod in the faf client.
7. Make sure that Common Mod Tools is activated as well.
8. Adjust your settings in the ingame settings menu.

## Changelog from Ecomanager-v11 to Ecomanager-CBT

### Behavior Changes
* Added a 2-minute wait time before the mod takes any actions at all. This is to avoid it taking actions that could screw up very optimized or fragile build orders like a hydro rush.
* Increased the start time for the throttler from 3 min to 8 min. So no throttling will happen during the first 8 minutes of the game.
* Adjusted energy throttle priorities:
  * Allowed the throttling of t3 air factories.
  * Land and naval facs are now only throttled as a last resort, as they use very little energy anyway. 
* Made it so a significant number of units are never throttled, even if you are stalling. Excluded from throttling are:
  * ACU/SACU Upgrades
  * Pgen Construction
  * T1 Mex Construction
  * Mex Upgrades (see bug fixes below)
  * T1 FactoryCommander Upgrades
  * T1 Fac Construction
  * HQ Upgrades
  * PD, AA, Shield Construction
  * Shield, Radar, Stealth upkeep
* Changed it so the automagical upgrade and then pause functionality only effects t1 mexes to avoid the unintended behavior where engies tasked with upgrading a t1 mex to t2 sometimes triggered and then assisted the subsequent upgrade to t3, which is devestating when happening on accident.

### Bug and compatability fixes:
* Fixed overlay turning into a giant black square sometimes. - Fixed by Crotalus in his v12 version that was never pushed to vault it seems.
* Fixed throttling always being on, regardless of what you select in the options.
* Removed broken features: Mex-upgrade-optimization, mass-throttle, mass-fab-throttling, settings that didn't do anything.
* Fixed bug where the construction of T2 mass fabs was never paused (due to overlapping categories in the constructionCategories table)
* Fixed a bug where t1 mexes would sometimes upgrade to t2 on their own if the auto-mex-upgrade-and-pause-feature was turned on. I.e. the upgrade would start as planned, but it wouldn't be paused, unintentionally upgrading the mex the entire way.
* Mex upgrades are now never paused by the e-throttler. I think that was causing the bug where, if you are low on energy, the auto-mex-upgrade-and-pause-feature would start a mex upgrade as usual but the pause would be registered as an energy-throttle pause, not a auto-mex-upgrade-and-pause-feature pause. That would then result in the upgrading t1 mex unintentionally getting unpaused which can obviously be disastrous if it happens at the wrong time.
* Fixed misplacement of overlays with >100% ui scale.
* Removed useless missile overlay for sera cruiser.

## Features

### MEX-overlay
Shows graphical overlay over mexes to easier spot the different mex levels.

Colors:
* Green - T1 Mex, T2 Mex with storages
* Yellow - currently upgrading mex
* Red - T3 Mex without storages
* White - Fully upgraded T3 mex

### MEX-Upgrade/pause
Easier handling of mex upgrades. When an engineer start assisting a paused mex it'll automatically unpause.

### Energy Throttle
When low of energy, energy users are throttled to prevent energy stall. Different users have different priority, massfabs are lower priority and always throttled if energy goes <80%.
Shields/radar etc. are never touched. Remember to build some energy storage because mod cannot respond faster than ~1 s due to FA pause lag. It's possible to set threshold by command.

### Nuke-overlay
Shows the number of missiles in silos for nukes / anti nukes. Also applies for battleships / nuke subs.

### Autoshare
Shares resources between allied players that also are using this mod. Resources are only shared when a player needs it and another player has plenty of resources.

Commands:
/m <amount>|auto
Sets the threshold when to share mass
/e <amount>|auto
Sets the threshold when to share energy

## Known Bugs
* ACU and SACU upgrades can not be paused automatically.
  * This is because u:GetFocus() never returns anything if u is an ACU or a SACU (see throttle.lua). Interestingly, engineeres assisting those upgrades can be paused, as can ACUs or SACUS that assist something else. Only them upgrading themselves can not be paused. This is weird, and pausing would be useful when e.g. making RAS or tele, so I should get around to figure out how to do that. Maybe the function to call needs to be whatever mexes call when they upgrade themselves? Maybe they are not part of the construction but the consumption category (even though mexes are not) and the logic there can't handle ACUs? Not sure.

## Improvement/Feature Ideas
* Once you have a para, all throttling should immediately turn off. An edge case for sure, but a very obvious improvement nonetheless.
* A hotkey, not just a setting, that turns off all throttling until you press it again.
* A hotkey that removes all selected units and buildings from being throttled until their production is finished/for the next minute/for the rest of the game.
