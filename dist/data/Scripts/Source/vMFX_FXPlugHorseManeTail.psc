Scriptname vMFX_FXPlugHorseManeTail extends vMFX_FXPluginBase  

Import Game
Import Utility

Function SetNodeList()
	dataTextureSwapNodeList = New String[7]
	dataTextureSwapNodeList[0] = "horse:2" 		; Default mane/tail node
	dataTextureSwapNodeList[1] = "horse:4" 		; tail node added by Convenient Horses
	dataTextureSwapNodeList[2] = "Shadowmere:2" 	; mane/tail node for Shadowmere's model
	dataTextureSwapNodeList[3] = "Shadowmere:4" 	; tail node for Shadowmere's model added by Convenient Horses
	dataTextureSwapNodeList[4] = "maneout" 		; mane/tail nodes used by some Animallica models and presumably others
	dataTextureSwapNodeList[5] = "manein" 			; "
	dataTextureSwapNodeList[6] = "tail" 			; "
EndFunction
