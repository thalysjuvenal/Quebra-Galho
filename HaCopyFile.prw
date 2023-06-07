#include "protheus.ch"


/**************************************************************************************************
Função:
HaCopyFile

Autor:
Thalys Augusto Alves Juvenal

Data:
17/12/2020

Descrição:
Efetua a copia de um arquivo entre o servidor e o Cliente, e vice-versa.

Parâmetros:
Nenhum

Retorno:
Nenhum

**************************************************************************************************/
User Function HaCopyFile
Local cTipoArq 	:= "Todos os Arquivos (*.*)     | *.* |"
Local cArqOrig
Local cArqDest
Local cPathDest

//+-------------------------------------------------+
//| Abre a janela para seleção do arquivo de origem |
//+-------------------------------------------------+
cArqOrig := cGetFile(cTipoArq,"Selecione o arquivo que será copiado",0,,.T.,GETF_LOCALFLOPPY + GETF_LOCALHARD + GETF_NETWORKDRIVE)
cArqDest := SubStr(cArqOrig,RAT("\",cArqOrig) + 1,Len(cArqOrig))

If !Empty(cArqDest)
	If SubStr(cArqOrig,2,1) == ":"
		//+------------------------------------------------+
		//| Abre a janela para seleção da pasta de destino |
		//+------------------------------------------------+
		cPathDest := cGetFile(cTipoArq,"Selecione a pasta de destino",0,,.T., GETF_NETWORKDRIVE + GETF_RETDIRECTORY)
		If !Empty(cPathDest)
			cPathDest := SubStr(cPathDest,1,RAT("\",cPathDest))
			CpyT2S(cArqOrig, cPathDest, .F.)
		EndIf
	Else
		//+------------------------------------------------+
		//| Abre a janela para seleção da pasta de destino |
		//+------------------------------------------------+
		cPathDest := cGetFile(cTipoArq,"Selecione a pasta de destino",0,,.T.,GETF_LOCALFLOPPY + GETF_LOCALHARD + GETF_NETWORKDRIVE + GETF_RETDIRECTORY)
		If !Empty(cPathDest)
			cPathDest := SubStr(cPathDest,1,RAT("\",cPathDest))
			CpyS2T(cArqOrig, cPathDest, .F.)
		EndIf
	EndIf
EndIf
	
Return .T.
