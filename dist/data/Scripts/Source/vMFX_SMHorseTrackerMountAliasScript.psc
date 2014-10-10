Scriptname vMFX_SMHorseTrackerMountAliasScript extends ReferenceAlias  
{Reference hopefully pointing at player's new horse}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

ReferenceAlias Property CurrentMount Auto

;--=== Variables ===--


;--=== Events ===--

Event OnInit()
	If IsRunning()
		Debug.Trace("vMFXSMHorseTrackerMountAliasScript : OnInit!")
		SendModEvent("vMFX_MFXSetCurrentMount")
	EndIf
EndEvent
