Scriptname vMFX_HorseHoofprintsMEScript extends activemagiceffect  
{Place custom hoofprint object(s) while moving}

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

Actor Property PlayerRef Auto

ImpactDataSet Property vMFX_FootStepFWalkingImpactSet Auto
ImpactDataSet Property vMFX_FootStepBWalkingImpactSet Auto

ImpactDataSet Property vMFX_FootStepFRunningImpactSet Auto
ImpactDataSet Property vMFX_FootStepBRunningImpactSet Auto

ImpactDataSet Property vMFX_FootStepFFlyingImpactSet Auto
ImpactDataSet Property vMFX_FootStepBFlyingImpactSet Auto

;--=== Variables ===--

Int _iFootStepF
Int _iFootStepB

String _sLastEventName
String _sEventName

Bool _bOnRight

Actor _SelfRef

ImpactDataSet _FImpactSet 
ImpactDataSet _BImpactSet 

Float _Emissive = 1.0

;ObjectReference _SpawnPoint

;--=== Events ===--

Event OnInit()

EndEvent

Event onEffectStart(Actor akTarget, Actor akCaster)
	_SelfRef = akTarget
	Debug.Trace(self + "OnEffectStart!")
	RegisterForAnimationEvent(_SelfRef,"FootFront")
	RegisterForAnimationEvent(_SelfRef,"FootBack")
	;RegisterForAnimationEvent(_SelfRef,"syncRight")
	;RegisterForAnimationEvent(_SelfRef,"syncLeft")
	RegisterForAnimationEvent(_SelfRef,"HorseIdle")
	RegisterForAnimationEvent(_SelfRef,"HorseLocomotion")
	RegisterForAnimationEvent(_SelfRef,"HorseSprint")
	RegisterForAnimationEvent(_SelfRef,"landEnd")
	RegisterForAnimationEvent(_SelfRef,"forwardFallFromJump")
	RegisterForAnimationEvent(_SelfRef,"SoundPlay")
	RegisterForAnimationEvent(_SelfRef,"rearUpEnd")
	
	RegisterForSingleUpdate(1.0)
EndEvent

Event onUpdate()
	Armor FooArmor = _SelfRef.GetWornForm(0x00080000) as Armor
	;Armor FooArmor = _SelfRef.GetWornForm(0x00000001) as Armor

	If FooArmor
		ArmorAddon FooArmorAddon = FooArmor.GetNthArmorAddon(0)
		Debug.Trace(self + ": Armor is " + FooArmor)
		Debug.Trace(self + ": ArmorAddon is " + FooArmor.GetNthArmorAddon(0))
		;Function AddNodeOverrideFloat(ObjectReference ref, bool isFemale, string node, int key, int index, float value, bool persist) native global
		;NiOverride.AddNodeOverrideFloat(_SelfRef,False,"eyeGlow",1,0,_Emissive,True)
		
		;Function AddOverrideFloat(ObjectReference ref, bool isFemale, Armor arm, ArmorAddon addon, string node, int key, int index, float value, bool persist) native global
		
		NiOverride.AddOverrideFloat(_SelfRef,False,FooArmor,FooArmorAddon,"EyeGlow",1,0,_Emissive,True)
		
		Debug.Trace(self + ": Called NiOverride!")
		;float Function GetPropertyFloat(ObjectReference ref, bool firstPerson, Armor arm, ArmorAddon addon, string node, int key, int index) native global
		Float EmissiveMult = NiOverride.GetPropertyFloat(_SelfRef,false,FooArmor,FooArmorAddon,"EyeGlow",1,0)
		Debug.Trace(self + ": EmissiveMult is " + EmissiveMult)
		;bool Function HasOverride(ObjectReference ref, bool isFemale, Armor arm, ArmorAddon addon, string node, int key, int index) native global
		Debug.Trace(self + ": HasOverride is " + NiOverride.HasOverride(_SelfRef,False,FooArmor,FooArmorAddon,"EyeGlow",1,0))
		_Emissive += 1.0
		RegisterForSingleUpdate(5)
	Else
		Debug.Trace(self + ": No armor!")
		RegisterForSingleUpdate(1.0)
	EndIf
EndEvent

Event OnAnimationEvent(ObjectReference akSource, String asEventName)
	If asEventName == "HorseLocomotion"
		GotoState("Walking")
	ElseIf asEventName == "HorseSprint"
		GotoState("Running")
	EndIf
EndEvent	
	
State Walking
	Event OnBeginState()
		Debug.Trace(self + ": Entered walking state!")
	EndEvent

	Event OnAnimationEvent(ObjectReference akSource, String asEventName)
		If asEventName == "FootFront"
			If _iFootStepF % 2
				_SelfRef.PlayImpactEffect(vMFX_FootStepFWalkingImpactSet, "HorseLPhalangesManus", 0, 0, -0.5, 64)
			Else
				_SelfRef.PlayImpactEffect(vMFX_FootStepFWalkingImpactSet, "HorseFrontRLegPhalangesManus", 0, 0, -0.5, 64)
			EndIf
			_iFootStepF += 1
		ElseIf asEventName == "FootBack"
			If _iFootStepB % 2
				_SelfRef.PlayImpactEffect(vMFX_FootStepBWalkingImpactSet, "HorseLPhalanxPrima", 0, 0, -0.5, 64)
			Else
				_SelfRef.PlayImpactEffect(vMFX_FootStepBWalkingImpactSet, "HorseRPhalanxPrima", 0, 0, -0.5, 64)
			EndIf
			_iFootStepB += 1
		ElseIf asEventName == "HorseSprint"
			GoToState("Running")
		EndIf
	EndEvent
EndState 

State Running
	Event OnBeginState()
		Debug.Trace(self + ": Entered running state!")
	EndEvent
	Event OnAnimationEvent(ObjectReference akSource, String asEventName)
		If asEventName == "FootFront"
			If _iFootStepF % 2
				_SelfRef.PlayImpactEffect(vMFX_FootStepFRunningImpactSet, "HorseLPhalangesManus", 0, 0, -0.5, 64)
			Else
				_SelfRef.PlayImpactEffect(vMFX_FootStepFRunningImpactSet, "HorseFrontRLegPhalangesManus", 0, 0, -0.5, 64)
			EndIf
			_iFootStepF += 1
		ElseIf asEventName == "FootBack"
			If _iFootStepB % 2
				_SelfRef.PlayImpactEffect(vMFX_FootStepBRunningImpactSet, "HorseLPhalanxPrima", 0, 0, -0.5, 64)
			Else
				_SelfRef.PlayImpactEffect(vMFX_FootStepBRunningImpactSet, "HorseRPhalanxPrima", 0, 0, -0.5, 64)
			EndIf
			_iFootStepB += 1
		ElseIf asEventName == "HorseLocomotion"
			GoToState("Walking")
		EndIf
	EndEvent
EndState

Event onEffectFinish(Actor akTarget, Actor akCaster)
;	If _SpawnPoint
;		_SpawnPoint.Delete()
;	EndIf
EndEvent

;--=== Functions ===--
