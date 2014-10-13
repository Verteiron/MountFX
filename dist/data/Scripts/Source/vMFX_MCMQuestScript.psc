Scriptname vMFX_MCMQuestScript extends SKI_ConfigBase  

;--=== Imports ===--

Import Utility
Import Game
Import vMFX_Registry

Quest Property vMFX_MetaQuest Auto
Quest Property vMFX_FXRegistryQuest Auto

String[] Pages

Int[]	_SkinOptions
Int[]	_SpellOptions
Int[]	_PluginOptions
Int[]	_DisabledSlots

Bool	_IncompatibleMesh

vMFX_FXRegistryScript _MFXRegistry

Actor 	PlayerMount

Race	HorseRace
Race	CurrentRace

String	CurrentOutfit = "Default"

Form[] 	_CurrentOutfit
String[]	_CurrentOutfitStrings ; 'cause GetText is slow

Int DataVersion

String[] sSlotNames

String[] sSlotOptions30
String[] sSlotOptions31
String[] sSlotOptions32
String[] sSlotOptions33
String[] sSlotOptions34
String[] sSlotOptions35
String[] sSlotOptions36
String[] sSlotOptions37
String[] sSlotOptions38
String[] sSlotOptions39
String[] sSlotOptions40
String[] sSlotOptions41
String[] sSlotOptions42
String[] sSlotOptions43
String[] sSlotOptions44
String[] sSlotOptions45
String[] sSlotOptions46
String[] sSlotOptions47
String[] sSlotOptions48
String[] sSlotOptions49
String[] sSlotOptions50
String[] sSlotOptions51
String[] sSlotOptions52
String[] sSlotOptions53
String[] sSlotOptions54
String[] sSlotOptions55
String[] sSlotOptions56
String[] sSlotOptions57
String[] sSlotOptions58
String[] sSlotOptions59
String[] sSlotOptions60
String[] sSlotOptions61

Armor[] kSlotArmors30
Armor[] kSlotArmors31
Armor[] kSlotArmors32
Armor[] kSlotArmors33
Armor[] kSlotArmors34
Armor[] kSlotArmors35
Armor[] kSlotArmors36
Armor[] kSlotArmors37
Armor[] kSlotArmors38
Armor[] kSlotArmors39
Armor[] kSlotArmors40
Armor[] kSlotArmors41
Armor[] kSlotArmors42
Armor[] kSlotArmors43
Armor[] kSlotArmors44
Armor[] kSlotArmors45
Armor[] kSlotArmors46
Armor[] kSlotArmors47
Armor[] kSlotArmors48
Armor[] kSlotArmors49
Armor[] kSlotArmors50
Armor[] kSlotArmors51
Armor[] kSlotArmors52
Armor[] kSlotArmors53
Armor[] kSlotArmors54
Armor[] kSlotArmors55
Armor[] kSlotArmors56
Armor[] kSlotArmors57
Armor[] kSlotArmors58
Armor[] kSlotArmors59
Armor[] kSlotArmors60
Armor[] kSlotArmors61

String[] sSpellNames
Spell[]  kSpellList

Bool _Updating

Event OnConfigInit()
	_MFXRegistry = vMFX_FXRegistryQuest as vMFX_FXRegistryScript
	ModName = "MountFX"
		
	Pages = New String[4]

	Pages[0] = "Skins and armor"
	Pages[1] = "Special effects"
	Pages[2] = "NIOverride tweaks"
	Pages[3] = "Manage plugins"
		
	_SkinOptions = New Int[128]
	_PluginOptions = New Int[128]
	HorseRace = Game.GetFormFromFile(0x000131fd,"Skyrim.esm") as Race
	CurrentRace = HorseRace
	UnregisterForModEvent("vMFX_MFXUpdateMCM")
	RegisterForModEvent("vMFX_MFXUpdateMCM", "OnMFXUpdateMCM")
EndEvent

Event OnGameReload()
    parent.OnGameReload()
	UnregisterForModEvent("vMFX_MFXUpdateMCM")
	RegisterForModEvent("vMFX_MFXUpdateMCM", "OnMFXUpdateMCM")
	ApplySettings()
EndEvent

Event OnMFXUpdateMCM(String eventName, String strArg, Float numArg, Form sender)
	Debug.Trace("MFX/MCM: Received update event!")
	_MFXRegistry.UpdateOutfitFilters()
	UpdateOptions()
EndEvent

;State Updating
	;Event OnMFXUpdateMCM(String eventName, String strArg, Float numArg, Form sender)
	;EndEvent
;	
	;Function UpdateOptions()
	;EndFunction
;EndState

Event OnConfigOpen()
	;_MFXRegistry.UpdateOutfitFilters()
EndEvent

Event OnPageReset(string a_page)
	UpdateSettings()
	vMFX_FXPluginBase MFXPlugin
	PlayerMount = Game.GetPlayersLastRiddenHorse()
	Int skIndex = 0
	Debug.Trace("MFX/MCM: a_page is " + a_page)
	If a_page == Pages[0] ; Armors / Skins
		If !PlayerMount
			AddHeaderOption("Get a mount, then try again!")
			Return
		EndIf
		SetCursorFillMode(TOP_TO_BOTTOM)
		_SkinOptions = New Int[128]
		CurrentRace = HorseRace
		;Int jOutfit = GetRegObj("Outfits." + CurrentOutfit)
		_CurrentOutfitStrings = New String[64]
		AddHeaderOption(CurrentRace.GetName())
		Int iOptionFlags 
		Int iBipedSlot = 30
		While iBipedSlot < 64
			If JArray.FindForm(GetRegObj("Slots." + iBipedSlot + ".Races"),CurrentRace) >= 0
				iOptionFlags = OPTION_FLAG_NONE
				Bool bDisplayOption = True
				If !GetSlotArmors(iBipedSlot)[1] && !GetSlotArmors(iBipedSlot)[2] ; JArray.FindInt(GetRegObj("Outfits." + CurrentOutfit + ".DisabledSlots"),iBipedSlot) >= 0 
					iOptionFlags = OPTION_FLAG_DISABLED
					bDisplayOption = False
				EndIf
				Form kFormForSlot = GetRegForm("Outfits." + CurrentOutfit + ".Slots[" + iBipedSlot + "]")
				If kFormForSlot
					_CurrentOutfitStrings[iBipedSlot] = kFormForSlot.GetName()
				Else
					_CurrentOutfitStrings[iBipedSlot] = "None/Not set"
				EndIf
				If bDisplayOption
					_SkinOptions[iBipedSlot] = AddMenuOption(_MFXRegistry.SlotNames[iBipedSlot],_CurrentOutfitStrings[iBipedSlot],iOptionFlags)
					Debug.Trace("MFX/MCM: Added " + _SkinOptions[iBipedSlot] + " with ID " + iBipedSlot)
				Else
					Debug.Trace("MFX/MCM: Skipped " + _SkinOptions[iBipedSlot])
				EndIf
			EndIf
			iBipedSlot += 1
		EndWhile
	ElseIf a_page == Pages[1] ; Spells and other EffectShader
		If !PlayerMount
			AddHeaderOption("Get a mount, then try again!")
			Return
		EndIf
		SetCursorFillMode(TOP_TO_BOTTOM)
		_SpellOptions = New Int[128]
		CurrentRace = HorseRace
		AddHeaderOption(CurrentRace.GetName())
		Int i = 0
		While i < kSpellList.Length
			Spell kSpell = kSpellList[i]
			If kSpell
				Int iOptionFlags = OPTION_FLAG_NONE
				Bool bDisplayOption = True
				;Additional logic here if needed
				If bDisplayOption
					_SpellOptions[i] = AddToggleOption(sSpellNames[i],PlayerMount.HasSpell(kSpell),iOptionFlags)
					Debug.Trace("MFX/MCM: Added Spell option " + kSpell + " with ID " + i)
				Else
					Debug.Trace("MFX/MCM: Skipped " + kSpell)
				EndIf
			EndIf
			i += 1
		EndWhile
	ElseIf a_page == Pages[3] ; Plugin management
		SetCursorFillMode(LEFT_TO_RIGHT)
		Int i = 0
		While i < _MFXRegistry.vMFX_regFXPlugins.GetSize()
			MFXPlugin = _MFXRegistry.vMFX_regFXPlugins.GetAt(i) as vMFX_FXPluginBase
			_PluginOptions[i] = AddToggleOption(MFXPlugin.infoPluginName,MFXPlugin.infoEnabled)
			i += 1
		EndWhile
	EndIf
EndEvent

Event OnOptionSelect(Int Option)
	Int idx = _SpellOptions.Find(Option)
	If idx >= 0 ; Spell option was selected
		Spell kSpell = kSpellList[idx]
		If kSpell
			If PlayerMount.HasSpell(kSpell)
				PlayerMount.RemoveSpell(kSpell)
				SetToggleOptionValue(Option,False)
			Else
				PlayerMount.AddSpell(kSpell,False)
				SetToggleOptionValue(Option,True)
			EndIf
		EndIf
	EndIf
EndEvent

Event OnOptionMenuOpen(Int Option)
	Debug.Trace("MFX/MCM: OnOptionMenuOpen(" + Option + ")")
	vMFX_FXPluginBase MFXPlugin
	Int iSlotNum = _SkinOptions.Find(Option)
	Debug.Trace("MFX/MCM: Slot number is " + iSlotNum)
	SetMenuDialogOptions(GetSlotOptions(iSlotNum))
	Int iIndex = GetSlotOptions(iSlotNum).Find(_CurrentOutfitStrings[iSlotNum])
	SetMenuDialogStartIndex(iIndex)
	SetMenuDialogDefaultIndex(0)
EndEvent

Event OnOptionMenuAccept(int option, int index)
	Debug.Trace("MFX/MCM: OnOptionMenuAccept(" + Option + "," + index + ")")
	If index >= 0
		Int iSlotNum = _SkinOptions.Find(Option)
		Debug.Trace("MFX/MCM: User picked " + GetSlotOptions(iSlotNum)[index] + ", which is Armor " + GetSlotArmors(iSlotNum)[index])
		SetMenuOptionValue(option, GetSlotOptions(iSlotNum)[index])
		Int Result = _MFXRegistry.AddArmorToOutfit(iSlotNum,GetSlotArmors(iSlotNum)[index])
		If Result != 0
			;_DisabledSlots = _MFXRegistry.DisabledSlots
			DataVersion = 0
			Debug.Trace("MFX/MCM: MFXRegistry reports change in allowed slots, forcing page reset...")
			UpdateOptions()
			ForcePageReset()
		EndIf
	EndIf
EndEvent

event OnConfigClose()
	SendModEvent("vMFX_MFXOutfitUpdated")
	;_MFXRegistry.ApplyCurrentOutfit(PlayerMount)
endEvent

Function UpdateSettings()

EndFunction

function ApplySettings()

EndFunction

Function UpdateOptions()
	Debug.Trace("MFX/MCM: Our DataVersion is " + DataVersion + ", MFXRegistry.DataVersion is " + _MFXRegistry.DataVersion)
	Float StartTime = Utility.GetCurrentRealTime()
	If DataVersion == _MFXRegistry.DataVersion && CurrentRace == _MFXRegistry.RaceFilter
		Return
	EndIf
	sSlotNames = New String[128]
	Int iBipedSlot
	String sSlotName
	
	Int jArmorsforSlot
	Armor kArmor
	int skIndex = 0
	String[] sArmorNames
	Armor[] kArmors = New Armor[128]
	
	Int i = 0
	Int j = 0
	Int[] SlotsForRace = _MFXRegistry.regGetSlotsForRace(CurrentRace)
	Debug.Trace("MFX/MCM: Found " + SlotsForRace.Find(0) + " slots for this race!")
	iBipedSlot = 30
	Debug.Trace("MFX/MCM:  Loading armor for Outfit " + CurrentOutfit + "...")
	While iBipedSlot < 62
		If SlotsForRace.Find(iBipedSlot) >= 0
			kArmors = New Armor[128]
			Debug.Trace("MFX/MCM:  Loading armor for BipedSlot " + iBipedSlot + "...")
			sSlotNames[iBipedSlot] = _MFXRegistry.SlotNames[iBipedSlot]
			sArmorNames = New String[128]
			;ArmorsforSlot = _MFXRegistry.regGetArmorsForSlot(iBipedSlot)
			jArmorsForSlot = GetRegObj("Outfits." + CurrentOutfit + ".FilteredList." + iBipedSlot + ".Forms")
			Debug.Trace("MFX/MCM:  Found " + JArray.Count(jArmorsForSlot) + " armors for BipedSlot " + iBipedSlot + "!")
			i = 0
			kArmors[0] = None
			sArmorNames[0] = "None/Not set"
			skIndex = 1
			While i < kArmors.Length
				kArmor = JArray.GetForm(jArmorsForSlot,i) as Armor
				If kArmor
					kArmors[skIndex] = kArmor
					sArmorNames[skIndex] = kArmor.GetName()
					skIndex += 1
				EndIf
				i += 1
			EndWhile
			
			SetSlotArmors(iBipedSlot,kArmors)
			SetSlotOptions(iBipedSlot,sArmorNames)
		EndIf
		iBipedSlot += 1
	EndWhile

	Int jRaceFormMap = GetRegObj("RaceForms")
	String sRaceUUID = jFormMap.GetStr(jRaceFormMap,CurrentRace)
	Int jSpellList = GetFormLinkArray(CurrentRace,"Spells")
	Debug.Trace("MFX/MCM:  Found " + JArray.Count(jSpellList) + " spells for Race " + CurrentRace + "!")
	kSpellList = New Spell[128]
	sSpellNames = New String[128]
	i = 0
	Int idx = 0
	While i < JArray.Count(jSpellList)
		Spell kSpell = JArray.GetForm(jSpelllist,i) as Spell
		If kSpell
			kSpellList[idx] = kSpell
			sSpellNames[idx] = kSpell.GetName()
			idx += 1
		EndIf
		i += 1
	EndWhile
	
	DataVersion = _MFXRegistry.DataVersion
	Debug.Trace("MFX/MCM: Updated MCM lists in " + (Utility.GetCurrentRealTime() - StartTime) + "s.")
EndFunction

Function SetSlotOptions(Int Index, String[] SlotOptions)
	If Index == 30
		sSlotOptions30 = SlotOptions
	ElseIf Index == 31
		sSlotOptions31 = SlotOptions
	ElseIf Index == 32
		sSlotOptions32 = SlotOptions
	ElseIf Index == 33
		sSlotOptions33 = SlotOptions
	ElseIf Index == 34
		sSlotOptions34 = SlotOptions
	ElseIf Index == 35
		sSlotOptions35 = SlotOptions
	ElseIf Index == 36
		sSlotOptions36 = SlotOptions
	ElseIf Index == 37
		sSlotOptions37 = SlotOptions
	ElseIf Index == 38
		sSlotOptions38 = SlotOptions
	ElseIf Index == 39
		sSlotOptions39 = SlotOptions
	ElseIf Index == 40
		sSlotOptions40 = SlotOptions
	ElseIf Index == 41
		sSlotOptions41 = SlotOptions
	ElseIf Index == 42
		sSlotOptions42 = SlotOptions
	ElseIf Index == 43
		sSlotOptions43 = SlotOptions
	ElseIf Index == 44
		sSlotOptions44 = SlotOptions
	ElseIf Index == 45
		sSlotOptions45 = SlotOptions
	ElseIf Index == 46
		sSlotOptions46 = SlotOptions
	ElseIf Index == 47
		sSlotOptions47 = SlotOptions
	ElseIf Index == 48
		sSlotOptions48 = SlotOptions
	ElseIf Index == 49
		sSlotOptions49 = SlotOptions
	ElseIf Index == 50
		sSlotOptions50 = SlotOptions
	ElseIf Index == 51
		sSlotOptions51 = SlotOptions
	ElseIf Index == 52
		sSlotOptions52 = SlotOptions
	ElseIf Index == 53
		sSlotOptions53 = SlotOptions
	ElseIf Index == 54
		sSlotOptions54 = SlotOptions
	ElseIf Index == 55
		sSlotOptions55 = SlotOptions
	ElseIf Index == 56
		sSlotOptions56 = SlotOptions
	ElseIf Index == 57
		sSlotOptions57 = SlotOptions
	ElseIf Index == 58
		sSlotOptions58 = SlotOptions
	ElseIf Index == 59
		sSlotOptions59 = SlotOptions
	ElseIf Index == 60
		sSlotOptions60 = SlotOptions
	ElseIf Index == 61
		sSlotOptions61 = SlotOptions
	EndIf
EndFunction

String[] Function GetSlotOptions(Int Index)
	If Index == 30
		Return sSlotOptions30
	ElseIf Index == 30
		Return sSlotOptions30
	ElseIf Index == 31
		Return sSlotOptions31
	ElseIf Index == 32
		Return sSlotOptions32
	ElseIf Index == 33
		Return sSlotOptions33
	ElseIf Index == 34
		Return sSlotOptions34
	ElseIf Index == 35
		Return sSlotOptions35
	ElseIf Index == 36
		Return sSlotOptions36
	ElseIf Index == 37
		Return sSlotOptions37
	ElseIf Index == 38
		Return sSlotOptions38
	ElseIf Index == 39
		Return sSlotOptions39
	ElseIf Index == 40
		Return sSlotOptions40
	ElseIf Index == 41
		Return sSlotOptions41
	ElseIf Index == 42
		Return sSlotOptions42
	ElseIf Index == 43
		Return sSlotOptions43
	ElseIf Index == 44
		Return sSlotOptions44
	ElseIf Index == 45
		Return sSlotOptions45
	ElseIf Index == 46
		Return sSlotOptions46
	ElseIf Index == 47
		Return sSlotOptions47
	ElseIf Index == 48
		Return sSlotOptions48
	ElseIf Index == 49
		Return sSlotOptions49
	ElseIf Index == 50
		Return sSlotOptions50
	ElseIf Index == 51
		Return sSlotOptions51
	ElseIf Index == 52
		Return sSlotOptions52
	ElseIf Index == 53
		Return sSlotOptions53
	ElseIf Index == 54
		Return sSlotOptions54
	ElseIf Index == 55
		Return sSlotOptions55
	ElseIf Index == 56
		Return sSlotOptions56
	ElseIf Index == 57
		Return sSlotOptions57
	ElseIf Index == 58
		Return sSlotOptions58
	ElseIf Index == 59
		Return sSlotOptions59
	ElseIf Index == 60
		Return sSlotOptions60
	ElseIf Index == 61
		Return sSlotOptions61
	EndIf
EndFunction

Function SetSlotArmors(Int Index, Armor[] SlotArmors)
	If Index == 30
		kSlotArmors30 = SlotArmors
	ElseIf Index == 31
		kSlotArmors31 = SlotArmors
	ElseIf Index == 32
		kSlotArmors32 = SlotArmors
	ElseIf Index == 33
		kSlotArmors33 = SlotArmors
	ElseIf Index == 34
		kSlotArmors34 = SlotArmors
	ElseIf Index == 35
		kSlotArmors35 = SlotArmors
	ElseIf Index == 36
		kSlotArmors36 = SlotArmors
	ElseIf Index == 37
		kSlotArmors37 = SlotArmors
	ElseIf Index == 38
		kSlotArmors38 = SlotArmors
	ElseIf Index == 39
		kSlotArmors39 = SlotArmors
	ElseIf Index == 40
		kSlotArmors40 = SlotArmors
	ElseIf Index == 41
		kSlotArmors41 = SlotArmors
	ElseIf Index == 42
		kSlotArmors42 = SlotArmors
	ElseIf Index == 43
		kSlotArmors43 = SlotArmors
	ElseIf Index == 44
		kSlotArmors44 = SlotArmors
	ElseIf Index == 45
		kSlotArmors45 = SlotArmors
	ElseIf Index == 46
		kSlotArmors46 = SlotArmors
	ElseIf Index == 47
		kSlotArmors47 = SlotArmors
	ElseIf Index == 48
		kSlotArmors48 = SlotArmors
	ElseIf Index == 49
		kSlotArmors49 = SlotArmors
	ElseIf Index == 50
		kSlotArmors50 = SlotArmors
	ElseIf Index == 51
		kSlotArmors51 = SlotArmors
	ElseIf Index == 52
		kSlotArmors52 = SlotArmors
	ElseIf Index == 53
		kSlotArmors53 = SlotArmors
	ElseIf Index == 54
		kSlotArmors54 = SlotArmors
	ElseIf Index == 55
		kSlotArmors55 = SlotArmors
	ElseIf Index == 56
		kSlotArmors56 = SlotArmors
	ElseIf Index == 57
		kSlotArmors57 = SlotArmors
	ElseIf Index == 58
		kSlotArmors58 = SlotArmors
	ElseIf Index == 59
		kSlotArmors59 = SlotArmors
	ElseIf Index == 60
		kSlotArmors60 = SlotArmors
	ElseIf Index == 61
		kSlotArmors61 = SlotArmors
	EndIf
EndFunction

Armor[] Function GetSlotArmors(Int Index)
	If Index == 30
		Return kSlotArmors30
	ElseIf Index == 30
		Return kSlotArmors30
	ElseIf Index == 31
		Return kSlotArmors31
	ElseIf Index == 32
		Return kSlotArmors32
	ElseIf Index == 33
		Return kSlotArmors33
	ElseIf Index == 34
		Return kSlotArmors34
	ElseIf Index == 35
		Return kSlotArmors35
	ElseIf Index == 36
		Return kSlotArmors36
	ElseIf Index == 37
		Return kSlotArmors37
	ElseIf Index == 38
		Return kSlotArmors38
	ElseIf Index == 39
		Return kSlotArmors39
	ElseIf Index == 40
		Return kSlotArmors40
	ElseIf Index == 41
		Return kSlotArmors41
	ElseIf Index == 42
		Return kSlotArmors42
	ElseIf Index == 43
		Return kSlotArmors43
	ElseIf Index == 44
		Return kSlotArmors44
	ElseIf Index == 45
		Return kSlotArmors45
	ElseIf Index == 46
		Return kSlotArmors46
	ElseIf Index == 47
		Return kSlotArmors47
	ElseIf Index == 48
		Return kSlotArmors48
	ElseIf Index == 49
		Return kSlotArmors49
	ElseIf Index == 50
		Return kSlotArmors50
	ElseIf Index == 51
		Return kSlotArmors51
	ElseIf Index == 52
		Return kSlotArmors52
	ElseIf Index == 53
		Return kSlotArmors53
	ElseIf Index == 54
		Return kSlotArmors54
	ElseIf Index == 55
		Return kSlotArmors55
	ElseIf Index == 56
		Return kSlotArmors56
	ElseIf Index == 57
		Return kSlotArmors57
	ElseIf Index == 58
		Return kSlotArmors58
	ElseIf Index == 59
		Return kSlotArmors59
	ElseIf Index == 60
		Return kSlotArmors60
	ElseIf Index == 61
		Return kSlotArmors61
	EndIf
EndFunction