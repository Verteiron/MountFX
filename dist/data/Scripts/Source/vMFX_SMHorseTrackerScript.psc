Scriptname vMFX_SMHorseTrackerScript extends Quest  
{StoryManager starts this when player activates a Horse}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

ReferenceAlias Property CurrentMount Auto

;--=== Variables ===--


;--=== Events ===--

Event OnInit()
	Debug.Trace("vMFXSMHorseTracker: OnInit!")
	RegisterForSingleUpdate(5)
EndEvent

Event OnUpdate()
	Stop()
EndEvent

