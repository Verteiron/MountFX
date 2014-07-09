Scriptname vMFX_PlayerLoadGameAliasScript extends ReferenceAlias  

;--=== Events ===--

Event OnPlayerLoadGame()
	(GetOwningQuest() as vMFX_FXPluginBase).OnGameReload()
EndEvent
