Scriptname vMFX_FXRegistryScript extends Quest  
{Track all registered mount FX and plugin content}

;--=== Imports ===--

Import Utility
Import Game
Import vMFX_Registry

;--=== Properties ===--

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
			sReturn[i] = JArray.GetStr(jNames,iN)
			iN += 1
			While iN < JArray.Count(jNames)
				sReturn[i] = sReturn[i] + "/" + JArray.GetStr(jNames,iN)
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
	RegisterForSingleUpdate(0.1)
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
	;Debug.Trace("MFX/FXRegistry/RegisterPlugin: Checking for plugin " + infoESPFile + "/" + infoPluginName)
	DataVersion += 1
	String sPluginKey = "Plugins." + infoESPFile + "." + infoPluginName
	Int jPluginFormMap = GetRegObj("PluginForms")
	String sUUIDPlugin
	If !JFormMap.HasKey(jPluginFormMap,MFXPlugin) 
		Debug.Trace("MFX/FXRegistry/RegisterPlugin: Generating UUID for new plugin " + infoESPFile + "/" + infoPluginName)
		sUUIDPlugin = GetUUID()
		MFXPlugin.UUID = sUUIDPlugin
		JFormMap.SetStr(jPluginFormMap,MFXPlugin,sUUIDPlugin)
		SetRegForm(sPluginKey + ".Form",MFXPlugin)
		SetRegForm("Index." + sUUIDPlugin,MFXPlugin)
		SetRegObj("Plugins." + sUUIDPlugin,GetRegObj("Plugins." + infoESPFile + "." + infoPluginName))
		Debug.Trace("MFX/FXRegistry/RegisterPlugin: " + infoESPFile + "/" + infoPluginName + " UUID set to " + sUUIDPlugin)
	Else
		sUUIDPlugin = GetRegStr(sPluginKey + ".UUID")
		MFXPlugin.UUID = sUUIDPlugin
	EndIf

	If MFXPlugin.infoVersion != GetRegInt("Plugins." + sUUIDPlugin + ".Version")
		SetRegStr(sPluginKey + ".UUID",sUUIDPlugin)
		SetRegStr(sPluginKey + ".Name",infoPluginName)
		SetRegStr(sPluginKey + ".Source",infoESPFile)
		SetRegInt(sPluginKey + ".Priority",MFXPlugin.infoPriority)
		SetRegInt(sPluginKey + ".Version",MFXPlugin.infoVersion)
		SetRegObj(sPluginKey + ".IncompatibleSlots",JArray.objectWithInts(MFXPlugin.dataUnsupportedSlot))
		SetRegObj(sPluginKey + ".RequiredArmors",JArray.Object())
		JArray.addFromFormList(GetRegObj(sPluginKey + ".RequiredArmors"),MFXPlugin.dataRequiredArmorList)
		Debug.Trace("MFX/FXRegistry/RegisterPlugin: " + infoESPFile + "/" + infoPluginName + " registered version " + MFXPlugin.infoVersion)
	Else
		;Debug.Trace("MFX/FXRegistry/RegisterPlugin:  Plugin already loaded!")
		_LockedBy = ""	
		GoToState("")
		Return 1
	EndIf
		
	Int iRace = 0
	While iRace < MFXPlugin.dataRaces.Length
		Race newRace = MFXPlugin.dataRaces[iRace]
		If newRace
			RegisterRace(MFXPlugin, newRace)
		EndIf
		iRace += 1
	EndWhile
	
	If MFXPlugin.dataArmorSlotNumbers.Length
		Int i = 0
		Debug.Trace("MFX/FXRegistry/RegisterPlugin:  Registering " + MFXPlugin.dataArmorSlotNumbers.Length + " ArmorSlots from '" + infoPluginName + "'")
		While i < MFXPlugin.dataArmorSlotNumbers.Length
			String sSlotName = ""
			If i < MFXPlugin.dataArmorSlotNames.Length
				sSlotName = MFXPlugin.dataArmorSlotNames[i]
			EndIf
			iRace = 0
			While iRace < MFXPlugin.dataRaces.Length
				Bool SlotResult = RegisterArmorSlot(MFXPlugin, MFXPlugin.dataRaces[iRace], MFXPlugin.dataArmorSlotNumbers[i], sSlotName)
				iRace += 1
			EndWhile
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
			Debug.Trace("MFX/FXRegistry/RegisterPlugin: " + MFXPlugin.infoPluginName + " registered " + Result + " forms for " + MFXPlugin.dataRaces[iRace].GetName() + "!")
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
	String sUUIDPlugin = MFXPlugin.UUID
	If StringUtil.Find(sESPFile,".esp") > -1
		sESPFile = StringUtil.Substring(sESPFile,0,StringUtil.GetLength(sESPFile) - 4)
	EndIf
	Int jPluginObj = GetRegObj("Plugins." + sUUIDPlugin)

	String sUUIDRace
	Int jRaceFormMap = GetRegObj("RaceForms")
	If !JFormMap.HasKey(jRaceFormMap,akRace)
		sUUIDRace = GetUUID()
		JFormMap.SetStr(jRaceFormMap,akRace,sUUIDRace)
		SetRegForm("Races." + sUUIDRace + ".Form",akRace)
		SetRegStr("Races." + sUUIDRace + ".Name",akRace.GetName())
	Else
		sUUIDRace = JFormMap.GetStr(jRaceFormMap,akRace)
	EndIf
	
	CreateRegFormLink(MFXPlugin,akRace,"Races","Plugins")
	CreateRegObjLink(jPluginObj,GetRegObj("Races." + sUUIDRace),"Races","Plugins")

	Int iResult = CountFormLinks(MFXPlugin,"Races")
	
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
	String sUUIDPlugin = MFXPlugin.UUID	
	If !sUUIDPlugin
		Debug.Trace("MFX/FXRegistry/RegisterArmor: Plugin " + MFXPlugin + " isn't registered!")
	EndIf
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
				If bResult && MFXPlugin.dataArmorSlotNumbers.Find(iBipedSlot) >= 0
					;;Debug.Trace("MFXRegistry: Added " + iBipedSlot + ",iSlotCount is " + iSlotCount)
					iArmorSlots[iSlotCount] = iBipedSlot
					iSlotCount += 1
				ElseIf bResult && MFXPlugin.dataArmorSlotNumbers.Find(iBipedSlot) >= 0
					;Mod lists this slot as being used, just not registered to it.
				Else
					Debug.Trace("MFX/FXRegistry: " + MFXPlugin.infoESPFile + "/" + MFXPlugin.infoPluginName + "/" + akArmor.GetName() + ". Slot " + iBipedSlot + " is not registered or listed by plugin.",1)
					NumFailures += 1
				EndIf
			endIf
			h = Math.LeftShift(h,1)
		endWhile
		i += 1
	EndWhile
	
	If NumFailures
		Debug.Trace("MFX/FXRegistry: WARNING! Armor " + MFXPlugin.infoESPFile + "/" + MFXPlugin.infoPluginName + "/" + akArmor.GetName() + " is using " + NumFailures + " unregistered slot(s)!")
;		Return 0
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
		i = 0
		While i < MFXPlugin.dataRequiredArmorList.GetSize()
			Form kRequiredArmor = MFXPlugin.dataRequiredArmorList.GetAt(i)
			CreateRegFormLink(akArmor,kRequiredArmor,"RequiredArmors","ArmorsEnabled")
			CreateRegFormLink(MFXPlugin,kRequiredArmor,"RequiredArmors","PluginsEnabled")
			i += 1
		EndWhile
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
		Int iSlotNameIndex = MFXPlugin.dataArmorSlotNumbers.Find(iBipedSlot)
		;Debug.Trace("MFX/FXRegistry: " + MFXPlugin.infoPluginName + " registered slot " + iBipedSlot + " as " + MFXPlugin.dataArmorSlotNames[iSlotNameIndex])
	ElseIf MFXPlugin.dataArmorSlotNumbers.Find(iBipedSlot) > 0 
		; Plugin didn't register the slot but is aware of its use
		;Debug.Trace("MFX/FXRegistry: " + MFXPlugin.infoPluginName + " is using slot " + iBipedSlot + " without registering it.")
	Else 
		; plugin hasn't registered for this slot and doesn't think it's using it.
		bFail = True
		bFailReason = MFXPlugin.infoPluginName + " does not know it's using slot " + iBipedSlot + "!"
	EndIf
	
	If bFail
		;GotoState("")
		;Debug.Trace("MFX/FXRegistry: ArmorSlot check: " + bFailReason)
		Return False
	EndIf
	;GotoState("")
	Return True

EndFunction

Bool Function RegisterArmorSlot(vMFX_FXPluginBase MFXPlugin, Race akRace, Int iBipedSlot, String sSlotName, Bool bOverwrite = False)
	;Debug.Trace("MFX/FXRegistry: RegisterArmorSlot(" + MFXPlugin + ", " + akRace + ", " + iArmorSlot + ", " + sSlotName + ")")
	
	Bool bFail = False
	String bFailReason = ""

	If !JValue.IsMap(GetRegObj("Slots." + iBipedSlot))
		Debug.Trace("MFX/FXRegistry/RegisterArmorSlot: Creating slot " + iBipedSlot + " from " + MFXPlugin.infoPluginName)
		SetRegInt("Slots." + iBipedSlot + ".BipedSlot",iBipedSlot)
		SetRegObj("Slots." + iBipedSlot + ".Names",JArray.Object())
	EndIf
	
	Int jSlot = GetRegObj("Slots." + iBipedSlot)

	If !jSlot
		bFail = True
		bFailReason = "Couldn't get a valid JObject for " + iBipedSlot
	EndIf

	Int jSlotNames = GetRegObj("Slots." + iBipedSlot + ".Names")
	
	If !bFail
		If sSlotName && JArray.FindStr(jSlotNames,sSlotName) < 0
			JArray.AddStr(jSlotNames,sSlotName)
		EndIf
		CreateRegForm2ObjLink(MFXPlugin,jSlot,"Slots","Plugins")
		CreateRegForm2ObjLink(akRace,jSlot,"Slots","Races")
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

;String Function GetSlotNameForRace(Race akRace, int iArmorSlot)
;	Debug.Trace("MFX/FXRegistry: GetSlotNameForRace(" + akRace + "," + iArmorSlot + ")")
;	Int i = 0
;	Int iRace = _RaceIndex.Find(akRace)
;	Debug.Trace("MFX/FXRegistry:  iRace: " + iRace)
;	While i >= 0 && i < _SlotRaceIndex.Length
;		i = _SlotRaceIndex.Find(iRace,i)
;		Debug.Trace("MFX/FXRegistry:   Race search returned i: " + i)
;		If i >= 0 && _SlotArmorSlotIndex[i] == iArmorSlot
;			Debug.Trace("MFX/FXRegistry:   ArmorSlot matched at i: " + i)
;			Debug.Trace("MFX/FXRegistry:   _SlotArmorSlotNameIndex[i]: " + _SlotArmorSlotNameIndex[i])
;			Return _SlotArmorSlotNameIndex[i]
;		ElseIf i >= 0
;			i += 1
;		EndIf
;	EndWhile
;	Debug.Trace("MFX/FXRegistry:  Nothing found!")
;	Return ""
;EndFunction

;String Function GetPluginForSlot(Race akRace, int iArmorSlot)
;	Debug.Trace("MFX/FXRegistry: GetPluginForSlot(" + akRace + "," + iArmorSlot + ")")
;	Int i = 0
;	Int iRace = _RaceIndex.Find(akRace)
;	Debug.Trace("MFX/FXRegistry:  iRace: " + iRace)
;	While i >= 0 && i < _SlotRaceIndex.Length
;		i = _SlotRaceIndex.Find(iRace,i)
;		Debug.Trace("MFX/FXRegistry:   Race search returned i: " + i)
;		If i >= 0 && _SlotArmorSlotIndex[i] == iArmorSlot
;			Debug.Trace("MFX/FXRegistry:   ArmorSlot matched at i: " + i)
;			Debug.Trace("MFX/FXRegistry:   _SlotPluginIndex[i]: " + _SlotPluginIndex[i])
;			Debug.Trace("MFX/FXRegistry:   _PluginNameIndex[_SlotPluginIndex[i]]: " + _PluginNameIndex[_SlotPluginIndex[i]])
;			Return _PluginNameIndex[_SlotPluginIndex[i]]
;		ElseIf i >= 0
;			i += 1
;		EndIf
;	EndWhile
;	Debug.Trace("MFX/FXRegistry:  Nothing found!")
;	Return ""
;EndFunction

;vMFX_FXPluginBase Function GetPluginForArmor(Armor akArmor)
;	Debug.Trace("MFX/FXRegistry: GetPluginForArmor(" + akArmor + ")")
;	Int i = 0
;	Int j = 0
;	Int iFI
;	vMFX_FXPluginBase MFXPlugin
;	While i < vMFX_regFXPlugins.GetSize()
;		MFXPlugin = vMFX_regFXPlugins.GetAt(i) as vMFX_FXPluginBase
;		j = 0
;		While j < MFXPlugin.dataFormlists.Length
;			If MFXPlugin.dataFormlists[j].HasForm(akArmor)
;				Debug.Trace("MFX/FXRegistry:  Returning " + MFXPlugin.infoPluginName)
;				Return MFXPlugin
;			EndIf
;			j += 1
;		EndWhile
;		i += 1
;	EndWhile
;	Debug.Trace("MFX/FXRegistry:  Nothing found!")
;	Return None
;EndFunction

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

Int Function AddArmorToOutfit(Int iBipedSlot, Armor NewArmor, String asOutfitName = "Default")
	Bool bCompatibilityChanged = False
	Armor kOldArmor = _OutfitCurrent[iBipedSlot] as Armor
	_OutfitCurrent[iBipedSlot] = NewArmor
	If !HasRegKey("Outfits." + asOutfitName + ".Slots")
		SetRegObj("Outfits." + asOutfitName + ".Slots",JArray.ObjectWithSize(64))
		SetRegInt("Outfits." + asOutfitName + ".Version", 1)
	EndIf
	;Int jOutfit = GetRegObj("Outfits." + asOutfitName + ".Slots")
	;JArray.SetForm(jOutfit,iBipedSlot,NewArmor)
	If !HasRegKey("Outfits." + asOutfitName + ".EnabledArmor")
		SetRegObj("Outfits." + asOutfitName + ".EnabledArmor",JArray.object())
	EndIf
	Int jEnabledArmor = GetRegObj("Outfits." + asOutfitName + ".EnabledArmor")
	
	;Remove enabled armors attached to the outgoing armor
	If JArray.Count(GetFormLinkArray(kOldArmor,"ArmorsEnabled"))
		Int jArmorsToRemove = GetFormLinkArray(kOldArmor,"ArmorsEnabled")
		Int i = JArray.Count(jArmorsToRemove)
		While i > 0
			i -= 1
			Int idx = JArray.FindForm(jEnabledArmor,JArray.GetForm(jArmorsToRemove,i))
			If idx >= 0
				JArray.eraseIndex(jEnabledArmor,idx)
				bCompatibilityChanged = True
			EndIf
		EndWhile
	EndIf
	
	;Add enabled armors attached to the incoming armor
	If JArray.Count(GetFormLinkArray(NewArmor,"ArmorsEnabled"))
		JArray.AddFromArray(jEnabledArmor,GetFormLinkArray(NewArmor,"ArmorsEnabled"))
		bCompatibilityChanged = True
	EndIf

	SetRegForm("Outfits." + asOutfitName + ".Slots[" + iBipedSlot + "]",NewArmor)

	;Update disabled slots if this plugin changes the body type
	If iBipedSlot == 30 
		vMFX_FXPluginBase OwningPlugin
		OwningPlugin = regGetPluginForArmor(NewArmor)
		If OwningPlugin.dataChangesBody
			bCompatibilityChanged = True
			Debug.Trace("MFX/FXRegistry/AddArmorToOutfit: Owning plugin is slot 30 and changes Body!")
			If !HasRegKey("Outfits." + asOutfitName + ".DisabledSlots")
				SetRegObj("Outfits." + asOutfitName + ".DisabledSlots",JArray.objectWithInts(OwningPlugin.dataUnsupportedSlot))
			Else
				Int jDisabledSlots = GetRegObj("Outfits." + asOutfitName + ".DisabledSlots")
				Int jNewDisabledSlots = JArray.objectWithInts(OwningPlugin.dataUnsupportedSlot)
				JArray.addFromArray(jDisabledSlots, jNewDisabledSlots)
			EndIf
			IncompatibleMesh = True
			DisabledSlots = OwningPlugin.dataUnsupportedSlot
			DisablingArmor = NewArmor
			DisablingPlugin = OwningPlugin
		Else
			Debug.Trace("MFX/FXRegistry/AddArmorToOutfit: Owning plugin is slot 30 but doesn't change Body!")
			SetRegObj("Outfits." + asOutfitName + ".DisabledSlots",JArray.object())
			IncompatibleMesh = False
			DisabledSlots = New Int[32]
			DisablingArmor = None
			DisablingPlugin = None
			If kOldArmor
				If regGetPluginForArmor(kOldArmor).dataChangesBody
					bCompatibilityChanged = True
				EndIf
			EndIf
		EndIf
	EndIf

	;Unequip armor that was disabled by the change
	If bCompatibilityChanged
		SetRegInt("Outfits." + asOutfitName + ".Version", GetRegInt("Outfits." + asOutfitName + ".Version") + 1)
		UpdateOutfitFilters(asOutfitName)
		Int jOutfitSlots = GetRegObj("Outfits." + asOutfitName + ".Slots")
		Int iSlotToCheck = 0
		While iSlotToCheck < JArray.Count(jOutfitSlots)
			Armor kArmor = JArray.GetForm(jOutfitSlots,iSlotToCheck) as Armor
			If kArmor
				If !OutfitAllowsSlotWithArmor(asOutfitName,iSlotToCheck,kArmor)
					Debug.Trace("MFX/FXRegistry/AddArmorToOutfit: Removing incompatible armor " + kArmor.GetName() + " " + kArmor + "!")
					_OutfitCurrent[iSlotToCheck] = None
				EndIf
			EndIf
			iSlotToCheck += 1
		EndWhile
	EndIf

	If bCompatibilityChanged
		Return -1
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

Function UpdateOutfitFilters(String asOutfitName = "Default",Bool abForce = False)
	Int iFilterVersion = GetRegInt("Outfits." + asOutfitName + ".FilteredList.Version")
	Int iOutfitVersion = GetRegInt("Outfits." + asOutfitName + ".Version")
	If (iFilterVersion && (iFilterVersion == iOutfitVersion)) && !abForce
		Return
	EndIf
	Int iBipedSlot = 30
	While iBipedSlot < 62
		SetRegObj("Outfits." + asOutfitName + ".FilteredList." + iBipedSlot + ".Forms",GetAllowedArmorForSlotJ(iBipedSlot,asOutfitName))
		iBipedSlot += 1
	EndWhile
	SetRegInt("Outfits." + asOutfitName + ".FilteredList.Version",iOutfitVersion)
EndFunction

Bool Function OutfitAllowsSlotWithArmor(String asOutfitName = "Default", Int aiBipedSlot, Armor akArmor)
	If JArray.FindForm(GetRegObj("Outfits." + asOutfitName + ".FilteredList." + aiBipedSlot + ".Forms"),akArmor) >= 0
		Return True
	EndIf
	Return False
EndFunction

Armor[] Function GetAllowedArmorForSlot(Int aiBipedSlot, String asOutfitName = "Default")
	Armor[] kReturnArmor = New Armor[128]
	
	Int jArmorForSlot = GetAllowedArmorForSlotJ(aiBipedSlot, asOutfitName)
	
	Int i = 0
	Int iCount = 0
	
	While i < JArray.Count(jArmorForSlot)
		Armor kArmor = JArray.GetForm(jArmorForSlot,i) as Armor
		If kArmor
			kReturnArmor[iCount] = kArmor
			iCount += 1
		EndIf
		i += 1
	EndWhile
	Return kReturnArmor
EndFunction

Int Function GetAllowedArmorForSlotJ(Int aiBipedSlot, String asOutfitName = "Default")
	Int jArmorList = JArray.Object()
	Armor[] kArmorsForSlot = regGetArmorsForSlot(aiBipedSlot)
	Int jOutfit = GetRegObj("Outfits." + asOutfitName + ".Slots")
	Int i = 0
	Int iCount = 0
	Int jEnabledArmor = GetRegObj("Outfits." + asOutfitName + ".EnabledArmor")	
	
	While i < kArmorsForSlot.Length
		Armor kArmor = kArmorsForSlot[i]
		Bool bAddArmor = True
		If kArmor
			Int jRequiredArmors = GetFormLinkArray(kArmor,"RequiredArmors")
			;Don't add if this slot has been disabled 
			If JArray.FindInt(GetRegObj("Outfits." + asOutfitName + ".DisabledSlots"),aiBipedSlot) >= 0
				bAddArmor = False
			EndIf
			
			;Don't add if this armor has unmet requirements
			If jRequiredArmors && bAddArmor ;Skip this if we're already disabled
				bAddArmor = False
				Int iReqListCount = JArray.Count(jRequiredArmors)
				While iReqListCount > 0
					iReqListCount -= 1
					If JArray.FindForm(jOutfit,JArray.GetForm(jRequiredArmors,iReqListCount)) >= 0
						bAddArmor = True
					EndIf
				EndWhile
			EndIf
			
			;DO add if this armor is specifically enabled by another part of the outfit, even if it was previously disabled
			If JArray.FindForm(jEnabledArmor,kArmor) >= 0
				bAddArmor = True
			EndIf
			
			If bAddArmor
				JArray.AddForm(jArmorList,kArmor)
				;Debug.Trace("MFX/FXRegistry: Armor[" + iCount + "] for Slot " + aiBipedSlot + " is " + kArmor.GetName())
				iCount += 1
			EndIf
		EndIf
		i += 1
	EndWhile
	Return jArmorList
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
		;SpinLock("RegisterPlugin",MFXPlugin.infoESPFile + " - " + MFXPlugin.infoPluginName)
		;WaitMenuMode(MFXPlugin.infoPriority * 0.1)
		;Return RegisterPlugin(MFXPlugin)
		Return -1
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
	CreateRegFormLink(MFXPlugin,NewRace,"Races","Plugins")
EndFunction

Function regLinkPluginArmor(vMFX_FXPluginBase MFXPlugin, Armor NewArmor)
	;Create a link between Plugin and Armor
	CreateRegFormLink(MFXPlugin,NewArmor,"Armors","Plugins")
EndFunction

Function regLinkPluginSlot(vMFX_FXPluginBase MFXPlugin, Int iBipedSlot)
	;Create a link between Plugin and BipedSlot
	CreateRegForm2ObjLink(MFXPlugin,GetRegObj("Slots." + iBipedSlot),"Slots","Plugins")
EndFunction

Function regLinkArmorSlot(Armor NewArmor, Int iBipedSlot)
	;Create a link between Armor and BipedSlot
	CreateRegForm2ObjLink(NewArmor,GetRegObj("Slots." + iBipedSlot),"Slots","Armors")
EndFunction

Function regLinkArmorRace(Armor NewArmor, Race NewRace)
	;Create a link between Armor and Race
	CreateRegFormLink(NewArmor,NewRace,"Races","Armors")
EndFunction

Function regLinkRaceSlot(Race NewRace,Int iBipedSlot)
	;Create a link between Race and BipedSlot
	CreateRegForm2ObjLink(NewRace,GetRegObj("Slots." + iBipedSlot),"Slots","Races")	
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
	;Debug.Trace("MFXRegistry: Plugins for slot " + iBipedSlot + ": " + iMax)
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
	Int jPluginsForRace = GetFormLinkArray(akRace,"Plugins")
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
	Int jPluginsForRace = GetFormLinkArray(akArmor,"Plugins")
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
	;Debug.Trace("MFXRegistry: Getting races for plugin " + MFXPlugin.infoPluginName)
	Race[] Races = New Race[128]
	Race kRace 
	Int i = 0
	Int iCount = 0
	Int jRacesForPlugin = GetFormLinkArray(MFXPlugin,"Races")
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
	Int jArmorsForPlugin = GetFormLinkArray(MFXPlugin,"Armors")
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
	Int jArmorsForPlugin = GetFormLinkArray(MFXRace,"Armors")
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
	Int jSlotsForPlugin = GetFormLinkArray(MFXPlugin,"Slots")
	Int iMax = JArray.Count(jSlotsForPlugin)
	While i < iCount
		iSlot = JMap.GetInt(JArray.GetObj(jSlotsForPlugin,i),"BipedSlot")
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
	Int jSlotsForRace = GetFormLinkArray(akRace,"Slots")
	Int iMax = JArray.Count(jSlotsForRace)
	While i < iMax
		iSlot = JMap.GetInt(JArray.GetObj(jSlotsForRace,i),"BipedSlot")
		If iSlot
			Slots[iCount] = iSlot
			iCount += 1
		EndIf
		i += 1
	EndWhile
	Return Slots
EndFunction

