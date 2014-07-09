Scriptname vMFX_EyeGlowEnableScript extends ObjectReference  

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--  
;--=== Variables ===--

Actor _ActorRef
Bool _Equipped

;--=== Events ===--

Event OnInit()
	Debug.Trace(self + ": OnInit!")
EndEvent

Event OnLoad()
	Debug.Trace(self + ": OnLoad!")
EndEvent

Event OnEquipped(Actor akActor)
	Debug.Trace(self + ": Equipped by " + akActor)
	_ActorRef = akActor
	_Equipped = True
	akActor.PlaySubGraphAnimation("SkinGone")
	Wait(10)
	akActor.PlaySubGraphAnimation("SkinFadeIn")
	Wait(10)
	akActor.PlaySubGraphAnimation("SkinThere")
	Wait(10)
	akActor.PlaySubGraphAnimation("SkinFadeOut")
EndEvent

Event OnUnEquipped(Actor akActor)
	Debug.Trace(self + ": Unequipped by " + akActor)
	Wait(1)
	akActor.EquipItem(Self)
	_Equipped = False
EndEvent

Event OnUpdate()
	
EndEvent

