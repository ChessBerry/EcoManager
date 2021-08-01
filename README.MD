EcoManager

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
