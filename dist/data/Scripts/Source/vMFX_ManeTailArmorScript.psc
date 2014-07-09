Scriptname vMFX_ManeTailArmorScript extends ObjectReference  
{Plays the ManeFade animation for CH compatibility}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--  

;--=== Variables ===--

Actor _ActorRef
Bool _Equipped

Event OnLoad()
	Debug.Trace("OnLoad!")
EndEvent

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
	Debug.Trace("OnContainerChanged! Old: " + akOldContainer + ". New: " + akNewContainer)
EndEvent

Event OnEquipped(Actor akActor)
	_ActorRef = akActor
	_Equipped = True
	Debug.Trace("Equipped by " + akActor)
	akActor.PlaySubGraphAnimation("ManeFadeIn")
EndEvent

Event OnUnEquipped(Actor akActor)
	_Equipped = False
	Debug.Trace("Unequipped by " + akActor)
EndEvent

Event OnUpdate()
	
EndEvent

