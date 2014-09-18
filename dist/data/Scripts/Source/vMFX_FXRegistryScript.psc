Scriptname vMFX_FXRegistryScript extends Quest  
{Track all registered mount FX and plugin content}

;--=== Imports ===--

Import Utility
Import Game
Import vMFX_Registry

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

String[] Property SlotNames Hidden
	String[] Function Get()
		Int i = 30
		String[] sReturn = New String[128]
		While i < 64
			Int iN = 0
			Int jNames = GetRegObj("Slots." + i + ".Names")
			While iN < JArray.Count(jNames)
				sReturn[i] = sReturn[i] + JArray.GetStr(jNames,iN) + "/"
				iN += 1
			EndWhile
			i += 1
		EndWhile
		Return sReturn
	EndFunction
EndProperty

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
;String[] 	SlotNames

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
	Debug.Trace("MFX/FXRegistry: OnInit!")
	OnGameReload()
EndEvent

Event OnGameReload()
	RegisterForModEvent("vMFX_MFXPluginMessage", "OnMFXPluginMessage")
	RegisterForModEvent("vMFX_MFXOutfitUpdated", "OnMFXPOutfitUpdated")
EndEvent

Event OnMFXPluginMessage(String eventName, String strArg, Float numArg, Form sender)
	;Debug.Trace("MFX/FXRegistry: OnMFXPluginMessage(" + eventName + "," + strArg + "," + numArg + "," + sender + ")")
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
	Debug.Trace("MFX/FXRegistry: OnReset!")
EndEvent

Event OnUpdate()
	_PluginPingCount = 0
	_StartTime = GetCurrentRealTime()
	Debug.Trace("MFX/FXRegistry: Registering plugins at priority " + _iPriorityCheck + "...")
	SendModEvent("vMFX_MFXRegistryReady")
	Int WaitTimer = 0
	Int WaitMax = 60
	While (_PluginReadyCount <  _PluginPingCount || _PluginPingCount == 0) && WaitTimer < WaitMax
		;Debug.Trace("MFX/FXRegistry: " + _PluginReadyCount + "/" + _PluginPingCount + " plugins registered...")
		WaitMenuMode(1)
		WaitTimer += 1
	EndWhile
	If WaitTimer >= WaitMax
		Debug.Trace("MFX/FXRegistry: WARNING! Plugin registration timed out with only " + _PluginReadyCount + "/" + _PluginPingCount + " plugins registered!")
		Debug.Notification("MountFX timed out while registering one or more of your installed plugins. This could be due to a problem with a plugin, or a plugin that adds a huge number of effects.")
	EndIf
	Debug.Trace("MFX/FXRegistry: " + _PluginReadyCount + "/" + _PluginPingCount + " plugins registered in " + (GetCurrentRealTime() - _StartTime) + "s.")
	SendModEvent("vMFX_MFXUpdateMCM")
EndEvent


;--=== Functions ===--

Function Initialize(Bool bFirstTime = False)
	GotoState("Busy")

	Debug.Trace("MFX/FXRegistry: Initializing!")
	
	If bFirstTime
		ResetRegistry()
	EndIf
	
	GotoState("")
	RegisterForSingleUpdate(10.1)
	Debug.Trace("MFX/FXRegistry: Initialization complete!")
EndFunction

Function ResetRegistry()
	Debug.Trace("MFX/FXRegistry:  Resetting registry...")
	
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

;	SlotNames = New String[128]
	
	Debug.Trace("MFX/FXRegistry:  Reset complete!")
EndFunction

Function SetRaceFilter(Race akFilterRace)
	Float StartTime = GetCurrentRealTime()
	vMFX_regSortPluginsByRace.Revert()
	vMFX_regSortArmorsByRace.Revert()
	vMFX_FXPluginBase MFXPlugin
	Debug.Trace("MFX/FXRegistry: Setting race filter to " + akFilterRace.GetName())
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
	Debug.Trace("MFX/FXRegistry: Race filter took " + (GetCurrentRealTime() - StartTime) + "s to process.")
	Debug.Trace("MFX/FXRegistry: " + vMFX_regSortPluginsByRace.GetSize() + "/" + vMFX_regFXPlugins.GetSize() + " plugins added to filtered list.")
	Debug.Trace("MFX/FXRegistry: " + vMFX_regSortArmorsByRace.GetSize() + "/" + vMFX_regArmors.GetSize() + " armors added to filtered list.")
EndFunction

Int Function RegisterPlugin(vMFX_FXPluginBase MFXPlugin)
	GoToState("Busy")
	String infoPluginName = MFXPlugin.infoPluginName
	String infoESPFile = MFXPlugin.infoESPFile
	If StringUtil.Find(infoESPFile,".esp") > -1
		infoESPFile = StringUtil.Substring(infoESPFile,0,StringUtil.GetLength(infoESPFile) - 4)
	EndIf
	_LockedBy = infoESPFile + " - '" + infoPluginName + "'"
	Debug.Trace("MFX/FXRegistry: Checking for plugin " + infoESPFile + "/" + infoPluginName)
	If !HasRegKey("Plugins." + infoESPFile + "." + infoPluginName)
		SetRegForm("Plugins." + infoESPFile + "." + infoPluginName + ".Form",MFXPlugin)
	EndIf
	Debug.Trace("MFX/FXRegistry:  Plugin added!")
	
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
		Debug.Trace("MFX/FXRegistry:  Registering " + MFXPlugin.dataArmorNewSlotNumbers.Length + " ArmorSlots from '" + infoPluginName + "'")
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
			Debug.Trace("MFX/FXRegistry: " + MFXPlugin.infoPluginName + " registered " + Result + " forms for " + MFXPlugin.dataRaces[iRace].GetName() + "!")
			iDFL += 1
		EndWhile
		iRace += 1
	EndWhile

	If MaxPriority < MFXPlugin.infoPriority
		MaxPriority = MFXPlugin.infoPriority
	EndIf

	_LockedBy = ""
	GotoState("")
	Return 1
EndFunction

Int Function RegisterRace(vMFX_FXPluginBase MFXPlugin, Race akRace)
	String RaceName = akRace.GetName()
	String sESPFile = MFXPlugin.infoESPFile
	If StringUtil.Find(sESPFile,".esp") > -1
		sESPFile = StringUtil.Substring(sESPFile,0,StringUtil.GetLength(sESPFile) - 4)
	EndIf
	String KeyName = "Plugins." + sESPFile + "." + MFXPlugin.infoPluginName + ".Races"

	Int jRaceArray = GetRegObj(KeyName)
	If !jRaceArray
		jRaceArray = JArray.Object()
		SetRegObj(KeyName,jRaceArray)
	EndIf

	Int iResult = JArray.FindForm(jRaceArray,akRace)
	If iResult < 0
		JArray.AddForm(jRaceArray,akRace)
		iResult = JArray.Count(jRaceArray) - 1
	EndIf

	regLinkPluginRace(MFXPlugin,akRace)
	
	Return iResult
EndFunction

Int Function RegisterFXFormList(vMFX_FXPluginBase MFXPlugin, Formlist akFXList, Race akRace = None)
	;GotoState("Busy")
	If !akFXList
		Return 0
	EndIf
	_LockedBy = MFXPlugin.infoPluginName
	If !_LockedBy
		_LockedBy = "Unknown"
	EndIf
	Int iTotal = 0
	Int iIndex = 0
	While iIndex < akFXList.GetSize()
		If akFXList.GetAt(iIndex) As FormList != None
			;Debug.Trace("MFX/FXRegistry: Processing Formlist " + akFXList.GetAt(iIndex))
			iTotal += RegisterFXFormList(MFXPlugin, akFXList.GetAt(iIndex) as FormList, akRace)
			;ProcessFXFormList
		ElseIf akFXList.GetAt(iIndex) As Spell != None
			;Debug.Trace("MFX/FXRegistry: Processing Spell " + akFXList.GetAt(iIndex))
			iTotal += 1
			Int Result = RegisterSpell(MFXPlugin, akRace, akFXList.GetAt(iIndex) As Spell)
		ElseIf akFXList.GetAt(iIndex) As Armor != None
			;Debug.Trace("MFX/FXRegistry: Processing Armor " + akFXList.GetAt(iIndex))
			Int NumSlots = RegisterArmor(MFXPlugin,akRAce,akFXList.GetAt(iIndex) as Armor)
			;Bool Success = RegisterArmorSlot(sPluginName, akRace, (akFXList.GetAt(iIndex) As Armor).GetNthArmorAddon(0), String sSlotName, Bool bOverwrite = False)
			iTotal += 1
			;ProcessArmor
		Else ; If kReference.IsDisabled() 
			Debug.Trace("MFX/FXRegistry: Unknown form type encountered - " + akFXList.GetAt(iIndex))
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
		;Debug.Trace("MFX/FXRegistry: Armor " + akArmor.GetName() + "/" + i + " has mask " + iFXArmorAASlotMask)
		int h = 0x00000001
		while (h < 0x80000000)
			if Math.LogicalAND(iFXArmorAASlotMask, h)
				;Debug.Trace("MFX/FXRegistry: Checking ArmorSlot " + h + " from " + MFXPlugin.infoESPFile + "/" + MFXPlugin.infoPluginName + "/" + akArmor.GetName())
				Bool bResult = CheckArmorSlot(MFXPlugin,akRace,h)
				iBipedSlot = GetBipedFromSlotMask(h)
				If bResult && MFXPlugin.dataArmorNewSlotNumbers.Find(iBipedSlot) >= 0
					;;Debug.Trace("MFXRegistry: Added " + iBipedSlot + ",iSlotCount is " + iSlotCount)
					iArmorSlots[iSlotCount] = iBipedSlot
					iSlotCount += 1
				ElseIf bResult && MFXPlugin.dataArmorSlotsUsed.Find(iBipedSlot) >= 0
					;Mod lists this slot as being used, just not registered to it.
				Else
					Debug.Trace("MFX/FXRegistry: " + MFXPlugin.infoESPFile + "/" + MFXPlugin.infoPluginName + "/" + akArmor.GetName() + ". Slot " + iBipedSlot + " is not registered or listed by plugin.")
					NumFailures += 1
				EndIf
			endIf
			h = Math.LeftShift(h,1)
		endWhile
		i += 1
	EndWhile
	
	If NumFailures
		Debug.Trace("MFX/FXRegistry: WARNING! Armor " + MFXPlugin.infoESPFile + "/" + MFXPlugin.infoPluginName + "/" + akArmor.GetName() + " rejected due to " + NumFailures + " unregistered slot(s)!")
		Return 0
	EndIf

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
;	Debug.Trace("MFX/FXRegistry: CheckArmorSlot(" + MFXPlugin + ", " + akRace + ", " + iArmorSlot + ")")
	Bool bFail = False
	String bFailReason = ""

	Int iBipedSlot = GetBipedFromSlotMask(iArmorSlot)
	
	vMFX_FXPluginBase[] PluginsForSlot = regGetPluginsForSlot(iBipedSlot)
	
	If PluginsForSlot.Find(MFXPlugin) >= 0
		Int iSlotNameIndex = MFXPlugin.dataArmorNewSlotNumbers.Find(iBipedSlot)
		;Debug.Trace("MFX/FXRegistry: " + MFXPlugin.infoPluginName + " registered slot " + iBipedSlot + " as " + MFXPlugin.dataArmorNewSlotNames[iSlotNameIndex])
	ElseIf MFXPlugin.dataArmorSlotsUsed.Find(iBipedSlot) > 0 
		; Plugin didn't register the slot but is aware of its use
		;Debug.Trace("MFX/FXRegistry: " + MFXPlugin.infoPluginName + " is using slot " + iBipedSlot + " without registering it.")
	Else 
		; plugin hasn't registered for this slot and doesn't think it's using it.
		bFail = True
		bFailReason = MFXPlugin.infoPluginName + " does not know it's using slot " + iBipedSlot + "!!"
	EndIf
	
	If bFail
		;GotoState("")
		Debug.Trace("MFX/FXRegistry: ArmorSlot check FAILED - " + bFailReason)
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
	;Debug.Trace("MFX/FXRegistry: RegisterArmorSlot(" + MFXPlugin + ", " + akRace + ", " + iArmorSlot + ", " + sSlotName + ")")
	
	Bool bFail = False
	String bFailReason = ""

	If !JValue.IsMap(GetRegObj("Slots." + iBipedSlot))
		Debug.Trace("MFX/FXRegistry/RegisterArmorSlot: Creating slot " + iBipedSlot + " from " + MFXPlugin.infoPluginName)
		SetRegObj("Slots." + iBipedSlot + ".Plugins",JArray.Object())
		SetRegObj("Slots." + iBipedSlot + ".Races",JArray.Object())
		SetRegObj("Slots." + iBipedSlot + ".Armors",JArray.Object())
		SetRegObj("Slots." + iBipedSlot + ".Names",JArray.Object())
	EndIf
	
	Int jSlot = GetRegObj("Slots." + iBipedSlot)

	If !jSlot
		bFail = True
		bFailReason = "Couldn't get a valid JObject for " + iBipedSlot
	EndIf

	Int jSlotNames = GetRegObj("Slots." + iBipedSlot + ".Names")
	Int jSlotRaces = GetRegObj("Slots." + iBipedSlot + ".Races")
	Int jSlotPlugins = GetRegObj("Slots." + iBipedSlot + ".Plugins")
	Int jSlotArmors = GetRegObj("Slots." + iBipedSlot + ".Armors")
	
	If !bFail
		If sSlotName && JArray.FindStr(jSlotNames,sSlotName) < 0
			JArray.AddStr(jSlotNames,sSlotName)
		EndIf
		If akRace && JArray.FindForm(jSlotRaces,akRace) < 0
			JArray.Addform(jSlotRaces,akRace)
		EndIf
		If MFXPlugin && JArray.FindForm(jSlotPlugins,MFXPlugin) < 0
			JArray.Addform(jSlotPlugins,MFXPlugin)
		EndIf
		regLinkPluginSlot(MFXPlugin,iBipedSlot)
		regLinkRaceSlot(akRace,iBipedSlot)
		Debug.Trace("MFX/FXRegistry: Registered ArmorSlot " + sSlotName + "(" + iBipedSlot + ")")
	EndIf
		
	If bFail
		;GotoState("")
		Debug.Trace("MFX/FXRegistry: ArmorSlot registration failed - " + bFailReason)
		Return False
	EndIf

	Return True
EndFunction

Function SpinLock(String sFunctionName,String sRequestorName)
	Float StartTime = GetCurrentRealTime()
	Debug.Trace("MFX/FXRegistry: " + sFunctionName + " called by " + sRequestorName + " but is locked by " + _LockedBy + ". Waiting...")
	Int Timer = 0
	While GetState() == "Busy" && Timer < 100
		WaitMenuMode(0.1)
		;If Timer % 10 == 0
			;Debug.Trace("MFX/FXRegistry: " + sFunctionName + " still locked after " + (Timer / 10) + "s. Waiting...")
		;EndIf
		Timer += 1
	EndWhile
	Debug.Trace("MFX/FXRegistry: " + sFunctionName + " unlocked after " + (GetCurrentRealTime() - StartTime) + "s. Processing request from " + sRequestorName)
EndFunction

String Function GetSlotNameForRace(Race akRace, int iArmorSlot)
	Debug.Trace("MFX/FXRegistry: GetSlotNameForRace(" + akRace + "," + iArmorSlot + ")")
	Int i = 0
	Int iRace = _RaceIndex.Find(akRace)
	Debug.Trace("MFX/FXRegistry:  iRace: " + iRace)
	While i >= 0 && i < _SlotRaceIndex.Length
		i = _SlotRaceIndex.Find(iRace,i)
		Debug.Trace("MFX/FXRegistry:   Race search returned i: " + i)
		If i >= 0 && _SlotArmorSlotIndex[i] == iArmorSlot
			Debug.Trace("MFX/FXRegistry:   ArmorSlot matched at i: " + i)
			Debug.Trace("MFX/FXRegistry:   _SlotArmorSlotNameIndex[i]: " + _SlotArmorSlotNameIndex[i])
			Return _SlotArmorSlotNameIndex[i]
		ElseIf i >= 0
			i += 1
		EndIf
	EndWhile
	Debug.Trace("MFX/FXRegistry:  Nothing found!")
	Return ""
EndFunction

String Function GetPluginForSlot(Race akRace, int iArmorSlot)
	Debug.Trace("MFX/FXRegistry: GetPluginForSlot(" + akRace + "," + iArmorSlot + ")")
	Int i = 0
	Int iRace = _RaceIndex.Find(akRace)
	Debug.Trace("MFX/FXRegistry:  iRace: " + iRace)
	While i >= 0 && i < _SlotRaceIndex.Length
		i = _SlotRaceIndex.Find(iRace,i)
		Debug.Trace("MFX/FXRegistry:   Race search returned i: " + i)
		If i >= 0 && _SlotArmorSlotIndex[i] == iArmorSlot
			Debug.Trace("MFX/FXRegistry:   ArmorSlot matched at i: " + i)
			Debug.Trace("MFX/FXRegistry:   _SlotPluginIndex[i]: " + _SlotPluginIndex[i])
			Debug.Trace("MFX/FXRegistry:   _PluginNameIndex[_SlotPluginIndex[i]]: " + _PluginNameIndex[_SlotPluginIndex[i]])
			Return _PluginNameIndex[_SlotPluginIndex[i]]
		ElseIf i >= 0
			i += 1
		EndIf
	EndWhile
	Debug.Trace("MFX/FXRegistry:  Nothing found!")
	Return ""
EndFunction

vMFX_FXPluginBase Function GetPluginForArmor(Armor akArmor)
	Debug.Trace("MFX/FXRegistry: GetPluginForArmor(" + akArmor + ")")
	Int i = 0
	Int j = 0
	Int iFI
	vMFX_FXPluginBase MFXPlugin
	While i < vMFX_regFXPlugins.GetSize()
		MFXPlugin = vMFX_regFXPlugins.GetAt(i) as vMFX_FXPluginBase
		j = 0
		While j < MFXPlugin.dataFormlists.Length
			If MFXPlugin.dataFormlists[j].HasForm(akArmor)
				Debug.Trace("MFX/FXRegistry:  Returning " + MFXPlugin.infoPluginName)
				Return MFXPlugin
			EndIf
			j += 1
		EndWhile
		i += 1
	EndWhile
	Debug.Trace("MFX/FXRegistry:  Nothing found!")
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
	Debug.Trace("MFX/FXRegistry: Getting index for Plugin " + sFilename)
	Int iResult = -1
	iResult = _PluginNameIndex.Find(sFilename)
	If iResult < 0
		Debug.Trace("MFX/FXRegistry: Plugin " + sFilename + " not yet registered, adding it to the index...")
		Int iNew = FindFreeIndexString(_PluginNameIndex)
		If iNew < 0
			Return iResult
		Else
			_PluginNameIndex[iNew] = sFileName
			iResult = iNew
			Debug.Trace("MFX/FXRegistry: Plugin added at index " + iResult)
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
		Debug.Trace("MFX/FXRegistry: WARNING! Plugin CurrentMount update timed out with only " + _PluginMountUpdateCount + "/" + _PluginReadyCount + " plugins reporting!")
	EndIf
	;Debug.Trace("MFX/FXRegistry: " + _PluginMountUpdateCount + "/" + _PluginReadyCount + " !")
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
			Debug.Trace("MFX/FXRegistry: Slot " + i + " is " + thisArmor + ", was " + lastArmor)
		EndIf
		If thisArmor != None
			;Debug.Trace("MFX/FXRegistry: Slot " + i + " is " + thisArmor + ", was " + lastArmor)
			If !CurrentMount.IsEquipped(thisArmor)
				; Was not equipped, but is now
				;GetPluginForArmor(thisArmor).HandleEquip(thisArmor)
				thisArmor.SendModEvent("vMFX_MFXArmorEquip","",i)
			EndIf
		ElseIf lastArmor != None
			;Debug.Trace("MFX/FXRegistry: Slot " + i + " is None, was " + lastArmor)
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
		Debug.Trace("MFX/FXRegistry: WARNING! Plugin equipment checks timed out with only " + _PluginArmorCheckCount + "/" + vMFX_regFXPlugins.GetSize() + " plugins checked!")
	EndIf
	Debug.Trace("MFX/FXRegistry: " + _PluginArmorCheckCount + "/" + SlotCount + " plugins checked!")
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


Function regLinkPluginRace(vMFX_FXPluginBase MFXPlugin, Race NewRace)
	;Create a link between Plugin and Race
	Int jLinkFormMap = GetRegObj("LinkFormMap")
	If !jLinkFormMap
		Debug.Trace("MFX/FXRegistry: Adding LinkFormMap JFormMap to registry...")
		jLinkFormMap = JFormMap.Object()
		SetRegObj("LinkFormMap",jLinkFormMap)
	EndIf
	
	Int jRaceLinks = JFormMap.GetObj(jLinkFormMap,NewRace)
	Int jPluginLinks = JFormMap.GetObj(jLinkFormMap,MFXPlugin)

	If !jRaceLinks
		Debug.Trace("MFX/FXRegistry: Adding RaceLinks JMap to " + NewRace + "...")
		jRaceLinks = JMap.Object()
		JFormMap.SetObj(jLinkFormMap,NewRace,jRaceLinks)
	EndIf

	If !jPluginLinks
		Debug.Trace("MFX/FXRegistry: Adding PluginLinks JMap to " + MFXPlugin + "...")
		jPluginLinks = JMap.Object()
		JFormMap.SetObj(jLinkFormMap,MFXPlugin,jPluginLinks)
	EndIf

	Int jRacePluginList = JMap.GetObj(jRaceLinks,"Plugins")
	If !jRacePluginList
		Debug.Trace("MFX/FXRegistry: Adding RacePluginList JArray to RaceLinks...")
		jRacePluginList = JArray.Object()
		JMap.SetObj(jRaceLinks,"Plugins",jRacePluginList)
	EndIf
	
	Int jPluginRaceList = JMap.GetObj(jPluginLinks,"Races")
	If !jPluginRaceList
		Debug.Trace("MFX/FXRegistry: Adding PluginRaceList JArray to PluginLinks...")
		jPluginRaceList = JArray.Object()
		JMap.SetObj(jPluginLinks,"Races",jPluginRaceList)
	EndIf
	
	If JArray.FindForm(jRacePluginList,MFXPlugin) < 0
		JArray.AddForm(jRacePluginList,MFXPlugin)
	EndIf
	If JArray.FindForm(jPluginRaceList,NewRace) < 0
		JArray.AddForm(jPluginRaceList,NewRace)
	EndIf

EndFunction

Function regLinkPluginArmor(vMFX_FXPluginBase MFXPlugin, Armor NewArmor)
	;Create a link between Plugin and Armor
	Int jLinkFormMap = GetRegObj("LinkFormMap")
	If !jLinkFormMap
		Debug.Trace("MFX/FXRegistry: Adding LinkFormMap JFormMap to registry...")
		jLinkFormMap = JFormMap.Object()
		SetRegObj("LinkFormMap",jLinkFormMap)
	EndIf
	
	Int jArmorLinks = JFormMap.GetObj(jLinkFormMap,NewArmor)
	Int jPluginLinks = JFormMap.GetObj(jLinkFormMap,MFXPlugin)

	If !jArmorLinks
		Debug.Trace("MFX/FXRegistry: Adding ArmorLinks JMap to " + NewArmor + "...")
		jArmorLinks = JMap.Object()
		JFormMap.SetObj(jLinkFormMap,NewArmor,jArmorLinks)
	EndIf

	If !jPluginLinks
		Debug.Trace("MFX/FXRegistry: Adding PluginLinks JMap to " + MFXPlugin + "...")
		jPluginLinks = JMap.Object()
		JFormMap.SetObj(jLinkFormMap,MFXPlugin,jPluginLinks)
	EndIf

	Int jArmorPluginList = JMap.GetObj(jArmorLinks,"Plugins")
	If !jArmorPluginList
		Debug.Trace("MFX/FXRegistry: Adding ArmorPluginList JArray to ArmorLinks...")
		jArmorPluginList = JArray.Object()
		JMap.SetObj(jArmorLinks,"Plugins",jArmorPluginList)
	EndIf
	
	Int jPluginArmorList = JMap.GetObj(jPluginLinks,"Armors")
	If !jPluginArmorList
		Debug.Trace("MFX/FXRegistry: Adding PluginArmorList JArray to PluginLinks...")
		jPluginArmorList = JArray.Object()
		JMap.SetObj(jPluginLinks,"Armors",jPluginArmorList)
	EndIf
	
	If JArray.FindForm(jArmorPluginList,MFXPlugin) < 0
		JArray.AddForm(jArmorPluginList,MFXPlugin)
	EndIf
	If JArray.FindForm(jPluginArmorList,NewArmor) < 0
		JArray.AddForm(jPluginArmorList,NewArmor)
	EndIf
EndFunction

Function regLinkPluginSlot(vMFX_FXPluginBase MFXPlugin, Int iBipedSlot)
	;Create a link between Plugin and BipedSlot
	Int jLinkFormMap = GetRegObj("LinkFormMap")
	If !jLinkFormMap
		Debug.Trace("MFX/FXRegistry: Adding LinkFormMap JFormMap to registry...")
		jLinkFormMap = JFormMap.Object()
		SetRegObj("LinkFormMap",jLinkFormMap)
	EndIf
	
	Int jSlotLinks = GetRegObj("Slots." + iBipedSlot)
	Int jPluginLinks = JFormMap.GetObj(jLinkFormMap,MFXPlugin)

	If !jSlotLinks
		Debug.Trace("MFX/FXRegistry: Adding SlotLinks JMap to " + iBipedSlot + "...")
		jSlotLinks = JMap.Object()
		SetRegObj("Slots." + iBipedSlot,jSlotLinks)
	EndIf

	If !jPluginLinks
		Debug.Trace("MFX/FXRegistry: Adding PluginLinks JMap to " + MFXPlugin + "...")
		jPluginLinks = JMap.Object()
		JFormMap.SetObj(jLinkFormMap,MFXPlugin,jPluginLinks)
	EndIf

	Int jSlotPluginList = JMap.GetObj(jSlotLinks,"Plugins")
	If !jSlotPluginList
		Debug.Trace("MFX/FXRegistry: Adding SlotPluginList JArray to SlotLinks...")
		jSlotPluginList = JArray.Object()
		JMap.SetObj(jSlotLinks,"Plugins",jSlotPluginList)
	EndIf
	
	Int jPluginSlotList = JMap.GetObj(jPluginLinks,"Slots")
	If !jPluginSlotList
		Debug.Trace("MFX/FXRegistry: Adding PluginSlotList JArray to PluginLinks...")
		jPluginSlotList = JArray.Object()
		JMap.SetObj(jPluginLinks,"Slots",jPluginSlotList)
	EndIf
	
	If JArray.FindForm(jSlotPluginList,MFXPlugin) < 0
		JArray.AddForm(jSlotPluginList,MFXPlugin)
	EndIf
	If JArray.FindInt(jPluginSlotList,iBipedSlot) < 0
		JArray.AddInt(jPluginSlotList,iBipedSlot)
	EndIf
EndFunction

Function regLinkArmorSlot(Armor NewArmor, Int iBipedSlot)
	;Create a link between Armor and BipedSlot
	Int jLinkFormMap = GetRegObj("LinkFormMap")
	If !jLinkFormMap
		Debug.Trace("MFX/FXRegistry: Adding LinkFormMap JFormMap to registry...")
		jLinkFormMap = JFormMap.Object()
		SetRegObj("LinkFormMap",jLinkFormMap)
	EndIf
	
	Int jSlotLinks = GetRegObj("Slots." + iBipedSlot)
	Int jArmorLinks = JFormMap.GetObj(jLinkFormMap,NewArmor)

	If !jSlotLinks
		Debug.Trace("MFX/FXRegistry: Adding SlotLinks JMap to " + iBipedSlot + "...")
		jSlotLinks = JMap.Object()
		SetRegObj("Slots." + iBipedSlot,jSlotLinks)
	EndIf

	If !jArmorLinks
		Debug.Trace("MFX/FXRegistry: Adding ArmorLinks JMap to " + NewArmor + "...")
		jArmorLinks = JMap.Object()
		JFormMap.SetObj(jLinkFormMap,NewArmor,jArmorLinks)
	EndIf

	Int jSlotArmorList = JMap.GetObj(jSlotLinks,"Armors")
	If !jSlotArmorList
		Debug.Trace("MFX/FXRegistry: Adding SlotArmorList JArray to SlotLinks...")
		jSlotArmorList = JArray.Object()
		JMap.SetObj(jSlotLinks,"Armors",jSlotArmorList)
	EndIf
	
	Int jArmorSlotList = JMap.GetObj(jArmorLinks,"Slots")
	If !jArmorSlotList
		Debug.Trace("MFX/FXRegistry: Adding ArmorSlotList JArray to ArmorLinks...")
		jArmorSlotList = JArray.Object()
		JMap.SetObj(jArmorLinks,"Slots",jArmorSlotList)
	EndIf
	
	If JArray.FindForm(jSlotArmorList,NewArmor) < 0
		JArray.AddForm(jSlotArmorList,NewArmor)
	EndIf
	If JArray.FindInt(jArmorSlotList,iBipedSlot) < 0
		JArray.AddInt(jArmorSlotList,iBipedSlot)
	EndIf
EndFunction

Function regLinkArmorRace(Armor NewArmor, Race NewRace)
	;Create a link between Armor and Race
	Int jLinkFormMap = GetRegObj("LinkFormMap")
	If !jLinkFormMap
		Debug.Trace("MFX/FXRegistry: Adding LinkFormMap JFormMap to registry...")
		jLinkFormMap = JFormMap.Object()
		SetRegObj("LinkFormMap",jLinkFormMap)
	EndIf
	
	Int jArmorLinks = JFormMap.GetObj(jLinkFormMap,NewArmor)
	Int jRaceLinks = JFormMap.GetObj(jLinkFormMap,NewRace)

	If !jArmorLinks
		Debug.Trace("MFX/FXRegistry: Adding ArmorLinks JMap to " + NewArmor + "...")
		jArmorLinks = JMap.Object()
		JFormMap.SetObj(jLinkFormMap,NewArmor,jArmorLinks)
	EndIf

	If !jRaceLinks
		Debug.Trace("MFX/FXRegistry: Adding RaceLinks JMap to " + NewRace + "...")
		jRaceLinks = JMap.Object()
		JFormMap.SetObj(jLinkFormMap,NewRace,jRaceLinks)
	EndIf

	Int jArmorRaceList = JMap.GetObj(jArmorLinks,"Races")
	If !jArmorRaceList
		Debug.Trace("MFX/FXRegistry: Adding ArmorRaceList JArray to ArmorLinks...")
		jArmorRaceList = JArray.Object()
		JMap.SetObj(jArmorLinks,"Races",jArmorRaceList)
	EndIf
	
	Int jRaceArmorList = JMap.GetObj(jRaceLinks,"Armors")
	If !jRaceArmorList
		Debug.Trace("MFX/FXRegistry: Adding RaceArmorList JArray to RaceLinks...")
		jRaceArmorList = JArray.Object()
		JMap.SetObj(jRaceLinks,"Armors",jRaceArmorList)
	EndIf
	
	If JArray.FindForm(jArmorRaceList,NewRace) < 0
		JArray.AddForm(jArmorRaceList,NewRace)
	EndIf
	If JArray.FindForm(jRaceArmorList,NewArmor) < 0
		JArray.AddForm(jRaceArmorList,NewArmor)
	EndIf
EndFunction

Function regLinkRaceSlot(Race NewRace,Int iBipedSlot)
	;Create a link between Race and BipedSlot
	Int jLinkFormMap = GetRegObj("LinkFormMap")
	If !jLinkFormMap
		Debug.Trace("MFX/FXRegistry: Adding LinkFormMap JFormMap to registry...")
		jLinkFormMap = JFormMap.Object()
		SetRegObj("LinkFormMap",jLinkFormMap)
	EndIf
	
	Int jSlotLinks = GetRegObj("Slots." + iBipedSlot)
	Int jRaceLinks = JFormMap.GetObj(jLinkFormMap,NewRace)

	If !jSlotLinks
		Debug.Trace("MFX/FXRegistry: Adding SlotLinks JMap to " + iBipedSlot + "...")
		jSlotLinks = JMap.Object()
		SetRegObj("Slots." + iBipedSlot,jSlotLinks)
	EndIf

	If !jRaceLinks
		Debug.Trace("MFX/FXRegistry: Adding RaceLinks JMap to " + NewRace + "...")
		jRaceLinks = JMap.Object()
		JFormMap.SetObj(jLinkFormMap,NewRace,jRaceLinks)
	EndIf

	Int jSlotRaceList = JMap.GetObj(jSlotLinks,"Races")
	If !jSlotRaceList
		Debug.Trace("MFX/FXRegistry: Adding SlotRaceList JArray to SlotLinks...")
		jSlotRaceList = JArray.Object()
		JMap.SetObj(jSlotLinks,"Races",jSlotRaceList)
	EndIf
	
	Int jRaceSlotList = JMap.GetObj(jRaceLinks,"Slots")
	If !jRaceSlotList
		Debug.Trace("MFX/FXRegistry: Adding RaceSlotList JArray to RaceLinks...")
		jRaceSlotList = JArray.Object()
		JMap.SetObj(jRaceLinks,"Slots",jRaceSlotList)
	EndIf
	
	If JArray.FindForm(jSlotRaceList,NewRace) < 0
		JArray.AddForm(jSlotRaceList,NewRace)
	EndIf
	If JArray.FindInt(jRaceSlotList,iBipedSlot) < 0
		JArray.AddInt(jRaceSlotList,iBipedSlot)
	EndIf
EndFunction

Race[] Function regGetRacesForSlot(Int iBipedSlot)
	;;Debug.Trace("MFXRegistry: Getting races for slot " + iBipedSlot)
	Race[] Races = New Race[128]
	Race kRace 
	Int i = 0
	Int iCount = 0
	Int jRacesForSlot = GetRegObj("Slots." + iBipedSlot + ".Races")
	Int iMax = JArray.Count(jRacesForSlot)
	While i < iMax
		kRace = JArray.GetForm(jRacesForSlot,i) as Race
		If kRace
			Races[iCount] = kRace
			iCount += 1
		EndIf
		i += 1
	EndWhile
	
	Return Races
EndFunction

vMFX_FXPluginBase[] Function regGetPluginsForSlot(Int iBipedSlot)
	vMFX_FXPluginBase[] Plugins = New vMFX_FXPluginBase[128]
	vMFX_FXPluginBase kPlugin 
	Int i = 0
	Int iCount = 0
	Int jPluginsForSlot = GetRegObj("Slots." + iBipedSlot + ".Plugins")
	Int iMax = JArray.Count(jPluginsForSlot)
	Debug.Trace("MFXRegistry: Plugins for slot " + iBipedSlot + ": " + iMax)
	While i < iMax
		kPlugin = JArray.GetForm(jPluginsForSlot,i) as vMFX_FXPluginBase
		If kPlugin
			Plugins[iCount] = kPlugin
			iCount += 1
		EndIf
		i += 1
	EndWhile
	
	Return Plugins
EndFunction

vMFX_FXPluginBase[] Function regGetPluginsForRace(Race akRace)
	;;Debug.Trace("MFXRegistry: Getting plugins for race " + akRace.GetName())
	vMFX_FXPluginBase[] Plugins = New vMFX_FXPluginBase[128]
	vMFX_FXPluginBase kPlugin 
	Int i = 0
	Int iCount = 0
	Int jPluginsForRace = JMap.GetObj(JFormMap.GetObj(GetRegObj("LinkFormMap"),akRace),"Plugins")
	Int iMax = JArray.Count(jPluginsForRace)
	While i < iMax
		kPlugin = JArray.GetForm(jPluginsForRace,i) as vMFX_FXPluginBase
		If kPlugin
			Plugins[iCount] = kPlugin
			iCount += 1
		EndIf
		i += 1
	EndWhile
	
	Return Plugins
EndFunction

vMFX_FXPluginBase Function regGetPluginForArmor(Armor akArmor)
	;;Debug.Trace("MFXRegistry: Getting plugins for race " + akArmor.GetName())
	vMFX_FXPluginBase kPlugin
	Int i = 0
	Int iCount = 0
	Int jPluginsForRace = JMap.GetObj(JFormMap.GetObj(GetRegObj("LinkFormMap"),akArmor),"Plugins")
	Int iMax = JArray.Count(jPluginsForRace)
	While i < iMax
		kPlugin = JArray.GetForm(jPluginsForRace,i) as vMFX_FXPluginBase
		If kPlugin
			Return kPlugin
			iCount += 1
		EndIf
		i += 1
	EndWhile
	
	Return None
EndFunction

Race[] Function regGetRacesForPlugin(vMFX_FXPluginBase MFXPlugin)
	;;Debug.Trace("MFXRegistry: Getting races for plugin " + MFXPlugin.infoPluginName)
	Race[] Races = New Race[128]
	Race kRace 
	Int i = 0
	Int iCount = 0
	Int jRacesForPlugin = JMap.GetObj(JFormMap.GetObj(GetRegObj("LinkFormMap"),MFXPlugin),"Races")
	Int iMax = JArray.Count(jRacesForPlugin)
	While i < iCount
		kRace = JArray.GetForm(jRacesForPlugin,i) as Race
		If kRace
			Races[iCount] = kRace
			iCount += 1
		EndIf
		i += 1
	EndWhile
	
	Return Races
EndFunction

Armor[] Function regGetArmorsForPlugin(vMFX_FXPluginBase MFXPlugin)
	;;Debug.Trace("MFXRegistry: Getting Armors for plugin " + MFXPlugin.infoPluginName)
	Armor[] Armors = New Armor[128]
	Armor kArmor 
	Int i = 0
	Int iCount = 0
	Int jArmorsForPlugin = JMap.GetObj(JFormMap.GetObj(GetRegObj("LinkFormMap"),MFXPlugin),"Armors")
	Int iMax = JArray.Count(jArmorsForPlugin)
	While i < iMax
		kArmor = JArray.GetForm(jArmorsForPlugin,i) as Armor
		If kArmor
			Armors[iCount] = kArmor
			iCount += 1
		EndIf
		i += 1
	EndWhile
	
	Return Armors
EndFunction

Armor[] Function regGetArmorsForRace(Race MFXRace)
	;;Debug.Trace("MFXRegistry: Getting Armors for Race " + MFXRace.infoRaceName)
	Armor[] Armors = New Armor[128]
	Armor kArmor 
	Int i = 0
	Int iCount = 0
	Int jArmorsForPlugin = JMap.GetObj(JFormMap.GetObj(GetRegObj("LinkFormMap"),MFXRace),"Armors")
	Int iMax = JArray.Count(jArmorsForPlugin)
	While i < iCount
		kArmor = JArray.GetForm(jArmorsForPlugin,i) as Armor
		If kArmor
			Armors[iCount] = kArmor
			iCount += 1
		EndIf
		i += 1
	EndWhile
	
	Return Armors
EndFunction

Armor[] Function regGetArmorsForSlot(Int iBipedSlot)
	;;Debug.Trace("MFXRegistry: Getting Armors for slot " + iBipedSlot)
	Armor[] Armors = New Armor[128]
	Armor kArmor 
	Int i = 0
	Int iCount = 0
	Int jArmorsForSlot = GetRegObj("Slots." + iBipedSlot + ".Armors")
	Int iMax = JArray.Count(jArmorsForSlot)
	While i < iMax
		kArmor = JArray.GetForm(jArmorsForSlot,i) as Armor
		If kArmor
			Armors[iCount] = kArmor
			iCount += 1
		EndIf
		i += 1
	EndWhile
	
	Return Armors
EndFunction

Int[] Function regGetSlotsForPlugin(vMFX_FXPluginBase MFXPlugin)
	;;Debug.Trace("MFXRegistry: Getting slots for plugin " + MFXPlugin.infoPluginName)
	Int[] Slots = New Int[128]
	Int iSlot 
	Int i = 0
	Int iCount = 0
	Int jSlotsForPlugin = JMap.GetObj(JFormMap.GetObj(GetRegObj("LinkFormMap"),MFXPlugin),"Slots")
	Int iMax = JArray.Count(jSlotsForPlugin)
	While i < iCount
		iSlot = JArray.GetInt(jSlotsForPlugin,i)
		If iSlot
			Slots[iCount] = iSlot
			iCount += 1
		EndIf
		i += 1
	EndWhile
	
	Return Slots
EndFunction

Int[] Function regGetSlotsForRace(Race akRace)
	;;Debug.Trace("MFXRegistry: Getting slots for Race " + akRace.GetName())
	Int[] Slots = New Int[128]
	Int iSlot 
	Int i = 0
	Int iCount = 0
	Int jSlotsForRace = JMap.GetObj(JFormMap.GetObj(GetRegObj("LinkFormMap"),akRace),"Slots")
	Int iMax = JArray.Count(jSlotsForRace)
	While i < iMax
		iSlot = JArray.GetInt(jSlotsForRace,i)
		If iSlot
			Slots[iCount] = iSlot
			iCount += 1
		EndIf
		i += 1
	EndWhile
	
	Return Slots
EndFunction

