# Envyniv's TF2 Battle Royale Vscript concept gamemode source

- Players are all moved to RED

	- Teams are partitioned into subteams through [this](https://github.com/envyniv/tf_subteam_man)

		- Team member highlighting can be set to use outlines or the `rendercolor` property
	
	- Friendly fire is activated
	
		- Uses [this friendlyfire fix script](https://github.com/envyniv/tf_vscript_friendlyfire)
		
- Crates drop random weapon.

	- Default is from class' arsenal but this behaviour can be configured
	
	- Weapons drop based on resource-intensiveness. melee weapons drop first, then hitscan,
then projectile

- Made for 100 players in mind

	-	On round start, players are marked for death, to make death easier in the first minute, so that
more resources can be used.

