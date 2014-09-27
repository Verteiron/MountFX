Scriptname vMFX_FXPluginSaddle extends vMFX_FXPluginBase  

Import Game
Import Utility
Import vMFX_Registry

Bool Property CHInstalled = False Auto Hidden

GlobalVariable 	Property CHHorseEquipmentMode Auto Hidden
Formlist 		Property CHHorseEquipmentList Auto Hidden

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

;Event OnInit()
;	SetSaddleMode()
;	Parent.OnInit()
;EndEvent

;Event OnGameReload()
;	Parent.OnGameReload()
;EndEvent

Event OnMFXRegistryReady(String eventName, String strArg, Float numArg, Form sender)
	SetSaddleMode()
	Parent.OnMFXRegistryReady(eventName, strArg, numArg, sender)
EndEvent

Function SetSaddleMode()
	CHInstalled = False
	If GetModByName("Convenient Horses.esp") != 255
		Quest CH = Quest.GetQuest("CH")
		If CH.IsRunning()
			CHInstalled = True
		EndIf
	EndIf
	If CHInstalled
		SetModeCH()
	Else
		SetModeVanilla()
	EndIf
	
EndFunction

Function SetModeVanilla()
	GoToState("")
	SetRegBool("Config.Compat.ConvenientHorses.Enabled",False)
	Debug.Trace("MFXP/" + infoESPFile + "/" + infoPluginName + ": Convenient Horses is not installed or running.")
	CHHorseEquipmentMode = None
	dataArmorSlotNames = New String[1]
	dataArmorSlotNames[0] = "Saddle"
	dataFormLists[0] = GetFormFromFile(0x0200640b,"vMFX_MountFX.esp") as FormList
EndFunction

Function SetModeCH()
	GoToState("CHMode")
	SetRegBool("Config.Compat.ConvenientHorses.Enabled",True)
	Debug.Trace("MFXP/" + infoESPFile + "/" + infoPluginName + ": Convenient Horses is installed and running! CH will handle saddle/armor placement!")
	CHHorseEquipmentMode = GetFormFromFile(0x021610dd,"Convenient Horses.esp") as GlobalVariable
	dataArmorSlotNames = New String[1]
	dataArmorSlotNames[0] = "Saddle/Armor"
	CHHorseEquipmentList = GetFormFromFile(0x021610dc,"Convenient Horses.esp") as FormList
	Debug.Trace("MFXP/" + infoESPFile + "/" + infoPluginName + ": CHHorseEquipmentList contains " + CHHorseEquipmentList.GetSize() + " items!")
	dataFormLists[0] = CHHorseEquipmentList
EndFunction

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
	CHHorseEquipmentMode.SetValueInt(ArmorIndex + 1) ; Set to 0 if not found, otherwise to appropriate CHHorseEquipmentMode
	Debug.Trace("MFXP/" + infoESPFile + "/" + infoPluginName + ": akArmor is " + akArmor + " at index " + ArmorIndex)
	If akArmor.HasKeywordString("CHHorseArmor")
		ManeHidden = True
	Else
		ManeHidden = False
	EndIf
EndFunction

Function HideMane(Bool bHideMane)
	ManeHidden = bHideMane
EndFunction

State CHMode
	Event OnMFXArmorEquip(String eventName, String strArg, Float numArg, Form sender)
	;numArg is the biped slot, sender is the armor.
		Busy = True
		Debug.Trace("MFXP/" + infoESPFile + "/" + infoPluginName + ": OnMFXArmorEquip(numArg = " + numArg + ",sender = " + sender + ")")
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
		Debug.Trace("MFXP/" + infoESPFile + "/" + infoPluginName + ": OnMFXArmorUnequip(numArg = " + numArg + ",sender = " + sender + ")")
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
		If dataArmorSlotNumbers.Find(numArg as Int) < 0 || numArg != 30 || numArg != 50
			Return
		EndIf
		While Busy
			Utility.Wait(0.1)
		EndWhile
		Busy = True
		Debug.Trace("MFXP/" + infoESPFile + "/" + infoPluginName + ": OnMFXArmorCheck(strArg = " + strArg + ", numArg = " + numArg + ",sender = " + sender + ")")
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
			If CHHorseEquipmentMode.GetValue() > 0
				ManeHidden = True
			Else
				ManeHidden = False
			EndIf
		EndIf
		SendModEvent("vMFX_MFXPluginMessage","checkcomplete")
	EndEvent
EndState
