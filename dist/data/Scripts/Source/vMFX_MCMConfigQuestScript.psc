Scriptname vMFX_MCMConfigQuestScript extends SKI_ConfigBase  

Quest Property vMFX_MetaQuest Auto
Quest Property vMFX_FXRegistryQuest Auto

String[] Pages

Int[]	_SkinOptions
Int[]	_PluginOptions
vMFX_FXRegistryScript _MFXRegistry

Race	HorseRace

Event OnConfigInit()
	_MFXRegistry = vMFX_FXRegistryQuest as vMFX_FXRegistryScript
	ModName = "MountFX Config"
		
	Pages = New String[4]

	Pages[0] = "Options"
	Pages[1] = "Manage plugins"
		

	HorseRace = Game.GetFormFromFile(0x000131fd,"Skyrim.esm") as Race
EndEvent

Event OnGameReload()
    parent.OnGameReload()
	ApplySettings()

EndEvent

Event OnConfigOpen()
	
EndEvent

Event OnPageReset(string a_page)
	UpdateSettings()
EndEvent

Event OnOptionMenuOpen(Int Option)
EndEvent

event OnConfigClose()

endEvent

Function UpdateSettings()

EndFunction

function ApplySettings()

EndFunction
