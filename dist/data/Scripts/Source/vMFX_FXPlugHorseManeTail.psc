Scriptname vMFX_FXPlugHorseManeTail extends vMFX_FXPluginBase  

Import Game
Import Utility

String[] Property NodeList Auto

Event OnInit()
	NodeList = New String[7]
	NodeList[0] = "horse:2" 		; Default mane/tail node
	NodeList[1] = "horse:4" 		; tail node added by Convenient Horses
	NodeList[2] = "Shadowmere:2" 	; mane/tail node for Shadowmere's model
	NodeList[3] = "Shadowmere:4" 	; tail node for Shadowmere's model added by Convenient Horses
	NodeList[4] = "maneout" 		; mane/tail nodes used by some Animallica models and presumably others
	NodeList[5] = "manein" 			; "
	NodeList[6] = "tail" 			; "
	Parent.OnInit()
EndEvent

Event OnMFXArmorEquip(String eventName, String strArg, Float numArg, Form sender)
;numArg is the biped slot, sender is the armor.
	Busy = True
	Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): OnMFXArmorEquip(numArg = " + numArg + ",sender = " + sender + ")")
	If sender as Armor
		If CurrentMount && numArg == 35 ; Mane/Tail
			ValidateTexturesFromArmor(sender as Armor)
			;HandleEquip(sender as Armor)
		ElseIf CurrentMount && numArg == 30 ; Body
			;If body has swapped, override nodes may have changed or been clobbered.
			;HandleEquip(sender as Armor)
			Wait(1)
			ValidateTexturesFromArmor(sender as Armor)
		Else 
			HandleEquip(sender as Armor)
		EndIf
	EndIf
	Busy = False
EndEvent

Event OnMFXArmorUnequip(String eventName, String strArg, Float numArg, Form sender)
;numArg is the biped slot, sender is the armor.
	Busy = True
	Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): OnMFXArmorUnequip(numArg = " + numArg + ",sender = " + sender + ")")
	If sender as Armor
		If CurrentMount && numArg == 35 ; Mane/Tail
			ClearTextures()
			;HandleUnequip(sender as Armor)
		Else 
			HandleUnequip(sender as Armor)
		EndIf
	EndIf
	Busy = False
EndEvent

Event OnMFXArmorCheck(String eventName, String strArg, Float numArg, Form sender)
;numArg is the biped slot, sender is the armor
;This checks to see whether sender is equipped. If it isn't, equip it. 
;If sender is not armor, then unequip any item in the bipedslot provided by this plugin
	If dataArmorSlotsUsed.Find(numArg as Int) < 0
		Return
	EndIf
	While Busy
		Wait(0.1)
	EndWhile
	Busy = True
	;Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): OnMFXArmorCheck(strArg = " + strArg + ", numArg = " + numArg + ",sender = " + sender + ")")
	If sender as Armor
		If CurrentMount && numArg == 35 ; Mane/Tail
			ValidateTexturesFromArmor(sender as Armor)
		ElseIf CurrentMount && numArg == 30 ; Body
			Wait(1)
			ValidateTexturesFromArmor(sender as Armor)
		EndIf
	Else
		;RemovePluginArmor(numArg as Int)
	EndIf
	Busy = False
	SendModEvent("vMFX_MFXPluginMessage","checkcomplete")
EndEvent

Function CopyTexturesFromArmor(Armor akArmor)
	If !CurrentMount
		Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Aborting, no current mount!")
		Return
	EndIf
	If !akArmor
		Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Aborting, passed armor is invalid!")
		Return
	EndIf
	Int iNodeIdx = 0
	While iNodeIdx < NodeList.Length
		String sNodeName = NodeList[iNodeIdx]
		Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Checking node " + sNodeName + "...")
		If sNodeName
			If NIOverride.GetNodePropertyString(CurrentMount,CurrentMount.GetActorBase().GetSex(),sNodeName,9,0) ; First texture path, should always exist
			;If NetImmerse.HasNode(CurrentMount,"sNodeName",True)
				Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): CurrentMount has node " + sNodeName + "!")
				ArmorAddon kArmorAddon = akArmor.GetNthArmorAddon(0)
				Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Armor " + akArmor + " has AA " + kArmorAddon)
				TextureSet kTextureSet = kArmorAddon.GetModelNthTextureSet(0,False,CurrentMount.GetActorBase().GetSex())
				Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): AA " + kArmorAddon + " has TextureSet " + kTextureSet)
				NIOverride.AddNodeOverrideTextureSet(CurrentMount,CurrentMount.GetActorBase().GetSex(),sNodeName,6,-1,kTextureSet,True)
			EndIf
		EndIf
		iNodeIdx += 1
	EndWhile
EndFunction

Function ValidateTexturesFromArmor(Armor akArmor)
	If !CurrentMount
		Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Aborting, no current mount!")
		Return
	EndIf
	If !akArmor
		Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Aborting, passed armor is invalid!")
		Return
	EndIf
	Int iNodeIdx = 0
	While iNodeIdx < NodeList.Length
		String sNodeName = NodeList[iNodeIdx]
		Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Checking node " + sNodeName + "...")
		If sNodeName
			If NIOverride.GetNodePropertyString(CurrentMount,CurrentMount.GetActorBase().GetSex(),sNodeName,9,0) ; First texture path, should always exist
				Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): CurrentMount has node " + sNodeName + "!")
				ArmorAddon kArmorAddon = akArmor.GetNthArmorAddon(0)
				Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Armor " + akArmor + " has AA " + kArmorAddon)
				TextureSet kTextureSet = kArmorAddon.GetModelNthTextureSet(0,False,CurrentMount.GetActorBase().GetSex())
				Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): AA " + kArmorAddon + " has TextureSet " + kTextureSet)
				If !NIOverride.HasNodeOverride(CurrentMount,CurrentMount.GetActorBase().GetSex(),sNodeName,6,-1)
					NIOverride.AddNodeOverrideTextureSet(CurrentMount,CurrentMount.GetActorBase().GetSex(),sNodeName,6,-1,kTextureSet,True)
				Else
					If NIOverride.GetNodeOverrideTextureSet(CurrentMount,CurrentMount.GetActorBase().GetSex(),sNodeName,6,-1) != kTextureSet
						NIOverride.AddNodeOverrideTextureSet(CurrentMount,CurrentMount.GetActorBase().GetSex(),sNodeName,6,-1,kTextureSet,True)
					EndIf
				EndIf
			;If NetImmerse.HasNode(CurrentMount,"sNodeName",True)
			EndIf
		EndIf
		iNodeIdx += 1
	EndWhile
EndFunction

Function ClearTextures()
	Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Clearing textures...")
	If !CurrentMount
		Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Aborting, no current mount!")
		Return
	EndIf
	Int iNodeIdx = 0
	While iNodeIdx < NodeList.Length
		String sNodeName = NodeList[iNodeIdx]
		Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Checking node " + sNodeName + "...")
		If sNodeName
			If NIOverride.GetNodePropertyString(CurrentMount,CurrentMount.GetActorBase().GetSex(),sNodeName,9,0) ; First texture path, should always exist
			;If NetImmerse.HasNode(CurrentMount,"sNodeName",True)
				Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): CurrentMount has node " + sNodeName + "!")
				NIOverride.RemoveAllNodeNameOverrides(CurrentMount,CurrentMount.GetActorBase().GetSex(),sNodeName)
				Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Removed overrides for " + sNodeName + " on CurrentMount!")
			EndIf
		EndIf
		iNodeIdx += 1
	EndWhile
EndFunction
