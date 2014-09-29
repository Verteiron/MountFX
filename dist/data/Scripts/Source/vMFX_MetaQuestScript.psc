Scriptname vMFX_MetaQuestScript extends Quest  
{Do initialization and track variables for scripts}

;--=== Imports ===--

Import Utility
Import Game
Import vMFX_Registry

;--=== Properties ===--

Actor Property PlayerRef Auto

Bool Property Ready = False Auto

Int Property ModVersion Auto Hidden

Int Property ModVersionMajor Auto Hidden
Int Property ModVersionMinor Auto Hidden
Int Property ModVersionPatch Auto Hidden

String Property ModName = "MountFX" Auto Hidden

Message Property vMFX_ModLoadedMSG Auto
Message Property vMFX_ModUpdatedMSG Auto

Quest Property vMFX_FXRegistryQuest Auto

;--=== Config variables ===--

GlobalVariable Property vMFX_CFG_Changed Auto
GlobalVariable Property vMFX_CFG_Shutdown Auto

;--=== Variables ===--

Int _iCurrentVersion
String _sCurrentVersion

Bool _Running

Float _ScriptLatency
Float _StartTime
Float _EndTime

;--=== Events ===--

Event OnInit()
	If ModVersion == 0
		DoUpkeep(True)
	EndIf
EndEvent

Event OnReset()
	Debug.Trace("MFX: Metaquest event: OnReset")
EndEvent

;--=== Functions ===--

Function DoUpkeep(Bool DelayedStart = True)
	;FIXME: CHANGE THIS WHEN UPDATING!
	ModVersionMajor = 0
	ModVersionMinor = 0
	ModVersionPatch = 1
	_iCurrentVersion = GetVersionInt(ModVersionMajor,ModVersionMinor,ModVersionPatch)
	_sCurrentVersion = GetVersionString(_iCurrentVersion)
	String sModVersion = GetVersionString(ModVersion as Int)
	RegisterForModEvent("vMFX_InitBegin","OnInitState")
	RegisterForModEvent("vMFX_InitEnd","OnInitState")
	RegisterForModEvent("vMFX_UpkeepBegin","OnUpkeepState")
	RegisterForModEvent("vMFX_UpkeepEnd","OnUpkeepState")
	RegisterForModEvent("vMFX_Shutdown","OnShutdown")
	Ready = False
	If DelayedStart
		Wait(RandomFloat(3,5))
	EndIf
	CheckDependencies()
	Debug.Trace("MFX: Performing upkeep...")
	Debug.Trace("MFX: Loaded version is " + GetVersionString(ModVersion) + ", Current version is " + _sCurrentVersion)
	If ModVersion == 0
		Debug.Trace("MFX: Newly installed, doing initialization...")
		DoInit()
		If ModVersion == _iCurrentVersion
			Debug.Trace("MFX: Initialization succeeded.")
		Else
			Debug.Trace("MFX: WARNING! Initialization had a problem!")
		EndIf
	ElseIf ModVersion < _iCurrentVersion
		Debug.Trace("MFX: Installed version is older. Starting the upgrade...")
		DoUpgrade()
		If ModVersion != _iCurrentVersion
			Debug.Trace("MFX: WARNING! Upgrade failed!")
			Debug.MessageBox("WARNING! The MountFX upgrade failed for some reason. You should report this to the mod author.")
		EndIf
		Debug.Trace("MFX: Upgraded to " + _iCurrentVersion)
		vMFX_ModUpdatedMSG.Show(_iCurrentVersion)
	Else
		Debug.Trace("MFX: Loaded, no updates.")
		;CheckForOrphans()
	EndIf
	CheckForExtras()
	UpdateConfig()
	Debug.Trace("MFX: Upkeep complete!")
EndFunction

Function DoInit()
	Debug.Trace("MFX: Initializing...")
	Int jMFX = JDB.SolveObj(".vMFX")
	If !jMFX
		jMFX = JMap.Object()
		JDB.SolveObjSetter(".vMFX",jMFX,True)
	EndIf
	(vMFX_FXRegistryQuest as vMFX_FXRegistryScript).Initialize(bFirstTime = True)
	InitReg()
	If !GetRegBool("Config.DefaultsSet")
		SetRegObj("Plugins",JMap.Object(),True)
		SetRegObj("PluginForms",JFormMap.Object(),True)
		SetRegObj("Races",JMap.Object(),True)
		SetRegObj("RaceForms",JFormMap.Object(),True)
		SetRegObj("Armors",JMap.Object(),True)
		SetRegObj("ArmorForms",JFormMap.Object(),True)
		SetRegObj("Slots",JMap.Object(),True)
		SetRegObj("LinkFormMap",JFormMap.Object())
		SetConfigDefaults()
	EndIf
	_Running = True
	ModVersion = _iCurrentVersion
	SetRegInt("Version.Major",ModVersionMajor)
	SetRegInt("Version.Minor",ModVersionMinor)
	SetRegInt("Version.Patch",ModVersionPatch)
	vMFX_ModLoadedMSG.Show(ModVersionMajor,ModVersionMinor,ModVersionPatch)
EndFunction

Function DoUpgrade()
	_Running = False
	
	;Generic upgrade code
	If ModVersion < _iCurrentVersion
		Debug.Trace("MFX: Upgrading to " + GetVersionString(_iCurrentVersion) + "...")
		;FIXME: Do upgrade stuff!
		ModVersion = _iCurrentVersion
		SetRegInt("Version.Major",ModVersionMajor)
		SetRegInt("Version.Minor",ModVersionMinor)
		SetRegInt("Version.Patch",ModVersionPatch)
		Debug.Trace("MFX: Upgrade to " + GetVersionString(_iCurrentVersion) + " complete!")
	EndIf
	
	_Running = True
	Debug.Trace("MFX: Upgrade complete!")
EndFunction

Function UpdateConfig()
	Debug.Trace("MFX: Updating configuration...")

	Debug.Trace("MFX: Updated configuration values, some scripts may update in the background!")
EndFunction

Function SetConfigDefaults(Bool abForce = False)
	If !GetRegBool("Config.DefaultsSet") || abForce
		Debug.Trace("MFX: Setting Config defaults!")
		SetRegBool("Config.Enabled",True,True,True)
		SetRegBool("Config.Compat.Enabled",True,True,True)
		SetRegBool("Config.Warnings.Enabled",True,True,True)
		SetRegBool("Config.Debug.Perf.Threads.Limit",False,True,True)
		SetRegInt ("Config.Debug.Perf.Threads.Max",50,True,True)
		SetRegBool("Config.DefaultsSet",True)
	EndIf
EndFunction

Bool Function CheckDependencies()
	Float fSKSE = SKSE.GetVersion() + SKSE.GetVersionMinor() * 0.01 + SKSE.GetVersionBeta() * 0.0001
	Debug.Trace("MFX: SKSE is version " + fSKSE)
	Debug.Trace("MFX: JContainers is version " + SKSE.GetPluginVersion("Jcontainers") + ", API is " + JContainers.APIVersion())
	Debug.Trace("MFX: CharGen is version " + SKSE.GetPluginVersion("chargen"))
	Debug.Trace("MFX: NIOverride is version " + SKSE.GetPluginVersion("nioverride"))
	;Debug.MessageBox("SKSE version is " + fSKSE)
	If fSKSE < 1.0700
		Debug.MessageBox("MountFX\nSKSE is missing or not installed correctly. This mod requires SKSE 1.7.0 or higher, but the current version is " + fSKSE + ".\nThe mod will now shut down.")
		Return False
	Else
		;Proceed
	EndIf
	If JContainers.APIVersion() != 3
		Debug.MessageBox("MountFX\nThe SKSE plugin JContainers is missing or not installed correctly. This mod requires JContainers with API 3 (3.1.x), but the current version reports a different API version.\nThe mod will now shut down.")
		Return False
	Else
		;Proceed
	EndIf
;	If SKSE.GetPluginVersion("chargen") < 3
;		Debug.MessageBox("MountFX\nThe SKSE plugin CharGen is missing or not installed correctly. This mod requires RaceMenu 2.9.1 or higher.\nThe mod will now shut down.")
;		Return False
;	Else
;		;Proceed
;	EndIf
;	If SKSE.GetPluginVersion("nioverride") >= 3 && NIOverride.GetScriptVersion() > 1
;		SetConfigBool("NIO_UseDye",True)
;	Else
;		SetConfigBool("NIO_UseDye",False)
;	EndIf
	Return True
EndFunction

Int Function GetVersionInt(Int iMajor, Int iMinor, Int iPatch)
	Return Math.LeftShift(iMajor,16) + Math.LeftShift(iMinor,8) + iPatch
EndFunction

String Function GetVersionString(Int iVersion)
	Int iMajor = Math.RightShift(iVersion,16)
	Int iMinor = Math.LogicalAnd(Math.RightShift(iVersion,8),0xff)
	Int iPatch = Math.LogicalAnd(iVersion,0xff)
	String sMajorZero
	String sMinorZero
	String sPatchZero
	If !iMajor
		sMajorZero = "0"
	EndIf
	If !iMinor
		sMinorZero = "0"
	EndIf
	;If !iPatch
		;sPatchZero = "0"
	;EndIf
	;Debug.Trace("MFX: Got version " + iVersion + ", returning " + sMajorZero + iMajor + "." + sMinorZero + iMinor + "." + sPatchZero + iPatch)
	Return sMajorZero + iMajor + "." + sMinorZero + iMinor + "." + sPatchZero + iPatch
EndFunction

Function CheckForExtras()
	If GetModByName("Dawnguard.esm") != 255
		Debug.Trace("MFX: Dawnguard is installed!")
	EndIf
	If GetModByName("Dragonborn.esm") != 255
		Debug.Trace("MFX: Dragonborn is installed!")
	EndIf
EndFunction
