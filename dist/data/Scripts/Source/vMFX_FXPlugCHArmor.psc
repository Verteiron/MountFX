Scriptname vMFX_FXPlugCHArmor extends vMFX_FXPluginBase  

Import Utility

GlobalVariable Property CHHorseArmorMode Auto

Bool Property ManeHidden Hidden
	Function Set(Bool bManeHidden)
		;Utility.Wait(0.25)
		If !CurrentMount.Is3DLoaded()
			;No animation, just set the property below
		ElseIf bManeHidden && _ManeHidden
			;CurrentMount.PlaySubGraphAnimation("ManeFadeOut")
			CurrentMount.PlaySubGraphAnimation("ManeGone")
		ElseIf bManeHidden && !_ManeHidden
			CurrentMount.PlaySubGraphAnimation("ManeFadeOut")
			;CurrentMount.PlaySubGraphAnimation("ManeGone")
		ElseIf !bManeHidden && _ManeHidden
			CurrentMount.PlaySubGraphAnimation("ManeFadeIn")
			;CurrentMount.PlaySubGraphAnimation("ManeThere")
		ElseIf !bManeHidden && !_ManeHidden
			;CurrentMount.PlaySubGraphAnimation("ManeFadeIn")
			CurrentMount.PlaySubGraphAnimation("ManeThere")
		EndIf
		_ManeHidden = bManeHidden
	EndFunction
	Bool Function Get()
		Return _ManeHidden
	EndFunction
EndProperty

Bool _ManeHidden = False

Int Function CHArmorIndex(Armor akArmor)
	;-1 for no, anything else for true
	If !akArmor
		Return -1
	Else 
		Return dataFormlists[0].Find(akArmor)
	EndIf
EndFunction

Function HandleCHVars(Armor akArmor)
	Int ArmorIndex = CHArmorIndex(akArmor)
	CHHorseArmorMode.SetValueInt(ArmorIndex + 1) ; Set to 0 if not found, otherwise to appropriate CHHorseArmorMode
	Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): akArmor is " + akArmor + " at index " + ArmorIndex)
	If ArmorIndex >= 0
		ManeHidden = True
	Else
		ManeHidden = False
	EndIf
EndFunction

Function HideMane(Bool bHideMane)
	ManeHidden = bHideMane
EndFunction

Event OnMFXArmorEquip(String eventName, String strArg, Float numArg, Form sender)
;numArg is the biped slot, sender is the armor.
	Busy = True
	Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): OnMFXArmorEquip(numArg = " + numArg + ",sender = " + sender + ")")
	If sender as Armor
		HandleEquip(sender as Armor)
		If numArg == 45 ; Saddle/Armor
			HandleCHVars(sender as Armor)
		EndIf
	EndIf
	If numArg == 30 || numArg == 50 
		While !CurrentMount.IsEquipped(sender)
			Wait(0.1)
		EndWhile
		HandleCHVars(CurrentMount.GetWornForm(0x00008000) as Armor)
	EndIf
	Busy = False
EndEvent

Event OnMFXArmorUnequip(String eventName, String strArg, Float numArg, Form sender)
;numArg is the biped slot, sender is the armor.
	Busy = True
	Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): OnMFXArmorUnequip(numArg = " + numArg + ",sender = " + sender + ")")
	If sender as Armor
		HandleUnequip(sender as Armor)
		If numArg == 45 ; Saddle/Armor
			HandleCHVars(None)
		EndIf
	EndIf
	If numArg == 30 || numArg == 50 
		While CurrentMount.IsEquipped(sender)
			Wait(0.1)
		EndWhile
		HandleCHVars(CurrentMount.GetWornForm(0x00008000) as Armor)
	EndIf
	Busy = False
EndEvent

Event OnMFXArmorCheck(String eventName, String strArg, Float numArg, Form sender)
;numArg is the biped slot, sender is the armor
;This checks to see whether sender is equipped. If it isn't, equip it. 
;If sender is not armor, then unequip any item in the bipedslot provided by this plugin
	If dataArmorSlotsUsed.Find(numArg as Int) < 0 || numArg != 30 || numArg != 50
		Return
	EndIf
	While Busy
		Utility.Wait(0.1)
	EndWhile
	Busy = True
	Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): OnMFXArmorCheck(strArg = " + strArg + ", numArg = " + numArg + ",sender = " + sender + ")")
	If sender as Armor
		If !CurrentMount.IsEquipped(sender as Armor) && numArg == 45
			HandleCHVars(sender as Armor)
			HandleEquip(sender as Armor)
		ElseIf numArg == 50 ; Body || Mane/Tail
			;Utility.Wait(0.25)
			HandleCHVars(CurrentMount.GetWornForm(0x00008000) as Armor)
			;ManeHidden = _ManeHidden ; Setting the property to itself forces it to double-check the mane's state
		EndIf
	Else
		RemovePluginArmor(numArg as Int)
		HandleCHVars(CurrentMount.GetWornForm(0x00008000) as Armor)
	EndIf
	Busy = False
	If numArg == 30 || numArg == 45 || numArg == 50 
		If CHHorseArmorMode.GetValue() > 0
			ManeHidden = True
		Else
			ManeHidden = False
		EndIf
	EndIf
	SendModEvent("vMFX_MFXPluginMessage","checkcomplete")
EndEvent
