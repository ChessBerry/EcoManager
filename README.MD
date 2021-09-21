EcoManager

__Changes by CheeseBerry__
Adjusted energy throttle priorities a bit. Notably engies building power generators can now also be throttled, but the mod will do so only as the very last resort.
Allowed the throttling of t3 air factories. I don't know why that was explicitly commented out before.
Commander Upgrades, Shields, Radars, Stealth are still never touched.

Fixed bug where the construction of T2 mass fabs was never paused (due to overlapping categories in the constructionCategories table)

Increased the start time for the throttler from 3 min to 8 min. So no throttling will happen during the first 8 minutes of the game.

Changed it so the automagical upgrade and then pause functionality only effects t1 mexes to avoid the bug where engies tasked with upgrading a t1 mex to t2 sometimes triggered and then assisted the subsequent upgrade to t3, which is devestating when happening on accident.

The construction of t1 mexes is now never paused.

Adjusted land and naval e-throttling priorities:
Changed it so that land and naval facs are basically never paused. Only ACU upgrades or stuff not throttled at all has a higher priority. Reason being that a surprisingly throttled production can totally screw you, while barely helping with any power stalls. If you need to pause basically everything to get power back up and running, you'd want to do so manually anyway.

__TODO by CheeseBerry__
Right now ACU and SACU upgrades can not be paused as u:GetFocus() never returns anything if u is an ACU or a SACU (see throttle.lua). Interestingly, engineeres assisting those upgrades can be paused, as can ACUs or SACUS that assist something else. Only them upgrading themselves can not be paused. This is weird, and pausing would be useful when e.g. making RAS or tele, so I should get around to figure out how to do that. Maybe the function to call needs to be whatever mexes call when they upgrade themselves? Maybe they are not part of the construction but the consumption category (even though mexes are not) and the logic there can't handles ACUs? Not sure

__README_from_the_original_author_below__

__MEX-overlay__
Shows graphical overlay over mexes to easier spot the different mex levels.

Colors:
Green - T1 Mex, T2 Mex with storages
Yellow - currently upgrading mex
Red - T2 Mex without storages
White - Fully upgraded T3 mex

__Nuke-overlay__ 
Shows the number of missiles in silos for nukes / anti nukes. Also applies for battleships / nuke subs.

__Autoshare__
Shares resources between allied players that also are using this mod. Resources are only shared when a player needs it and another player has plenty of resources.
It's possible to change the threshold when to share resources by changing sliders in the UI. Default mode is 'auto'.

Commands:
/m <amount>|auto
Sets the threshold when to share mass
/e <amount>|auto
Sets the threshold when to share energy

__MEX-Upgrade/pause__
Easier handling of mex upgrades. When an engineer start assisting a paused mex it'll automatically unpause. There are two different upgrade modes:

Auto:
T1 / T2 Mexes with storages are automatically upgrade / paused. Watch out for patrolling / attack-move engineers which will assist paused stuff when mass > 50%.
On click mode prevents this, see below:

On click:
Select or assist a mex to upgrade / unpause it.

__Energy Throttle__
When low of energy, energy users are throttled to prevent energy stall. Different users have different priority, massfabs are lower priority and always throttled if energy goes <80%. 
Shields/radar etc are never touched. Remember to build some energy storage because mod cannot respond faster than ~1 s due to FA pause lag. It's possible to set threshold by command. 

Commands:
/t <amount>|auto
Sets the threshold when to throttle energy, auto means throttle at <=15% (<=1% at beginning until energy income > 1000.
If <amount> is set to 0 only massfabs are throttled (< 80%)


__Desync window close__
The desync window are closed after the first click on OK. The game is still desynced but you can play on without the irritating window popping up all the time.

__Show Options__
/options - Show some info about game options

__Max Shield upgrade__
Upgrade a cybran shield to maximum by selecting it and press Ctrl-Shift S
