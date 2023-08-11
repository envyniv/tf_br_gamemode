IncludeScript("tf_vscript_friendlyfire/_.nut", null)
IncludeScript("br_gamemode/player.nut", this)
IncludeScript("br_gamemode/teams.nut", this)
//IncludeScript("give_tf_weapon/_master.nut", null)

//convars but for vscript
::mapVars <- {
	br_players_per_team = 4
	br_team_highlight = 0
	br_rid_wearables = true
	br_allow_crate_chute = true
	br_marked_time = 90
}

::iPlayersPerTeam <- function [this] () { return mapVars.br_players_per_team }

::GameRules <- Entities.FindByClassname(null, "tf_gamerules")

::MaxPlayers <- MaxClients().tointeger();

//table of tables
local weaponTable = {
	scattergun={
		idx = 13
		mdl = "models/weapons/w_models/w_scattergun.mdl"
	}
	forceanature={
		idx = 45
		mdl = "models/weapons/c_models/c_double_barrel.mdl"
	}
	classes = [["scattergun", "forceanature"]]
}


//  https://wiki.alliedmods.net/Team_fortress_2_item_definition_indexes#Primary_.5BSlot_0.5D

::SpawnDroppedWeapon <- function(iIndex, sModelname, vOrigin)
{
    local weapon = Entities.CreateByClassname("tf_dropped_weapon");
    NetProps.SetPropInt(weapon, "m_Item.m_iItemDefinitionIndex", iIndex);
    NetProps.SetPropInt(weapon, "m_Item.m_iEntityLevel", 5);
    NetProps.SetPropInt(weapon, "m_Item.m_iEntityQuality", 6);
    NetProps.SetPropInt(weapon, "m_Item.m_bInitialized", 1);
    weapon.SetModelSimple(sModelname);
    weapon.SetOrigin(vOrigin);
    weapon.DispatchSpawn();
}

::SpawnDroppedAmmo <- function(iAmount, vOrigin, iType = 7) {
		/*
			TF_AMMO_DUMMY = 0,
			TF_AMMO_PRIMARY,
			TF_AMMO_SECONDARY,
			TF_AMMO_METAL,
			TF_AMMO_GRENADES1,
			TF_AMMO_GRENADES2,
			TF_AMMO_GRENADES3,
			TF_AMMO_COUNT,
		*/
		local modelname = "models/items/ammopack_medium.mdl"
		if (iAmount < 21)
			modelname = "models/items/ammopack_small.mdl"
		else if (iAmount >= 100)
			modelname = "models/items/ammopack_large.mdl"
    local ammo = Entities.CreateByClassname("tf_ammo_pack");
    NetProps.SetPropIntArray(ammo, "m_iAmmo", iAmount, iType);
    ammo.SetModelSimple(modelname);
    ammo.SetOrigin(vOrigin);
    ammo.DispatchSpawn();
}

function SpawnWeaponCrate(vOrigin, sWeapon = null, bParachute = true) {
	local cratemodel = "models/props_hydro/barrel_crate_half.mdl"
	local crate = Entities.CreateByClassname("prop_physics_override")
	crate.SetModelSimple(cratemodel);
	crate.SetOrigin(vOrigin);
}

::hideHUDPlayersTop <- function(player) {
	local HideHudValue = NetProps.GetPropInt(player, "m_Local.m_iHideHUD")
	NetProps.SetPropInt( player, "m_Local.m_iHideHUD", HideHudValue | (Constants.FHideHUD.HIDEHUD_MISCSTATUS) )
}

function ClearWeapons(player) {
	for (local i = 0; i < 7; i++) {
    local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i);
    if (weapon == null)
        continue;
    //printl(weapon);
	}
}

function setUpConvars() {
	// friendly fire
	Convars.SetValue("mp_friendlyfire", 1);
	
	// turn off blood splatters
	//Convars.SetValue("mp_decals", 0);
	
	// no random crits
	Convars.SetValue("tf_weapon_criticals", 0);
	// turn off autobalance
	Convars.SetValue("mp_autoteambalance", 0);
	Convars.SetValue("mp_scrambleteams_auto", 0);
	Convars.SetValue("mp_teams_unbalance_limit", 0);
	//proudly stolen from LizardOfOz
	Convars.SetValue("tf_stalematechangeclasstime", casti2f(0x7fa00000)); //NaN.
}

function GetScriptVar() {}

function ScriptVar() {}
/*
::PlayerThink <- function() {
	local team = teams[teamsByPlayers[self]].players
	for(local i = 0; i < team.len(); i++) {
		local target = team[i]
		if (target == self)
			continue
		if (target != null)
			self.DrawIndicatorTo(target)
		//printl(this + " in team with " + target)
	}
	return -1;
}
*/
::ReviveMarkerThink <- function() {
	local player = NetProps.GetPropEntity(self, "m_hOwner")
	if (NetProps.GetPropInt(player, "m_lifeState") == 0)
		self.Kill()
	return 0.2
}

function SpawnReviveMarker(pRepresenting)
{
    local revmarker = Entities.CreateByClassname("entity_revive_marker")
    NetProps.SetPropEntity(revmarker, "m_hOwner", pRepresenting)
    revmarker.SetTeam(pRepresenting.GetTeam())
    revmarker.SetAbsAngles(pRepresenting.GetAbsAngles())
    revmarker.SetOrigin(pRepresenting.GetOrigin())
    Entities.DispatchSpawn(revmarker)
    revmarker.SetBodygroup(1, pRepresenting.GetPlayerClass() - 1)
    //NetProps.SetPropEntity(revmarker, "m_hOwner", pRepresenting)
    AddThinkToEnt(revmarker, "ReviveMarkerThink")
    //DumpChangedProps(revmarker)
}

ClearGameEventCallbacks()

function OnGameEvent_teamplay_round_active(params) {
	//marked for death to every player
	
	for (local i = 1; i <= MaxPlayers ; i++) {
    local player = PlayerInstanceFromIndex(i)
    if (player == null) continue
    player.AddCondEx(30, mapVars.br_marked_time, null)
    //player.ClearWeapons()
	}
	local lsh = GetListenServerHost()
	lsh.Weapon_Drop(NetProps.GetPropEntityArray(lsh, "m_hMyWeapons", 0))
	
}

function OnGameEvent_player_disconnect(params) {
	local p = GetPlayerFromUserID(params.userid);
	local idx = teams[teamsByPlayers[p]].players.find(p)
	teams[teamsByPlayers[p]].players.remove(idx)
}

function OnGameEvent_player_death(params) {
	local p = GetPlayerFromUserID(params.userid);
	if (
		(p != null) &&
		("hasMedic" in teams[teamsByPlayers[p]]) &&
		(p.GetPlayerClass() != Constants.ETFClass.TF_CLASS_MEDIC ))
		SpawnReviveMarker(p)
}

function OnGameEvent_player_spawn(params) {
	local p = GetPlayerFromUserID(params.userid);
	if (p != null) {
		if (params.team & 2) {
			QueueToCustomTeam(p)
			hideHUDPlayersTop(p)
		}
	}
}

function OnScriptHook_OnTakeDamage(params) {
/*
	const_entity 	handle 	The entity which took damage
	inflictor 	handle 	The entity which dealt the damage, can be null
	weapon 	handle 	The weapon which dealt the damage, can be null
	attacker 	handle 	The owner of the damage, can be null
	damage 	float 	Damage amount
	max_damage 	float 	Damage cap
	damage_bonus 	float 	Additional damage (e.g. from crits)
	damage_bonus_provider 	handle 	Owner of the damage bonus
	base_damage_const 	float 	Base damage
	damage_force 	Vector 	Damage force
	damage_for_force_calc 	float 	If non-zero, this damage is used for force calculations
	damage_position 	Vector 	Where the damage actually came from
	reported_position 	Vector 	Where the damage supposedly came from
	damage_type 	int 	Damage type. See Constants.FDmgType
	damage_custom 	int 	Special damage type. See Constants.ETFDmgCustom
	damage_stats 	int 	Unused
	force_friendly_fire 	bool 	If true, force the damage to friendlyfire, regardless of this entity's and attacker's team
	ammo_type 	int 	Unused
	player_penetration_count 	int 	How many players the damage has penetrated so far
	damaged_other_players 	int 	How many players other than the attacker has the damage been applied to. Used for rocket jump damage reduction
	crit_type 	int 	Type of crit damage. 0 - None, 1 - Mini, 2 - Full
	early_out 	bool 	If set to true by the script, the game's damage routine will not run and it will simply return the currently set damage. 
*/
	
	//if it's not a player we don't care
	if (!(params.const_entity.IsPlayer() && params.inflictor.IsPlayer()))
		return
	local myTeam = teamsByPlayers[params.const_entity]
	local enemyTeam = teamsByPlayers[params.inflictor]
	if ((myTeam == enemyTeam) && (params.inflictor != params.const_entity))
			params.early_out = true
}

setUpConvars()
__CollectGameEventCallbacks(this)
