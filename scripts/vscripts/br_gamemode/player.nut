::CTFPlayer.DiscardCosmetics <- function() {
	for (local child = this.FirstMoveChild(); child != null; child = child.NextMovePeer()) {
    if (child.GetClassname() == "tf_wearable") {
      // nuke all tf_wearable's except the shields/banners/backpacks
			if (child.GetOwner() == this) // && (child.GetModelName().find("banner") != null))
				child.Kill();
			//else
			//	printl(child.GetOwner())
    }
	}
}

::CTFPlayer.MoveToTeam <- function(iTeam) {
	if (iTeam < 4) {
		this.ForceChangeTeam(iTeam, true)
		return
	}
  // move to red
	this.ForceChangeTeam(2, true)
	// add to custom team
	local iCTeam = iTeam-4
	teams[iCTeam].players.append(this);
	teamsByPlayers[this] <- iCTeam
	if (this.GetPlayerClass() == Constants.ETFClass.TF_CLASS_MEDIC)
		teams[iCTeam].hasMedic <- 0
	ColorPlayer(this, teams[iCTeam].color)
	// we remove the cosmetics to ensure new team color
	if (mapVars.br_rid_wearables)
		this.DiscardCosmetics()
}

::CTFPlayer.ClearWeapons <- function() {
	for (local slot = 0; slot < 7; slot++) {
    local weapon = NetProps.GetPropEntityArray(this, "m_hMyWeapons", slot)
    if (weapon) {
      if (weapon.GetSlot() == 2) // melee
        this.Weapon_Switch(weapon) // switch to melee
      else {
        weapon.Kill() // nuke everything else
        //NetProps.SetPropEntityArray(this, "m_hMyWeapons", null, slot)
      }
    }
	}
}

//void Weapon_Drop(handle weapon)
::CTFPlayer.Weapon_Drop <- function(hWeapon) {
	local iIdx = NetProps.GetPropInt(hWeapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex") //-1
	// TODO:
	local sModel = "models/weapons/w_models/w_scattergun.mdl"
	for (local slot = 0; slot < 7; slot++) {
    local newWeapon = NetProps.GetPropEntityArray(this, "m_hMyWeapons", slot)
    if (newWeapon)
      this.Weapon_Switch(newWeapon)
	}
	SpawnDroppedWeapon(iIdx, sModel, this.GetOrigin())
	//NetProps.SetPropEntityArray(this, "m_hMyWeapons", null, hWeapon.GetSlot())
	hWeapon.Kill()
}

//void Weapon_DropEx(handle weapon, Vector target, Vector velocity)
::CTFPlayer.Weapon_DropEx <- function(hWeapon, vTarget, vVelocity) {
	//TODO: vVelocity, vTarget
	local iIdx = NetProps.GetPropInt(hWeapon, "m_Item.m_iItemDefinitionIndex")
	local sModel = "models/weapons/w_models/w_scattergun.mdl"
	for (local slot = 0; slot < 7; slot++) {
    local newWeapon = NetProps.GetPropEntityArray(this, "m_hMyWeapons", slot)
    if (newWeapon)
      this.Weapon_Switch(newWeapon)
	}
	SpawnDroppedWeapon(iIdx, sModel, vTarget)
	hWeapon.Kill()
}
::CTFBot.Weapon_Drop <- CTFPlayer.Weapon_Drop
::CTFBot.Weapon_DropEx <- CTFPlayer.Weapon_DropEx

::CTFBot.DiscardCosmetics <- CTFPlayer.DiscardCosmetics
//::CTFBot.DrawIndicatorTo <- CTFPlayer.DrawIndicatorTo
::CTFBot.MoveToTeam <- CTFPlayer.MoveToTeam
::CTFBot.ClearWeapons <- CTFPlayer.ClearWeapons

