Scriptname vMFX_FXRegistryScript extends Quest  
{Track all registered mount FX and plugin content}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

Int Property ARRAYMAX = 512 AutoReadOnly Hidden

Actor Property PlayerRef Auto

Actor Property CurrentMount = None Auto Hidden

FormList Property vMFX_reg Auto
FormList Property vMFX_regArmors Auto
FormList Property vMFX_regRaces Auto
FormList Property vMFX_regFXPlugins Auto
FormList Property vMFX_regSlots Auto
FormList Property vMFX_regSpells Auto
FormList Property vMFX_regSortArmorsByRace Auto
FormList Property vMFX_regSortPluginsByRace Auto
FormList Property vMFX_regSortArmorsBySlot Auto
FormList Property vMFX_regSortPluginsBySlot Auto
FormList Property vMFX_regArmorsWithReqs Auto

FormList[] Property vMFX_reg_Slots Auto

Bool Property IncompatibleMesh = False Auto
Int[] Property DisabledSlots Auto
Armor Property DisablingArmor Auto
vMFX_FXPluginBase Property DisablingPlugin Auto

String[] Property SlotNames Auto

Int Property MaxPriority Auto

Race Property RaceFilter
	Function Set(Race akFilterRace)
		If _RaceFilterProp != akFilterRace
			SetRaceFilter(akFilterRace)
		EndIf
		_RaceFilterProp = akFilterRace
	EndFunction
	Race Function Get()
		Return _RaceFilterProp
	EndFunction
EndProperty

Int Property DataVersion Auto

;--=== Variables ===--

Int 		_PluginPingCount
Int 		_PluginPingTotalCount
Int 		_PluginReadyCount
Int 		_PluginReadyTotalCount
Int			_PluginArmorCheckCount
Int			_PluginMountUpdateCount

Race		_RaceFilterProp

Bool 		_Running

Float 		_ScriptLatency
Float 		_StartTime
Float 		_EndTime

String 		_LockedBy

Race[] 		_RaceIndex

String[]	_PluginNameIndex
String[] 	SlotNames

vMFX_FXPluginBase[]	_FXPluginForms
Int[] 				_FXPluginSlots

Armor[]		_ArmorIndex

Int[]		_SlotArmorSlotIndex
String[]	_SlotArmorSlotNameIndex
Int[]		_SlotRaceIndex
Int[]		_SlotPluginIndex

Form[]		_OutfitCurrent
Form[]		_OutfitPrevious

Actor		_CurrentMount

Int 		_iPriorityCheck

;--Registry arrays

Int[]					_regSlots1
Form[]					_regArmors1
Form[]					_regPlugins1
Form[]					_regRaces1
Int[]		_regLookupSlotRace1
Int[]		_regLookupRace1
Int[]		_regLookupPlugin1
Int[]		_regLookupArmor1
Int[]		_regLookupSlot1
Int[]		_regLookupRaceSlot1
Int[]		_regLookupPluginRace1
Int[]		_regLookupRacePlugin1
Int[]		_regLookupPluginSlot1
Int[]		_regLookupSlotPlugin1
Int[]		_regLookupArmorSlot1
Int[]		_regLookupSlotArmor1
Int[]		_regLookupArmorPlugin1
Int[]		_regLookupPluginArmor1

Int[]					_regSlots2
Form[]					_regArmors2
Form[]					_regPlugins2
Form[]					_regRaces2
Int[]		_regLookupRace2
Int[]		_regLookupPlugin2
Int[]		_regLookupArmor2
Int[]		_regLookupSlot2
Int[]		_regLookupSlotRace2
Int[]		_regLookupRaceSlot2
Int[]		_regLookupPluginRace2
Int[]		_regLookupRacePlugin2
Int[]		_regLookupPluginSlot2
Int[]		_regLookupSlotPlugin2
Int[]		_regLookupArmorSlot2
Int[]		_regLookupSlotArmor2
Int[]		_regLookupArmorPlugin2
Int[]		_regLookupPluginArmor2

Int[]					_regSlots3
Form[]					_regArmors3
Form[]					_regPlugins3
Form[]					_regRaces3
Int[]		_regLookupRace3
Int[]		_regLookupPlugin3
Int[]		_regLookupArmor3
Int[]		_regLookupSlot3
Int[]		_regLookupSlotRace3
Int[]		_regLookupRaceSlot3
Int[]		_regLookupPluginRace3
Int[]		_regLookupRacePlugin3
Int[]		_regLookupPluginSlot3
Int[]		_regLookupSlotPlugin3
Int[]		_regLookupArmorSlot3
Int[]		_regLookupSlotArmor3
Int[]		_regLookupArmorPlugin3
Int[]		_regLookupPluginArmor3

Int[]					_regSlots4
Form[]					_regArmors4
Form[]					_regPlugins4
Form[]					_regRaces4
Int[]		_regLookupRace4
Int[]		_regLookupPlugin4
Int[]		_regLookupArmor4
Int[]		_regLookupSlot4
Int[]		_regLookupSlotRace4
Int[]		_regLookupRaceSlot4
Int[]		_regLookupPluginRace4
Int[]		_regLookupRacePlugin4
Int[]		_regLookupPluginSlot4
Int[]		_regLookupSlotPlugin4
Int[]		_regLookupArmorSlot4
Int[]		_regLookupSlotArmor4
Int[]		_regLookupArmorPlugin4
Int[]		_regLookupPluginArmor4
;--End Registry arrays

FormList[]	_regPluginIndex
FormList[]	_regPluginByRaceIndex
FormList[]	_regPluginBySlotIndex
FormList[]	_regArmorBySlotIndex
FormList[]	_regArmorByRaceIndex

String _dbgFunction
String _dbgContext

;--=== Events ===--

Event OnInit()
	Debug.Trace("vMFXRegistry: OnInit!")
	OnGameReload()
EndEvent

Event OnGameReload()
	RegisterForModEvent("vMFX_MFXPluginMessage", "OnMFXPluginMessage")
	RegisterForModEvent("vMFX_MFXOutfitUpdated", "OnMFXPOutfitUpdated")
EndEvent

Event OnMFXPluginMessage(String eventName, String strArg, Float numArg, Form sender)
	;Debug.Trace("vMFXRegistry: OnMFXPluginMessage(" + eventName + "," + strArg + "," + numArg + "," + sender + ")")
	If strArg == "ping"
		_PluginPingCount += 1
		_PluginPingTotalCount += 1
	ElseIf strArg == "ready"
		_PluginReadyCount += 1
		_PluginReadyTotalCount += 1
	ElseIf strArg == "checkcomplete"
		_PluginArmorCheckCount += 1
	ElseIf strArg == "mountupdated"
		_PluginMountUpdateCount += 1
	EndIf
EndEvent

Event OnMFXPOutfitUpdated(String eventName, String strArg, Float numArg, Form sender)
	ApplyCurrentOutfit(GetPlayersLastRiddenHorse())
EndEvent

Event OnReset()
	Debug.Trace("vMFXRegistry: OnReset!")
EndEvent

Event OnUpdate()
	_PluginPingCount = 0
	_StartTime = GetCurrentRealTime()
	Debug.Trace("vMFXRegistry: Registering plugins at priority " + _iPriorityCheck + "...")
	SendModEvent("vMFX_MFXRegistryReady")
	Int WaitTimer = 0
	Int WaitMax = 60
	While (_PluginReadyCount <  _PluginPingCount || _PluginPingCount == 0) && WaitTimer < WaitMax
		;Debug.Trace("vMFXRegistry: " + _PluginReadyCount + "/" + _PluginPingCount + " plugins registered...")
		WaitMenuMode(1)
		WaitTimer += 1
	EndWhile
	If WaitTimer >= WaitMax
		Debug.Trace("vMFXRegistry: WARNING! Plugin registration timed out with only " + _PluginReadyCount + "/" + _PluginPingCount + " plugins registered!")
		Debug.Notification("MountFX timed out while registering one or more of your installed plugins. This could be due to a problem with a plugin, or a plugin that adds a huge number of effects.")
	EndIf
	Debug.Trace("vMFXRegistry: " + _PluginReadyCount + "/" + _PluginPingCount + " plugins registered in " + (GetCurrentRealTime() - _StartTime) + "s.")
	SendModEvent("vMFX_MFXUpdateMCM")

EndEvent

Function PrintDemoData()
	regGetPluginsForRace(Racefilter)
	Int i = 0
	Int iBipedSlot
	While i < 512 
		iBipedSlot = ArrayGetIntAtXT("slot",i)
		If iBipedSlot >= 0
			vMFX_FXPluginBase[] MFXPlugins = regGetPluginsForSlot(iBipedSlot)
			Race[] Races = regGetRacesForSlot(iBipedSlot)
			Int j = 0
			While j <  MFXPlugins.Length
				If MFXPlugins[j]
					;Debug.Trace("MFXRegistry: Slot " + iBipedSlot + " is provided for race " + Races[0].GetName() + " by plugin " + MFXPlugins[j].infoPluginName )
				Else
					j = 127
				EndIf
				j += 1
			EndWhile
		Else
			i = 511
		EndIf
		i += 1
	EndWhile

	vMFX_FXPluginBase MFXPlugin
	i = 0
	While i < 512 
		MFXPlugin = ArrayGetFormAtXT("plugin",i) as vMFX_FXPluginBase
		If MFXPlugin != None
			regShowPluginTree(MFXPlugin)
		Else
			i = 511
		EndIf
		i += 1
	EndWhile

	Armor MFXArmor
	i = 0
	While i < 512 
		MFXArmor = ArrayGetFormAtXT("armor",i) as Armor
		If MFXArmor != None
			;Debug.Trace("MFXRegistry: Armor " + MFXArmor.GetName() + " is provided by " + regGetPluginForArmor(MFXArmor).infoPluginName)
		Else
			i = 511
		EndIf
		i += 1
	EndWhile
	
	iBipedSlot = 30
	Int SlotID
	While iBipedSlot < 64
		SlotID = ArrayFindIntXT("slot",iBipedSlot)
		If SlotID > -1
			vMFX_FXPluginBase[] MFXPlugins = regGetPluginsForSlot(iBipedSlot)
			Race[] Races = regGetRacesForSlot(iBipedSlot)
			Int j = 0
			While j <  MFXPlugins.Length
				If MFXPlugins[j]
					;Debug.Trace("MFXRegistry: Slot " + iBipedSlot + " is provided for race " + Races[0].GetName() + " by plugin " + MFXPlugins[j].infoPluginName )
				Else
					j = 127
				EndIf
				j += 1
			EndWhile
		EndIf
		iBipedSlot += 1
	EndWhile
	
	iBipedSlot = 30
	While iBipedSlot < 64
		SlotID = ArrayFindIntXT("slot",iBipedSlot)
		If SlotID > -1
			Armor[] Armors = regGetArmorsForSlot(iBipedSlot)
			Int j = 0
			While j <  Armors.Length
				If Armors[j]
					;Debug.Trace("MFXRegistry: Slot " + iBipedSlot + " has armor " + Armors[j].GetName())
				Else
					j = 127
				EndIf
				j += 1
			EndWhile
		EndIf
		iBipedSlot += 1
	EndWhile
EndFunction

;--=== Functions ===--

Function Initialize(Bool bFirstTime = False)
	GotoState("Busy")

	Debug.Trace("vMFXRegistry: Initializing!")
	
	If bFirstTime
		ResetRegistry()
	EndIf
	
	GotoState("")
	RegisterForSingleUpdate(10.1)
	Debug.Trace("vMFXRegistry: Initialization complete!")
EndFunction

Function ResetRegistry()
	Debug.Trace("vMFXRegistry:  Resetting registry...")
	vMFX_reg.Revert()
	vMFX_regArmors.Revert()
	vMFX_regRaces.Revert()
	vMFX_regFXPlugins.Revert()
	vMFX_regSlots.Revert()
	vMFX_regSpells.Revert()
	vMFX_regSortArmorsByRace.Revert()
	vMFX_regSortPluginsByRace.Revert()
	vMFX_regSortArmorsBySlot.Revert()
	vMFX_regSortPluginsBySlot.Revert()
	
	Int i
	While i < vMFX_Reg_Slots.Length
		If vMFX_reg_Slots[i]
			vMFX_reg_Slots[i].Revert()
		EndIf
		i += 1
	EndWhile
	
	_ArmorIndex = New Armor[128]
	_RaceIndex = New Race[128]
	;_PluginFormIndex = New _FXPluginForms[128]
	_PluginNameIndex = New String[128]
	;_PluginFormIDIndex = New Int[128]
	
	_SlotPluginIndex = New Int[128]
	InitArray(_SlotPluginIndex)
	_SlotRaceIndex = New Int[128]
	InitArray(_SlotRaceIndex)
	_SlotArmorSlotIndex = New Int[128]
	InitArray(_SlotArmorSlotIndex)
	_SlotArmorSlotNameIndex = New String[128]

	_regPluginByRaceIndex = New FormList[128]
	_regPluginBySlotIndex = New FormList[128]
	_regArmorBySlotIndex = New FormList[128]
	_regArmorByRaceIndex = New FormList[128]

	_FXPluginForms = New vMFX_FXPluginBase[128]
	_FXPluginSlots = New Int[128]
	
	_OutfitCurrent = New Form[128]
	_OutfitPrevious = New Form[128]

	SlotNames = New String[128]
	
	InitRegistryArrays()
	
	Debug.Trace("vMFXRegistry:  Reset complete!")
EndFunction

Function SetRaceFilter(Race akFilterRace)
	Float StartTime = GetCurrentRealTime()
	vMFX_regSortPluginsByRace.Revert()
	vMFX_regSortArmorsByRace.Revert()
	vMFX_FXPluginBase MFXPlugin
	Debug.Trace("vMFXRegistry: Setting race filter to " + akFilterRace.GetName())
	Int i = vMFX_regFXPlugins.GetSize() - 1
	Int j = 0
	Int h = 0
	Int r = 0
	While i >= 0
		MFXPlugin = vMFX_regFXPlugins.GetAt(i) as vMFX_FXPluginBase
		If MFXPlugin.dataRaces.Find(akFilterRace) >= 0
			vMFX_regSortPluginsByRace.AddForm(MFXPlugin)
			j = MFXPlugin.dataFormlists.Length - 1
			While j >= 0
				Formlist MFXPluginFormList = MFXPlugin.dataFormlists[j]
				If MFXPluginFormList != None
					h = 0
					While h < MFXPluginFormList.GetSize()
						If MFXPluginFormList.GetAt(h) as Armor
							vMFX_regSortArmorsByRace.AddForm(MFXPluginFormList.GetAt(h) as Armor)
						EndIf
						h += 1
					EndWhile
				EndIf
				j -= 1
			EndWhile
		EndIf
		i -= 1
	EndWhile
	Debug.Trace("vMFXRegistry: Race filter took " + (GetCurrentRealTime() - StartTime) + "s to process.")
	Debug.Trace("vMFXRegistry: " + vMFX_regSortPluginsByRace.GetSize() + "/" + vMFX_regFXPlugins.GetSize() + " plugins added to filtered list.")
	Debug.Trace("vMFXRegistry: " + vMFX_regSortArmorsByRace.GetSize() + "/" + vMFX_regArmors.GetSize() + " armors added to filtered list.")
EndFunction

Int Function RegisterPlugin(vMFX_FXPluginBase MFXPlugin)
	GoToState("Busy")
	String infoPluginName = MFXPlugin.infoPluginName
	String infoESPFile = MFXPlugin.infoESPFile
	_LockedBy = infoESPFile + " - '" + infoPluginName + "'"
	Debug.Trace("vMFXRegistry: Checking for plugin " + infoESPFile + "/" + infoPluginName)
	Int iResult = regAddPlugin(MFXPlugin)
	Debug.Trace("vMFXRegistry:  Plugin added at index " + iResult)

	Int iRace = 0
	While iRace < MFXPlugin.dataRaces.Length
		Race newRace = MFXPlugin.dataRaces[iRace]
		If newRace
			RegisterRace(MFXPlugin, newRace)
		EndIf
		iRace += 1
	EndWhile
	DataVersion += 1
	
	If MFXPlugin.dataAddsArmorSlots
		Int i = 0
		Debug.Trace("vMFXRegistry:  Registering " + MFXPlugin.dataArmorNewSlotNumbers.Length + " ArmorSlots from '" + infoPluginName + "'")
		While i < MFXPlugin.dataArmorNewSlotNumbers.Length
			If MFXPlugin.dataArmorNewSlotNames[i]
				iRace = 0
				While iRace < MFXPlugin.dataRaces.Length
					Bool SlotResult = RegisterArmorSlot(MFXPlugin, MFXPlugin.dataRaces[iRace], MFXPlugin.dataArmorNewSlotNumbers[i], MFXPlugin.dataArmorNewSlotNames[i])
					iRace += 1
				EndWhile
			EndIf
			i += 1
		EndWhile
	EndIf

	_LockedBy = ""
	GotoState("")

	iRace = 0
	int idFL = 0
	While iRace < MFXPlugin.dataRaces.Length
		While idFL < MFXPlugin.dataFormLists.Length
			Int Result = RegisterFXFormList(MFXPlugin, MFXPlugin.dataFormLists[iDFL], MFXPlugin.dataRaces[iRace])
			Debug.Trace("vMFXRegistry: " + MFXPlugin.infoPluginName + " registered " + Result + " forms for " + MFXPlugin.dataRaces[iRace].GetName() + "!")
			iDFL += 1
		EndWhile
		iRace += 1
	EndWhile

	If MaxPriority < MFXPlugin.infoPriority
		MaxPriority = MFXPlugin.infoPriority
	EndIf

	_LockedBy = ""
	GotoState("")
	Return iResult
EndFunction

Int Function RegisterRace(vMFX_FXPluginBase MFXPlugin, Race akRace)
	String RaceName = akRace.GetName()
	Int iResult = regAddRace(akRace)
	If regGetPluginsForRace(akRace).Find(MFXPlugin) < 0
		regLinkPluginRace(MFXPlugin,akRace)
		DataVersion += 1
	EndIf
	;Debug.Trace("vMFXRegistry:  Race " + RaceName + " registered at index " + iResult)
	Return iResult
EndFunction

Int Function RegisterFXFormList(vMFX_FXPluginBase MFXPlugin, Formlist akFXList, Race akRace = None)
	;GotoState("Busy")
	
	_LockedBy = MFXPlugin.infoPluginName
	If !_LockedBy
		_LockedBy = "Unknown"
	EndIf
	Int iTotal = 0
	Int iIndex = 0
	While iIndex < akFXList.GetSize()
		If akFXList.GetAt(iIndex) As FormList != None
			;Debug.Trace("vMFXRegistry: Processing Formlist " + akFXList.GetAt(iIndex))
			iTotal += RegisterFXFormList(MFXPlugin, akFXList.GetAt(iIndex) as FormList, akRace)
			;ProcessFXFormList
		ElseIf akFXList.GetAt(iIndex) As Spell != None
			;Debug.Trace("vMFXRegistry: Processing Spell " + akFXList.GetAt(iIndex))
			iTotal += 1
			Int Result = RegisterSpell(MFXPlugin, akRace, akFXList.GetAt(iIndex) As Spell)
		ElseIf akFXList.GetAt(iIndex) As Armor != None
			;Debug.Trace("vMFXRegistry: Processing Armor " + akFXList.GetAt(iIndex))
			Int NumSlots = RegisterArmor(MFXPlugin,akRAce,akFXList.GetAt(iIndex) as Armor)
			;Bool Success = RegisterArmorSlot(sPluginName, akRace, (akFXList.GetAt(iIndex) As Armor).GetNthArmorAddon(0), String sSlotName, Bool bOverwrite = False)
			iTotal += 1
			;ProcessArmor
		Else ; If kReference.IsDisabled() 
			Debug.Trace("vMFXRegistry: Unknown form type encountered - " + akFXList.GetAt(iIndex))
		EndIf
		iIndex += 1
	EndWhile
	Return iTotal
	;GotoState("")
EndFunction

Int Function RegisterSpell(vMFX_FXPluginBase MFXPlugin, Race akRace, Spell akSpell)
	
	Return 0
EndFunction

Int Function RegisterArmor(vMFX_FXPluginBase MFXPlugin, Race akRace, Armor akArmor)
	
	Int NumFailures = 0
	Int NumAddons = akArmor.GetNumArmorAddons()
	Int i = 0
	Int iBipedSlot = 0
	Int iSlotCount = 0
	FormList FXArmorSlot
	ArmorAddon FXArmorAA
	Int iFXArmorAASlotMask
	Int[] iArmorSlots = New Int[128]
	While i < NumAddons
		FXArmorAA = akArmor.GetNthArmorAddon(i)
		iFXArmorAASlotMask = FXArmorAA.GetSlotMask()
		;Debug.Trace("vMFXRegistry: Armor " + akArmor.GetName() + "/" + i + " has mask " + iFXArmorAASlotMask)
		int h = 0x00000001
		while (h < 0x80000000)
			if Math.LogicalAND(iFXArmorAASlotMask, h)
				;Debug.Trace("vMFXRegistry: Checking ArmorSlot " + h + " from " + MFXPlugin.infoESPFile + "/" + MFXPlugin.infoPluginName + "/" + akArmor.GetName())
				Bool bResult = CheckArmorSlot(MFXPlugin,akRace,h)
				iBipedSlot = GetBipedFromSlotMask(h)
				If bResult && MFXPlugin.dataArmorNewSlotNumbers.Find(iBipedSlot) >= 0
					;;Debug.Trace("MFXRegistry: Added " + iBipedSlot + ",iSlotCount is " + iSlotCount)
					iArmorSlots[iSlotCount] = iBipedSlot
					iSlotCount += 1
				ElseIf bResult && MFXPlugin.dataArmorSlotsUsed.Find(iBipedSlot) >= 0
					;Mod lists this slot as being used, just not registered to it.
				Else
					Debug.Trace("vMFXRegistry: " + MFXPlugin.infoESPFile + "/" + MFXPlugin.infoPluginName + "/" + akArmor.GetName() + ". Slot " + iBipedSlot + " is not registered or listed by plugin.")
					NumFailures += 1
				EndIf
			endIf
			h = Math.LeftShift(h,1)
		endWhile
		i += 1
	EndWhile
	
	If NumFailures
		Debug.Trace("vMFXRegistry: WARNING! Armor " + MFXPlugin.infoESPFile + "/" + MFXPlugin.infoPluginName + "/" + akArmor.GetName() + " rejected due to " + NumFailures + " unregistered slot(s)!")
		Return 0
	EndIf

	Int ArmorID = regAddArmor(akArmor)
	regLinkPluginArmor(MFXPlugin,akArmor)
	regLinkArmorRace(akArmor,akRace)
	
	i = 0
	While i < iSlotCount
		regLinkArmorSlot(akArmor,iArmorSlots[i])
		i += 1
	EndWhile
	If MFXPlugin.dataRequiredArmorList != None
		vMFX_regArmorsWithReqs.AddForm(akArmor)
	EndIf
	DataVersion += 1
	Return iSlotCount
EndFunction

Bool Function CheckArmorSlot(vMFX_FXPluginBase MFXPlugin, Race akRace, Int iArmorSlot)
;	Debug.Trace("vMFXRegistry: CheckArmorSlot(" + MFXPlugin + ", " + akRace + ", " + iArmorSlot + ")")
	Bool bFail = False
	String bFailReason = ""

	Int iBipedSlot = GetBipedFromSlotMask(iArmorSlot)
	
	Int PluginID = regAddPlugin(MFXPlugin)
	Int RaceID = regAddRace(akRace)
	
	If PluginID < 0
		bFail = True
		bFailReason = "Bad PluginID: " + PluginID
	ElseIf RaceID < 0
		bFail = True
		bFailReason = "Bad RaceID: " + RaceID
	EndIf
	
	vMFX_FXPluginBase[] PluginsForSlot = regGetPluginsForSlot(iBipedSlot)
	
	If PluginsForSlot.Find(MFXPlugin) >= 0
		Int iSlotNameIndex = MFXPlugin.dataArmorNewSlotNumbers.Find(iBipedSlot)
		;Debug.Trace("vMFXRegistry: " + MFXPlugin.infoPluginName + " registered slot " + iBipedSlot + " as " + MFXPlugin.dataArmorNewSlotNames[iSlotNameIndex])
	ElseIf MFXPlugin.dataArmorSlotsUsed.Find(iBipedSlot) > 0 
		; Plugin didn't register the slot but is aware of its use
		;Debug.Trace("vMFXRegistry: " + MFXPlugin.infoPluginName + " is using slot " + iBipedSlot + " without registering it.")
	Else 
		; plugin hasn't registered for this slot and doesn't think it's using it.
		bFail = True
		bFailReason = MFXPlugin.infoPluginName + " does not know it's using slot " + iBipedSlot + "!!"
	EndIf
	
	If bFail
		;GotoState("")
		Debug.Trace("vMFXRegistry: ArmorSlot check FAILED - " + bFailReason)
		Return False
	EndIf
	;GotoState("")
	Return True

EndFunction

vMFX_FXPluginBase[] Function GetPluginsForSlot(int iBipedSlot)
	Int i
	Int iFR
	Int iResultIndex
	vMFX_FXPluginBase MFXPlugin
	vMFX_FXPluginBase[] Result
	Result = New vMFX_FXPluginBase[128]
	While i < vMFX_regFXPlugins.GetSize()
		iFR = vMFX_reg_Slots[iBipedSlot].Find(vMFX_regFXPlugins.GetAt(i))
		If iFR >= 0
			Result[iResultIndex] = vMFX_reg_Slots[iBipedSlot].GetAt(iFR) as vMFX_FXPluginBase
			iResultIndex += 1
		EndIf
		i += 1
	EndWhile
	Return Result
EndFunction

FormList Function GetArmorsForRaceSlot(Race akRace, Int iBipedSlot)
	Formlist ResultList
EndFunction

Bool Function RegisterArmorSlot(vMFX_FXPluginBase MFXPlugin, Race akRace, Int iBipedSlot, String sSlotName, Bool bOverwrite = False)
	;Debug.Trace("vMFXRegistry: RegisterArmorSlot(" + MFXPlugin + ", " + akRace + ", " + iArmorSlot + ", " + sSlotName + ")")
	
	Bool bFail = False
	String bFailReason = ""
	
	Int PluginID = regAddPlugin(MFXPlugin)
	Int RaceID = regAddRace(akRace)
	
	If PluginID < 0
		bFail = True
		bFailReason = "Bad PluginID: " + PluginID
	ElseIf RaceID < 0
		bFail = True
		bFailReason = "Bad RaceID: " + RaceID
	EndIf
	
	Int SlotID = -1
	If !bFail
		SlotID = regAddSlot(iBipedSlot)
		If SlotID < 0
			bFail = True
			bFailReason = "Returned SlotID was invalid: " + SlotID
		EndIf
	EndIf
	
	If !bFail
		If SlotNames[iBipedSlot] == ""
			SlotNames[iBipedSlot] = sSlotName
		ElseIf StringUtil.Find(SlotNames[iBipedSlot],sSlotName) < 0
			SlotNames[iBipedSlot] = SlotNames[iBipedSlot] + "/" + sSlotName
		EndIf
		regLinkPluginSlot(MFXPlugin,iBipedSlot)
		regLinkRaceSlot(akRace,iBipedSlot)
		Debug.Trace("vMFXRegistry: Registered ArmorSlot " + sSlotName + "(" + iBipedSlot + ") with SlotID " + SlotID)
		DataVersion += 1
		vMFX_FXPluginBase[] PluginsForSlot = regGetPluginsForSlot(iBipedSlot)
		If PluginsForSlot.Find(None) > 1 ; at least 2 entries for this slot
			Int i 
			Int iFR
			While i < PluginsForSlot.Length && PluginsForSlot[i] != None
				iFR = PluginsForSlot[i].dataArmorNewSlotNumbers.Find(iBipedSlot)
				If PluginsForSlot[i] != MFXPlugin
					Debug.Trace("vMFXRegistry: ArmorSlot " + iBipedSlot + " is also used by " + PluginsForSlot[i].infoESPFile + "/'" + PluginsForSlot[i].infoPluginName + "' as " + PluginsForSlot[i].dataArmorNewSlotNames[iFR])
				EndIf
				i += 1
			EndWhile
		EndIf
	EndIf
		
	If bFail
		;GotoState("")
		Debug.Trace("vMFXRegistry: ArmorSlot registration failed - " + bFailReason)
		Return False
	EndIf

	Return True
EndFunction

Function SpinLock(String sFunctionName,String sRequestorName)
	Float StartTime = GetCurrentRealTime()
	Debug.Trace("vMFXRegistry: " + sFunctionName + " called by " + sRequestorName + " but is locked by " + _LockedBy + ". Waiting...")
	Int Timer = 0
	While GetState() == "Busy" && Timer < 100
		WaitMenuMode(0.1)
		;If Timer % 10 == 0
			;Debug.Trace("vMFXRegistry: " + sFunctionName + " still locked after " + (Timer / 10) + "s. Waiting...")
		;EndIf
		Timer += 1
	EndWhile
	Debug.Trace("vMFXRegistry: " + sFunctionName + " unlocked after " + (GetCurrentRealTime() - StartTime) + "s. Processing request from " + sRequestorName)
EndFunction

String Function GetSlotNameForRace(Race akRace, int iArmorSlot)
	Debug.Trace("vMFXRegistry: GetSlotNameForRace(" + akRace + "," + iArmorSlot + ")")
	Int i = 0
	Int iRace = _RaceIndex.Find(akRace)
	Debug.Trace("vMFXRegistry:  iRace: " + iRace)
	While i >= 0 && i < _SlotRaceIndex.Length
		i = _SlotRaceIndex.Find(iRace,i)
		Debug.Trace("vMFXRegistry:   Race search returned i: " + i)
		If i >= 0 && _SlotArmorSlotIndex[i] == iArmorSlot
			Debug.Trace("vMFXRegistry:   ArmorSlot matched at i: " + i)
			Debug.Trace("vMFXRegistry:   _SlotArmorSlotNameIndex[i]: " + _SlotArmorSlotNameIndex[i])
			Return _SlotArmorSlotNameIndex[i]
		ElseIf i >= 0
			i += 1
		EndIf
	EndWhile
	Debug.Trace("vMFXRegistry:  Nothing found!")
	Return ""
EndFunction

String Function GetPluginForSlot(Race akRace, int iArmorSlot)
	Debug.Trace("vMFXRegistry: GetPluginForSlot(" + akRace + "," + iArmorSlot + ")")
	Int i = 0
	Int iRace = _RaceIndex.Find(akRace)
	Debug.Trace("vMFXRegistry:  iRace: " + iRace)
	While i >= 0 && i < _SlotRaceIndex.Length
		i = _SlotRaceIndex.Find(iRace,i)
		Debug.Trace("vMFXRegistry:   Race search returned i: " + i)
		If i >= 0 && _SlotArmorSlotIndex[i] == iArmorSlot
			Debug.Trace("vMFXRegistry:   ArmorSlot matched at i: " + i)
			Debug.Trace("vMFXRegistry:   _SlotPluginIndex[i]: " + _SlotPluginIndex[i])
			Debug.Trace("vMFXRegistry:   _PluginNameIndex[_SlotPluginIndex[i]]: " + _PluginNameIndex[_SlotPluginIndex[i]])
			Return _PluginNameIndex[_SlotPluginIndex[i]]
		ElseIf i >= 0
			i += 1
		EndIf
	EndWhile
	Debug.Trace("vMFXRegistry:  Nothing found!")
	Return ""
EndFunction

vMFX_FXPluginBase Function GetPluginForArmor(Armor akArmor)
	Debug.Trace("vMFXRegistry: GetPluginForArmor(" + akArmor + ")")
	Int i = 0
	Int j = 0
	Int iFI
	vMFX_FXPluginBase MFXPlugin
	While i < vMFX_regFXPlugins.GetSize()
		MFXPlugin = vMFX_regFXPlugins.GetAt(i) as vMFX_FXPluginBase
		j = 0
		While j < MFXPlugin.dataFormlists.Length
			If MFXPlugin.dataFormlists[j].HasForm(akArmor)
				Debug.Trace("vMFXRegistry:  Returning " + MFXPlugin.infoPluginName)
				Return MFXPlugin
			EndIf
			j += 1
		EndWhile
		i += 1
	EndWhile
	Debug.Trace("vMFXRegistry:  Nothing found!")
	Return None
EndFunction

Int Function FindFreeIndexForm(Form[] aiArray)
	
EndFunction

Int Function FindFreeIndexString(String[] aiArray)
	Int i = 0
	While aiArray[i] != "" && i < aiArray.Length
		i += 1
	EndWhile
	If i < aiArray.Length
		Return i
	Else
		Return -1
	EndIf
EndFunction

Int Function FindFreeIndexInt(Int[] aiArray)
	Int i = 0
	While aiArray[i] != 0 && i < aiArray.Length
		i += 1
	EndWhile
	If i < aiArray.Length
		Return i
	Else
		Return -1
	EndIf
EndFunction

Int Function RegisterFakePlugin(String sFilename)
	Debug.Trace("vMFXRegistry: Getting index for Plugin " + sFilename)
	Int iResult = -1
	iResult = _PluginNameIndex.Find(sFilename)
	If iResult < 0
		Debug.Trace("vMFXRegistry: Plugin " + sFilename + " not yet registered, adding it to the index...")
		Int iNew = FindFreeIndexString(_PluginNameIndex)
		If iNew < 0
			Return iResult
		Else
			_PluginNameIndex[iNew] = sFileName
			iResult = iNew
			Debug.Trace("vMFXRegistry: Plugin added at index " + iResult)
		EndIf
	EndIf
	Return iResult
EndFunction

Function InitArray(Int[] aiArray)
	Int i = 0
	While i < aiArray.Length
		aiArray[i] = -1
		i += 1
	EndWhile
EndFunction

Int Function AddArmorToOutfit(Int iBipedSlot, Armor NewArmor)
	_OutfitCurrent[iBipedSlot] = NewArmor
	If iBipedSlot == 30
		vMFX_FXPluginBase OwningPlugin
		OwningPlugin = GetPluginForArmor(NewArmor)
		If OwningPlugin.dataChangesBody
			IncompatibleMesh = True
			DisabledSlots = OwningPlugin.dataUnsupportedSlot
			DisablingArmor = NewArmor
			DisablingPlugin = OwningPlugin
			Return DisabledSlots.Length
		Else
			IncompatibleMesh = False
			DisabledSlots = New Int[32]
			DisablingArmor = None
			DisablingPlugin = None
		EndIf
	EndIf
	Return 0
EndFunction

Form[] Function GetOutfit(Actor PlayerMount = None)
	If !CurrentMount
		CurrentMount = Game.GetPlayersLastRiddenHorse()
	EndIf
	If !PlayerMount
		PlayerMount = CurrentMount
	EndIf
	Return _OutfitCurrent
EndFunction

Function UpdateCurrentMount(Actor akMount)
	_PluginMountUpdateCount = 0
	CurrentMount = _CurrentMount
	CurrentMount.SendModEvent("vMFX_MFXSetCurrentMount")
	Int WaitTimer = 0
	Int WaitMax = 100
	While (_PluginMountUpdateCount <  _PluginReadyCount || _PluginMountUpdateCount == 0) && WaitTimer < WaitMax
		WaitMenuMode(0.1)
		WaitTimer += 1
	EndWhile
	If WaitTimer >= WaitMax
		Debug.Trace("vMFXRegistry: WARNING! Plugin CurrentMount update timed out with only " + _PluginMountUpdateCount + "/" + _PluginReadyCount + " plugins reporting!")
	EndIf
	;Debug.Trace("vMFXRegistry: " + _PluginMountUpdateCount + "/" + _PluginReadyCount + " !")
EndFunction

Function ApplyCurrentOutfit(Actor PlayerMount)
	Int i = 30
	Armor lastArmor = None
	Armor thisArmor = None
	_CurrentMount = Game.GetPlayersLastRiddenHorse()
	UpdateCurrentMount(_CurrentMount)
	;CurrentMount.SetAlpha(0.001,True)
	While i < _OutfitCurrent.Length
		lastArmor = _OutfitPrevious[i] as Armor
		thisArmor = _OutfitCurrent[i] as Armor
		If thisArmor != None || lastArmor != None
			Debug.Trace("vMFXRegistry: Slot " + i + " is " + thisArmor + ", was " + lastArmor)
		EndIf
		If thisArmor != None
			;Debug.Trace("vMFXRegistry: Slot " + i + " is " + thisArmor + ", was " + lastArmor)
			If !CurrentMount.IsEquipped(thisArmor)
				; Was not equipped, but is now
				;GetPluginForArmor(thisArmor).HandleEquip(thisArmor)
				thisArmor.SendModEvent("vMFX_MFXArmorEquip","",i)
			EndIf
		ElseIf lastArmor != None
			;Debug.Trace("vMFXRegistry: Slot " + i + " is None, was " + lastArmor)
			; Was equipped, now is not
			;GetPluginForArmor(thisArmor).RemovePluginArmor(i)
			lastArmor.SendModEvent("vMFX_MFXArmorUnequip","",i)
		Else
			;Was not equipped, is not equipped now
		EndIf
		i += 1
	EndWhile
	WaitMenuMode(1.0)
	VerifyOutfit()
EndFunction

Function VerifyOutfit()
	Int iBipedSlot = 30
	_PluginArmorCheckCount = 0
	Int SlotCount = 0
	Int[] SlotsForRace = regGetSlotsForRace(RaceFilter)
	While iBipedSlot < 62
		If SlotsForRace.Find(iBipedSlot) >= 0 ; Don't send an event unless this slot is registered
			If _OutfitCurrent[iBipedSlot]
				_OutfitCurrent[iBipedSlot].SendModEvent("vMFX_MFXArmorCheck","",iBipedSlot)
			Else
				SendModEvent("vMFX_MFXArmorCheck","",iBipedSlot)
			EndIf
			SlotCount += 1
		EndIf
		_OutfitPrevious[iBipedSlot] = _OutfitCurrent[iBipedslot]
		iBipedSlot += 1
	EndWhile
	Int WaitTimer = 0
	Int WaitMax = 100
	While (_PluginArmorCheckCount <  vMFX_regFXPlugins.GetSize() || _PluginArmorCheckCount == 0) && WaitTimer < WaitMax
		WaitMenuMode(0.1)
		WaitTimer += 1
	EndWhile
	If WaitTimer >= WaitMax
		Debug.Trace("vMFXRegistry: WARNING! Plugin equipment checks timed out with only " + _PluginArmorCheckCount + "/" + vMFX_regFXPlugins.GetSize() + " plugins checked!")
	EndIf
	Debug.Trace("vMFXRegistry: " + _PluginArmorCheckCount + "/" + SlotCount + " plugins checked!")
EndFunction

State Busy
	Int Function RegisterPlugin(vMFX_FXPluginBase MFXPlugin)
		SpinLock("RegisterPlugin",MFXPlugin.infoESPFile + " - " + MFXPlugin.infoPluginName)
		WaitMenuMode(MFXPlugin.infoPriority * 0.1)
		Return RegisterPlugin(MFXPlugin)
	EndFunction
EndState

; This is required because CK doesn't let you put hex into the property fields. Really guys?
Int Function GetSlotMaskFromBiped(Int intMask)
;	Debug.Trace("vMFXGetSlotMaskFromBiped: Converting " + intMask)
	If intMask == 30  ; HEAD 
		 Return 0x00000001 
	EndIf
	If intMask == 31  ; Hair 
		 Return 0x00000002 
	EndIf
	If intMask == 32  ; BODY 
		 Return 0x00000004 
	EndIf
	If intMask == 33  ; Hands 
		 Return 0x00000008 
	EndIf
	If intMask == 34  ; Forearms 
		 Return 0x00000010 
	EndIf
	If intMask == 35  ; Amulet 
		 Return 0x00000020 
	EndIf
	If intMask == 36  ; Ring 
		 Return 0x00000040 
	EndIf
	If intMask == 37  ; Feet 
		 Return 0x00000080 
	EndIf
	If intMask == 38  ; Calves 
		 Return 0x00000100 
	EndIf
	If intMask == 39  ; SHIELD 
		 Return 0x00000200 
	EndIf
	If intMask == 40  ; TAIL 
		 Return 0x00000400 
	EndIf
	If intMask == 41  ; LongHair 
		 Return 0x00000800 
	EndIf
	If intMask == 42  ; Circlet 
		 Return 0x00001000 
	EndIf
	If intMask == 43  ; Ears 
		 Return 0x00002000 
	EndIf
	If intMask == 44  ; Unnamed 
		 Return 0x00004000 
	EndIf
	If intMask == 45  ; Unnamed 
		 Return 0x00008000 
	EndIf
	If intMask == 46  ; Unnamed 
		 Return 0x00010000 
	EndIf
	If intMask == 47  ; Unnamed 
		 Return 0x00020000 
	EndIf
	If intMask == 48  ; Unnamed 
		 Return 0x00040000 
	EndIf
	If intMask == 49  ; Unnamed 
		 Return 0x00080000 
	EndIf
	If intMask == 50  ; DecapitateHead 
		 Return 0x00100000 
	EndIf
	If intMask == 51  ; Decapitate 
		 Return 0x00200000 
	EndIf
	If intMask == 52  ; Unnamed 
		 Return 0x00400000 
	EndIf
	If intMask == 53  ; Unnamed 
		 Return 0x00800000 
	EndIf
	If intMask == 54  ; Unnamed 
		 Return 0x01000000 
	EndIf
	If intMask == 55  ; Unnamed 
		 Return 0x02000000 
	EndIf
	If intMask == 56  ; Unnamed 
		 Return 0x04000000 
	EndIf
	If intMask == 57  ; Unnamed 
		 Return 0x08000000 
	EndIf
	If intMask == 58  ; Unnamed 
		 Return 0x10000000 
	EndIf
	If intMask == 59  ; Unnamed 
		 Return 0x20000000 
	EndIf
	If intMask == 60  ; Unnamed 
		 Return 0x40000000 
	EndIf
	If intMask == 61  ; FX01 
		 Return 0x80000000 
	EndIf
	Debug.Trace("vMFXGetSlotMaskFromBiped: Unknown mask number " + intMask)
	Return intMask
EndFunction

Int Function GetBipedFromSlotMask(Int intMask)
;	Debug.Trace("vMFXGetSlotMaskFromBiped: Converting " + intMask)
	If intMask == 0x00000001   ; HEAD 
		 Return 30
	EndIf
	If intMask == 0x00000002   ; Hair 
		 Return 31
	EndIf
	If intMask == 0x00000004   ; BODY 
		 Return 32
	EndIf
	If intMask == 0x00000008  ; Hands 
		 Return 33 
	EndIf
	If intMask == 0x00000010  ; Forearms 
		 Return 34 
	EndIf
	If intMask == 0x00000020  ; Amulet 
		 Return 35 
	EndIf
	If intMask == 0x00000040  ; Ring 
		 Return 36 
	EndIf
	If intMask == 0x00000080  ; Feet 
		 Return 37 
	EndIf
	If intMask == 0x00000100  ; Calves 
		 Return 38 
	EndIf
	If intMask == 0x00000200  ; SHIELD 
		 Return 39 
	EndIf
	If intMask == 0x00000400  ; TAIL 
		 Return 40 
	EndIf
	If intMask == 0x00000800  ; LongHair 
		 Return 41 
	EndIf
	If intMask == 0x00001000  ; Circlet 
		 Return 42 
	EndIf
	If intMask == 0x00002000  ; Ears 
		 Return 43 
	EndIf
	If intMask == 0x00004000  ; Unnamed 
		 Return 44 
	EndIf
	If intMask == 0x00008000  ; Unnamed 
		 Return 45 
	EndIf
	If intMask == 0x00010000  ; Unnamed 
		 Return 46 
	EndIf
	If intMask == 0x00020000  ; Unnamed 
		 Return 47 
	EndIf
	If intMask == 0x00040000  ; Unnamed 
		 Return 48 
	EndIf
	If intMask == 0x00080000  ; Unnamed 
		 Return 49 
	EndIf
	If intMask == 0x00100000  ; DecapitateHead 
		 Return 50 
	EndIf
	If intMask == 0x00200000  ; Decapitate 
		 Return 51 
	EndIf
	If intMask == 0x00400000  ; Unnamed 
		 Return 52 
	EndIf
	If intMask == 0x00800000  ; Unnamed 
		 Return 53 
	EndIf
	If intMask == 0x01000000  ; Unnamed 
		 Return 54 
	EndIf
	If intMask == 0x02000000  ; Unnamed 
		 Return 55 
	EndIf
	If intMask == 0x04000000  ; Unnamed 
		 Return 56 
	EndIf
	If intMask == 0x08000000  ; Unnamed 
		 Return 57 
	EndIf
	If intMask == 0x10000000  ; Unnamed 
		 Return 58 
	EndIf
	If intMask == 0x20000000  ; Unnamed 
		 Return 59 
	EndIf
	If intMask == 0x40000000  ; Unnamed 
		 Return 60 
	EndIf
	If intMask == 0x80000000  ; FX01 
		 Return 61 
	EndIf
	Debug.Trace("vMFXGetBipedFromSlotMask: Unknown slotmask " + intMask)
	Return intMask
EndFunction










Int Function regAddRace(Race NewRace)
	;Adds Race entry
	Int Result = ArrayFindFormXT("race",NewRace)
	If Result < 0
		If ArrayAddFormXT("race",NewRace)
			Result = ArrayFindFormXT("race",NewRace)
			;Debug.Trace("MFXRegistry: Added new race at index " + Result)
		EndIf
	EndIf
	
	Return Result
EndFunction

Int Function regAddPlugin(vMFX_FXPluginBase MFXPlugin)
	;Adds Plugin entry 
	Int Result = ArrayFindFormXT("plugin",MFXPlugin)
	If Result < 0
		If ArrayAddFormXT("plugin",MFXPlugin)
			Result = ArrayFindFormXT("plugin",MFXPlugin)
			;Debug.Trace("MFXRegistry: Added new plugin at index " + Result)
		EndIf
	EndIf
	
	Return Result
EndFunction

Int Function regAddArmor(Armor NewArmor)
	;Adds Armor entry 
	Int Result = ArrayFindFormXT("armor",NewArmor)
	If Result < 0
		If ArrayAddFormXT("armor",NewArmor)
			Result = ArrayFindFormXT("armor",NewArmor)
			;Debug.Trace("MFXRegistry: Added armor " + NewArmor.GetName() + " at ID " + Result)
		EndIf
	EndIf
	
	Return Result
EndFunction

Int Function regAddSlot(Int iBipedSlot)
	;Add Slot entry
	Int Result = ArrayFindIntXT("slot",iBipedSlot)
	If Result < 0
		If ArrayAddIntXT("slot",iBipedSlot) > -1
			Result = ArrayFindIntXT("slot",iBipedSlot)
			;Debug.Trace("MFXRegistry: Added new slot at index " + Result)
		EndIf
	EndIf
	
	Return Result
EndFunction

Function regLinkPluginRace(vMFX_FXPluginBase MFXPlugin, Race NewRace)
	;Create a link between Plugin and Race
	Int RaceID = regAddRace(NewRace)
	Int PluginID = regAddPlugin(MFXPlugin)

	Int RaceIDCheck
	Int PluginIDCheck
	
	Int RaceIndex = -1
	Int PluginIndex = -1
	
	Int i = 0
	While i < 512
		RaceIDCheck = ArrayGetIntAtXT("LookupRace",i)
		If RaceIDCheck == RaceID
			If ArrayGetIntAtXT("LookupRacePlugin",i) == -1
				RaceIndex = i
			EndIf
		EndIf
		PluginIDCheck = ArrayGetIntAtXT("LookupPlugin",i)
		If PluginIDCheck == PluginID
			If ArrayGetIntAtXT("LookupPluginRace",i) == -1
				PluginIndex = i
			EndIf
		EndIf
		If RaceIDCheck == -1 && PluginIDCheck == -1
			i = 511
		EndIf
		i += 1
	EndWhile
	
	If RaceIndex == -1
		RaceIndex = ArrayAddIntXT("LookupRace",RaceID)
	EndIf
	If PluginIndex == -1
		PluginIndex = ArrayAddIntXT("LookupPlugin",PluginID)
	EndIf
	
	Bool Result1 = ArrayPutIntAtXT("LookupRacePlugin",RaceIndex,PluginID)
	Bool Result2 = ArrayPutIntAtXT("LookupPluginRace",PluginIndex,RaceID)
EndFunction

Function regLinkPluginArmor(vMFX_FXPluginBase MFXPlugin, Armor NewArmor)
	;Create a link between Plugin and Armor
	Int ArmorID = regAddArmor(NewArmor)
	Int PluginID = regAddPlugin(MFXPlugin)

	Int ArmorIDCheck
	Int PluginIDCheck
	
	Int ArmorIndex = -1
	Int PluginIndex = -1
	
	Int i = 0
	While i < 512
		ArmorIDCheck = ArrayGetIntAtXT("LookupArmor",i)
		If ArmorIDCheck == ArmorID
			If ArrayGetIntAtXT("LookupArmorPlugin",i) == -1
				ArmorIndex = i
			EndIf
		EndIf
		PluginIDCheck = ArrayGetIntAtXT("LookupPlugin",i)
		If PluginIDCheck == PluginID
			If ArrayGetIntAtXT("LookupPluginArmor",i) == -1
				PluginIndex = i
			EndIf
		EndIf
		If ArmorIDCheck == -1 && PluginIDCheck == -1
			i = 511
		EndIf
		i += 1
	EndWhile
	
	If ArmorIndex == -1
		ArmorIndex = ArrayAddIntXT("LookupArmor",ArmorID)
	EndIf
	If PluginIndex == -1
		PluginIndex = ArrayAddIntXT("LookupPlugin",PluginID)
	EndIf
	
	Bool Result1 = ArrayPutIntAtXT("LookupArmorPlugin",ArmorIndex,PluginID)
	Bool Result2 = ArrayPutIntAtXT("LookupPluginArmor",PluginIndex,ArmorID)
EndFunction

Function regLinkPluginSlot(vMFX_FXPluginBase MFXPlugin, Int iBipedSlot)
	;Create a link between Plugin and BipedSlot
	Int SlotID = regAddSlot(iBipedSlot)
	Int PluginID = regAddPlugin(MFXPlugin)

	Int PluginIDCheck
	Int SlotIDCheck
	
	Int PluginIndex = -1
	Int SlotIndex = -1
	
	Int i = 0
	While i < 512
		PluginIDCheck = ArrayGetIntAtXT("LookupPlugin",i)
		If PluginIDCheck == PluginID
			If ArrayGetIntAtXT("LookupPluginSlot",i) == -1
				PluginIndex = i
			EndIf
		EndIf
		SlotIDCheck = ArrayGetIntAtXT("LookupSlot",i)
		If SlotIDCheck == SlotID
			If ArrayGetIntAtXT("LookupSlotPlugin",i) == -1
				SlotIndex = i
			EndIf
		EndIf
		If PluginIDCheck == -1 && SlotIDCheck == -1
			i = 511
		EndIf
		i += 1
	EndWhile
	
	If PluginIndex == -1
		PluginIndex = ArrayAddIntXT("LookupPlugin",PluginID)
	EndIf
	If SlotIndex == -1
		SlotIndex = ArrayAddIntXT("LookupSlot",SlotID)
	EndIf
	Bool Result1 = ArrayPutIntAtXT("LookupSlotPlugin",SlotIndex,PluginID)
	Bool Result2 = ArrayPutIntAtXT("LookupPluginSlot",PluginIndex,SlotID)
	;;Debug.Trace("MFXRegistry: Result1: " + Result1)
	;;Debug.Trace("MFXRegistry: Result2: " + Result2)
	;Debug.Trace("MFXRegistry: Linked " + MFXPlugin.infoPluginName + " to " + iBipedSlot + "(" + SlotNames[iBipedSlot] + ")")
EndFunction

Function regLinkArmorSlot(Armor NewArmor, Int iBipedSlot)
	;Create a link between Armor and BipedSlot
	Int SlotID = regAddSlot(iBipedSlot)
	Int ArmorID = regAddArmor(NewArmor)
	
	Int ArmorIDCheck
	Int SlotIDCheck
	
	Int ArmorIndex = -1
	Int SlotIndex = -1
	
	Int i = 0
	While i < 512
		ArmorIDCheck = ArrayGetIntAtXT("LookupArmor",i)
		If ArmorIDCheck == ArmorID
			If ArrayGetIntAtXT("LookupArmorSlot",i) == -1
				ArmorIndex = i
			EndIf
		EndIf
		SlotIDCheck = ArrayGetIntAtXT("LookupSlot",i)
		If SlotIDCheck == SlotID
			If ArrayGetIntAtXT("LookupSlotArmor",i) == -1
				SlotIndex = i
			EndIf
		EndIf
		If ArmorIDCheck == -1 && SlotIDCheck == -1
			i = 511
		EndIf
		i += 1
	EndWhile
	
	If ArmorIndex == -1
		ArmorIndex = ArrayAddIntXT("LookupArmor",ArmorID)
	EndIf
	If SlotIndex == -1
		SlotIndex = ArrayAddIntXT("LookupSlot",SlotID)
	EndIf
	
	;;Debug.Trace("MFXRegistry:   SlotIndex created at " + SlotIndex)
	;;Debug.Trace("MFXRegistry:  ArmorIndex created at " + ArmorIndex)
	
	Bool Result1 = ArrayPutIntAtXT("LookupSlotArmor",SlotIndex,ArmorID)
	Bool Result2 = ArrayPutIntAtXT("LookupArmorSlot",ArmorIndex,SlotID)
	;Debug.Trace("MFXRegistry: Linked " + NewArmor.GetName() + " to " + iBipedSlot + "(" + SlotNames[iBipedSlot] + ")")
EndFunction

Function regLinkArmorRace(Armor NewArmor, Race NewRace)
	;Create a link between Armor and Race
	Int RaceID = regAddRace(NewRace)
	Int ArmorID = regAddArmor(NewArmor)
	
	Int ArmorIDCheck
	Int RaceIDCheck
	
	Int ArmorIndex = -1
	Int RaceIndex = -1
	
	Int i = 0
	While i < 512
		ArmorIDCheck = ArrayGetIntAtXT("LookupArmor",i)
		If ArmorIDCheck == ArmorID
			If ArrayGetIntAtXT("LookupArmorRace",i) == -1
				ArmorIndex = i
			EndIf
		EndIf
		RaceIDCheck = ArrayGetIntAtXT("LookupRace",i)
		If RaceIDCheck == RaceID
			If ArrayGetIntAtXT("LookupRaceArmor",i) == -1
				RaceIndex = i
			EndIf
		EndIf
		If ArmorIDCheck == -1 && RaceIDCheck == -1
			i = 511
		EndIf
		i += 1
	EndWhile
	
	If ArmorIndex == -1
		ArmorIndex = ArrayAddIntXT("LookupArmor",ArmorID)
	EndIf
	If RaceIndex == -1
		RaceIndex = ArrayAddIntXT("LookupRace",RaceID)
	EndIf
		
	Bool Result1 = ArrayPutIntAtXT("LookupRaceArmor",RaceIndex,ArmorID)
	Bool Result2 = ArrayPutIntAtXT("LookupArmorRace",ArmorIndex,RaceID)
	;Debug.Trace("MFXRegistry: Linked " + NewArmor.GetName() + " to " + NewRace.GetName())
EndFunction

Function regLinkRaceSlot(Race NewRace,Int iBipedSlot)
	;Create a link between Race and BipedSlot
	Int RaceID = regAddRace(NewRace)
	Int SlotID = regAddSlot(iBipedSlot)
	
	Int RaceIDCheck
	Int SlotIDCheck
	
	Int RaceIndex = -1
	Int SlotIndex = -1
	
	Int i = 0
	While i < 512
		RaceIDCheck = ArrayGetIntAtXT("LookupRace",i)
		If RaceIDCheck == RaceID
			If ArrayGetIntAtXT("LookupRaceSlot",i) == -1
				RaceIndex = i
			EndIf
		EndIf
		SlotIDCheck = ArrayGetIntAtXT("LookupSlot",i)
		If SlotIDCheck == SlotID
			If ArrayGetIntAtXT("LookupSlotRace",i) == -1
				SlotIndex = i
			EndIf
		EndIf
		If RaceIDCheck == -1 && SlotIDCheck == -1
			i = 511
		EndIf
		i += 1
	EndWhile
	
	If RaceIndex == -1
		RaceIndex = ArrayAddIntXT("LookupRace",RaceID)
	EndIf
	If SlotIndex == -1
		SlotIndex = ArrayAddIntXT("LookupSlot",SlotID)
	EndIf
		
	Bool Result1 = ArrayPutIntAtXT("LookupRaceSlot",RaceIndex,SlotID)
	Bool Result2 = ArrayPutIntAtXT("LookupSlotRace",SlotIndex,RaceID)
	;Debug.Trace("MFXRegistry: Linked " + NewRace.GetName() + " to " + iBipedSlot + "(" + SlotNames[iBipedSlot] + ")")
EndFunction

Race[] Function regGetRacesForSlot(Int iBipedSlot)
	;;Debug.Trace("MFXRegistry: Getting races for slot " + iBipedSlot)
	Race[] Races = New Race[128]
	Race akRace 
	Int RaceIndex = -1
	Int RaceID = -1
	Int i = 0
	Int iCount = 0
	Int SlotID = ArrayFindIntXT("slot",iBipedSlot)
	;;Debug.Trace("MFXRegistry:  SlotID is " + SlotID)
	;Int ExpectedCount = ArrayCountIntXT("LookupRaceSlot",SlotID)
	;;Debug.Trace("MFXRegistry:  Expecting " + ExpectedCount + " races...")
	i = ArrayFindIntXT("LookupRaceSlot",SlotID)
	While i < 512
		RaceIndex = ArrayGetIntAtXT("LookupRaceSlot",i)
		If RaceIndex == SlotID
			RaceID = ArrayGetIntAtXT("LookupRace",i)
			If RaceID > -1
				akRace = None
				akRace = ArrayGetFormAtXT("race",RaceID) as Race
				If Races.Find(akRace) < 0
					Races[iCount] = akRace
					iCount += 1
					;;Debug.Trace("MFXRegistry:  Found " + Races[iCount - 1].GetName())
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return Races
EndFunction

vMFX_FXPluginBase[] Function regGetPluginsForSlot(Int iBipedSlot)
	;;Debug.Trace("MFXRegistry: Getting plugins for slot " + iBipedSlot)
	vMFX_FXPluginBase[] MFXPlugins = New vMFX_FXPluginBase[128]
	Int i = 0
	Int iCount = 0
	Int SlotID = ArrayFindIntXT("slot",iBipedSlot)
	;;Debug.Trace("MFXRegistry:  SlotID is " + SlotID)
	;Int ExpectedCount = ArrayCountIntXT("LookupPluginSlot",SlotID)
	;;Debug.Trace("MFXRegistry:  Expecting " + ExpectedCount + " plugins...")
	While i < 128
		
		If _regLookupPluginSlot1[i] == SlotID
			If _regLookupPlugin1[i] > -1
				If MFXPlugins.Find(_regPlugins1[_regLookupPlugin1[i]] as vMFX_FXPluginBase) < 0
					MFXPlugins[iCount] = _regPlugins1[_regLookupPlugin1[i]] as vMFX_FXPluginBase
					iCount += 1
					;;Debug.Trace("MFXRegistry:  Found " + MFXPlugins[iCount - 1].infoPluginName)
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return MFXPlugins
EndFunction

vMFX_FXPluginBase[] Function regGetPluginsForRace(Race akRace)
	;;Debug.Trace("MFXRegistry: Getting plugins for race " + akRace.GetName())
	vMFX_FXPluginBase[] MFXPlugins = New vMFX_FXPluginBase[128]
	Int i = 0
	Int iCount = 0
	Int RaceID = ArrayFindFormXT("race",akRace)
	;;Debug.Trace("MFXRegistry:  RaceID is " + RaceID)
	Int ExpectedCount = ArrayCountIntXT("LookupPluginRace",RaceID)
	;;Debug.Trace("MFXRegistry:  Expecting " + ExpectedCount + " plugins...")
	While i < 128
		
		If _regLookupPluginRace1[i] == RaceID
			If _regLookupPlugin1[i] > -1
				If MFXPlugins.Find(_regPlugins1[_regLookupPlugin1[i]] as vMFX_FXPluginBase) < 0
					MFXPlugins[iCount] = _regPlugins1[_regLookupPlugin1[i]] as vMFX_FXPluginBase
					iCount += 1
					;;Debug.Trace("MFXRegistry:  Found " + MFXPlugins[iCount - 1].infoPluginName)
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return MFXPlugins
EndFunction

vMFX_FXPluginBase Function regGetPluginForArmor(Armor akArmor)
	;;Debug.Trace("MFXRegistry: Getting plugins for race " + akArmor.GetName())
	vMFX_FXPluginBase MFXPlugin
	Int i = 0
	Int iCount = 0
	Int ArmorID = ArrayFindFormXT("armor",akArmor)
	;;Debug.Trace("MFXRegistry:  ArmorID is " + ArmorID)
	Int ExpectedCount = ArrayCountIntXT("LookupPluginArmor",ArmorID)
	;;Debug.Trace("MFXRegistry:  Expecting " + ExpectedCount + " plugins...")
	While i < 128
		
		If _regLookupPluginArmor1[i] == ArmorID
			If _regLookupPlugin1[i] > -1
				MFXPlugin = _regPlugins1[_regLookupPlugin1[i]] as vMFX_FXPluginBase
				Return MFXPlugin
				;;Debug.Trace("MFXRegistry:  Found " + MFXPlugins[iCount - 1].infoPluginName)
			EndIf
		EndIf
		i += 1
	EndWhile
EndFunction

Race[] Function regGetRacesForPlugin(vMFX_FXPluginBase MFXPlugin)
	;;Debug.Trace("MFXRegistry: Getting races for plugin " + MFXPlugin.infoPluginName)
	Race[] Races = New Race[128]
	Int i = 0
	Int iCount = 0
	Int PluginID = ArrayFindFormXT("plugin",MFXPlugin)
	;;Debug.Trace("MFXRegistry:  PluginID is " + PluginID)
	Int ExpectedCount = ArrayCountIntXT("LookupRacePlugin",PluginID)
	;;Debug.Trace("MFXRegistry:  Expecting " + ExpectedCount + " races...")
	While i < 128
		
		If _regLookupRacePlugin1[i] == PluginID
			If _regLookupRace1[i] > -1
				If Races.Find(_regRaces1[_regLookupRace1[i]] as Race) < 0
					Races[iCount] = _regRaces1[_regLookupRace1[i]] as Race
					iCount += 1
					;;Debug.Trace("MFXRegistry:  Found " + Races[iCount - 1].GetName())
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return Races
EndFunction

Armor[] Function regGetArmorsForPlugin(vMFX_FXPluginBase MFXPlugin)
	;;Debug.Trace("MFXRegistry: Getting Armors for plugin " + MFXPlugin.infoPluginName)
	Armor[] Armors = New Armor[128]
	Int i = 0
	Int iCount = 0
	Int PluginID = ArrayFindFormXT("plugin",MFXPlugin)
	Int ArmorIndex = -1
	Int ArmorID = -1
	Armor akArmor
	;;Debug.Trace("MFXRegistry:  PluginID is " + PluginID)
	;Int ExpectedCount = ArrayCountIntXT("LookupArmorPlugin",PluginID)
	;;Debug.Trace("MFXRegistry:  Expecting " + ExpectedCount + " Armors...")
	While i < 512
		ArmorIndex = ArrayGetIntAtXT("LookupArmorPlugin",i)
		If ArmorIndex == PluginID
			ArmorID = ArrayGetIntAtXT("LookupArmor",i)
			If ArmorID > -1
				akArmor = None
				akArmor = ArrayGetFormAtXT("armor",ArmorID) as Armor
				If Armors.Find(akArmor) < 0
					Armors[iCount] = akArmor
					iCount += 1
					;;Debug.Trace("MFXRegistry:  Found " + Armors[iCount - 1].GetName())
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile
	;;Debug.Trace("MFXRegistry: Returning " + iCount + " armors for " + MFXPlugin.infoPluginName)
	Return Armors
EndFunction

Armor[] Function regGetArmorsForRace(Race MFXRace)
	;;Debug.Trace("MFXRegistry: Getting Armors for Race " + MFXRace.infoRaceName)
	Armor[] Armors = New Armor[128]
	Int i = 0
	Int iCount = 0
	Int RaceID = ArrayFindFormXT("race",MFXRace)
	Int ArmorIndex = -1
	Int ArmorID = -1
	Armor akArmor
	;;Debug.Trace("MFXRegistry:  RaceID is " + RaceID)
	;Int ExpectedCount = ArrayCountIntXT("LookupArmorRace",RaceID)
	;;Debug.Trace("MFXRegistry:  Expecting " + ExpectedCount + " Armors...")
	While i < 512
		ArmorIndex = ArrayGetIntAtXT("LookupArmorRace",i)
		If ArmorIndex == RaceID
			ArmorID = ArrayGetIntAtXT("LookupArmor",i)
			If ArmorID > -1
				akArmor = None
				akArmor = ArrayGetFormAtXT("armor",ArmorID) as Armor
				If Armors.Find(akArmor) < 0
					Armors[iCount] = akArmor
					iCount += 1
					;;Debug.Trace("MFXRegistry:  Found " + Armors[iCount - 1].GetName())
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile
	;;Debug.Trace("MFXRegistry: Returning " + iCount + " armors for " + MFXRace.infoRaceName)
	Return Armors
EndFunction

Armor[] Function regGetArmorsForSlot(Int iBipedSlot)
	;;Debug.Trace("MFXRegistry: Getting Armors for slot " + iBipedSlot)
	Armor[] Armors = New Armor[128]
	Int i = 0
	Int iCount = 0
	Int SlotID = ArrayFindIntXT("slot",iBipedSlot)
	Int ArmorIndex = -1
	Int ArmorID = -1
	Armor akArmor
	;;Debug.Trace("MFXRegistry:  SlotID is " + SlotID)
	;Int ExpectedCount = ArrayCountIntXT("LookupArmorSlot",SlotID)
	;;Debug.Trace("MFXRegistry:  Expecting " + ExpectedCount + " Armors...")
	While i < 512
		ArmorIndex = ArrayGetIntAtXT("LookupArmorSlot",i)
		If ArmorIndex == SlotID
			ArmorID = ArrayGetIntAtXT("LookupArmor",i)
			If ArmorID > -1
				akArmor = None
				akArmor = ArrayGetFormAtXT("armor",ArmorID) as Armor
				If Armors.Find(akArmor) < 0
					Armors[iCount] = akArmor
					iCount += 1
					;;Debug.Trace("MFXRegistry:  Found " + Armors[iCount - 1].GetName())
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile
	;;Debug.Trace("MFXRegistry: Returning " + iCount + " armors for slot " + iBipedSlot)
	Return Armors
EndFunction

Int[] Function regGetSlotsForPlugin(vMFX_FXPluginBase MFXPlugin)
	;;Debug.Trace("MFXRegistry: Getting slots for plugin " + MFXPlugin.infoPluginName)
	Int[] Slots = New Int[128]
	Int i = 0
	Int iCount = 0
	Int PluginID = ArrayFindFormXT("plugin",MFXPlugin)
	;;Debug.Trace("MFXRegistry:  PluginID is " + PluginID)
	Int ExpectedCount = ArrayCountIntXT("LookupSlotPlugin",PluginID)
	;;Debug.Trace("MFXRegistry:  Expecting " + ExpectedCount + " Slots...")
	While i < 128
		
		If _regLookupSlotPlugin1[i] == PluginID
			If _regLookupSlot1[i] > -1
				If Slots.Find(_regSlots1[_regLookupSlot1[i]]) < 0
					Slots[iCount] = _regSlots1[_regLookupSlot1[i]]
					iCount += 1
					;;Debug.Trace("MFXRegistry:  Found " + Slots[iCount - 1])
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return Slots
EndFunction

Int[] Function regGetSlotsForRace(Race akRace)
	;;Debug.Trace("MFXRegistry: Getting slots for Race " + akRace.GetName())
	Int[] Slots = New Int[128]
	Int i = 0
	Int iCount = 0
	Int RaceID = ArrayFindFormXT("Race",akRace)
	;;Debug.Trace("MFXRegistry:  RaceID is " + RaceID)
	Int ExpectedCount = ArrayCountIntXT("LookupSlotRace",RaceID)
	;;Debug.Trace("MFXRegistry:  Expecting " + ExpectedCount + " Slots...")
	While i < 128
		
		If _regLookupSlotRace1[i] == RaceID
			If _regLookupSlot1[i] > -1
				If Slots.Find(_regSlots1[_regLookupSlot1[i]]) < 0
					Slots[iCount] = _regSlots1[_regLookupSlot1[i]]
					iCount += 1
					;;Debug.Trace("MFXRegistry:  Found " + Slots[iCount - 1])
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return Slots
EndFunction

Function regShowPluginTree(vMFX_FXPluginBase MFXPlugin)
	Int i = 0
	Int j = 0
	Int k = 0
	Int iCount = 0
	Int PluginID = ArrayFindFormXT("plugin",MFXPlugin)
	Debug.Trace("MFXRegistry: PluginID is " + PluginID)
	Debug.Trace("MFXRegistry: ------ START " + MFXPlugin.infoPluginName + " TREE ------")
	Debug.Trace("MFXRegistry:  " + MFXPlugin.infoPluginName)
	Race[] Races = regGetRacesForPlugin(MFXPlugin)
	Int[] Slots = regGetSlotsforPlugin(MFXPlugin)
	Armor[] Armors = regGetArmorsForPlugin(MFXPlugin)
	
	i = 0
	While i < 128
		If i == 0
			Debug.Trace("MFXRegistry:  |--RACES")
		EndIf
		If Races[i]
			Debug.Trace("MFXRegistry:  |  |--" + Races[i].GetName())
			Int[] SlotsForRace = regGetSlotsForRace(Races[i])
			j = 0
			Debug.Trace("MFXRegistry:  |  |  |--SLOTS")
			While j < 128
				If SlotsForRace[j] > 0 && Slots.Find(SlotsForRace[j]) >= 0
					Debug.Trace("MFXRegistry:  |  |  |  |--" + SlotsForRace[j] + "(" + SlotNames[SlotsForRace[j]] + ")")
					Armor[] ArmorsForSlot = regGetArmorsForSlot(SlotsForRace[j])
					k = 0
					Debug.Trace("MFXRegistry:  |  |  |  |  |--ARMORS")
					While k < 128
						If ArmorsForSlot[k] && Armors.Find(ArmorsForSlot[k]) >= 0
							Debug.Trace("MFXRegistry:  |  |  |  |     |--" + ArmorsForSlot[k].GetName())
						EndIf
						k += 1
					EndWhile
				EndIf
				j += 1
			EndWhile
		EndIf
		i += 1
	EndWhile
	Debug.Trace("MFXRegistry:  ")
	Debug.Trace("MFXRegistry: ------ FINIS " + MFXPlugin.infoPluginName + " TREE ------")
EndFunction


;--=== Chesko's extended array functions ===--
;Thanks Chesko!

;Armor[]					_regArmors
;vMFX_FXPluginBase[]		_regPlugins
;Race[]					_regRaces
;Int[]					_regSlots
;Int[]		_regLookupSlotRace
;Int[]		_regLookupRaceSlot
;Int[]		_regLookupPluginRace
;Int[]		_regLookupRacePlugin
;Int[]		_regLookupPluginSlot
;Int[]		_regLookupSlotPlugin
;Int[]		_regLookupArmorSlot
;Int[]		_regLookupSlotArmor

Form function ArrayGetFormAtXT(string ArrayID, Int Index)
	if ArrayID == "plugin"
		Form DoGetForm = ArrayGetFormXT_doForm(_regPlugins1, _regPlugins2, _regPlugins3, _regPlugins4, Index)
		return DoGetForm
	elseif ArrayID == "armor"
		Form DoGetForm = ArrayGetFormXT_doForm(_regArmors1, _regArmors2, _regArmors3, _regArmors4, Index)
		return DoGetForm
	elseif ArrayID == "race"
		Form DoGetForm = ArrayGetFormXT_doForm(_regRaces1, _regRaces2, _regRaces3, _regRaces4, Index)
		return DoGetForm
	else
		return None
	endif
	
	Return None
EndFunction

Form function ArrayGetFormXT_doForm(Form[] fArray1, Form[] fArray2, Form[] fArray3, Form[] fArray4, Int Index)
	Form ReturnForm 

	If Index < 128
		ReturnForm = fArray1[Index]
	ElseIf Index < 256
		ReturnForm = fArray2[Index - 128]
	ElseIf Index < 384
		ReturnForm = fArray3[Index - 256]
	ElseIf Index < 512
		ReturnForm = fArray4[Index - 384]
	Else
		;Return ReturnForm
	EndIf

	Return ReturnForm
EndFunction

Bool function ArrayPutFormAtXT(string ArrayID, Form MyForm, Int Index)
	if ArrayID == "plugin"
		Bool DoPutForm = ArrayPutFormXT_doForm(_regPlugins1, _regPlugins2, _regPlugins3, _regPlugins4, MyForm, Index)
		return DoPutForm
	elseif ArrayID == "armor"
		Bool DoPutForm = ArrayPutFormXT_doForm(_regArmors1, _regArmors2, _regArmors3, _regArmors4, MyForm, Index)
		return DoPutForm
	elseif ArrayID == "race"
		Bool DoPutForm = ArrayPutFormXT_doForm(_regRaces1, _regRaces2, _regRaces3, _regRaces4, MyForm, Index)
		return DoPutForm
	else
		return False
	endif
	
	Return False
EndFunction

bool function ArrayPutFormXT_doForm(Form[] fArray1, Form[] fArray2, Form[] fArray3, Form[] fArray4, Form MyForm, Int Index)
	
	If Index < 128
		fArray1[Index] = MyForm
	ElseIf Index < 256
		fArray2[Index - 128] = MyForm
	ElseIf Index < 384
		fArray3[Index - 256] = MyForm
	ElseIf Index < 512
		fArray4[Index - 384] = MyForm
	Else
		Return False
	EndIf

	Return True
EndFunction


Int function ArrayGetIntAtXT(string ArrayID, int Index)
	;;Debug.Trace("MFXRegistry: ArrayGetIntAtXT(ArrayID: " + ArrayID + ", Index: " + Index)
	if ArrayID == "slot"
		int DoGetInt = ArrayGetIntXT_doInt(_regSlots1, _regSlots2, _regSlots3, _regSlots4, Index)
		return DoGetInt
	elseif ArrayID == "LookupSlot"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupSlot1, _regLookupSlot2, _regLookupSlot3, _regLookupSlot4, Index)
		return DoGetInt
	elseif ArrayID == "LookupRace"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupRace1, _regLookupRace2, _regLookupRace3, _regLookupRace4, Index)
		return DoGetInt
	elseif ArrayID == "LookupPlugin"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupPlugin1, _regLookupPlugin2, _regLookupPlugin3, _regLookupPlugin4, Index)
		return DoGetInt
	elseif ArrayID == "LookupArmor"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupArmor1, _regLookupArmor2, _regLookupArmor3, _regLookupArmor4, Index)
		return DoGetInt
	elseif ArrayID == "LookupSlotRace"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupSlotRace1, _regLookupSlotRace2, _regLookupSlotRace3, _regLookupSlotRace4, Index)
		return DoGetInt
	elseif ArrayID == "LookupRaceSlot"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupRaceSlot1, _regLookupRaceSlot2, _regLookupRaceSlot3, _regLookupRaceSlot4, Index)
		return DoGetInt
	elseif ArrayID == "LookupPluginRace"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupPluginRace1, _regLookupPluginRace2, _regLookupPluginRace3, _regLookupPluginRace4, Index)
		return DoGetInt
	elseif ArrayID == "LookupRacePlugin"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupRacePlugin1, _regLookupRacePlugin2, _regLookupRacePlugin3, _regLookupRacePlugin4, Index)
		return DoGetInt
	elseif ArrayID == "LookupPluginSlot"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupPluginSlot1, _regLookupPluginSlot2, _regLookupPluginSlot3, _regLookupPluginSlot4, Index)
		return DoGetInt
	elseif ArrayID == "LookupSlotPlugin"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupSlotPlugin1, _regLookupSlotPlugin2, _regLookupSlotPlugin3, _regLookupSlotPlugin4, Index)
		return DoGetInt
	elseif ArrayID == "LookupArmorSlot"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupArmorSlot1, _regLookupArmorSlot2, _regLookupArmorSlot3, _regLookupArmorSlot4, Index)
		return DoGetInt
	elseif ArrayID == "LookupSlotArmor"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupSlotArmor1, _regLookupSlotArmor2, _regLookupSlotArmor3, _regLookupSlotArmor4, Index)
		return DoGetInt
	elseif ArrayID == "LookupArmorPlugin"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupArmorPlugin1, _regLookupArmorPlugin2, _regLookupArmorPlugin3, _regLookupArmorPlugin4, Index)
		return DoGetInt
	elseif ArrayID == "LookupPluginArmor"
		int DoGetInt = ArrayGetIntXT_doInt(_regLookupPluginArmor1, _regLookupPluginArmor2, _regLookupPluginArmor3, _regLookupPluginArmor4, Index)
		return DoGetInt
	else
		return 0
	endif
	
	Return 0
EndFunction

int function ArrayGetIntXT_doInt(Int[] fArray1, Int[] fArray2, Int[] fArray3, Int[] fArray4, Int Index)
	Int ReturnInt = 0
	If Index < 128
		ReturnInt = fArray1[Index]
	ElseIf Index < 256
		ReturnInt = fArray2[Index - 128]
	ElseIf Index < 384
		ReturnInt = fArray3[Index - 256]
	ElseIf Index < 512
		ReturnInt = fArray4[Index - 384]
	Else
		;Return ReturnInt
	EndIf
	Return ReturnInt
EndFunction

Bool function ArrayPutIntAtXT(string ArrayID, int Index, int MyInt)
	;;Debug.Trace("MFXRegistry: ArrayPutIntAtXT(ArrayID: " + ArrayID + ", Index: " + Index + ", MyInt: " + MyInt)
	if ArrayID == "slot"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regSlots1, _regSlots2, _regSlots3, _regSlots4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupSlot"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupSlot1, _regLookupSlot2, _regLookupSlot3, _regLookupSlot4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupRace"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupRace1, _regLookupRace2, _regLookupRace3, _regLookupRace4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupPlugin"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupPlugin1, _regLookupPlugin2, _regLookupPlugin3, _regLookupPlugin4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupArmor"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupArmor1, _regLookupArmor2, _regLookupArmor3, _regLookupArmor4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupSlotRace"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupSlotRace1, _regLookupSlotRace2, _regLookupSlotRace3, _regLookupSlotRace4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupRaceSlot"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupRaceSlot1, _regLookupRaceSlot2, _regLookupRaceSlot3, _regLookupRaceSlot4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupPluginRace"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupPluginRace1, _regLookupPluginRace2, _regLookupPluginRace3, _regLookupPluginRace4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupRacePlugin"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupRacePlugin1, _regLookupRacePlugin2, _regLookupRacePlugin3, _regLookupRacePlugin4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupPluginSlot"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupPluginSlot1, _regLookupPluginSlot2, _regLookupPluginSlot3, _regLookupPluginSlot4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupSlotPlugin"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupSlotPlugin1, _regLookupSlotPlugin2, _regLookupSlotPlugin3, _regLookupSlotPlugin4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupArmorSlot"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupArmorSlot1, _regLookupArmorSlot2, _regLookupArmorSlot3, _regLookupArmorSlot4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupSlotArmor"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupSlotArmor1, _regLookupSlotArmor2, _regLookupSlotArmor3, _regLookupSlotArmor4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupArmorPlugin"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupArmorPlugin1, _regLookupArmorPlugin2, _regLookupArmorPlugin3, _regLookupArmorPlugin4, MyInt, Index)
		return DoPutInt
	elseif ArrayID == "LookupPluginArmor"
		Bool DoPutInt = ArrayPutIntXT_doInt(_regLookupPluginArmor1, _regLookupPluginArmor2, _regLookupPluginArmor3, _regLookupPluginArmor4, MyInt, Index)
		return DoPutInt
	else
		return False
	endif
	
	Return False
EndFunction

Bool function ArrayPutIntXT_doInt(Int[] fArray1, Int[] fArray2, Int[] fArray3, Int[] fArray4, Int MyInt, Int Index)
	;;Debug.Trace("MFXRegistry: ArrayPutIntXT_doInt(Index: " + Index + ", MyInt: " + MyInt)
	If Index < 128
		fArray1[Index] = MyInt
	ElseIf Index < 256
		fArray2[Index - 128] = MyInt
	ElseIf Index < 384
		fArray3[Index - 256] = MyInt
	ElseIf Index < 512
		fArray4[Index - 384] = MyInt
	Else
		Return False
	EndIf

	Return True
EndFunction


bool function ArrayAddFormXT(string ArrayID, Form myForm)

	;-----------\
    ;Description \  Author: Chesko
    ;----------------------------------------------------------------
    ;Adds a form to the first available element in the first available array
	;associated with this ArrayID.
        
    ;-------------\
    ;Return Values \
    ;----------------------------------------------------------------
    ;               false           =               Error (array full) OR invalid Array ID
    ;               true            =               Success

	if ArrayID == "plugin"
		bool DoAddForm = ArrayAddFormXT_Do(_regPlugins1, _regPlugins2, _regPlugins3, _regPlugins4, myForm)
		return DoAddForm
	elseif ArrayID == "armor"
		bool DoAddForm = ArrayAddFormXT_Do(_regArmors1, _regArmors2, _regArmors3, _regArmors4, myForm)
		return DoAddForm
	elseif ArrayID == "race"
		bool DoAddForm = ArrayAddFormXT_Do(_regRaces1, _regRaces2, _regRaces3, _regRaces4, myForm)
		return DoAddForm
	else
		return false
	endif
	
endFunction

bool function ArrayRemoveFormXT(string ArrayID, Form myForm)

	;-----------\
    ;Description \  Author: Chesko
    ;----------------------------------------------------------------
    ;Removes a form from the arrays associated with the ArrayID.
        
    ;-------------\
    ;Return Values \
    ;----------------------------------------------------------------
    ;               false           =               Error (form not found) OR invalid Array ID
    ;               true            =               Success

	if ArrayID == "plugin"
		bool DoRemoveForm = ArrayRemoveFormXT_Do(_regPlugins1, _regPlugins2, _regPlugins3, _regPlugins4, myForm as vMFX_FXPluginBase, ArrayID)
		return DoRemoveForm
	elseif ArrayID == "armor"
		bool DoRemoveForm = ArrayRemoveFormXT_Do(_regArmors1, _regArmors2, _regArmors3, _regArmors4, myForm as Armor, ArrayID)
		return DoRemoveForm
	elseif ArrayID == "race"
		bool DoRemoveForm = ArrayRemoveFormXT_Do(_regRaces1, _regRaces2, _regRaces3, _regRaces4, myForm as Race, ArrayID)
		return DoRemoveForm
	else
		return false
	endif
	
endFunction

bool function ArrayHasFormXT(string ArrayID, Form myForm)

	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Attempts to find the given form in the given Array ID, and returns true if found
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false					= 		Form not found OR invalid array ID
	;		true			 		=		Form found
	
	if ArrayID == "plugin"
		bool DoHasForm = ArrayHasFormXT_Do(_regPlugins1, _regPlugins2, _regPlugins3, _regPlugins4, myForm as vMFX_FXPluginBase)
		return DoHasForm
	elseif ArrayID == "armor"
		bool DoHasForm = ArrayHasFormXT_Do(_regArmors1, _regArmors2, _regArmors3, _regArmors4, myForm as Armor)
		return DoHasForm
	elseif ArrayID == "race"
		bool DoHasForm = ArrayHasFormXT_Do(_regRaces1, _regRaces2, _regRaces3, _regRaces4, myForm as Race)
		return DoHasForm
	else
		return false
	endif
	
endFunction

int function ArrayFindFormXT(string ArrayID, Form myForm)

	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Attempts to find the given form in the given Array ID, and returns its index if found
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		-1						= 		Form not found OR invalid array ID
	;		0-511				 	=		Form's index
	
	if ArrayID == "plugin"
		int DoFindForm = ArrayFindFormXT_Do(_regPlugins1, _regPlugins2, _regPlugins3, _regPlugins4, myForm as vMFX_FXPluginBase)
		return DoFindForm
	elseif ArrayID == "armor"
		int DoFindForm = ArrayFindFormXT_Do(_regArmors1, _regArmors2, _regArmors3, _regArmors4, myForm as Armor)
		return DoFindForm
	elseif ArrayID == "race"
		int DoFindForm = ArrayFindFormXT_Do(_regRaces1, _regRaces2, _regRaces3, _regRaces4, myForm as Race)
		return DoFindForm
	else
		return -1
	endif
	
endFunction

bool function ArrayClearXT(string ArrayID)
	
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Clears all arrays associated with this array ID
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false = Invalid Array ID
	;		true  = Complete, Valid Array ID
	
	if ArrayID == "plugin"
		ArrayClearXT_Do(_regPlugins1, _regPlugins2, _regPlugins3, _regPlugins4)
		return true
	elseif ArrayID == "armor"
		ArrayClearXT_Do(_regArmors1, _regArmors2, _regArmors3, _regArmors4)
		return true
	elseif ArrayID == "race"
		ArrayClearXT_Do(_regRaces1, _regRaces2, _regRaces3, _regRaces4)
		return true
	else
		return false
	endif
	
endFunction

int function ArrayCountXT(string ArrayID)
	
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Counts the number of indicies associated with this array ID that do not have a "none" type
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		int DoCount = number of indicies that are not "none"
	;		-1			= Invalid Array ID
	
	if ArrayID == "plugin"
		int DoCount = ArrayCountXT_Do(_regPlugins1, _regPlugins2, _regPlugins3, _regPlugins4)
		return DoCount
	elseif ArrayID == "armor"
		int DoCount = ArrayCountXT_Do(_regArmors1, _regArmors2, _regArmors3, _regArmors4)
		return DoCount
	elseif ArrayID == "race"
		int DoCount = ArrayCountXT_Do(_regRaces1, _regRaces2, _regRaces3, _regRaces4)
		return DoCount
	else
		return -1
	endif
	
endFunction

int function ArrayCountFormXT(string ArrayID, Form myForm)
	
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Counts the number of times myForm appears in arrays associated with this array ID
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		int DoCount = number of times the form appears in the arrays associated with the Array ID
	;		-1			= Invalid Array ID
	
	if ArrayID == "plugin"
		int DoCount = ArrayCountFormXT_Do(_regPlugins1, _regPlugins2, _regPlugins3, _regPlugins4, myForm)
		return DoCount
	elseif ArrayID == "armor"
		int DoCount = ArrayCountFormXT_Do(_regArmors1, _regArmors2, _regArmors3, _regArmors4, myForm)
		return DoCount
	elseif ArrayID == "race"
		int DoCount = ArrayCountFormXT_Do(_regRaces1, _regRaces2, _regRaces3, _regRaces4, myForm)
		return DoCount
	else
		return -1
	endif
	
endFunction

bool function ArraySortXT(string ArrayID)
	
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Removes blank elements by shifting all elements down, moving elements
	;to arrays "below" the current one if necessary.
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		true 	= 	Success
	;		false 	= 	Sort not necessary
	
	if ArrayID == "plugin"
		bool DoSort = ArraySortXT_Do(_regPlugins1, _regPlugins2, _regPlugins3, _regPlugins4)
		return DoSort
	elseif ArrayID == "armor"
		bool DoSort = ArraySortXT_Do(_regArmors1, _regArmors2, _regArmors3, _regArmors4)
		return DoSort
	elseif ArrayID == "race"
		bool DoSort = ArraySortXT_Do(_regRaces1, _regRaces2, _regRaces3, _regRaces4)
		return DoSort
	else
		return false
	endif
	
endFunction


bool function ArrayAddFormXT_Do(Form[] fArray1, Form[] fArray2, Form[] fArray3, Form[] fArray4, Form myForm)
	;-----------\
    ;Description \  Author: Chesko
    ;----------------------------------------------------------------
    ;Adds a form to the first available element in the first available array
	;associated with this ArrayID.
    
	;-------------\
    ;Return Values \
    ;----------------------------------------------------------------
    ;               false           =               Error (array full)
    ;               true            =               Success
		
	int i = 0
	;notification("myArray.Length = " + myArray.Length)
    while i < fArray1.Length
        if fArray1[i] == none
            fArray1[i] = myForm
            ;notification("Adding " + myForm + " to the array.")
            return true
        else
            i += 1
        endif
    endWhile
    
	i = 0
	while i < fArray2.Length
        if fArray2[i] == none
            fArray2[i] = myForm
            ;notification("Adding " + myForm + " to the array.")
            return true
        else
            i += 1
        endif
    endWhile
	
	i = 0
	while i < fArray3.Length
        if fArray3[i] == none
            fArray3[i] = myForm
            ;notification("Adding " + myForm + " to the array.")
            return true
        else
            i += 1
        endif
    endWhile
	
	i = 0
	while i < fArray4.Length
        if fArray4[i] == none
            fArray4[i] = myForm
            ;notification("Adding " + myForm + " to the array.")
            return true
        else
            i += 1
        endif
    endWhile
	
    return false			;All arrays are full
	
endFunction

bool function ArrayRemoveFormXT_Do(Form[] fArray1, Form[] fArray2, Form[] fArray3, Form[] fArray4, Form myForm, string ArrayID, bool bSort = true)
	
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Removes a form from the array, if found.
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false		=		Error (Form not found)
	;		true		=		Success

	int i = 0
	while i < fArray1.Length
		if fArray1[i] == myForm
			fArray1[i] = none
			;notification("Removing element " + i)
			if bSort == true
				ArraySortXT(ArrayID)
			endif
			return true
		else
			i += 1
		endif
	endWhile

	i = 0
	while i < fArray2.Length
		if fArray2[i] == myForm
			fArray2[i] = none
			;notification("Removing element " + i)
			if bSort == true
				ArraySortXT(ArrayID)
			endif
			return true
		else
			i += 1
		endif
	endWhile		

	i = 0
	while i < fArray3.Length
		if fArray3[i] == myForm
			fArray3[i] = none
			;notification("Removing element " + i)
			if bSort == true
				ArraySortXT(ArrayID)
			endif
			return true
		else
			i += 1
		endif
	endWhile	
	
	i = 0
	while i < fArray4.Length
		if fArray4[i] == myForm
			fArray4[i] = none
			;notification("Removing element " + i)
			if bSort == true
				ArraySortXT(ArrayID)
			endif
			return true
		else
			i += 1
		endif
	endWhile	
	
	return false
	
endFunction

bool function ArrayHasFormXT_Do(Form[] fArray1, Form[] fArray2, Form[] fArray3, Form[] fArray4, Form myForm)
	
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Attempts to find the given form in the associated array ID, and returns true if found
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false					= 		Form not found
	;		true			 		=		Form found
	
	int i = 0
	while i < fArray1.Length
		if fArray1[i] == myForm
			return true
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray2.Length
		if fArray2[i] == myForm
			return true
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray3.Length
		if fArray3[i] == myForm
			return true
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray4.Length
		if fArray4[i] == myForm
			return true
		else
			i += 1
		endif
	endWhile
	
	return false

endFunction

int function ArrayFindFormXT_Do(Form[] fArray1, Form[] fArray2, Form[] fArray3, Form[] fArray4, Form myForm)
	
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Attempts to find the given form in the associated array ID, and returns its index if found
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		-1						= 		Form not found
	;		0-511			 		=		Form index
	
	
	int iFI = -1
	
	iFI = fArray1.Find(myForm)
	if iFI >= 0 
		return iFI
	endif

	iFI = fArray2.Find(myForm)
	if iFI >= 0 
		return iFI + 128
	endif

	iFI = fArray3.Find(myForm)
	if iFI >= 0 
		return iFI + 256
	endif

	iFI = fArray4.Find(myForm)
	if iFI >= 0 
		return iFI + 384
	endif

	return -1

endFunction

function ArrayClearXT_Do(Form[] fArray1, Form[] fArray2, Form[] fArray3, Form[] fArray4)

	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Deletes the contents of arrays.
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		none

	int i = 0
	while i < fArray1.Length
		fArray1[i] = none
		i += 1
	endWhile
	
	i = 0
	while i < fArray2.Length
		fArray2[i] = none
		i += 1
	endWhile
	
	i = 0
	while i < fArray3.Length
		fArray3[i] = none
		i += 1
	endWhile
	
	i = 0
	while i < fArray4.Length
		fArray4[i] = none
		i += 1
	endWhile
	
endFunction

int function ArrayCountXT_Do(Form[] fArray1, Form[] fArray2, Form[] fArray3, Form[] fArray4)

	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Counts the number of indicies associated with this array ID that do not have a "none" type
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		int myCount = number of indicies that are not "none"

	int myCount = 0
	
	int i = 0
	while i < fArray1.Length
		if fArray1[i] != none
			myCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray2.Length
		if fArray2[i] != none
			myCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray3.Length
		if fArray3[i] != none
			myCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray4.Length
		if fArray4[i] != none
			myCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	;notification("MyCount = " + myCount)	
	
	return myCount
	
endFunction

int function ArrayCountFormXT_Do(Form[] fArray1, Form[] fArray2, Form[] fArray3, Form[] fArray4, Form myForm)

	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Attempts to count the number of times the given form appears in the arrays associated with the Array ID.
        
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;               0			=               Form not found
	;               int i		=               Number of times form appears in array
    
	int iCount = 0
    
	int i = 0
	while i < fArray1.Length
		if fArray1[i] == myForm
			iCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray2.Length
		if fArray2[i] == myForm
			iCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray3.Length
		if fArray3[i] == myForm
			iCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray4.Length
		if fArray4[i] == myForm
			iCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
        
	return iCount
        
endFunction

bool function ArraySortXT_Do(Form[] fArray1, Form[] fArray2, Form[] fArray3, Form[] fArray4, int i = 0)

	;-----------\
	;Description \  Author: Chesko
	;----------------------------------------------------------------
	;Removes blank elements by shifting all elements down, moving elements
	;to arrays "below" the current one if necessary.
	;Optionally starts sorting from element i.
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;                 false        =           No sorting required
	;                 true         =           Success

	
	
	
	;notification("Sort Start")
	bool bFirstNoneFound = false
	int iFirstNoneFoundArray = 0
	int iFirstNonePos = 0
	while i < 512
		;Which array am I looking in?
		int j = 0					;Actual array index to check
		int myCurrArray				;Current array
		if i < 128
			myCurrArray = 1
			j = i
		elseif i < 256 && i >= 128
			j = i - 128
			myCurrArray = 2
		elseif i < 384 && i >= 256
			j = i - 256
			myCurrArray = 3
		elseif i < 512 && i >= 384
			j = i - 384
			myCurrArray = 4
		endif
		
		if myCurrArray == 1
			if fArray1[j] == none
				if bFirstNoneFound == false
					bFirstNoneFound = true
					iFirstNoneFoundArray = myCurrArray
					iFirstNonePos = j
					i += 1
				else
					i += 1
				endif
			else
				if bFirstNoneFound == true
					;check to see if it's a couple of blank entries in a row
					if !(fArray1[j] == none)
						;notification("Moving element " + i + " to index " + iFirstNonePos)
						if iFirstNoneFoundArray == 1
							fArray1[iFirstNonePos] = fArray1[j]
							fArray1[j] = none
						elseif iFirstNoneFoundArray == 2
							fArray2[iFirstNonePos] = fArray1[j]
							fArray1[j] = none
						elseif iFirstNoneFoundArray == 3
							fArray3[iFirstNonePos] = fArray1[j]
							fArray1[j] = none
						elseif iFirstNoneFoundArray == 4
							fArray4[iFirstNonePos] = fArray1[j]
							fArray1[j] = none
						endif
						;Call this function recursively until it returns
						ArraySortXT_Do(fArray1, fArray2, fArray3, fArray4, iFirstNonePos + 1)
						return true
					else
						i += 1
					endif
				else
					i += 1
				endif
			endif
		elseif myCurrArray == 2
			if fArray2[j] == none
				if bFirstNoneFound == false
					bFirstNoneFound = true
					iFirstNoneFoundArray = myCurrArray
					iFirstNonePos = j
					i += 1
				else
					i += 1
				endif
			else
				if bFirstNoneFound == true
					;check to see if it's a couple of blank entries in a row
					if !(fArray2[j] == none)
						;notification("Moving element " + i + " to index " + iFirstNonePos)
						if iFirstNoneFoundArray == 1
							fArray1[iFirstNonePos] = fArray2[j]
							fArray2[j] = none
						elseif iFirstNoneFoundArray == 2
							fArray2[iFirstNonePos] = fArray2[j]
							fArray2[j] = none
						elseif iFirstNoneFoundArray == 3
							fArray3[iFirstNonePos] = fArray2[j]
							fArray2[j] = none
						elseif iFirstNoneFoundArray == 4
							fArray4[iFirstNonePos] = fArray2[j]
							fArray2[j] = none
						endif
						;Call this function recursively until it returns
						ArraySortXT_Do(fArray1, fArray2, fArray3, fArray4, iFirstNonePos + 1)
						return true
					else
						i += 1
					endif
				else
					i += 1
				endif
			endif
		elseif myCurrArray == 3
			if fArray3[j] == none
				if bFirstNoneFound == false
					bFirstNoneFound = true
					iFirstNoneFoundArray = myCurrArray
					iFirstNonePos = j
					i += 1
				else
					i += 1
				endif
			else
				if bFirstNoneFound == true
					;check to see if it's a couple of blank entries in a row
					if !(fArray3[j] == none)
						;notification("Moving element " + i + " to index " + iFirstNonePos)
						if iFirstNoneFoundArray == 1
							fArray1[iFirstNonePos] = fArray3[j]
							fArray3[j] = none
						elseif iFirstNoneFoundArray == 2
							fArray2[iFirstNonePos] = fArray3[j]
							fArray3[j] = none
						elseif iFirstNoneFoundArray == 3
							fArray3[iFirstNonePos] = fArray3[j]
							fArray3[j] = none
						elseif iFirstNoneFoundArray == 4
							fArray4[iFirstNonePos] = fArray3[j]
							fArray3[j] = none
						endif
						;Call this function recursively until it returns
						ArraySortXT_Do(fArray1, fArray2, fArray3, fArray4, iFirstNonePos + 1)
						return true
					else
						i += 1
					endif
				else
					i += 1
				endif
			endif
		elseif myCurrArray == 4
			if fArray4[j] == none
				if bFirstNoneFound == false
					bFirstNoneFound = true
					iFirstNoneFoundArray = myCurrArray
					iFirstNonePos = j
					i += 1
				else
					i += 1
				endif
			else
				if bFirstNoneFound == true
					;check to see if it's a couple of blank entries in a row
					if !(fArray4[j] == none)
						;notification("Moving element " + i + " to index " + iFirstNonePos)
						if iFirstNoneFoundArray == 1
							fArray1[iFirstNonePos] = fArray4[j]
							fArray4[j] = none
						elseif iFirstNoneFoundArray == 2
							fArray2[iFirstNonePos] = fArray4[j]
							fArray4[j] = none
						elseif iFirstNoneFoundArray == 3
							fArray3[iFirstNonePos] = fArray4[j]
							fArray4[j] = none
						elseif iFirstNoneFoundArray == 4
							fArray4[iFirstNonePos] = fArray4[j]
							fArray4[j] = none
						endif
						;Call this function recursively until it returns
						ArraySortXT_Do(fArray1, fArray2, fArray3, fArray4, iFirstNonePos + 1)
						return true
					else
						i += 1
					endif
				else
					i += 1
				endif
			endif
		endif
	endWhile
	
	return false

endFunction

;Int[]		_regSlots
;Int[]		_regLookupSlotRace
;Int[]		_regLookupRaceSlot
;Int[]		_regLookupPluginRace
;Int[]		_regLookupRacePlugin
;Int[]		_regLookupPluginSlot
;Int[]		_regLookupSlotPlugin
;Int[]		_regLookupArmorSlot
;Int[]		_regLookupSlotArmor
;Int[]		_regLookupArmorPlugin
;Int[]		_regLookupPluginArmor

;------ INT functions

int function ArrayAddIntXT(string ArrayID, Int myInt)
	;;Debug.Trace("MFXRegistry: ArrayAddIntXT(ArrayID: " + ArrayID + ",myInt: " + myInt)
	;-----------\
    ;Description \  Author: Chesko
    ;----------------------------------------------------------------
    ;Adds a Int to the first available element in the first available array
	;associated with this ArrayID.
        
    ;-------------\
    ;Return Values \
    ;----------------------------------------------------------------
    ;               -1	           =               Error (array full) OR invalid Array ID
    ;               >=0            =               Index of new item

	if ArrayID == "slot"
		int DoAddInt = ArrayAddIntXT_doInt(_regSlots1, _regSlots2, _regSlots3, _regSlots4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupSlot"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupSlot1, _regLookupSlot2, _regLookupSlot3, _regLookupSlot4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupRace"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupRace1, _regLookupRace2, _regLookupRace3, _regLookupRace4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupPlugin"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupPlugin1, _regLookupPlugin2, _regLookupPlugin3, _regLookupPlugin4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupArmor"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupArmor1, _regLookupArmor2, _regLookupArmor3, _regLookupArmor4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupSlotRace"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupSlotRace1, _regLookupSlotRace2, _regLookupSlotRace3, _regLookupSlotRace4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupRaceSlot"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupRaceSlot1, _regLookupRaceSlot2, _regLookupRaceSlot3, _regLookupRaceSlot4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupPluginRace"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupPluginRace1, _regLookupPluginRace2, _regLookupPluginRace3, _regLookupPluginRace4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupRacePlugin"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupRacePlugin1, _regLookupRacePlugin2, _regLookupRacePlugin3, _regLookupRacePlugin4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupPluginSlot"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupPluginSlot1, _regLookupPluginSlot2, _regLookupPluginSlot3, _regLookupPluginSlot4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupSlotPlugin"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupSlotPlugin1, _regLookupSlotPlugin2, _regLookupSlotPlugin3, _regLookupSlotPlugin4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupArmorSlot"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupArmorSlot1, _regLookupArmorSlot2, _regLookupArmorSlot3, _regLookupArmorSlot4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupSlotArmor"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupSlotArmor1, _regLookupSlotArmor2, _regLookupSlotArmor3, _regLookupSlotArmor4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupArmorPlugin"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupArmorPlugin1, _regLookupArmorPlugin2, _regLookupArmorPlugin3, _regLookupArmorPlugin4, myInt)
		return DoAddInt
	elseif ArrayID == "LookupPluginArmor"
		int DoAddInt = ArrayAddIntXT_doInt(_regLookupPluginArmor1, _regLookupPluginArmor2, _regLookupPluginArmor3, _regLookupPluginArmor4, myInt)
		return DoAddInt
	else
		return -1
	endif
	
endFunction

bool function ArrayRemoveIntXT(string ArrayID, Int myInt)

	;-----------\
    ;Description \  Author: Chesko
    ;----------------------------------------------------------------
    ;Removes a Int from the arrays associated with the ArrayID.
        
    ;-------------\
    ;Return Values \
    ;----------------------------------------------------------------
    ;               false           =               Error (Int not found) OR invalid Array ID
    ;               true            =               Success

	if ArrayID == "slot"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regSlots1, _regSlots2, _regSlots3, _regSlots4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupSlot"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupSlot1, _regLookupSlot2, _regLookupSlot3, _regLookupSlot4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupRace"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupRace1, _regLookupRace2, _regLookupRace3, _regLookupRace4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupArmor"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupArmor1, _regLookupArmor2, _regLookupArmor3, _regLookupArmor4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupPlugin"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupPlugin1, _regLookupPlugin2, _regLookupPlugin3, _regLookupPlugin4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupRaceSlot"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupRaceSlot1, _regLookupRaceSlot2, _regLookupRaceSlot3, _regLookupRaceSlot4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupPluginRace"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupPluginRace1, _regLookupPluginRace2, _regLookupPluginRace3, _regLookupPluginRace4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupRacePlugin"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupRacePlugin1, _regLookupRacePlugin2, _regLookupRacePlugin3, _regLookupRacePlugin4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupPluginSlot"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupPluginSlot1, _regLookupPluginSlot2, _regLookupPluginSlot3, _regLookupPluginSlot4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupSlotPlugin"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupSlotPlugin1, _regLookupSlotPlugin2, _regLookupSlotPlugin3, _regLookupSlotPlugin4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupArmorSlot"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupArmorSlot1, _regLookupArmorSlot2, _regLookupArmorSlot3, _regLookupArmorSlot4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupSlotArmor"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupSlotArmor1, _regLookupSlotArmor2, _regLookupSlotArmor3, _regLookupSlotArmor4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupArmorPlugin"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupArmorPlugin1, _regLookupArmorPlugin2, _regLookupArmorPlugin3, _regLookupArmorPlugin4, myInt, ArrayID)
		return DoRemoveInt
	elseif ArrayID == "LookupPluginArmor"
		bool DoRemoveInt = ArrayRemoveIntXT_doInt(_regLookupPluginArmor1, _regLookupPluginArmor2, _regLookupPluginArmor3, _regLookupPluginArmor4, myInt, ArrayID)
		return DoRemoveInt
	else
		return false
	endif
	
endFunction

bool function ArrayHasIntXT(string ArrayID, Int myInt)

	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Attempts to find the given Int in the given Array ID, and returns true if found
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false					= 		Int not found OR invalid array ID
	;		true			 		=		Int found
	
	if ArrayID == "slot"
		bool DoHasInt = ArrayHasIntXT_doInt(_regSlots1, _regSlots2, _regSlots3, _regSlots4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupSlot"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupSlot1, _regLookupSlot2, _regLookupSlot3, _regLookupSlot4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupRace"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupRace1, _regLookupRace2, _regLookupRace3, _regLookupRace4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupArmor"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupArmor1, _regLookupArmor2, _regLookupArmor3, _regLookupArmor4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupPlugin"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupPlugin1, _regLookupPlugin2, _regLookupPlugin3, _regLookupPlugin4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupSlotRace"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupSlotRace1, _regLookupSlotRace2, _regLookupSlotRace3, _regLookupSlotRace4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupRaceSlot"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupRaceSlot1, _regLookupRaceSlot2, _regLookupRaceSlot3, _regLookupRaceSlot4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupPluginRace"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupPluginRace1, _regLookupPluginRace2, _regLookupPluginRace3, _regLookupPluginRace4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupRacePlugin"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupRacePlugin1, _regLookupRacePlugin2, _regLookupRacePlugin3, _regLookupRacePlugin4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupPluginSlot"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupPluginSlot1, _regLookupPluginSlot2, _regLookupPluginSlot3, _regLookupPluginSlot4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupSlotPlugin"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupSlotPlugin1, _regLookupSlotPlugin2, _regLookupSlotPlugin3, _regLookupSlotPlugin4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupArmorSlot"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupArmorSlot1, _regLookupArmorSlot2, _regLookupArmorSlot3, _regLookupArmorSlot4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupSlotArmor"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupSlotArmor1, _regLookupSlotArmor2, _regLookupSlotArmor3, _regLookupSlotArmor4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupArmorPlugin"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupArmorPlugin1, _regLookupArmorPlugin2, _regLookupArmorPlugin3, _regLookupArmorPlugin4, myInt)
		return DoHasInt
	elseif ArrayID == "LookupPluginArmor"
		bool DoHasInt = ArrayHasIntXT_doInt(_regLookupPluginArmor1, _regLookupPluginArmor2, _regLookupPluginArmor3, _regLookupPluginArmor4, myInt)
		return DoHasInt
	else
		return false
	endif
	
endFunction

int function ArrayFindIntXT(string ArrayID, Int myInt)
	;;Debug.Trace("MFXRegistry: ArrayFindIntXT(ArrayID: " + ArrayID + ", myInt: " + myInt)
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Attempts to find the given Int in the given Array ID, and returns true if found
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false					= 		Int not found OR invalid array ID
	;		true			 		=		Int found
	
	if ArrayID == "slot"
		int DoFindInt = ArrayFindIntXT_doInt(_regSlots1, _regSlots2, _regSlots3, _regSlots4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupSlot"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupSlot1, _regLookupSlot2, _regLookupSlot3, _regLookupSlot4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupRace"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupRace1, _regLookupRace2, _regLookupRace3, _regLookupRace4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupArmor"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupArmor1, _regLookupArmor2, _regLookupArmor3, _regLookupArmor4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupPlugin"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupPlugin1, _regLookupPlugin2, _regLookupPlugin3, _regLookupPlugin4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupSlotRace"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupSlotRace1, _regLookupSlotRace2, _regLookupSlotRace3, _regLookupSlotRace4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupRaceSlot"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupRaceSlot1, _regLookupRaceSlot2, _regLookupRaceSlot3, _regLookupRaceSlot4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupPluginRace"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupPluginRace1, _regLookupPluginRace2, _regLookupPluginRace3, _regLookupPluginRace4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupRacePlugin"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupRacePlugin1, _regLookupRacePlugin2, _regLookupRacePlugin3, _regLookupRacePlugin4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupPluginSlot"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupPluginSlot1, _regLookupPluginSlot2, _regLookupPluginSlot3, _regLookupPluginSlot4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupSlotPlugin"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupSlotPlugin1, _regLookupSlotPlugin2, _regLookupSlotPlugin3, _regLookupSlotPlugin4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupArmorSlot"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupArmorSlot1, _regLookupArmorSlot2, _regLookupArmorSlot3, _regLookupArmorSlot4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupSlotArmor"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupSlotArmor1, _regLookupSlotArmor2, _regLookupSlotArmor3, _regLookupSlotArmor4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupArmorPlugin"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupArmorPlugin1, _regLookupArmorPlugin2, _regLookupArmorPlugin3, _regLookupArmorPlugin4, myInt)
		return DoFindInt
	elseif ArrayID == "LookupPluginArmor"
		int DoFindInt = ArrayFindIntXT_doInt(_regLookupPluginArmor1, _regLookupPluginArmor2, _regLookupPluginArmor3, _regLookupPluginArmor4, myInt)
		return DoFindInt
	else
		return -1
	endif
	
endFunction

bool function ArrayIntClearXT(string ArrayID)
	
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Clears all arrays associated with this array ID
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false = Invalid Array ID
	;		true  = Complete, Valid Array ID
	
	if ArrayID == "slot"
		ArrayClearXT_doInt(_regSlots1, _regSlots2, _regSlots3, _regSlots4)
		return True
	elseif ArrayID == "LookupSlot"
		ArrayClearXT_doInt(_regLookupSlot1, _regLookupSlot2, _regLookupSlot3, _regLookupSlot4)
		return True
	elseif ArrayID == "LookupRace"
		ArrayClearXT_doInt(_regLookupRace1, _regLookupRace2, _regLookupRace3, _regLookupRace4)
		return True
	elseif ArrayID == "LookupArmor"
		ArrayClearXT_doInt(_regLookupArmor1, _regLookupArmor2, _regLookupArmor3, _regLookupArmor4)
		return True
	elseif ArrayID == "LookupPlugin"
		ArrayClearXT_doInt(_regLookupPlugin1, _regLookupPlugin2, _regLookupPlugin3, _regLookupPlugin4)
		return True
	elseif ArrayID == "LookupSlotRace"
		ArrayClearXT_doInt(_regLookupSlotRace1, _regLookupSlotRace2, _regLookupSlotRace3, _regLookupSlotRace4)
		return True
	elseif ArrayID == "LookupRaceSlot"
		ArrayClearXT_doInt(_regLookupRaceSlot1, _regLookupRaceSlot2, _regLookupRaceSlot3, _regLookupRaceSlot4)
		return True
	elseif ArrayID == "LookupPluginRace"
		ArrayClearXT_doInt(_regLookupPluginRace1, _regLookupPluginRace2, _regLookupPluginRace3, _regLookupPluginRace4)
		return True
	elseif ArrayID == "LookupRacePlugin"
		ArrayClearXT_doInt(_regLookupRacePlugin1, _regLookupRacePlugin2, _regLookupRacePlugin3, _regLookupRacePlugin4)
		return True
	elseif ArrayID == "LookupPluginSlot"
		ArrayClearXT_doInt(_regLookupPluginSlot1, _regLookupPluginSlot2, _regLookupPluginSlot3, _regLookupPluginSlot4)
		return True
	elseif ArrayID == "LookupSlotPlugin"
		ArrayClearXT_doInt(_regLookupSlotPlugin1, _regLookupSlotPlugin2, _regLookupSlotPlugin3, _regLookupSlotPlugin4)
		return True
	elseif ArrayID == "LookupArmorSlot"
		ArrayClearXT_doInt(_regLookupArmorSlot1, _regLookupArmorSlot2, _regLookupArmorSlot3, _regLookupArmorSlot4)
		return True
	elseif ArrayID == "LookupSlotArmor"
		ArrayClearXT_doInt(_regLookupSlotArmor1, _regLookupSlotArmor2, _regLookupSlotArmor3, _regLookupSlotArmor4)
		return True
	elseif ArrayID == "LookupArmorPlugin"
		ArrayClearXT_doInt(_regLookupArmorPlugin1, _regLookupArmorPlugin2, _regLookupArmorPlugin3, _regLookupArmorPlugin4)
		return True
	elseif ArrayID == "LookupPluginArmor"
		ArrayClearXT_doInt(_regLookupPluginArmor1, _regLookupPluginArmor2, _regLookupPluginArmor3, _regLookupPluginArmor4)
		return True
	else
		return false
	endif
	
endFunction

int function ArrayCountIntXT(string ArrayID, Int myInt)
	
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Counts the number of times myInt appears in arrays associated with this array ID
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		int DoCount = number of times the Int appears in the arrays associated with the Array ID
	;		-1			= Invalid Array ID
	
	if ArrayID == "slot"
		int DoCount = ArrayCountIntXT_doInt(_regSlots1, _regSlots2, _regSlots3, _regSlots4, myInt)
		return DoCount
	elseif ArrayID == "LookupSlot"
		int DoCount = ArrayCountIntXT_doInt(_regLookupSlot1, _regLookupSlot2, _regLookupSlot3, _regLookupSlot4, myInt)
		return DoCount
	elseif ArrayID == "LookupRace"
		int DoCount = ArrayCountIntXT_doInt(_regLookupRace1, _regLookupRace2, _regLookupRace3, _regLookupRace4, myInt)
		return DoCount
	elseif ArrayID == "LookupArmor"
		int DoCount = ArrayCountIntXT_doInt(_regLookupArmor1, _regLookupArmor2, _regLookupArmor3, _regLookupArmor4, myInt)
		return DoCount
	elseif ArrayID == "LookupPlugin"
		int DoCount = ArrayCountIntXT_doInt(_regLookupPlugin1, _regLookupPlugin2, _regLookupPlugin3, _regLookupPlugin4, myInt)
		return DoCount
	elseif ArrayID == "LookupSlotRace"
		int DoCount = ArrayCountIntXT_doInt(_regLookupSlotRace1, _regLookupSlotRace2, _regLookupSlotRace3, _regLookupSlotRace4, myInt)
		return DoCount
	elseif ArrayID == "LookupRaceSlot"
		int DoCount = ArrayCountIntXT_doInt(_regLookupRaceSlot1, _regLookupRaceSlot2, _regLookupRaceSlot3, _regLookupRaceSlot4, myInt)
		return DoCount
	elseif ArrayID == "LookupPluginRace"
		int DoCount = ArrayCountIntXT_doInt(_regLookupPluginRace1, _regLookupPluginRace2, _regLookupPluginRace3, _regLookupPluginRace4, myInt)
		return DoCount
	elseif ArrayID == "LookupRacePlugin"
		int DoCount = ArrayCountIntXT_doInt(_regLookupRacePlugin1, _regLookupRacePlugin2, _regLookupRacePlugin3, _regLookupRacePlugin4, myInt)
		return DoCount
	elseif ArrayID == "LookupPluginSlot"
		int DoCount = ArrayCountIntXT_doInt(_regLookupPluginSlot1, _regLookupPluginSlot2, _regLookupPluginSlot3, _regLookupPluginSlot4, myInt)
		return DoCount
	elseif ArrayID == "LookupSlotPlugin"
		int DoCount = ArrayCountIntXT_doInt(_regLookupSlotPlugin1, _regLookupSlotPlugin2, _regLookupSlotPlugin3, _regLookupSlotPlugin4, myInt)
		return DoCount
	elseif ArrayID == "LookupArmorSlot"
		int DoCount = ArrayCountIntXT_doInt(_regLookupArmorSlot1, _regLookupArmorSlot2, _regLookupArmorSlot3, _regLookupArmorSlot4, myInt)
		return DoCount
	elseif ArrayID == "LookupSlotArmor"
		int DoCount = ArrayCountIntXT_doInt(_regLookupSlotArmor1, _regLookupSlotArmor2, _regLookupSlotArmor3, _regLookupSlotArmor4, myInt)
		return DoCount
	elseif ArrayID == "LookupArmorPlugin"
		int DoCount = ArrayCountIntXT_doInt(_regLookupArmorPlugin1, _regLookupArmorPlugin2, _regLookupArmorPlugin3, _regLookupArmorPlugin4, myInt)
		return DoCount
	elseif ArrayID == "LookupPluginArmor"
		int DoCount = ArrayCountIntXT_doInt(_regLookupPluginArmor1, _regLookupPluginArmor2, _regLookupPluginArmor3, _regLookupPluginArmor4, myInt)
		return DoCount
	else
		return -1
	endif
	
endFunction

int function ArrayAddIntXT_doInt(Int[] fArray1, Int[] fArray2, Int[] fArray3, Int[] fArray4, Int myInt)
	;-----------\
    ;Description \  Author: Chesko
    ;----------------------------------------------------------------
    ;Adds a Int to the first available element in the first available array
	;associated with this ArrayID.
    
	;-------------\
    ;Return Values \
    ;----------------------------------------------------------------
    ;               -1	           =               Error (array full)
    ;               >=0            =               Index of new item
		
	int i = 0
	;notification("myArray.Length = " + myArray.Length)
    while i < fArray1.Length
        if fArray1[i] == -1
            fArray1[i] = myInt
            ;notification("Adding " + myInt + " to the array.")
            return i
        else
            i += 1
        endif
    endWhile
    
	i = 0
	while i < fArray2.Length
        if fArray2[i] == -1
            fArray2[i] = myInt
            ;notification("Adding " + myInt + " to the array.")
            return i + 128
        else
            i += 1
        endif
    endWhile
	
	i = 0
	while i < fArray3.Length
        if fArray3[i] == -1
            fArray3[i] = myInt
            ;notification("Adding " + myInt + " to the array.")
            return i + 256
        else
            i += 1
        endif
    endWhile
	
	i = 0
	while i < fArray4.Length
        if fArray4[i] == -1
            fArray4[i] = myInt
            ;notification("Adding " + myInt + " to the array.")
            return i + 384
        else
            i += 1
        endif
    endWhile
	
    return -1			;All arrays are full
	
endFunction

bool function ArrayRemoveIntXT_doInt(Int[] fArray1, Int[] fArray2, Int[] fArray3, Int[] fArray4, Int myInt, string ArrayID, bool bSort = true)
	
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Removes a Int from the array, if found.
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false		=		Error (Int not found)
	;		true		=		Success

	int i = 0
	while i < fArray1.Length
		if fArray1[i] == myInt
			fArray1[i] = -1
			;notification("Removing element " + i)
			if bSort == true
				ArraySortXT(ArrayID)
			endif
			return true
		else
			i += 1
		endif
	endWhile

	i = 0
	while i < fArray2.Length
		if fArray2[i] == myInt
			fArray2[i] = -1
			;notification("Removing element " + i)
			if bSort == true
				ArraySortXT(ArrayID)
			endif
			return true
		else
			i += 1
		endif
	endWhile		

	i = 0
	while i < fArray3.Length
		if fArray3[i] == myInt
			fArray3[i] = -1
			;notification("Removing element " + i)
			if bSort == true
				ArraySortXT(ArrayID)
			endif
			return true
		else
			i += 1
		endif
	endWhile	
	
	i = 0
	while i < fArray4.Length
		if fArray4[i] == myInt
			fArray4[i] = -1
			;notification("Removing element " + i)
			if bSort == true
				ArraySortXT(ArrayID)
			endif
			return true
		else
			i += 1
		endif
	endWhile	
	
	return false
	
endFunction

bool function ArrayHasIntXT_doInt(Int[] fArray1, Int[] fArray2, Int[] fArray3, Int[] fArray4, Int myInt)
	
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Attempts to find the given Int in the associated array ID, and returns true if found
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false					= 		Int not found
	;		true			 		=		Int found
	
	int i = 0
	while i < fArray1.Length
		if fArray1[i] == myInt
			return true
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray2.Length
		if fArray2[i] == myInt
			return true
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray3.Length
		if fArray3[i] == myInt
			return true
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray4.Length
		if fArray4[i] == myInt
			return true
		else
			i += 1
		endif
	endWhile
	
	return false

endFunction

int function ArrayFindIntXT_doInt(int[] fArray1, int[] fArray2, int[] fArray3, int[] fArray4, int myint)
	;;Debug.Trace("MFXRegistry: ArrayFindIntXT_doInt(myint: " + myint)
	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Attempts to find the given int in the associated array ID, and returns its index if found
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		-1						= 		int not found
	;		0-511			 		=		int index
	
	
	int iFI = -1
	
	iFI = fArray1.Find(myint)
	if iFI >= 0 
		return iFI
	endif

	iFI = fArray2.Find(myint)
	if iFI >= 0 
		return iFI + 128
	endif

	iFI = fArray3.Find(myint)
	if iFI >= 0 
		return iFI + 256
	endif

	iFI = fArray4.Find(myint)
	if iFI >= 0 
		return iFI + 384
	endif

	return -1

endFunction

function ArrayClearXT_doInt(Int[] fArray1, Int[] fArray2, Int[] fArray3, Int[] fArray4)

	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Deletes the contents of arrays.
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		0

	int i = 0
	while i < fArray1.Length
		fArray1[i] = -1
		i += 1
	endWhile
	
	i = 0
	while i < fArray2.Length
		fArray2[i] = -1
		i += 1
	endWhile
	
	i = 0
	while i < fArray3.Length
		fArray3[i] = -1
		i += 1
	endWhile
	
	i = 0
	while i < fArray4.Length
		fArray4[i] = -1
		i += 1
	endWhile
	
endFunction

int function ArrayCountXT_doInt(Int[] fArray1, Int[] fArray2, Int[] fArray3, Int[] fArray4)

	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Counts the number of indicies associated with this array ID that do not have a "0" type
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		int myCount = number of indicies that are not "0"

	int myCount = 0
	
	int i = 0
	while i < fArray1.Length
		if fArray1[i] != -1
			myCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray2.Length
		if fArray2[i] != -1
			myCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray3.Length
		if fArray3[i] != -1
			myCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray4.Length
		if fArray4[i] != -1
			myCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	;notification("MyCount = " + myCount)	
	
	return myCount
	
endFunction

int function ArrayCountIntXT_doInt(Int[] fArray1, Int[] fArray2, Int[] fArray3, Int[] fArray4, Int myInt)

	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Attempts to count the number of times the given Int appears in the arrays associated with the Array ID.
        
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;               0			=               Int not found
	;               int i		=               Number of times Int appears in array
    
	int iCount = 0
    
	int i = 0
	while i < fArray1.Length
		if fArray1[i] == myInt
			iCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray2.Length
		if fArray2[i] == myInt
			iCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray3.Length
		if fArray3[i] == myInt
			iCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
	
	i = 0
	while i < fArray4.Length
		if fArray4[i] == myInt
			iCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile
        
	return iCount
        
endFunction

bool function ArraySortXT_doInt(Int[] fArray1, Int[] fArray2, Int[] fArray3, Int[] fArray4, int i = 0)

	;-----------\
	;Description \  Author: Chesko
	;----------------------------------------------------------------
	;Removes blank elements by shifting all elements down, moving elements
	;to arrays "below" the current one if necessary.
	;Optionally starts sorting from element i.
	
	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;                 false        =           No sorting required
	;                 true         =           Success

	
	
	
	;notification("Sort Start")
	bool bFirst0Found = false
	int iFirst0FoundArray = 0
	int iFirst0Pos = 0
	while i < 512
		;Which array am I looking in?
		int j = 0					;Actual array index to check
		int myCurrArray				;Current array
		if i < 128
			myCurrArray = 1
			j = i
		elseif i < 256 && i >= 128
			j = i - 128
			myCurrArray = 2
		elseif i < 384 && i >= 256
			j = i - 256
			myCurrArray = 3
		elseif i < 512 && i >= 384
			j = i - 384
			myCurrArray = 4
		endif
		
		if myCurrArray == 1
			if fArray1[j] == -1
				if bFirst0Found == false
					bFirst0Found = true
					iFirst0FoundArray = myCurrArray
					iFirst0Pos = j
					i += 1
				else
					i += 1
				endif
			else
				if bFirst0Found == true
					;check to see if it's a couple of blank entries in a row
					if !(fArray1[j] == -1)
						;notification("Moving element " + i + " to index " + iFirst0Pos)
						if iFirst0FoundArray == 1
							fArray1[iFirst0Pos] = fArray1[j]
							fArray1[j] = -1
						elseif iFirst0FoundArray == 2
							fArray2[iFirst0Pos] = fArray1[j]
							fArray1[j] = -1
						elseif iFirst0FoundArray == 3
							fArray3[iFirst0Pos] = fArray1[j]
							fArray1[j] = -1
						elseif iFirst0FoundArray == 4
							fArray4[iFirst0Pos] = fArray1[j]
							fArray1[j] = -1
						endif
						;Call this function recursively until it returns
						ArraySortXT_doInt(fArray1, fArray2, fArray3, fArray4, iFirst0Pos + 1)
						return true
					else
						i += 1
					endif
				else
					i += 1
				endif
			endif
		elseif myCurrArray == 2
			if fArray2[j] == -1
				if bFirst0Found == false
					bFirst0Found = true
					iFirst0FoundArray = myCurrArray
					iFirst0Pos = j
					i += 1
				else
					i += 1
				endif
			else
				if bFirst0Found == true
					;check to see if it's a couple of blank entries in a row
					if !(fArray2[j] == -1)
						;notification("Moving element " + i + " to index " + iFirst0Pos)
						if iFirst0FoundArray == 1
							fArray1[iFirst0Pos] = fArray2[j]
							fArray2[j] = -1
						elseif iFirst0FoundArray == 2
							fArray2[iFirst0Pos] = fArray2[j]
							fArray2[j] = -1
						elseif iFirst0FoundArray == 3
							fArray3[iFirst0Pos] = fArray2[j]
							fArray2[j] = -1
						elseif iFirst0FoundArray == 4
							fArray4[iFirst0Pos] = fArray2[j]
							fArray2[j] = -1
						endif
						;Call this function recursively until it returns
						ArraySortXT_doInt(fArray1, fArray2, fArray3, fArray4, iFirst0Pos + 1)
						return true
					else
						i += 1
					endif
				else
					i += 1
				endif
			endif
		elseif myCurrArray == 3
			if fArray3[j] == -1
				if bFirst0Found == false
					bFirst0Found = true
					iFirst0FoundArray = myCurrArray
					iFirst0Pos = j
					i += 1
				else
					i += 1
				endif
			else
				if bFirst0Found == true
					;check to see if it's a couple of blank entries in a row
					if !(fArray3[j] == -1)
						;notification("Moving element " + i + " to index " + iFirst0Pos)
						if iFirst0FoundArray == 1
							fArray1[iFirst0Pos] = fArray3[j]
							fArray3[j] = -1
						elseif iFirst0FoundArray == 2
							fArray2[iFirst0Pos] = fArray3[j]
							fArray3[j] = -1
						elseif iFirst0FoundArray == 3
							fArray3[iFirst0Pos] = fArray3[j]
							fArray3[j] = -1
						elseif iFirst0FoundArray == 4
							fArray4[iFirst0Pos] = fArray3[j]
							fArray3[j] = -1
						endif
						;Call this function recursively until it returns
						ArraySortXT_doInt(fArray1, fArray2, fArray3, fArray4, iFirst0Pos + 1)
						return true
					else
						i += 1
					endif
				else
					i += 1
				endif
			endif
		elseif myCurrArray == 4
			if fArray4[j] == -1
				if bFirst0Found == false
					bFirst0Found = true
					iFirst0FoundArray = myCurrArray
					iFirst0Pos = j
					i += 1
				else
					i += 1
				endif
			else
				if bFirst0Found == true
					;check to see if it's a couple of blank entries in a row
					if !(fArray4[j] == -1)
						;notification("Moving element " + i + " to index " + iFirst0Pos)
						if iFirst0FoundArray == 1
							fArray1[iFirst0Pos] = fArray4[j]
							fArray4[j] = -1
						elseif iFirst0FoundArray == 2
							fArray2[iFirst0Pos] = fArray4[j]
							fArray4[j] = -1
						elseif iFirst0FoundArray == 3
							fArray3[iFirst0Pos] = fArray4[j]
							fArray4[j] = -1
						elseif iFirst0FoundArray == 4
							fArray4[iFirst0Pos] = fArray4[j]
							fArray4[j] = -1
						endif
						;Call this function recursively until it returns
						ArraySortXT_doInt(fArray1, fArray2, fArray3, fArray4, iFirst0Pos + 1)
						return true
					else
						i += 1
					endif
				else
					i += 1
				endif
			endif
		endif
	endWhile
	
	return false

endFunction


Function InitRegistryArrays()
;--Registry arrays

	_regSlots1 					= New Int[128]					
	_regArmors1 				= New Form[128]					
	_regPlugins1 				= New Form[128]					
	_regRaces1 					= New Form[128]					
	_regLookupSlotRace1 		= New Int[128]		
	_regLookupRace1 			= New Int[128]		
	_regLookupPlugin1 			= New Int[128]		
	_regLookupArmor1 			= New Int[128]		
	_regLookupSlot1 			= New Int[128]		
	_regLookupRaceSlot1 		= New Int[128]		
	_regLookupPluginRace1 		= New Int[128]		
	_regLookupRacePlugin1 		= New Int[128]		
	_regLookupPluginSlot1 		= New Int[128]		
	_regLookupSlotPlugin1 		= New Int[128]		
	_regLookupArmorSlot1 		= New Int[128]		
	_regLookupSlotArmor1 		= New Int[128]		
	_regLookupArmorPlugin1 		= New Int[128]		
	_regLookupPluginArmor1 		= New Int[128]		

	_regSlots2 					= New Int[128]					
	_regArmors2 				= New Form[128]					
	_regPlugins2 				= New Form[128]					
	_regRaces2 					= New Form[128]					
	_regLookupRace2 			= New Int[128]		
	_regLookupPlugin2 			= New Int[128]		
	_regLookupArmor2 			= New Int[128]		
	_regLookupSlot2 			= New Int[128]		
	_regLookupSlotRace2 		= New Int[128]		
	_regLookupRaceSlot2 		= New Int[128]		
	_regLookupPluginRace2 		= New Int[128]		
	_regLookupRacePlugin2 		= New Int[128]		
	_regLookupPluginSlot2 		= New Int[128]		
	_regLookupSlotPlugin2 		= New Int[128]		
	_regLookupArmorSlot2 		= New Int[128]		
	_regLookupSlotArmor2 		= New Int[128]		
	_regLookupArmorPlugin2 		= New Int[128]		
	_regLookupPluginArmor2 		= New Int[128]		

	_regSlots3 					= New Int[128]					
	_regArmors3 				= New Form[128]					
	_regPlugins3 				= New Form[128]					
	_regRaces3 					= New Form[128]					
	_regLookupRace3 			= New Int[128]		
	_regLookupPlugin3 			= New Int[128]		
	_regLookupArmor3 			= New Int[128]		
	_regLookupSlot3 			= New Int[128]		
	_regLookupSlotRace3 		= New Int[128]		
	_regLookupRaceSlot3 		= New Int[128]		
	_regLookupPluginRace3 		= New Int[128]		
	_regLookupRacePlugin3 		= New Int[128]		
	_regLookupPluginSlot3 		= New Int[128]		
	_regLookupSlotPlugin3 		= New Int[128]		
	_regLookupArmorSlot3 		= New Int[128]		
	_regLookupSlotArmor3 		= New Int[128]		
	_regLookupArmorPlugin3 		= New Int[128]		
	_regLookupPluginArmor3 		= New Int[128]		

	_regSlots4 					= New Int[128]					
	_regArmors4 				= New Form[128]					
	_regPlugins4 				= New Form[128]					
	_regRaces4 					= New Form[128]					
	_regLookupRace4 			= New Int[128]		
	_regLookupPlugin4 			= New Int[128]		
	_regLookupArmor4 			= New Int[128]		
	_regLookupSlot4 			= New Int[128]		
	_regLookupSlotRace4 		= New Int[128]		
	_regLookupRaceSlot4 		= New Int[128]		
	_regLookupPluginRace4 		= New Int[128]		
	_regLookupRacePlugin4 		= New Int[128]		
	_regLookupPluginSlot4 		= New Int[128]		
	_regLookupSlotPlugin4 		= New Int[128]		
	_regLookupArmorSlot4 		= New Int[128]		
	_regLookupSlotArmor4 		= New Int[128]		
	_regLookupArmorPlugin4 		= New Int[128]		
	_regLookupPluginArmor4 		= New Int[128]		
	;--End Registry arrays

	Int i = 0
	While i < 128
		_regSlots1[i] = -1
		_regLookupSlotRace1[i] = -1
		_regLookupRace1[i] = -1
		_regLookupPlugin1[i] = -1
		_regLookupArmor1[i] = -1
		_regLookupSlot1[i] = -1
		_regLookupRaceSlot1[i] = -1
		_regLookupPluginRace1[i] = -1
		_regLookupRacePlugin1[i] = -1
		_regLookupPluginSlot1[i] = -1
		_regLookupSlotPlugin1[i] = -1
		_regLookupArmorSlot1[i] = -1
		_regLookupSlotArmor1[i] = -1
		_regLookupArmorPlugin1[i] = -1
		_regLookupPluginArmor1[i] = -1

		_regSlots2[i] = -1
		_regLookupRace2[i] = -1
		_regLookupPlugin2[i] = -1
		_regLookupArmor2[i] = -1
		_regLookupSlot2[i] = -1
		_regLookupSlotRace2[i] = -1
		_regLookupRaceSlot2[i] = -1
		_regLookupPluginRace2[i] = -1
		_regLookupRacePlugin2[i] = -1
		_regLookupPluginSlot2[i] = -1
		_regLookupSlotPlugin2[i] = -1
		_regLookupArmorSlot2[i] = -1
		_regLookupSlotArmor2[i] = -1
		_regLookupArmorPlugin2[i] = -1
		_regLookupPluginArmor2[i] = -1

		_regSlots3[i] = -1
		_regLookupRace3[i] = -1
		_regLookupPlugin3[i] = -1
		_regLookupArmor3[i] = -1
		_regLookupSlot3[i] = -1
		_regLookupSlotRace3[i] = -1
		_regLookupRaceSlot3[i] = -1
		_regLookupPluginRace3[i] = -1
		_regLookupRacePlugin3[i] = -1
		_regLookupPluginSlot3[i] = -1
		_regLookupSlotPlugin3[i] = -1
		_regLookupArmorSlot3[i] = -1
		_regLookupSlotArmor3[i] = -1
		_regLookupArmorPlugin3[i] = -1
		_regLookupPluginArmor3[i] = -1

		_regSlots4[i] = -1
		_regLookupRace4[i] = -1
		_regLookupPlugin4[i] = -1
		_regLookupArmor4[i] = -1
		_regLookupSlot4[i] = -1
		_regLookupSlotRace4[i] = -1
		_regLookupRaceSlot4[i] = -1
		_regLookupPluginRace4[i] = -1
		_regLookupRacePlugin4[i] = -1
		_regLookupPluginSlot4[i] = -1
		_regLookupSlotPlugin4[i] = -1
		_regLookupArmorSlot4[i] = -1
		_regLookupSlotArmor4[i] = -1
		_regLookupArmorPlugin4[i] = -1
		_regLookupPluginArmor4[i] = -1
		i += 1
	EndWhile
	
EndFunction