Scriptname vMFX_MetaQuestPlayerAliasScript extends ReferenceAlias

;--=== Imports ===--

Import Utility
Import Game

;--=== Properties ===--

Quest Property vMFX_MetaQuest Auto

;--=== Variables ===--

;--=== Events ===--

Event OnPlayerLoadGame()
	(vMFX_MetaQuest as vMFX_MetaQuestScript).DoUpkeep()
EndEvent

Event OnUpdate()
	;Do nothing
EndEvent

;--=== Functions ===--
