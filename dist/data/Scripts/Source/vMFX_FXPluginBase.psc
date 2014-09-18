Scriptname vMFX_FXPluginBase extends Quest
{Base script for MountFX plugins}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

Bool Property infoEnabled = True Auto Hidden

Actor Property CurrentMount = None Auto Hidden

Bool Property Busy = False Auto Hidden

Bool Property dataChangesBody = False Auto
{This plugin alters the basic model enough to break other plugins. Needed for Arvak.}

Bool Property dataTextureSwapOnly = False Auto
{This plugin takes the supplied armor and copies its attached TextureSet to the target without equipping it.}

Formlist Property dataRequiredArmorList Auto
{What armor, if any, must be equipped or selected in order to use this plugin.}

Int[] Property dataUnsupportedSlot Auto
{What slots are known to be incompatible with this plugin.}

Int Property infoPriority = 1 Auto
{0 is first. Default is 1. If you are extending an existing plugin, this should be higher than that plugin's priority.}

Bool Property dataAddsArmorSlots = False Auto
{Enable this if your mod adds new named data slots to the races in dataRace.}

Int[] Property dataArmorSlotsUsed Auto
{Slots used by armor in this plugin. Use this only if adding new Armor to an already-registered slot!}

Int[] Property dataArmorNewSlotNumbers Auto
{Slots used by this plugin or added to each Race in dataRace. See the documentation.}

String[] Property dataArmorNewSlotNames Auto
{New slot names to add to this Race. Index must match that of dataArmorNewSlotNumbers. See the documentation. }

Race[] Property dataRaces Auto
{The races this plugin will apply effects to. All races must share the same skeleton. Set to None to apply to ALL mountable races.}

Formlist[] Property dataFormlists Auto
{The formlist of every Armor, Spell, or additional Formlist you wish to register for this race.}

String Property	infoESPFile Auto
{The name of the plugin's ESP file, like "vMFX_MountFX.esp".}

String Property	infoPluginName Auto
{The friendly name of the plugin. This should be the actual name of the ESP file.}

String Property infoAuthor Auto
{The name of the plugin author.}

String Property infoArtCredit Auto
{The name of the artist (if not the author).}

Int Property infoVersion = 1 Auto
{Version. Increment this if the plugin gets updated.}

;--=== Variables ===--

Bool 					_Running

Int						_RegistryID
Int						_RegistryVersion

vMFX_FXRegistryScript	_MFXRegistry

Actor					_CurrentMount

;--=== Events ===--

Event OnInit()
	Debug.Trace("MFXP: OnInit!")
	OnGameReload()
EndEvent

Event OnReset()
	Debug.Trace("MFXP: OnReset!")
EndEvent

Event OnGameReload()
	RegisterForModEvent("vMFX_MFXRegistryReady", "OnMFXRegistryReady")
	RegisterForModEvent("vMFX_MFXArmorPick", "OnMFXArmorPick")
	RegisterForModEvent("vMFX_MFXArmorEquip", "OnMFXArmorEquip")
	RegisterForModEvent("vMFX_MFXArmorUnequip", "OnMFXArmorUnequip")
	RegisterForModEvent("vMFX_MFXArmorCheck", "OnMFXArmorCheck")
	RegisterForModEvent("vMFX_MFXSetCurrentMount", "OnMFXSetCurrentMount")
EndEvent

Event OnMFXSetCurrentMount(String eventName, String strArg, Float numArg, Form sender)
;sender should be the mount itself
	If sender as Actor
		_CurrentMount = sender as Actor
	EndIf
	;Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): OnMFXSetCurrentMount(strArg = " + strArg + ",sender = " + sender + ")")
	;_CurrentMount = _MFXRegistry.CurrentMount
	Debug.Trace("MFXPlugin: Current mount set to " + _CurrentMount)
	;Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): OnMFXSetCurrentMount(strArg = " + strArg + ",sender = " + sender + ")")
	CurrentMount = _CurrentMount
	SendModEvent("vMFX_MFXPluginMessage","mountupdated")
EndEvent

Event OnMFXArmorPick(String eventName, String strArg, Float numArg, Form sender)
;strArg is the FormID picked, numArg is the biped slot

EndEvent

Event OnMFXArmorEquip(String eventName, String strArg, Float numArg, Form sender)
;numArg is the biped slot, sender is the armor.
	Busy = True
	;Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): OnMFXArmorEquip(numArg = " + numArg + ",sender = " + sender + ")")
	If sender as Armor
		HandleEquip(sender as Armor)
	EndIf
	Busy = False
EndEvent

Event OnMFXArmorUnequip(String eventName, String strArg, Float numArg, Form sender)
;numArg is the biped slot, sender is the armor.
	Busy = True
	;Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): OnMFXArmorUnequip(numArg = " + numArg + ",sender = " + sender + ")")
	If sender as Armor
		HandleUnequip(sender as Armor)
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
		If !_CurrentMount.IsEquipped(sender as Armor)
			HandleEquip(sender as Armor)	
		EndIf
	Else
		RemovePluginArmor(numArg as Int)
	EndIf
	Busy = False
	SendModEvent("vMFX_MFXPluginMessage","checkcomplete")
EndEvent

Event OnMFXRegistryReady(String eventName, String strArg, Float numArg, Form sender)
	vMFX_FXRegistryScript NewFXRegistry = sender as vMFX_FXRegistryScript
	; Already registered?
	SendModEvent("vMFX_MFXPluginMessage","ping")
	if (_MFXRegistry == NewFXRegistry || NewFXRegistry == none)
		;SendModEvent("vMFX_MFXPluginMessage","ready")
		return
	endIf
	;Debug.Trace("MFXPlugin: Registering (" + infoESPFile + "/'" + infoPluginName + "')...")
	If !dataArmorSlotsUsed
		dataArmorSlotsUsed = dataArmorNewSlotNumbers
	EndIf
	Int Timer
	While NewFXRegistry.MaxPriority < (infoPriority - 1) && Timer < 10
		WaitMenuMode(1)
		Timer += 1
	EndWhile
	_RegistryID = NewFXRegistry.RegisterPlugin(self)

	; Success
	if (_RegistryID >= 0)
		_MFXRegistry = NewFXRegistry
		;Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): Registered as ID " + _RegistryID + "!")
		SendModEvent("vMFX_MFXPluginMessage","ready")
;		RegisterForSingleUpdate(0.1)
	endIf
EndEvent

Event OnUpdate()
	RegisterMFXPlugin()
EndEvent
;--=== Functions ===--

Function UpdateCurrentMount()
	_CurrentMount = _MFXRegistry.CurrentMount
	Debug.Trace("MFXPlugin: Current mount set to " + _CurrentMount)
	;Debug.Trace("MFXPlugin: (" + infoESPFile + "/'" + infoPluginName + "'): OnMFXSetCurrentMount(strArg = " + strArg + ",sender = " + sender + ")")
	CurrentMount = _CurrentMount
EndFunction

Function RegisterMFXPlugin()
	;If dataRace
		;Int RaceResult = _MFXRegistry.RegisterRace(dataRace)
		;Debug.Trace("vMFX_FXPlugin(" + infoESPFile + "): Registered " + dataRace + " as " + RaceResult + "!")
	;EndIf
EndFunction

Bool Function IsPluginArmor(Armor akArmor)
	Int i = 0
	While i < dataFormlists.Length
		If dataFormlists[i].HasForm(akArmor)
			Return True
		EndIf
		i += 1
	EndWhile
	Return False
EndFunction

Function HandleEquip(Armor akArmor = None)
	If !akArmor
		Return ; Nothing to do, if it's an unequip we'll get an unequip event
	EndIf
	If !IsPluginArmor(akArmor)
		Return ; This is not our armor
	EndIf
	;WaitMenuMode((infoPriority as Float) * 0.1)
	Int iSlotMask = akArmor.GetSlotMask()
	Form CurrentArmor = _CurrentMount.GetWornForm(iSlotMask)
	_CurrentMount.EquipItem(akArmor,True,True)
	If CurrentArmor
		_CurrentMount.RemoveItem(CurrentArmor)
	EndIf
EndFunction

Function HandleUnequip(Armor akArmor = None)
	If !akArmor
		Return ; Nothing to do, if it's an unequip we'll get an unequip event
	EndIf
	If !IsPluginArmor(akArmor)
		Return ; This is not our armor
	EndIf
	If _CurrentMount.GetItemCount(akArmor) > 0 || _CurrentMount.IsEquipped(akArmor)
		_CurrentMount.RemoveItem(akArmor,_CurrentMount.GetItemCount(akArmor),True)
	EndIf
EndFunction

Function RemovePluginArmor(Int iBipedSlot)
;Remove plugin-provided armor from specified BipedSlot
	Int SlotIndex 
	SlotIndex = dataArmorSlotsUsed.Find(iBipedSlot)
	If SlotIndex < 0 || SlotIndex >= dataFormLists.Length
		;Debug.Trace("vMFX_FXPlugin(" + infoESPFile + "): Not managing slot " + iBipedSlot + ", so nothing to do.")
		Return
	EndIf
	Int iSlotMask = _MFXRegistry.GetSlotMaskFromBiped(iBipedSlot)
	Form CurrentArmor = _CurrentMount.GetWornForm(iSlotMask)
	If CurrentArmor
		If dataFormLists[SlotIndex].Find(CurrentArmor) >= 0
			_CurrentMount.RemoveItem(CurrentArmor)
			Debug.Trace("vMFX_FXPlugin(" + infoESPFile + "): Removing Armor " + CurrentArmor.GetName() + "!")	
		EndIf
	EndIf
EndFunction

String Function GetSlotName()

EndFunction
