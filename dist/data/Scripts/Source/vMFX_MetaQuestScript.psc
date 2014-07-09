Scriptname vMFX_MetaQuestScript extends Quest  
{Do initialization and track variables for scripts}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

Actor Property PlayerRef Auto

Float Property ModVersion Auto

Message Property vMFX_ModLoadedMSG Auto
Message Property vMFX_ModUpdatedMSG Auto

Quest Property vMFX_FXRegistryQuest Auto

;--=== Variables ===--

Float _CurrentVersion
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
	Debug.Trace("vMFX: Metaquest event: OnReset")
EndEvent

;--=== Functions ===--

Function DoUpkeep(Bool DelayedStart = True)
	;FIXME: CHANGE THIS WHEN UPDATING!
	_CurrentVersion = 0.01
	_sCurrentVersion = GetVersionString(_CurrentVersion)
	String sErrorMessage
	If DelayedStart
		Wait(RandomFloat(2,4))
	EndIf
	Debug.Trace("vMFX: Performing upkeep...")
	Debug.Trace("vMFX: Loaded version is " + GetVersionString(ModVersion) + ", Current version is " + _sCurrentVersion)
	If ModVersion == 0
		Debug.Trace("vMFX: Newly installed, doing initialization...")
		DoInit()
		If ModVersion == _CurrentVersion
			Debug.Trace("vMFX: Initialization succeeded.")
		Else
			Debug.Trace("vMFX: WARNING! Initialization had a problem!")
		EndIf
	ElseIf ModVersion < _CurrentVersion
		Debug.Trace("vMFX: Installed version is older. Starting the upgrade...")
		DoUpgrade()
		If ModVersion != _CurrentVersion
			Debug.Trace("vMFX: WARNING! Upgrade failed!")
			Debug.MessageBox("WARNING! The MountFX upgrade failed for some reason. You should report this to the mod author.")
		EndIf
		Debug.Trace("vMFX: Upgraded to " + _CurrentVersion)
		vMFX_ModUpdatedMSG.Show(_CurrentVersion)
	Else
		Debug.Trace("vMFX: Loaded, no updates.")
		;CheckForOrphans()
	EndIf
	CheckForExtras()
	UpdateConfig()
	Debug.Trace("vMFX: Upkeep complete!")
EndFunction

Function DoInit()
	Debug.Trace("vMFX: Initializing...")
	(vMFX_FXRegistryQuest as vMFX_FXRegistryScript).Initialize(bFirstTime = True)
	_Running = True
	ModVersion = _CurrentVersion
	vMFX_ModLoadedMSG.Show(_CurrentVersion)
EndFunction

Function DoUpgrade()
	_Running = False
	If ModVersion < 0.01
		Debug.Trace("vMFX: Upgrading to 0.01...")
		ModVersion = 0.01
	EndIf
	_Running = True
	Debug.Trace("vMFX: Upgrade complete!")
EndFunction

Function UpdateConfig()
	Debug.Trace("vMFX: Updating configuration...")

	Debug.Trace("vMFX: Updated configuration values, some scripts may update in the background!")
EndFunction

String Function GetVersionString(Float fVersion)
	Int Major = Math.Floor(fVersion) as Int
	Int Minor = ((fVersion - (Major as Float)) * 100.0) as Int
	If Minor < 10
		Return Major + ".0" + Minor
	Else
		Return Major + "." + Minor
	EndIf
EndFunction

Function CheckForExtras()
EndFunction