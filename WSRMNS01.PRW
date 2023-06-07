#Include "Protheus.ch"
#Include "RestFul.ch"
#Include "Topconn.ch"
#Include "Tbiconn.ch"
#include "TbiCode.ch"
#include "Fileio.ch"
#Include 'Parmtype.ch'

/****************************************************************************/
/****************************************************************************/
/** Programa 	| WSRMNS01                                                 **/
/****************************************************************************/
/** Autor 		| Thalys Augusto                                 12/04/2021**/
/****************************************************************************/
/** Desc.		| Rotina de comunicação com o WebService da Manusis        **/
/**             | de venda                                                 **/
/****************************************************************************/
/** Uso			| EBBA X MANUSIS                                           **/
/****************************************************************************/
/****************************************************************************/
User Function WSRMNS01()

	Local aArea := {}
	Local lRet  := .T.
	Local cDir, cNom, cArq
	Local nI := 0

	Private cGrpMns := ""
	Private cF06Mns := ""
	Private cF10Mns := ""
	Private cA06Mns := ""
	Private cA10Mns := ""

	Public cLog := ""
	Public aLog := {}

	PREPARE ENVIRONMENT EMPRESA "06" FILIAL "16" Tables "SB1, SB2, SB9, SBM, NNR" MODULO ("EST")

	If Select("SX2") <> 0
		Conout("Ambiente EBBA aberto!")
	Else
		Conout("Erro ao Abrir Ambiente EBBA!")
		Return
	Endif

	aArea := GetArea()

	cGrpMns := SuperGetMV("EB_MNSGRP",.F.,"'1005','1009','1101','1102','1103','1104','1105','1106','1107','1108','1109','1110','1111','1112','1113','1114','1115','1116','1501'")
	cF06Mns := SuperGetMV("EB_MNSF06",.F.,"'02','11','16','17'")
	cF10Mns := SuperGetMV("EB_MNSF10",.F.,"'01','02'")
	cA06Mns := SuperGetMV("EB_MNSA06",.F.,"'PM','PC'")
	cA10Mns := SuperGetMV("EB_MNSA10",.F.,"'PM','PC'")

	cDir := "\SCHEDULES\"
	MakeDir( cDir )

	cDir := "\SCHEDULES\WSRMNS01\"
	MakeDir( cDir )

	cDir := "\SCHEDULES\WSRMNS01\" + DTOS( Date() ) + "\"
	MakeDir( cDir )

	cNom := Substr( Time(), 1, 2 ) + Substr( Time(), 4, 2 ) + Substr( Time(), 7, 2 )
	cArq := cDir + cNom + ".txt"

	aAdd( aLog, "+-----------------------------------------------------------------------+" )
	aAdd( aLog, DTOC( Date() ) + " " + Time() + " ROTINA DE ATUALIZAÇÃO DADOS MANUSIS 4" )
	aAdd( aLog, DTOC( Date() ) + " " + Time() + " WSRMNS01 " )
	aAdd( aLog, "+-----------------------------------------------------------------------+" )
	aAdd( aLog, " " )
	aAdd( aLog, DTOC( Date() ) + " " + Time() + " INICIANDO ATUALIZAÇÃO DOS DADOS" )

	//------------------------------------------------------------
	// Processa os Dados do Almoxarifados - Base tabela NNR
	//------------------------------------------------------------
	aAdd( aLog, DTOC( Date() ) + " " + Time() + " Almoxarifados" )
	ExpAlmox()
	aAdd( aLog, " " )

	//------------------------------------------------------------
	// Processa os Dados dos Grupos de Produtos - Base tabela SBM
	//------------------------------------------------------------
	aAdd( aLog, DTOC( Date() ) + " " + Time() + " Grupos de Produto" )
	ExpGrupo()
	aAdd( aLog, " " )

	//------------------------------------------------------------
	// Processa os Dados dos Produtos - Base tabela SB1
	//------------------------------------------------------------
	aAdd( aLog, DTOC( Date() ) + " " + Time() + " Dados do Produto" )
	ExpProd()
	aAdd( aLog, " " )

	//------------------------------------------------------------
	// Processa os Dados dos Saldos dos Produtos - Base tabela SB2
	//------------------------------------------------------------
	aAdd( aLog, DTOC( Date() ) + " " + Time() + " Saldos de Produto" )
	ExpSld()
	aAdd( aLog, " " )

	aAdd( aLog, "+-----------------------------------------------------------------------+" )
	aAdd( aLog, DTOC( Date() ) + " " + Time() + " Fim da Rotina." )
	aAdd( aLog, "+-----------------------------------------------------------------------+" )

	//-----------------------------------------------------------------------
	// Gerando Mensagem p/ Log
	//-----------------------------------------------------------------------
	For nI := 1 to Len( aLog )
		cLog += aLog[ nI ] + CHR(13) + CHR(10)
	Next
	//-----------------------------------------------------------------------

	// Gravando Log TXT
	MemoWrite( cArq, cLog )

	RestArea( aArea )

	RESET ENVIRONMENT

Return

/****************************************************************************/
/** Programa 	| ProcMetd                                                  **/
/****************************************************************************/
/** Autor 		| Thalys Augusto                            12/04/2021 **/
/****************************************************************************/
/** Desc.		| Rotina de processamento dos Métodos                      **/
/****************************************************************************/
Static Function ProcMetd( nTpo, oRest, oObjJson, cInterfc, cParam, cFilter )

	Local oObjJson
	Local aHeadStr := {}

	Local cUrl 	 := SuperGetMV("EB_MNSURL",.F.,"https://experimente.manusis4.com")
	Local cPath  := SuperGetMV("EB_MNSPATH",.F.,"/api/v1/") + cInterfc
	Local cToken := SuperGetMV("EB_MNSTOKN",.F.,"fcbfe439a7ab41f99a2ca7845bf07cf0")
	Local cRestRet
	Local lRestExe
	Local lRestRet
	Local lRet := .F.
	Local cErro := ""
	Local aRet := {}
	Local cCod := ""
	aAdd( aHeadStr, "App-Origin:API" )
	aAdd( aHeadStr, "Content-Type:application/json" )
	aAdd( aHeadStr, "Authorization:Token token=" + Alltrim( cToken ) )
	aAdd( aHeadStr, "X-Language:pt_BR" )

	If nTpo <> 1
		oRest := FwRest():New( cUrl )
		oRest:SetPath( cPath )
	Endif

	// GET - Consulta
	If nTpo = 1
		aAdd( aLog, DTOC( Date() ) + " " + Time() + " Realizando Get" )
		//cFilter := '?filter=[{"id":"filter","property":"code","value":"'+cParam+'"}]'
		oRest := FwRest():New( cUrl + cPath + cFilter )
		//Exemplo Filtro https://experimente.manusis4.com/api/v1/warehouses?filter=[{"id":"filter","property":"code","value":"0616PM"}]
		lRestExe := oRest:Get( aHeadStr )

		// POST - Inclusao
	ElseIf nTpo = 2
		oRest:SetPostParams( cParam )
		aAdd( aLog, DTOC( Date() ) + " " + Time() + " Realizando Post" )
		aAdd( aLog, DTOC( Date() ) + " " + Time() + " - " + cParam )
		lRestExe := oRest:Post( aHeadStr )

		// PUT - Alteracao
	ElseIf nTpo = 3
		aAdd( aLog, DTOC( Date() ) + " " + Time() + " Realizando Put" )
		aAdd( aLog, DTOC( Date() ) + " " + Time() + " - " + cParam )
		lRestExe := oRest:Put( aHeadStr, cParam )
	EndIf

	If lRestExe
		cRestRet := oRest:GetResult()
		lRestRet := FWJsonDeserialize( cRestRet, @oObjJson )

		lRet := oObjJson:META:SUCCESS

		If lRet
			If nTpo == 1 .And. oObjJson:META:COUNT > 0
				cCod := oObjJson:DATA[1]:ID
			Endif
			aAdd( aLog, DTOC( Date() ) + " " + Time() + " OK" )
		Else
			If AttIsMemberOf( oObjJson:META:ERRORS, "CODE" )
				cErro := DecodeUTF8( oObjJson:META:ERRORS:CODE[1], "cp1252" )
			ElseIf AttIsMemberOf( oObjJson:META:ERRORS, "BASE" )
				cErro := DecodeUTF8( oObjJson:META:ERRORS:BASE[1], "cp1252" )
			EndIf
			Iif(!Empty(cErro),cErro,"Erro interface "+cInterfc)
			aAdd( aLog, DTOC( Date() ) + " " + Time() + " Erro: " + cErro )
		EndIf
	Else
		cRestRet := oRest:GetLastError()
		aAdd( aLog, DTOC( Date() ) + " " + Time() + " Erro: " + cRestRet )
	EndIf

	Aadd(aRet,{lRet,cCod})

Return aRet

/****************************************************************************/
/** Programa 	| ExpAlmox                                                  **/
/****************************************************************************/
/** Autor 		| Thalys Augusto                            12/04/2021 **/
/****************************************************************************/
/** Desc.		| Rotina de carga e registro dos almoxarifados              **/
/****************************************************************************/
Static Function ExpAlmox()

	Local aArea := GetArea()
	Local cSql
	Local lRes := .T.
	Local oRest
	Local oObjJson
	Local cInterfc
	Local cParam
	Local cAre
	Local cCod
	Local cDes
	Local cFilter := ""
	Local cArqQry
	Local cQuery
	Local aOk := Array(1, 2)
	aOk[1,1] := .T.
	aOk[1,2] :=  ""

	cArqQry:= GetNextAlias()
	cQuery := ""
	cQuery += " SELECT DISTINCT '06' EMPRESA, B2_FILIAL, B2_LOCAL, NNR_DESCRI FROM SB2060 B2"
	cQuery += " INNER JOIN NNR060 NNR ON B2_LOCAL = NNR_CODIGO AND NNR_MANUSI = ' ' AND NNR.D_E_L_E_T_ = ''"
	cQuery += " WHERE B2_FILIAL IN ("+cF06Mns+")"
	cQuery += " AND B2_LOCAL IN ("+cA06Mns+")"
	cQuery += " AND B2.D_E_L_E_T_ = ''"
	cQuery += " UNION "
	cQuery += " SELECT DISTINCT '10' EMPRESA, B2_FILIAL, B2_LOCAL, NNR_DESCRI FROM SB2100 B2"
	cQuery += " INNER JOIN NNR060 NNR ON B2_LOCAL = NNR_CODIGO AND NNR_MANUSI = ' ' AND NNR.D_E_L_E_T_ = ''"
	cQuery += " WHERE B2_FILIAL IN ("+cF10Mns+")"
	cQuery += " AND B2_LOCAL IN ("+cA10Mns+")"
	cQuery += " AND B2.D_E_L_E_T_ = ''"
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cArqQry,.F.,.T.)

	DbSelectArea(cArqQry)
	DbGoTop()
	While !Eof()
		cAre := "271"
		cCod := Alltrim(&(cArqQry+"->EMPRESA")) + Alltrim(&(cArqQry+"->B2_FILIAL")) + Alltrim(&(cArqQry+"->B2_LOCAL"))
		cDes := Alltrim(&(cArqQry+"->NNR_DESCRI"))

		aAdd( aLog, DTOC( Date() ) + " " + Time() + " " + cCod + "-" + cDes)

		//---------------------------------------------------------------------------
		// Define os Parametros do Put
		//---------------------------------------------------------------------------
		cInterfc := "warehouses/EBH|||" + cCod + "?by_api_id=1"
		cParam 	:= '{ "description":"' 	+ cDes + '" }'
		//---------------------------------------------------------------------------
		// Realiza o Processamento do Metodo Put
		//---------------------------------------------------------------------------
		aOk := ProcMetd( 3, @oRest, oObjJson, cInterfc, cParam, cFilter )

		//---------------------------------------------------------------------------
		// Atualiza Flag de exportacao de registros
		//---------------------------------------------------------------------------
		If aOk[1,1]
			AtuFlg( 1, "", "", Substr(cCod,5,2), "")
		Else
			//---------------------------------------------------------------------------
			// Define os Parametros do Post
			//---------------------------------------------------------------------------
			cInterfc := "warehouses"
			cParam 	:= '{"area_id":' 		+ cAre + ','   + ;
				'"code":"'    		+ cCod + '",'  + ;
				'"description":"' 	+ cDes + '"}'
			//---------------------------------------------------------------------------
			// Realiza o Processamento do Metodo Post
			//---------------------------------------------------------------------------
			aOk := ProcMetd( 2, oRest, oObjJson, cInterfc, cParam, cFilter )

			//---------------------------------------------------------------------------
			// Atualiza Flag de exportacao de registros
			//---------------------------------------------------------------------------
			If aOk[1,1]
				AtuFlg( 1, "", "", Substr(cCod,5,2), "")
			Endif

		EndIf

		dbSkip()
	EndDo

	If Select(cArqQry) > 0
		dbselectArea(cArqQry)
		dbCloseArea()
	EndIf

	RestArea(aArea)

Return aOk[1,1]

/****************************************************************************/
/** Programa 	| ExpGrupo                                                 **/
/****************************************************************************/
/** Autor 		| Thalys Augusto                           12/04/2021 **/
/****************************************************************************/
/** Desc.		| Rotina de carga e registro dos Grupos de Produtos        **/
/****************************************************************************/
Static Function ExpGrupo()

	Local aArea := GetArea()
	Local cSql
	Local lRes := .T.
	Local oRest
	Local oObjJson
	Local cInterfc
	Local cParam
	Local cAre
	Local cCod
	Local cDes
	Local cFilter := ""
	Local aOk := Array(1, 2)
	aOk[1,1] := .T.
	aOk[1,2] :=  ""

	cArqQry:= GetNextAlias()
	cQuery := ""
	cQuery := " SELECT BM_GRUPO, BM_DESC FROM SBM060"
	cQuery += " WHERE BM_FILIAL = ''"
	cQuery += " AND BM_GRUPO IN ("+cGrpMns+")"
	cQuery += " AND BM_MANUSIS = ''"
	cQuery += " AND D_E_L_E_T_ = ''"
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cArqQry,.F.,.T.)
	DbSelectArea(cArqQry)
	DbGoTop()

	While !Eof()
		cAre := "271"
		cCod := Alltrim(&(cArqQry+"->BM_GRUPO"))
		cDes := Alltrim(&(cArqQry+"->BM_DESC"))

		aAdd( aLog, DTOC( Date() ) + " " + Time() + " " + cCod + "-" + cDes )

		//---------------------------------------------------------------------------
		// Define os Parametros do Put
		//---------------------------------------------------------------------------
		cInterfc := "material_groups/" + cCod + "?by_api_id=1"
		cParam 	:= '{ "description":"' + cDes + '" }'

		//---------------------------------------------------------------------------
		// Realiza o Processamento do Metodo Put
		//---------------------------------------------------------------------------
		aOk := ProcMetd( 3, @oRest, oObjJson, cInterfc, cParam, cFilter )

		//---------------------------------------------------------------------------
		// Atualiza Flag de exportacao de registros
		//---------------------------------------------------------------------------
		If aOk[1,1]
			AtuFlg( 2, "", "", cCod, "")
		Else
			//---------------------------------------------------------------------------
			// Define os Parametros do Post
			//---------------------------------------------------------------------------
			cInterfc := "material_groups"
			cParam 	:= '{"area_id":' 		+ cAre + ','   + ;
				'"code":"'    		+ cCod + '",'  + ;
				'"description":"' 	+ cDes + '"}'
			//---------------------------------------------------------------------------
			// Realiza o Processamento do Metodo Post
			//---------------------------------------------------------------------------
			aOk := ProcMetd( 2, oRest, oObjJson, cInterfc, cParam, cFilter )

			//---------------------------------------------------------------------------
			// Atualiza Flag de exportacao de registros
			//---------------------------------------------------------------------------
			If aOk[1,1]
				AtuFlg( 2, "", "", cCod, "")
			Endif
		EndIf

		dbSkip()
	EndDo

	If Select(cArqQry) > 0
		dbselectArea(cArqQry)
		dbCloseArea()
	EndIf

	RestArea( aArea )

Return aOk[1,1]

/****************************************************************************/
/** Programa 	| ExpProd                                                  **/
/****************************************************************************/
/** Autor 		| Thalys Augusto                                   12/04/2021 **/
/****************************************************************************/
/** Desc.		| Rotina de carga e registro de Cadastro de Produtos       **/
/****************************************************************************/
Static Function ExpProd()

	Local aArea		:= GetArea()
	Local cQuery	:= ""
	Local lRes		:= .T.
	Local cUM		:= ""
	Local cArqQry
	Local oRest
	Local oObjJson
	Local cInterfc
	Local cParam
	Local cAre
	Local cCod
	Local cDes
	Local cGrp
	Local cFilter := ""
	Local aOk := Array(1, 2)
	aOk[1,1] := .T.
	aOk[1,2] :=  ""

	cArqQry:= GetNextAlias()
	cQuery := ""
	cQuery := " SELECT B1_COD, B1_DESC, B1_GRUPO,"
	cQuery += " CASE B1_UM"
	cQuery += " WHEN 'KM' THEN '1'"
	cQuery += " WHEN 'M'  THEN '2'"
	cQuery += " WHEN 'CM' THEN '3'"
	cQuery += " WHEN 'L'  THEN '4'"
	cQuery += " WHEN 'ML' THEN '5'"
	cQuery += " WHEN 'PT' THEN '6'"
	cQuery += " WHEN 'CX' THEN '7'"
	cQuery += " WHEN 'PC' THEN '8'"
	cQuery += " WHEN 'UN' THEN '9'"
	cQuery += " WHEN 'KG' THEN '10'"
	cQuery += " WHEN 'G'  THEN '11'"
	cQuery += " WHEN 'TL' THEN '12'"
	cQuery += " ELSE '9'  END AS B1_UM"
	cQuery += " FROM SB1060"
	cQuery += " WHERE B1_FILIAL = ''"
	cQuery += " AND B1_GRUPO IN ("+cGrpMns+")"
	cQuery += " AND B1_MANUSIS = ''"
	cQuery += " AND D_E_L_E_T_ = ''"
	cQuery += " ORDER BY B1_GRUPO, B1_COD"
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cArqQry,.F.,.T.)

	DbSelectArea(cArqQry)
	DbGoTop()
	While !Eof()

		//---------------------------------------------------------------------------
		// Define os Parametros do Get
		//---------------------------------------------------------------------------
		cInterfc := "material_groups"
		cParam 	:= Alltrim(&(cArqQry+"->B1_GRUPO"))
		cFilter := '?filter=[{"id":"filter","property":"code","value":"'+cParam+'"}]'

		//Exemplo Filtro https://experimente.manusis4.com/api/v1/warehouses?filter=[{"id":"filter","property":"code","value":"0616PM"}]
		//---------------------------------------------------------------------------
		// Realiza o Processamento do Metodo Get
		//---------------------------------------------------------------------------
		aOk := ProcMetd( 1, @oRest, oObjJson, cInterfc, cParam, cFilter )
		//---------------------------------------------------------------------------

		If aOk[1,1]
			cAre := "271"
			cCod := Alltrim(&(cArqQry+"->B1_COD"))
			cDes := Alltrim(&(cArqQry+"->B1_DESC"))
			cGrp := Alltrim(Str(aOk[1,2]))
			cUM  := &(cArqQry+"->B1_UM")
			aAdd( aLog, DTOC( Date() ) + " " + Time() + " " + cCod + "-" + cDes )

			//---------------------------------------------------------------------------
			// Define os Parametros do Put
			//---------------------------------------------------------------------------
			cInterfc := "materials/" + cCod + "?by_api_id=1"
			cParam 	:= '{ "description":"' 		+ cDes + '",' + ;
				'"material_group_id":"' + cGrp + '",'  + ;
				'"measure_unit_id":' 	+ cUM  + '}'

			//---------------------------------------------------------------------------
			// Realiza o Processamento do Metodo Put
			//---------------------------------------------------------------------------
			aOk := ProcMetd( 3, @oRest, oObjJson, cInterfc, cParam, cFilter )

			//---------------------------------------------------------------------------
			// Atualiza Flag de exportacao de registros
			//---------------------------------------------------------------------------
			If aOk[1,1]
				AtuFlg(3 ,"" , "",Alltrim(&(cArqQry+"->B1_COD")) , "")
			Else
				//---------------------------------------------------------------------------
				// Define os Parametros do Post
				//---------------------------------------------------------------------------

				cInterfc := "materials"
				cParam 	:= '{"area_id":' 	+ cAre + ','  + ;
					'"code":"'    				+ cCod + '",' + ;
					'"description":"'		 	+ cDes + '",' + ;
					'"material_group_id":"' 	+ cGrp + '",'  + ;
					'"measure_unit_id":' 		+ cUM  + '}'

				//---------------------------------------------------------------------------
				// Realiza o Processamento do Metodo Post
				//---------------------------------------------------------------------------
				aOk := ProcMetd( 2, oRest, oObjJson, cInterfc, cParam, cFilter )

				//---------------------------------------------------------------------------
				// Atualiza Flag de exportacao de registros
				//---------------------------------------------------------------------------
				If aOk[1,1]
					AtuFlg(3, "", "",Alltrim(&(cArqQry+"->B1_COD")), "")
				EndIf
			EndIf
		Endif

		DbselectArea(cArqQry)
		dbSkip()
	EndDo

	If Select(cArqQry) > 0
		dbselectArea(cArqQry)
		dbCloseArea()
	EndIf

	RestArea( aArea )

Return aOk[1,1]

/****************************************************************************/
/** Programa 	| ExpSld                                                   **/
/****************************************************************************/
/** Autor 		| Thalys Augusto                                   12/04/2021 **/
/****************************************************************************/
/** Desc.		| Rotina de carga e registro de Saldos de Produtos         **/
/****************************************************************************/
Static Function ExpSld()

	Local aArea		:= GetArea()
	Local cQuery	:= ""
	Local lRes		:= .T.
	Local cArqQry
	Local oRest
	Local oObjJson
	Local cInterfc
	Local cParam
	Local cAre
	Local cCod
	Local cAlm
	Local nCM1
	Local nSld
	Local cFilter := ""
	Local dDtfech := Dtos(GetMV("MV_ULMES"))
	Local aOk := Array(1, 2)
	aOk[1,1] := .T.
	aOk[1,2] :=  ""

	cArqQry:= GetNextAlias()
	cQuery := ""
	cQuery := " SELECT B2_COD, '06'+B2_FILIAL+B2_LOCAL AS ALMOX, B2_QATU, B2_CM1, B1_DESC, B2_LOCAL, ISNULL(B9_CM1,0) B9_CM1, B2_FILIAL FROM SB2060 B2"
	cQuery += " INNER JOIN SB1060 B1 ON B1_FILIAL = '' AND B1_MSBLQL <> '1' AND B2_COD = B1_COD AND B1.D_E_L_E_T_ = ''"
	cQuery += " LEFT JOIN SB9060 B9 ON B2_FILIAL = B9_FILIAL AND B2_COD = B9_COD AND B9_DATA = '"+dDtfech+"'  AND B2_LOCAL = B9_LOCAL AND B9.D_E_L_E_T_ = ''"
	cQuery += " WHERE B2_FILIAL IN ("+cF06Mns+")"
	cQuery += " AND B2_COD IN"
	cQuery += " (SELECT B1_COD FROM SB1060 WHERE B1_FILIAL = '' AND B1_GRUPO IN ("+cGrpMns+") AND D_E_L_E_T_ = '')"
	cQuery += " AND B2_LOCAL IN ("+cA06Mns+")"
	cQuery += " AND B2_MANUSIS = ''"
	cQuery += " AND B2.D_E_L_E_T_ = ''"
	cQuery += " UNION"
	cQuery += " SELECT B2_COD, '10'+B2_FILIAL+B2_LOCAL AS ALMOX, B2_QATU, B2_CM1, B1_DESC, B2_LOCAL, ISNULL(B9_CM1,0) B9_CM1, B2_FILIAL FROM SB2100 B2"
	cQuery += " INNER JOIN SB1060 B1 ON B1_FILIAL = '' AND B1_MSBLQL <> '1' AND B2_COD = B1_COD AND B1.D_E_L_E_T_ = ''"
	cQuery += " LEFT JOIN SB9100 B9 ON B2_FILIAL = B9_FILIAL AND B2_COD = B9_COD AND B9_DATA = '"+dDtfech+"'  AND B2_LOCAL = B9_LOCAL AND B9.D_E_L_E_T_ = ''"
	cQuery += " WHERE B2_FILIAL IN ("+cF10Mns+")"
	cQuery += " AND B2_COD IN"
	cQuery += " (SELECT B1_COD FROM SB1060 WHERE B1_FILIAL = '' AND B1_GRUPO IN ("+cGrpMns+") AND D_E_L_E_T_ = '')"
	cQuery += " AND B2_LOCAL IN ("+cA10Mns+")"
	cQuery += " AND B2_MANUSIS = ''"
	cQuery += " AND B2.D_E_L_E_T_ = ''"
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cArqQry,.F.,.T.)

	DbSelectArea(cArqQry)
	DbGoTop()
	While !Eof()
		cAre := "271"
		nSld :=  Alltrim(Str(&(cArqQry+"->B2_QATU")))
		nCM1 :=  Alltrim(Str(&(cArqQry+"->B9_CM1")))

		aAdd( aLog, DTOC( Date() ) + " " + Time() + " " + Alltrim(&(cArqQry+"->B2_COD")) + "-" + Alltrim(&(cArqQry+"->B1_DESC")) )

		//---------------------------------------------------------------------------
		// Define os Parametros do Get - Valida existencia do almoxarifado
		//---------------------------------------------------------------------------
		cInterfc := "warehouses"
		cParam 	:= Alltrim(&(cArqQry+"->ALMOX"))
		cFilter := '?filter=[{"id":"filter","property":"code","value":"'+cParam+'"}]'

		//---------------------------------------------------------------------------
		// Realiza o Processamento do Metodo Get, obtem almoxarifado
		//---------------------------------------------------------------------------
		aOk := ProcMetd( 1, @oRest, oObjJson, cInterfc, cParam, cFilter )
		//---------------------------------------------------------------------------

		If aOk[1,1]

			cAlm := Alltrim(Str(aOk[1,2]))

			//---------------------------------------------------------------------------
			// Define os Parametros do Get - Valida existencia do produto
			//---------------------------------------------------------------------------
			cInterfc := "materials"
			cParam 	 := Alltrim(&(cArqQry+"->B2_COD"))
			cFilter := '?filter=[{"id":"filter","property":"code","value":"'+cParam+'"}]'

			//---------------------------------------------------------------------------
			// Realiza o Processamento do Metodo Get, obtem codigo do produto
			//---------------------------------------------------------------------------
			aOk := ProcMetd( 1, @oRest, oObjJson, cInterfc, cParam, cFilter )
			//---------------------------------------------------------------------------
			If aOk[1,1]
				cInterfc := "warehouses_materials"
				cCod := Alltrim(Str(aOk[1,2]))
				cParam 	:= ""
				cFilter := '?filter=[{"id":"filter","property":"material_id","value":'+cCod+'}]&?filter2=[{"id":"filter2","property":"warehouse_id","value":'+cAlm+'}]'

				//---------------------------------------------------------------------------
				// Realiza o Processamento do Metodo Get, obtem registro produto x local
				//---------------------------------------------------------------------------
				aOk := ProcMetd( 1, @oRest, oObjJson, cInterfc, cParam, cFilter )
				//---------------------------------------------------------------------------

				If aOk[1,1] .And. !Empty(aOk[1,2])
					//---------------------------------------------------------------------------
					// Define os Parametros do Put
					//---------------------------------------------------------------------------
					cInterfc := "warehouses_materials/" + Alltrim(Str(aOk[1,2]))
					cParam 	 := '{"material_id":' 	+ cCod + ','+ ;
						'"warehouse_id":' 	+ cAlm + ','+ ;
						'"current_stock":'	+ nSld + ','+ ;
						'"unitary_cost":' 	+ nCM1 + '}'
					//---------------------------------------------------------------------------
					// Realiza o Processamento do Metodo Put
					//---------------------------------------------------------------------------
					aOk := ProcMetd( 3, @oRest, oObjJson, cInterfc, cParam )
					//---------------------------------------------------------------------------
					// Atualiza Flage de exportacao de registros
					//---------------------------------------------------------------------------
					If aOk[1,1]
						AtuFlg(4, Substr(&(cArqQry+"->ALMOX"),1,2), Substr(&(cArqQry+"->ALMOX"),3,2), Alltrim(&(cArqQry+"->B2_COD")), Alltrim(&(cArqQry+"->B2_LOCAL")))
					Endif
				Else
					//---------------------------------------------------------------------------
					// Define os Parametros do Post
					//---------------------------------------------------------------------------
					cInterfc := "warehouses_materials"
					cParam 	 := '{"area_id":'+ cAre + ','   + ;
						'"material_id":'    	 + cCod + ','  + ;
						'"warehouse_id":'		 + cAlm + ','  + ;
						'"current_stock":' 		 + nSld + ','  + ;
						'"unitary_cost":' 		 + nCM1 + '}'
					//---------------------------------------------------------------------------
					// Realiza o Processamento do Metodo Post
					//---------------------------------------------------------------------------
					aOk := ProcMetd( 2, oRest, oObjJson, cInterfc, cParam )
					//---------------------------------------------------------------------------
					// Atualiza Flag de exportacao de registros
					//---------------------------------------------------------------------------
					If aOk[1,1]
						AtuFlg(4, Substr(&(cArqQry+"->ALMOX"),1,2), Substr(&(cArqQry+"->ALMOX"),3,2), Alltrim(&(cArqQry+"->B2_COD")), Alltrim(&(cArqQry+"->B2_LOCAL")))
					Endif
				Endif
			EndIf
		Endif
		DbselectArea(cArqQry)
		dbSkip()
	EndDo

	//---------------------------------------------------------------------------
	// Atualiza registros que foram exportados para Manusis
	//---------------------------------------------------------------------------

	If Select(cArqQry) > 0
		dbselectArea(cArqQry)
		dbCloseArea()
	EndIf

	RestArea( aArea )

Return aOk[1,1]

/****************************************************************************/
/** Programa 	| AtuFlg                                                   **/
/****************************************************************************/
/** Autor 		| Thalys Augusto                                   12/04/2021 **/
/****************************************************************************/
/** Desc.		| Rotina de atualizacao do Flag Integracao Protheus/Manusis**/
/****************************************************************************/
Static Function AtuFlg(nOpc, cEmp, cFil, cCod, cLoc)
	Local cQry := ""
	Local nOk  := 0
	cFlag := Dtos(Date())

	ConOut("Iniciando gravacao flag ..."+Alltrim(Str(nOpc)) )

	Do Case
		Case nOpc == 1
			cQry := ""
			cQry := " UPDATE NNR060 SET NNR_MANUSI = '"+cFlag+"'"
			cQry += " WHERE NNR_FILIAL = ''"
			cQry += " AND NNR_CODIGO = '"+cCod+"'"
			cQry += " AND D_E_L_E_T_ = ''"
		Case nOpc == 2
			cQry := ""
			cQry := " UPDATE SBM060 SET BM_MANUSIS = '"+cFlag+"'"
			cQry += " WHERE BM_FILIAL = ''"
			cQry += " AND BM_GRUPO = '"+cCod+"'"
			cQry += " AND D_E_L_E_T_ = ''"
		Case nOpc == 3
			cQry := " UPDATE SB1060 SET B1_MANUSIS = '"+cFlag+"'"
			cQry += " WHERE B1_FILIAL = ''"
			cQry += " AND B1_COD = '"+cCod+"'"
			cQry += " AND D_E_L_E_T_ = ' '"
		Case nOpc == 4
			cQry := " UPDATE SB2"+cEmp+"0 SET B2_MANUSIS = '"+cFlag+"'"
			cQry += " WHERE B2_FILIAL = '"+cFil+"'"
			cQry += " AND B2_COD = '"+cCod+"'"
			cQry += " AND B2_LOCAL = '"+cLoc+"'"
			cQry += " AND D_E_L_E_T_ = ' '"
	EndCase

	nOk := TCSqlExec(cqry)

	If (nOk < 0)
		conout("TCSQLError() " + TCSQLError())
	Endif

	ConOut("Finalizando flag produtos...")

Return(nOk)

//--------------------------------

//@example: http://localhost:8082/wsrprotheus/FINAPV01?Empresa=99&xFilial=01&xPedido=000032
//@example: http://192.168.5.202:8082/WSEBBA/WSMNS01?xEmpresa=06&xFilial=16&xNumSA=345105
//@example: http://192.168.5.202:8082/WSEBBA/WSMNS01?xEmpresa=06&xFilial=16&xNumSA=345494&xItem=01
//@example: http://192.168.5.202:8082/WSEBBA/WSMNS01?xEmpresa=06&xFilial=16&xProduto=100200300051&xQuant=1&xLocal=PC&xCCusto=200501&xObserv=TESTE&xManusis=999999

//**************************************************************//
// Webservice RestFul             		       Data: 12/04/2021 //
// Desenvovido por Thalys Augusto                               //
// Responsável pela integracao entre Protheus e Manusis         //
// integrando as Solicitacoes ao Almoxarifado                   //
//**************************************************************//
User Function WSRMNS02()
Return

WSRestFul WSMNS01 DESCRIPTION "Tratamento de Solicitações ao Almoxarifado"

	// Definição das Variáveis
	WSData xEmpresa	as String
	WSData xFilial	as String
	WSData xNumSA	as String
	WSData xItem	as String
	WSData xProduto	as String
	WSData xQuant	as Float
	WSData xLocal	as String
	WSData xCCusto	as String
	WSData xObserv	as String
	WSData xManusis as String

	// Definição da Descrição do Método Get
	WSMethod Get DESCRIPTION "Método GET para Consulta dos dados de Solicitação ao Almoxarifado"

	// Definição da Descrição do Método Post
	WSMethod Post DESCRIPTION "Método POST para Inclusão de Solicitação ao Almoxarifado"

	// Definição da Descrição do Método Put
	WSMethod Put DESCRIPTION "Método PUT para Alteração de Solicitação ao Almoxarifado"

	// Definição da Descrição do Método Delete
	WSMethod Delete DESCRIPTION "Método DELETE para Exclusão de Solicitação ao Almoxarifado"

End WSRestFul

//**************************************************************//
// Definição do Método Get                                      //
//**************************************************************//

WSMethod Get WSReceive xEmpresa, xFilial, xNumSA WSService WSMNS01

	Local aVld 	:= {}
	Local oDat 	:= JsonObject():New()
	Local oIte 	:= JsonObject():New()
	Local oJson := JsonObject():New()

	Local xEmp
	Local xFil
	Local xSA
	Local aAux  := {}
	Local lRet  := .T.
	Local nI	:= 0
	Local cJson := ""

	// Finaliza o ambiente e abre novo ambiente
	RESET ENVIRONMENT
	Sleep(1000)

	PREPARE ENVIRONMENT EMPRESA (::xEmpresa) FILIAL (::xFilial)

	::SetContentType("application/json")

	//---------------------------------------
	// Validando os Dados Informados
	//---------------------------------------
	// Validando Parâmetro Filial
	If ValType( ::xEmpresa ) <> "U"
		// Validando Parâmetro Filial
		If ValType( ::xFilial ) <> "U"
			// Validando Parâmetro Pedido
			If ValType( ::xNumSA ) <> "U"
				xEmp := PADL( Alltrim( ::xEmpresa ), 2, "0" )
				xFil := PADL( Alltrim( ::xFilial ),  2, "0" )
				xSA  := PADR( Alltrim( ::xNumSA ),  TamSx3( "CQ_NUM" )[1] )

				aAux := ObtSA(xEmp, xFil, xSA)

				If ValType( aAux ) == "A" .And. Len( aAux ) > 0
					aAdd( aVld, aAux[ 1, 1 ] )
					aAdd( aVld, aAux[ 1, 2 ] )
					For nI := 1 To Len(aAux[2])
						oDat[ cValToChar( nI ) ] := JsonObject():New()
						oDat[ cValToChar( nI ) ][ "Empresa" ]		:= aAux[ 02, nI, 01 ]
						oDat[ cValToChar( nI ) ][ "Filial" ]		:= aAux[ 02, nI, 02 ]
						oDat[ cValToChar( nI ) ][ "Numero" ]		:= aAux[ 02, nI, 03 ]
						oDat[ cValToChar( nI ) ][ "Manusis" ]		:= aAux[ 02, nI, 04 ]
						oDat[ cValToChar( nI ) ][ "Emissao" ]		:= aAux[ 02, nI, 05 ]
						oDat[ cValToChar( nI ) ][ "Item" ]			:= aAux[ 02, nI, 06 ]
						oDat[ cValToChar( nI ) ][ "Produto" ] 		:= aAux[ 02, nI, 07 ]
						oDat[ cValToChar( nI ) ][ "Descricao" ]		:= aAux[ 02, nI, 08 ]
						oDat[ cValToChar( nI ) ][ "Unidade" ] 		:= aAux[ 02, nI, 09 ]
						oDat[ cValToChar( nI ) ][ "Almox" ] 		:= aAux[ 02, nI, 10 ]
						oDat[ cValToChar( nI ) ][ "QdeSolicitada" ] := aAux[ 02, nI, 11 ]
						oDat[ cValToChar( nI ) ][ "QdeEntregue" ] 	:= aAux[ 02, nI, 12 ]
						oDat[ cValToChar( nI ) ][ "DataEntrega" ] 	:= aAux[ 02, nI, 13 ]
						oDat[ cValToChar( nI ) ][ "Situacao" ]		:= aAux[ 02, nI, 14 ]
						oDat[ cValToChar( nI ) ][ "Observacao" ]	:= aAux[ 02, nI, 15 ]
					Next nI
				Else
					aAdd( aVld, .F. )
					aAdd( aVld, "Erro no acesso a empresa/filial destino!" )
				EndIf
			Else
				aAdd( aVld, .F. )
				aAdd( aVld, "Parametro [xNumSA] inválido ou não informado!" )
			EndIf
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xFilial] inválido ou não informado!" )
		EndIf
	Else
		aAdd( aVld, .F. )
		aAdd( aVld, "Parametro [xEmpresa] inválido ou não informado!" )
	EndIf

	oJson[ "valid" ] := aVld
	oJson[ "data" ]  := oDat

	cJson := oJson:ToJson()
	::SetResponse( EncodeUTF8( cJson, "cp1252" ) )

Return lRet

/****************************************************************************/
/** Programa 	| ObtSA                                                    **/
/****************************************************************************/
/** Autor 		| Thalys Augusto                                12/04/2021 **/
/****************************************************************************/
/** Desc.		| Rotina responsável pela obtencao dos dados da SA         **/
/****************************************************************************/
Static Function ObtSA(xEmp, xFil, xNumSA)
	Local cQuery := ""
	Local cArqQry
	Local aRes := {}
	Local aVld := {}
	Local aDat := {}

	cArqQry:= GetNextAlias()
	cQuery := ""
	cQuery += " SELECT CQ_FILIAL, CQ_NUM, CP_MANUSIS, CP_DTMANUS, CP_EMISSAO, CQ_ITEM, CQ_LOCAL, CQ_PRODUTO, CQ_DESCRI,"
	cQuery += " CASE WHEN CP_STATUS = '' THEN 'ABERTO' ELSE 'ENCERRADA' END AS CP_STATUS, MAX(CQ_OBS) CQ_OBS, CQ_UM,"
	cQuery += " MAX(CQ_QUANT) CQ_QUANT, MAX(ISNULL(D3_EMISSAO,'')) AS D3_EMISSAO, SUM(ISNULL(D3_QUANT, 0)) D3_QUANT"
	cQuery += " FROM SCQ"+xEmp+"0 CQ"
	cQuery += " INNER JOIN SCP"+xEmp+"0 CP ON CQ_FILIAL = CP_FILIAL AND CQ_NUM = CP_NUM AND CQ_ITEM = CP_ITEM AND CP.D_E_L_E_T_ = ''"
	cQuery += " LEFT JOIN SD3"+xEmp+"0 D3 ON CQ_FILIAL = D3_FILIAL AND CQ_NUMREQ = D3_NUMSEQ AND D3_NUMSEQ <> '' AND D3.D_E_L_E_T_ = ''"
	cQuery += " WHERE CQ_FILIAL = '"+xFil+"'"
	cQuery += " AND CQ_NUM = '"+xNumSA+"'"
	cQuery += " AND CQ.D_E_L_E_T_ = ''"
	cQuery += " GROUP BY CQ_FILIAL, CQ_NUM, CP_MANUSIS, CP_DTMANUS, CP_EMISSAO, CQ_ITEM, CQ_LOCAL, CQ_PRODUTO, CQ_DESCRI, CP_STATUS, CQ_UM"
	cQuery += " ORDER BY CQ_FILIAL, CQ_NUM, CQ_ITEM"
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cArqQry,.F.,.T.)

	Tcsetfield(cArqQry,"CP_DTMANUS","D")
	Tcsetfield(cArqQry,"CP_EMISSAO","D")
	Tcsetfield(cArqQry,"D3_EMISSAO","D")

	DbGotop()
	If !Eof()
		aAdd( aVld, .T. )
		aAdd( aVld, "" )
		While !Eof()//Transform(&(cArqQry+"->D3_QUANT"),"@E 999,999,999.9999" )
			Aadd(aDat,{xEmp, &(cArqQry+"->CQ_FILIAL"), &(cArqQry+"->CQ_NUM"), &(cArqQry+"->CP_MANUSIS"), Dtoc(&(cArqQry+"->CP_EMISSAO")), &(cArqQry+"->CQ_ITEM"), &(cArqQry+"->CQ_PRODUTO"), &(cArqQry+"->CQ_DESCRI"), &(cArqQry+"->CQ_UM"), &(cArqQry+"->CQ_LOCAL"),   cValToChar(&(cArqQry+"->CQ_QUANT")), cValToChar(&(cArqQry+"->D3_QUANT")), Dtoc(&(cArqQry+"->D3_EMISSAO")), &(cArqQry+"->CP_STATUS"), &(cArqQry+"->CQ_OBS")})
			DbSkip()
		End
	Else
		aAdd( aVld, .F. )
		aAdd( aVld, "Solicitação "+xNumSA+" não encontrada!" )
	Endif

	If Select(cArqQry) > 0
		dbselectArea(cArqQry)
		dbCloseArea()
	EndIf

	aAdd( aRes, aVld )
	aAdd( aRes, aDat )

Return(aRes)

//**************************************************************//
// Definição do Método Delete                                   //
//**************************************************************//
WSMethod Delete WSReceive xEmpresa, xFilial, xNumSA, xItem WSService WSMNS01

	Local aVld 	:= {}
	Local oDat 	:= JsonObject():New()
	Local oIte 	:= JsonObject():New()
	Local oJson := JsonObject():New()

	Local xEmp
	Local xFil
	Local xSA
	Local xIt
	Local lRet			:= .T.
	Local cJson			:= ""
	Local aItem 		:= {}
	Local aCab 			:= {}
	Local aCamposSCP	:= {}
	Local aCamposSD3	:= {}
	Local lMSHelpAuto	:= .F.
	Local lMsErroAuto	:= .F.

	::SetContentType("application/json")

	//---------------------------------------
	// Validando os Dados Informados
	//---------------------------------------
	// Validando Parâmetro Filial
	If ValType( ::xEmpresa ) <> "U"
		// Validando Parâmetro Filial
		If ValType( ::xFilial ) <> "U"
			xEmp := PADL( Alltrim( ::xEmpresa ), 2, "0" )
			xFil := PADL( Alltrim( ::xFilial ),  2, "0" )

			//-- Empresa e Filial sao validos
			//-- Finaliza o ambiente corrente
			//-- abre ambiente selecionado
			RESET ENVIRONMENT
			Sleep(1000)

			PREPARE ENVIRONMENT EMPRESA (::xEmpresa) FILIAL (::xFilial)

			// Validando Parâmetro SA
			If ValType( ::xNumSA ) <> "U"
				// Validando Parâmetro Item
				If ValType( ::xItem ) <> "U"
					xSA  := PADR( Alltrim( ::xNumSA ),  TamSx3( "CQ_NUM" )[1] )
					xIt  := PADR( Alltrim( ::xItem ),  TamSx3( "CQ_ITEM" )[1] )
					DbSelectArea("SCP")
					DbSetOrder(1) // CP_FILIAL+CP_NUM+CP_ITEM+DTOS(CP_EMISSAO)
					If DbSeek(FWxFilial("SCP")+xSA+xIt)
						If SCP->CP_STATUS == " "
							aCab:= {{"CP_SOLICIT"	,SCP->CP_SOLICIT	,NIL},;
								{"CP_EMISSAO"	,SCP->CP_EMISSAO	,NIL},;
								{"CP_NUM"		,SCP->CP_NUM		,NIL}}

							Aadd (aItem,{{"CP_PRODUTO"	,SCP->CP_PRODUTO	,NIL},;
								{"CP_ITEM"		,SCP->CP_ITEM		,NIL},;
								{"CP_QUANT"		,SCP->CP_QUANT		,NIL},;
								{"CP_LOCAL" 	,SCP->CP_LOCAL		,NIL},;
								{"CP_DESCRI"	,SCP->CP_DESCRI		,NIL},;
								{"CP_UM" 	  	,SCP->CP_UM			,NIL},;
								{"CP_CC"	  	,SCP->CP_CC			,NIL},;
								{"CP_CONTA"		,SCP->CP_CONTA		,NIL},;
								{"CP_QTSEGUM"	,SCP->CP_QTSEGUM	,NIL},;
								{"CP_SEGUM" 	,SCP->CP_SEGUM		,NIL},;
								{"CP_OBS"		,SCP->CP_OBS		,NIL},;
								{"CP_MANUSIS"	,SCP->CP_MANUSIS	,NIL},;
								{"CP_DATPRF"  	,SCP->CP_DATPRF		,NIL}})
							lMsErroAuto := .F.
							MSExecAuto({|x,y,z| mata105(x,y,z)},aCab,aItem,5)
							If lMsErroAuto
								aAdd( aVld, .F. )
								aAdd( aVld, "Erro na exclusão da SA!")
							Else
								aAdd( aVld, .T. )
								aAdd( aVld, "Excluida com sucesso!" )
							Endif
						Else
							aAdd( aVld, .F. )
							aAdd( aVld, "SA ja encerrada!" )
						Endif
					Else
						aAdd( aVld, .F. )
						aAdd( aVld, "Parametro [xNumSA] inválido!" )
					Endif
				Else
					aAdd( aVld, .F. )
					aAdd( aVld, "Parametro [xItem] inválido ou não informado!" )
				EndIf
			Else
				aAdd( aVld, .F. )
				aAdd( aVld, "Parametro [xNumSA] inválido ou não informado!" )
			EndIf
			RESET ENVIRONMENT
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xFilial] inválido ou não informado!" )
		EndIf
	Else
		aAdd( aVld, .F. )
		aAdd( aVld, "Parametro [xEmpresa] inválido ou não informado!" )
	EndIf

	oJson[ "valid" ] := aVld
	oJson[ "data" ]  := oDat

	cJson := oJson:ToJson()
	::SetResponse( EncodeUTF8( cJson, "cp1252" ) )

Return lRet

//**************************************************************//
// Definição do Método Post                                     //
//**************************************************************//
WSMethod Post WSReceive xEmpresa, xFilial, xProduto, xQuant, xLocal, xCCusto, xObserv, xManusis WSService WSMNS01

	Local aVld 	:= {}
	Local oDat 	:= JsonObject():New()
	Local oIte 	:= JsonObject():New()
	Local oJson := JsonObject():New()
	Local xEmp
	Local xFil
	Local xPrd
	Local nQde
	Local cAlm
	Local xCC
	Local xConta
	Local x2UM
	Local xUM
	Local xObs
	Local cItSA			:= "00"
	Local cNumSA		:= ""
	Local aItem 		:= {}
	Local aCab			:= {}
	Local lRet			:= .T.
	Local cJson			:= ""
	Local lMSHelpAuto	:= .F.
	Local lMsErroAuto	:= .F.

	::SetContentType("application/json")

	//-- Validando Parâmetro Filial
	If ValType( ::xEmpresa ) <> "U"

		//-- Validando Parâmetro Filial
		If ValType( ::xFilial ) <> "U"
			xEmp := PADL( Alltrim( ::xEmpresa ), 2, "0" )
			xFil := PADL( Alltrim( ::xFilial ),  2, "0" )

			//-- Empresa e Filial sao validos
			//-- Finaliza o ambiente corrente
			//-- abre ambiente selecionado
			RESET ENVIRONMENT
			Sleep(1000)

			PREPARE ENVIRONMENT EMPRESA (::xEmpresa) FILIAL (::xFilial)

			//-- Validando Produto
			If ValType( ::xProduto ) <> "U"
				xPrd  := PADR( Alltrim( ::xProduto ),  TamSx3( "B1_COD" )[1] )
				DbSelectArea("SB1")
				DbSetOrder(1)
				If DbSeek(FWxFilial("SB1")+xPrd)
					xUM		:= SB1->B1_UM
					x2UM	:= SB1->B1_SEGUM
					xDesc	:= SB1->B1_DESC
					xConta	:= SB1->B1_CONTA
					//-- Validando Quantidade
					nQde := ::xQuant
					If nQde > 0
						nQ2UM := ConvUM(xPrd, nQde, 0, 2)
						//-- Validando Local
						cAlm := PADR( Alltrim( ::xLocal ), TamSx3( "NNR_CODIGO" )[1] )
						DbSelectArea("NNR")
						DbSetOrder(1)
						If DbSeek( FWxFilial("NNR") + cAlm )
							//-- Validando Centro de Custos
							xCC := PADR( Alltrim( ::xCCusto ), TamSx3( "CTT_CUSTO" )[1] )
							DbSelectArea("CTT")
							DbSetOrder(1)
							If DbSeek(FWxFilial("CTT")+xCC)
								xObs := Alltrim(::xObserv)
								xMns := ::xManusis
								cItSA := Soma1(cItSA,2)
								Aadd (aItem,{{"CP_PRODUTO" 	,xPrd		,NIL},;
									{"CP_ITEM"		,cItSA		,NIL},;
									{"CP_QUANT"	,nQde		,NIL},;
									{"CP_LOCAL" 	,cAlm	    ,NIL},;
									{"CP_DESCRI"   ,xDesc		,NIL},;
									{"CP_UM" 	  	,xUM		,NIL},;
									{"CP_CC"	  	,xCC		,NIL},;
									{"CP_CONTA"	,xConta		,NIL},;
									{"CP_QTSEGUM"	,nQ2UM		,NIL},;
									{"CP_SEGUM" 	,x2UM		,NIL},;
									{"CP_OBS"		,xObs		,NIL},;
									{"CP_MANUSIS"	,xMns		,NIL},;
									{"CP_DATPRF"  	,ddatabase	,NIL}})

								cNumSA := NextNumero("SCP",1,"CP_NUM",.T.)
								aCab:= {{"CP_SOLICIT"		,"Ws Manusis"	,NIL},;
									{"CP_EMISSAO"	,ddatabase		,NIL},;
									{"CP_NUM"		,cNumSA			,NIL}}
								lMsErroAuto := .F.
								MSExecAuto({|x,y,z| mata105(x,y,z)},aCab,aItem,3)
								If lMsErroAuto
									aAdd( aVld, .F. )
									aAdd( aVld, "Erro na inclusao da SA!")
								Else
									aAdd( aVld, .T. )
									aAdd( aVld, cNumSA )
								Endif
							Else
								aAdd( aVld, .F. )
								aAdd( aVld, "Parametro [xCCusto] inválido !" )
							Endif
						Else
							aAdd( aVld, .F. )
							aAdd( aVld, "Parametro [xLocal] inválido !" )
						Endif
					Else
						aAdd( aVld, .F. )
						aAdd( aVld, "Parametro [xQuant] inválido !" )
					Endif
				Else
					aAdd( aVld, .F. )
					aAdd( aVld, "Parametro [xProduto] inválido !" )
				Endif
			Else
				aAdd( aVld, .F. )
				aAdd( aVld, "Parametro [xFilial] inválido ou não informado!" )
			Endif

			//-- Limpa ambiente
			RESET ENVIRONMENT

		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xFilial] inválido ou não informado!" )
		EndIf
	Else
		aAdd( aVld, .F. )
		aAdd( aVld, "Parametro [xEmpresa] inválido ou não informado!" )
	EndIf

	oJson[ "valid" ] := aVld
	oJson[ "data" ]  := oDat

	cJson := oJson:ToJson()
	::SetResponse( EncodeUTF8( cJson, "cp1252" ) )

Return lRet

//**************************************************************//
// Definição do Método Put                                      //
//**************************************************************//
WSMethod Put WSReceive xEmpresa, xFilial, xNumSA, xItem, xProduto, xQuant, xLocal, xCCusto, xObserv, xManusis WSService WSMNS01

	Local aVld 	:= {}
	Local oDat 	:= JsonObject():New()
	Local oIte 	:= JsonObject():New()
	Local oJson := JsonObject():New()
	Local xEmp
	Local xFil
	Local xPrd
	Local nQde
	Local cAlm
	Local xCC
	Local xConta
	Local x2UM
	Local xUM
	Local xObs
	Local cItSA			:= ""
	Local cNum			:= ""
	Local aItem 		:= {}
	Local aCab 			:= {}
	Local lRet			:= .T.
	Local cJson			:= ""
	Local lMSHelpAuto	:= .F.
	Local lMsErroAuto	:= .F.

	::SetContentType("application/json")

	//-- Validando Parâmetro Filial
	If ValType( ::xEmpresa ) <> "U"

		//-- Validando Parâmetro Filial
		If ValType( ::xFilial ) <> "U"
			xEmp  := PADL( Alltrim( ::xEmpresa ), 2, "0" )
			xFil  := PADL( Alltrim( ::xFilial ) , 2, "0" )
			xNum  := PADL( Alltrim( ::xNumSA )  , 6, "0" )
			xItSA := PADL( Alltrim( ::xItem )   , 2, "0" )

			//-- Empresa e Filial sao validos
			//-- Finaliza o ambiente corrente
			//-- abre ambiente selecionado
			RESET ENVIRONMENT
			Sleep(1000)

			PREPARE ENVIRONMENT EMPRESA (::xEmpresa) FILIAL (::xFilial)

			//-- Validando Produto
			If ValType( ::xProduto ) <> "U"
				xPrd  := PADR( Alltrim( ::xProduto ),  TamSx3( "B1_COD" )[1] )
				DbSelectArea("SB1")
				DbSetOrder(1)
				If DbSeek(FWxFilial("SB1")+xPrd)
					xUM		:= SB1->B1_UM
					x2UM	:= SB1->B1_SEGUM
					xDesc	:= SB1->B1_DESC
					xConta	:= SB1->B1_CONTA
					//-- Validando Quantidade
					nQde := ::xQuant
					If nQde > 0
						nQ2UM := ConvUM(xPrd, nQde, 0, 2)
						//-- Validando Local
						cAlm := PADR( Alltrim( ::xLocal ), TamSx3( "NNR_CODIGO" )[1] )
						DbSelectArea("NNR")
						DbSetOrder(1)
						If DbSeek( FWxFilial("NNR") + cAlm )
							//-- Validando Centro de Custos
							xCC := PADR( Alltrim( ::xCCusto ), TamSx3( "CTT_CUSTO" )[1] )
							DbSelectArea("CTT")
							DbSetOrder(1)
							If DbSeek(FWxFilial("CTT")+xCC)
								xObs := Alltrim(::xObserv)
								xMns := ::xManusis

								//-- Localiza SA a ser alterada
								DbSelectArea("SCP")
								DbSetOrder(1)
								If DbSeek(FWxFilial("SCP")+xNum+xItSA)
									aCab:= {{"CP_SOLICIT"	,"WS Manusis"	,NIL},;
										{"CP_EMISSAO"	,ddatabase		,NIL},;
										{"CP_NUM"		,SCP->CP_NUM	,NIL}}

									Aadd (aItem,{{"CP_PRODUTO"	,xPrd			,NIL},;
										{"CP_ITEM"		,SCP->CP_ITEM	,NIL},;
										{"CP_QUANT"		,nQde			,NIL},;
										{"CP_LOCAL" 	,cAlm			,NIL},;
										{"CP_DESCRI"	,xDesc			,NIL},;
										{"CP_UM" 	  	,xUM			,NIL},;
										{"CP_CC"	  	,xCC			,NIL},;
										{"CP_CONTA"		,xConta			,NIL},;
										{"CP_QTSEGUM"	,nQ2UM			,NIL},;
										{"CP_SEGUM" 	,x2UM			,NIL},;
										{"CP_OBS"		,xObs			,NIL},;
										{"CP_MANUSIS"	,xMns			,NIL},;
										{"CP_DATPRF"  	,ddatabase		,NIL}})
									lMsErroAuto := .F.
									MSExecAuto({|x,y,z| mata105(x,y,z)},aCab,aItem,4)
									If lMsErroAuto
										aAdd( aVld, .F. )
										aAdd( aVld, "Erro na alteracao da SA!")
									Else
										aAdd( aVld, .T. )
										aAdd( aVld, "SA alterada com sucesso" )
									Endif
								Else
									aAdd( aVld, .F. )
									aAdd( aVld, "Parametro [xSA] inválido !")
								EndIf
							Else
								aAdd( aVld, .F. )
								aAdd( aVld, "Parametro [xCCusto] inválido !")
							Endif
						Else
							aAdd( aVld, .F. )
							aAdd( aVld, "Parametro [xLocal] inválido !" )
						Endif
					Else
						aAdd( aVld, .F. )
						aAdd( aVld, "Parametro [xQuant] inválido !" )
					Endif
				Else
					aAdd( aVld, .F. )
					aAdd( aVld, "Parametro [xProduto] inválido !" )
				Endif
			Else
				aAdd( aVld, .F. )
				aAdd( aVld, "Parametro [xFilial] inválido ou não informado!" )
			Endif

			//-- Limpa ambiente
			RESET ENVIRONMENT

		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xFilial] inválido ou não informado!" )
		EndIf
	Else
		aAdd( aVld, .F. )
		aAdd( aVld, "Parametro [xEmpresa] inválido ou não informado!" )
	EndIf

	oJson[ "valid" ] := aVld
	oJson[ "data" ]  := oDat

	cJson := oJson:ToJson()
	::SetResponse( EncodeUTF8( cJson, "cp1252" ) )

Return lRet

//--------------------------------
//@example: http://localhost:8082/wsrprotheus/FINAPV01?Empresa=99&xFilial=01&xPedido=000032
//@example: http://192.168.5.202:8082/WSRMNS/WSMNS02?xEmpresa=06&xFilial=16&xNumSC=045274
//@example: http://192.168.5.202:8082/WSRMNS/WSMNS02?xEmpresa=06&xFilial=16&xNumSC=345494&xItem=01
//@example: http://192.168.5.202:8082/WSRMNS/WSMNS02?xEmpresa=06&xFilial=16&xProduto=100200300051&xQuant=1&xLocal=PC&xCCusto=200501&xObserv=TESTE&xManusis=999999
//**************************************************************//
// Webservice RestFul             		       Data: 12/04/2021 //
// Desenvovido por Thalys Augusto                               //
// Responsável pela integracao entre Protheus e Manusis         //
// integrando as Solicitacoes de Compra                         //
//**************************************************************//
User Function WSRMNS03()
Return

WSRestFul WSMNS02 DESCRIPTION "Tratamento de Solicitações de Compra"

	// Definição das Variáveis
	WSData xEmpresa	as String
	WSData xFilial	as String
	WSData xNumSC	as String
	WSData xItem	as String
	WSData xProduto	as String
	WSData xQuant	as Float
	WSData xLocal	as String
	WSData xCCusto	as String
	WSData xObserv	as String
	WSData xManusis as String
	WSData xDtNec 	as Date

	// Definição da Descrição do Método Get
	WSMethod Get DESCRIPTION "Método GET para Retorno dos dados de Solicitação de Compra"

	// Definição da Descrição do Método Post
	WSMethod Post DESCRIPTION "Método POST para Inclusão de Solicitação de Compra"

	// Definição da Descrição do Método Put
	WSMethod Put DESCRIPTION "Método PUT para Alteração de Solicitação de Compra"

	// Definição da Descrição do Método Delete
	WSMethod Delete DESCRIPTION "Método DELETE para Exclusão de Solicitação de Compra"

End WSRestFul

//**************************************************************//
// Definição do Método Get                                      //
//**************************************************************//
WSMethod Get WSReceive xEmpresa, xFilial, xNumSC WSService WSMNS02

	Local aVld 	:= {}
	Local oDat 	:= JsonObject():New()
	Local oIte 	:= JsonObject():New()
	Local oJson := JsonObject():New()

	Local xEmp
	Local xFil
	Local xSC
	Local aAux  := {}
	Local lRet  := .T.
	Local nI	:= 0
	Local cJson := ""
	Local lCont := .T.

	::SetContentType("application/json")

	//-- Valida Parâmetro Empresa
	If ValType( ::xEmpresa ) <> "U"
		xEmp := PADL( Alltrim( ::xEmpresa ), 2, "0" )
	Else
		aAdd( aVld, .F. )
		aAdd( aVld, "Parametro [xEmpresa] inválido ou não informado!" )
		lCont := .F.
	EndIf

	//-- Valida Parâmetro Filial
	If lCont
		If ValType( ::xFilial ) <> "U"
			xFil := PADL( Alltrim( ::xFilial ),  2, "0" )
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xFilial] inválido ou não informado!" )
			lCont := .F.
		EndIf
	Endif

	//-- Valida Parâmetro NumSC
	If lCont
		If ValType(::xNumSC) <> "U"
			xSC  := PADR( Alltrim( ::xNumSC ),  TamSx3( "C1_NUM" )[1] )
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [::xNumSC] inválido ou não informado!" )
			lCont := .F.
		EndIf
	Endif

	If lCont

		//-- Validou todas as informacoes
		//-- Finaliza o ambiente corrente
		//-- abre ambiente selecionado
		RESET ENVIRONMENT
		Sleep(1000)
		PREPARE ENVIRONMENT EMPRESA (xEmp) FILIAL (xFil)

		aAux := ObtSC(xEmp, xFil, xSC)
		If ValType( aAux ) == "A" .And. Len( aAux ) > 0
			aAdd( aVld, aAux[ 1, 1 ] )
			aAdd( aVld, aAux[ 1, 2 ] )
			For nI := 1 To Len(aAux[2])
				oDat[ cValToChar( nI ) ] := JsonObject():New()
				oDat[ cValToChar( nI ) ][ "Empresa" ]		:= aAux[ 02, nI, 01 ]
				oDat[ cValToChar( nI ) ][ "Filial" ]		:= aAux[ 02, nI, 02 ]
				oDat[ cValToChar( nI ) ][ "Emissao" ]		:= aAux[ 02, nI, 03 ]
				oDat[ cValToChar( nI ) ][ "Numero" ]		:= aAux[ 02, nI, 04 ]
				oDat[ cValToChar( nI ) ][ "Item" ]			:= aAux[ 02, nI, 05 ]
				oDat[ cValToChar( nI ) ][ "Produto" ] 		:= aAux[ 02, nI, 06 ]
				oDat[ cValToChar( nI ) ][ "Descricao" ]		:= aAux[ 02, nI, 07 ]
				oDat[ cValToChar( nI ) ][ "Unidade" ] 		:= aAux[ 02, nI, 08 ]
				oDat[ cValToChar( nI ) ][ "Almox" ] 		:= aAux[ 02, nI, 09 ]
				oDat[ cValToChar( nI ) ][ "CentroCusto" ] 	:= aAux[ 02, nI, 10 ]
				oDat[ cValToChar( nI ) ][ "QdeSolicitada"] 	:= aAux[ 02, nI, 11 ]
				oDat[ cValToChar( nI ) ][ "Situacao" ]		:= aAux[ 02, nI, 12 ]
				oDat[ cValToChar( nI ) ][ "Observacao" ]	:= aAux[ 02, nI, 13 ]
				oDat[ cValToChar( nI ) ][ "Solicitante" ]	:= aAux[ 02, nI, 14 ]
				oDat[ cValToChar( nI ) ][ "Necessidade" ]	:= aAux[ 02, nI, 15 ]
				/*
			oDat[ cValToChar( nI ) ][ "Empresa" ]		:= aAux[ 02, nI, 01 ]
			oDat[ cValToChar( nI ) ][ "Filial" ]		:= aAux[ 02, nI, 02 ]
			oDat[ cValToChar( nI ) ][ "Manusis" ]		:= aAux[ 02, nI, 03 ]
			oDat[ cValToChar( nI ) ][ "Emissao" ]		:= aAux[ 02, nI, 04 ]
			oDat[ cValToChar( nI ) ][ "Numero" ]		:= aAux[ 02, nI, 05 ]
			oDat[ cValToChar( nI ) ][ "Item" ]			:= aAux[ 02, nI, 06 ]
			oDat[ cValToChar( nI ) ][ "Produto" ] 		:= aAux[ 02, nI, 07 ]
			oDat[ cValToChar( nI ) ][ "Descricao" ]		:= aAux[ 02, nI, 08 ]
			oDat[ cValToChar( nI ) ][ "Unidade" ] 		:= aAux[ 02, nI, 09 ]
			oDat[ cValToChar( nI ) ][ "Almox" ] 		:= aAux[ 02, nI, 10 ]
			oDat[ cValToChar( nI ) ][ "CentroCusto" ] 	:= aAux[ 02, nI, 11 ]
			oDat[ cValToChar( nI ) ][ "QdeSolicitada"] 	:= aAux[ 02, nI, 12 ]
			oDat[ cValToChar( nI ) ][ "Situacao" ]		:= aAux[ 02, nI, 13 ]
			oDat[ cValToChar( nI ) ][ "Observacao" ]	:= aAux[ 02, nI, 14 ]
			oDat[ cValToChar( nI ) ][ "Solicitante" ]	:= aAux[ 02, nI, 15 ]
			oDat[ cValToChar( nI ) ][ "Necessidade" ]	:= aAux[ 02, nI, 16 ]
				*/
			Next nI
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xNumSC] não encontrado!" )
		EndIf

		RESET ENVIRONMENT

	Endif


	oJson[ "valid" ] := aVld
	oJson[ "data" ]  := oDat

	cJson := oJson:ToJson()
	::SetResponse( EncodeUTF8( cJson, "cp1252" ) )

Return lRet

//**************************************************************//
// Definição do Método Post                                     //
//**************************************************************//
WSMethod Post WSReceive xEmpresa, xFilial, xProduto, xQuant, xLocal, xCCusto, xObserv, xManusis WSService WSMNS02

	Local lRet  		:= .T.
	Local aVld 			:= {}
	Local oDat 			:= JsonObject():New()
	Local oIte 			:= JsonObject():New()
	Local oJson 		:= JsonObject():New()
	Local aCab			:= {}
	Local aItens		:= {}
	Local nVlEst		:= 0
	Local xEmp			:= ""
	Local xFil			:= ""
	Local cPrd			:= ""
	Local cAlm			:= ""
	Local cNumSC		:= ""
	Local cItSC			:= ""
	Local cDesc			:= ""
	Local nQde			:= 0
	Local cUM			:= ""
	Local cCC			:= ""
	Local cOBS			:= ""
	Local cMan			:= ""
	Local dDtNec		:= Ctod("")
	Local cJson			:= ""
	Local lMSHelpAuto	:= .F.
	Local lMsErroAuto	:= .F.

	::SetContentType("application/json")

	//---------------------------------------
	// Validando os Dados Informados
	//---------------------------------------

	//-- Valida Parâmetro Empresa
	If ValType( ::xEmpresa ) <> "U"
		xEmp := PADL( Alltrim( ::xEmpresa ), 2, "0" )
	Else
		aAdd( aVld, .F. )
		aAdd( aVld, "Parametro [xEmpresa] inválido ou não informado!" )
		lCont := .F.
	EndIf

	//-- Valida Parâmetro Filial
	If lCont
		If ValType( ::xFilial ) <> "U"
			xFil := PADL( Alltrim( ::xFilial ),  2, "0" )
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xFilial] inválido ou não informado!" )
			lCont := .F.
		EndIf
	Endif

	//-- Finaliza o ambiente corrente
	//-- abre ambiente selecionado
	RESET ENVIRONMENT
	Sleep(1000)
	PREPARE ENVIRONMENT EMPRESA (xEmp) FILIAL (xFil)

	//-- Valida Parâmetro Produto
	If lCont
		If ValType( ::xProduto ) <> "U"
			cPrd  := PADR( Alltrim( ::xProduto ),  TamSx3( "B1_COD" )[1] )
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(FWxFilial("SB1")+cPrd)
				cUM		:= SB1->B1_UM
				c2UM	:= SB1->B1_SEGUM
				cDesc	:= SB1->B1_DESC
			Else
				aAdd( aVld, .F. )
				aAdd( aVld, "Parametro [xProduto] não localizado!" )
				lCont := .F.
			Endif
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xProduto] inválido ou não informado!" )
			lCont := .F.
		Endif
	EndIf

	//-- Valida Parâmetro Centro de Custos
	If lCont
		If ValType( ::xProduto ) <> "U"
			cCC  := Alltrim( ::xCCusto )
			DbSelectArea("CTT")
			DbSetOrder(1)
			If !DbSeek(FWxFilial("CTT") + cCC)
				aAdd( aVld, .F. )
				aAdd( aVld, "Parametro [xCC] não localizado !" )
				lCont := .F.
			Endif
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xCC] inválido !" )
			lCont := .F.
		Endif
	EndIf

	//-- Valida Parâmetro Almoxarifado
	If lCont
		If ValType(::xLocal) <> "U"
			cAlm := PADR( Alltrim( ::xLocal ), TamSx3( "NNR_CODIGO" )[1] )
			DbSelectArea("NNR")
			DbSetOrder(1)
			If !DbSeek(FWxFilial("NNR")+cAlm)
				aAdd( aVld, .F. )
				aAdd( aVld, "Parametro [xLocal] não localizado !" )
			Endif
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xLocal] inválido !" )
			lCont := .F.
		Endif
	EndIf

	//-- Valida Parâmetro Almoxarifado
	If lCont
		nQde := ::xQuant
		If nQde > 0
			nQ2UM := ConvUM(cPrd, nQde, 0, 2)
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xQuant] inválido !" )
			lCont := .F.
		EndIf
	EndIf

	//-- Validou todos os parametros de entrada
	//-- Inicia processamento
	If lCont
		cOBS := Alltrim( ::xObserv )
		cMan := Alltrim( ::xManusis )

		//-- Obtem valor do produto da SC
		nVlEst := VlrEst(xFil, cPrd, cAlm)

		//-- Gera Numero da SC
		cNumSC	:= GETSX8NUM("SC1","C1_NUM")
		cItSC	:= "0001"

		aCab :=	{{"C1_NUM"		, cNumSC					, Nil },;
			{ "C1_EMISSAO"	, dDataBase 				, Nil },;
			{ "C1_SOLICIT"	, "WS Manusis"				, Nil } }

		aadd(aItens,{{"C1_ITEM"     ,cItSC				, nil },;
			{"C1_PRODUTO"   ,cPrd				, nil },;
			{"C1_DESCRI"    ,cDesc				, nil },;
			{"C1_UM"        ,cUM				, nil },;
			{"C1_QUANT"     ,nQde				, nil },;
			{"C1_CC"	    ,cCC				, nil },;
			{"C1_DATPRF"    ,dDataBase			, nil },;
			{"C1_LOCAL"  	,cAlm				, nil },;
			{"C1_OBS"   	,cOBS				, nil },;
			{"C1_VALESTI"   ,nVlEst				, nil },;
			{"C1_MANUSIS"   ,cMan				, nil }})

		dbSelectArea("SC1")
		lMsErroAuto := .F.
		MSExecAuto({|x,y,z|MATA110(x,y,z)},aCab, aItens ,3)
		If lMsErroAuto
			aAdd( aVld, .F. )
			aAdd( aVld, "Erro na inclusão da SC!")
		Else
			aAdd( aVld, .T. )
			aAdd( aVld, cNumSC )
		Endif
	EndIf

	RESET ENVIRONMENT

	oJson[ "valid" ] := aVld
	oJson[ "data" ]  := oDat

	cJson := oJson:ToJson()
	::SetResponse( EncodeUTF8( cJson, "cp1252" ) )

Return lRet

//**************************************************************//
// Definição do Método Put                                      //
//**************************************************************//
WSMethod Put WSReceive xEmpresa, xFilial, xNumSC, xItemSC, xProduto, xQuant, xLocal, xCCusto, xObserv, xManusis WSService WSMNS02

	Local lRet  		:= .T.
	Local aVld 			:= {}
	Local oDat 			:= JsonObject():New()
	Local oIte 			:= JsonObject():New()
	Local oJson 		:= JsonObject():New()
	Local aCab			:= {}
	Local aItens		:= {}
	Local nVlEst		:= 0
	Local xEmp			:= ""
	Local xFil			:= ""
	Local cPrd			:= ""
	Local cAlm			:= ""
	Local cNumSC		:= ""
	Local cItSC			:= ""
	Local cDesc			:= ""
	Local nQde			:= 0
	Local cUM			:= ""
	Local cCC			:= ""
	Local cOBS			:= ""
	Local cMan			:= ""
	Local dDtNec		:= Ctod("")
	Local cJson			:= ""
	Local lMSHelpAuto	:= .F.
	Local lMsErroAuto	:= .F.
	Local lCont			:= .T.

	::SetContentType("application/json")
	//---------------------------------------
	// Validando os Dados Informados
	//---------------------------------------

	//-- Valida Parâmetro Empresa
	If ValType( ::xEmpresa ) <> "U"
		xEmp := PADL( Alltrim( ::xEmpresa ), 2, "0" )
	Else
		aAdd( aVld, .F. )
		aAdd( aVld, "Parametro [xEmpresa] inválido ou não informado!" )
		lCont := .F.
	EndIf

	//-- Valida Parâmetro Filial
	If lCont
		If ValType( ::xFilial ) <> "U"
			xFil := PADL( Alltrim( ::xFilial ),  2, "0" )
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xFilial] inválido ou não informado!" )
			lCont := .F.
		EndIf
	Endif

	//-- Finaliza o ambiente corrente
	//-- abre ambiente selecionado
	RESET ENVIRONMENT
	Sleep(1000)
	PREPARE ENVIRONMENT EMPRESA (xEmp) FILIAL (xFil)

	//-- Valida Parâmetro Produto
	If lCont
		If ValType( ::xProduto ) <> "U"
			cPrd  := PADR( Alltrim( ::xProduto ),  TamSx3( "B1_COD" )[1] )
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(FWxFilial("SB1")+cPrd)
				cUM		:= SB1->B1_UM
				c2UM	:= SB1->B1_SEGUM
				cDesc	:= SB1->B1_DESC
			Else
				aAdd( aVld, .F. )
				aAdd( aVld, "Parametro [xProduto] não localizado!" )
				lCont := .F.
			Endif
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xProduto] inválido ou não informado!" )
			lCont := .F.
		Endif
	EndIf

	//-- Valida Parâmetro Centro de Custos
	If lCont
		If ValType( ::xProduto ) <> "U"
			cCC  := Alltrim( ::xCCusto )
			DbSelectArea("CTT")
			DbSetOrder(1)
			If !DbSeek(FWxFilial("CTT") + cCC)
				aAdd( aVld, .F. )
				aAdd( aVld, "Parametro [xCC] não localizado !" )
				lCont := .F.
			Endif
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xCC] inválido !" )
			lCont := .F.
		Endif
	EndIf

	//-- Valida Parâmetro Almoxarifado
	If lCont
		If ValType(::xLocal) <> "U"
			cAlm := PADR( Alltrim( ::xLocal ), TamSx3( "NNR_CODIGO" )[1] )
			DbSelectArea("NNR")
			DbSetOrder(1)
			If !DbSeek(FWxFilial("NNR")+cAlm)
				aAdd( aVld, .F. )
				aAdd( aVld, "Parametro [xLocal] não localizado !" )
			Endif
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xLocal] inválido !" )
			lCont := .F.
		Endif
	EndIf

	//-- Valida Parâmetro Almoxarifado
	If lCont
		nQde := ::xQuant
		If nQde > 0
			nQ2UM := ConvUM(cPrd, nQde, 0, 2)
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xQuant] inválido !" )
			lCont := .F.
		EndIf
	EndIf

	//-- Valida Numero da SC
	If lCont
		If ValType(::xNumSC) <> "U"
			cNumSC := PADR(Alltrim(::xNumSC), TamSx3("C1_NUM")[1])
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xQuant] inválido !" )
			lCont := .F.
		Endif
	Endif

	//-- Validou todos os parametros de entrada
	//-- Inicia processamento
	If lCont
		cOBS := Alltrim( ::xObserv )
		cMan := Alltrim( ::xManusis )
		cItSC := "0001"

		DbSelectArea("SC1")
		DbSetOrder(1)
		If DbSeek(FWxFilial("SC1")+cNumSC+cItemSC)
			If Alltrim(SC1->C1_PRODUTO) <> cPrd
				//-- Obtem valor da Solicitacao
				nVlEst := VlrEst(xFil, cPrd, cAlm)
			Else
				nVlEst	:= SC1->C1_VALESTI
			EndIf

			//-- Gera SC
			aCab :=	{{"C1_NUM"		, SC1->C1_NUM				, Nil },;
				{ "C1_EMISSAO"	, dDataBase 				, Nil },;
				{ "C1_SOLICIT"	, "WS Manusis"				, Nil } }

			aadd(aItens,{{"C1_ITEM"     ,cItSC				, nil },;
				{"C1_PRODUTO"   ,cPrd				, nil },;
				{"C1_DESCRI"    ,cDesc				, nil },;
				{"C1_UM"        ,cUM				, nil },;
				{"C1_QUANT"     ,nQde				, nil },;
				{"C1_CC"	    ,cCC				, nil },;
				{"C1_DATPRF"    ,dDataBase			, nil },;
				{"C1_LOCAL"  	,cAlm				, nil },;
				{"C1_OBS"   	,cOBS				, nil },;
				{"C1_VALESTI"   ,nVlEst				, nil },;
				{"C1_MANUSIS"   ,cMan				, nil }})

			dbSelectArea("SC1")
			lMsErroAuto := .F.
			MSExecAuto({|x,y,z|MATA110(x,y,z)},aCab, aItens ,4)
			If lMsErroAuto
				aAdd( aVld, .F. )
				aAdd( aVld, "Erro na inclusão da SC!")
			Else
				aAdd( aVld, .T. )
				aAdd( aVld, cNumSC )
			Endif
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xQuant] inválido !" )
		EndIf
	EndIf

	RESET ENVIRONMENT

	oJson[ "valid" ] := aVld
	oJson[ "data" ]  := oDat

	cJson := oJson:ToJson()
	::SetResponse( EncodeUTF8( cJson, "cp1252" ) )

Return lRet

//**************************************************************//
// Definição do Método Delete                                   //
//**************************************************************//
WSMethod Delete WSReceive xEmpresa, xFilial, xNumSC WSService WSMNS02

	Local aVld 	:= {}
	Local oDat 	:= JsonObject():New()
	Local oIte 	:= JsonObject():New()
	Local oJson := JsonObject():New()

	Local xEmp
	Local xFil
	Local xSC
	Local xIt
	Local lRet			:= .T.
	Local cJson			:= ""
	Local aCamposSC1	:= {}
	Local lMSHelpAuto	:= .F.
	Local lMsErroAuto	:= .F.
	Local aCab			:= {}
	Local aItens		:= {}
	Local lCont			:= .T.

	::SetContentType("application/json")

	//---------------------------------------
	// Validando os Dados Informados
	//---------------------------------------
	//-- Validando Parâmetro Empresa
	If ValType( ::xEmpresa ) <> "U"
		xEmp := PADL( Alltrim( ::xEmpresa ), 2, "0" )
	Else
		aAdd( aVld, .F. )
		aAdd( aVld, "Parametro [xEmpresa] inválido ou não informado!" )
		lCont := .F.
	EndIf

	//-- Validando Parâmetro Filial
	If lCont
		If ValType( ::xFilial ) <> "U"
			xFil := PADL( Alltrim( ::xFilial ),  2, "0" )
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xFilial] inválido ou não informado!" )
			lCont := .F.
		EndIf
	Endif

	//-- Validando Parâmetro SC
	If lCont
		If ValType( ::xNumSC ) <> "U"
			xSC  := PADR( Alltrim( ::xNumSC ),  TamSx3( "C1_NUM" )[1] )
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xNumSC] inválido ou não informado!" )
			lCont := .F.
		EndIf
	EndIf

	//-- Validou todos os parametros de entrada
	//-- Inicia processamento
	If lCont
		//-- Empresa e Filial sao validos
		//-- Finaliza o ambiente corrente
		//-- abre ambiente selecionado
		RESET ENVIRONMENT
		Sleep(1000)
		PREPARE ENVIRONMENT EMPRESA (xEmp) FILIAL (xFil)

		DbSelectArea("SC1")
		DbSetOrder(1) // C1_FILIAL+C1_NUM+C1_ITEM
		If DbSeek(FWxFilial("SC1")+xSC)
			aAdd(aCab, {"C1_NUM" 	, SC1->C1_NUM	, Nil })
			While !Eof() .And. SC1->C1_NUM == xSC
				aadd(aItens,{{"C1_ITEM"     ,SC1->C1_ITEM		, nil },;
					{"C1_PRODUTO"   ,SC1->C1_PRODUTO	, nil },;
					{"C1_QUANT"     ,SC1->C1_QUANT		, nil },;
					{"C1_UM"        ,SC1->C1_UM		, nil }})
				DbSelectArea("SC1")
				DbSkip()
			End
			dbSelectArea("SC1")
			MSExecAuto({|x,y,z|MATA110(x,y,z)},aCab, aItens ,5)
			If lMsErroAuto
				aAdd( aVld, .F. )
				aAdd( aVld, "Erro na exclusão da SC!")
			Else
				aAdd( aVld, .T. )
				aAdd( aVld, "" )
			Endif
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xNumSC] inválido!" )
		Endif
		RESET ENVIRONMENT
	EndIf

	oJson[ "valid" ] := aVld
	oJson[ "data" ]  := oDat

	cJson := oJson:ToJson()
	::SetResponse( EncodeUTF8( cJson, "cp1252" ) )

Return lRet

//--------------------------------
//@example: http://localhost:8082/wsrprotheus/FINAPV01?Empresa=99&xFilial=01&xPedido=000032
//@example: http://192.168.5.202:8082/WSRMNS/WSMNS03?xEmpresa=06&xFilial=16&xNumSC=045274
//@example: http://192.168.5.202:8082/WSRMNS/WSMNS03?xEmpresa=06&xFilial=16&xNumSC=345494&xItem=01
//@example: http://192.168.5.202:8082/WSRMNS/WSMNS03?xEmpresa=06&xFilial=16&xProduto=100200300051&xQuant=1&xLocal=PC&xCCusto=200501&xObserv=TESTE&xManusis=999999
//**************************************************************//
// Webservice RestFul             		       Data: 12/04/2021 //
// Desenvovido por Thalys Augusto                               //
// Responsável pela integracao entre Protheus e Manusis         //
// Funcao de consutla dos saldos em estoque                     //
//**************************************************************//
User Function WSRMNS04()
Return

WSRestFul WSMNS04 DESCRIPTION "Consulta saldo em Estoques"

	// Definição das Variáveis
	WSData xEmpresa	as String
	WSData xFilial	as String
	WSData xProduto	as String
	WSData xLocal	as String

	// Definição da Descrição do Método Get
	WSMethod Get DESCRIPTION "Método GET para Retorno dos saldos de Produtos"

End WSRestFul

//**************************************************************//
// Definição do Método Get                                      //
//**************************************************************//
WSMethod Get WSReceive xEmpresa, xFilial, xProduto, xLocal WSService WSMNS04

	Local aVld 	:= {}
	Local oDat 	:= JsonObject():New()
	Local oIte 	:= JsonObject():New()
	Local oJson := JsonObject():New()

	Local xEmp  := ""
	Local xFil  := ""
	Local xPrd  := ""
	Local cAlm	:= ""
	Local nSld  := 0

	Local aAux  := {}
	Local lRet  := .T.
	Local cJson := ""
	Local lCont := .T.

	::SetContentType("application/json")

	//-- Valida Parâmetro Empresa
	If ValType( ::xEmpresa ) <> "U"
		xEmp := PADL( Alltrim( ::xEmpresa ), 2, "0" )
	Else
		aAdd( aVld, .F. )
		aAdd( aVld, "Parametro [xEmpresa] inválido ou não informado!" )
		lCont := .F.
	EndIf

	//-- Valida Parâmetro Filial
	If lCont
		If ValType( ::xFilial ) <> "U"
			xFil := PADL( Alltrim( ::xFilial ),  2, "0" )
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xFilial] inválido ou não informado!" )
			lCont := .F.
		EndIf
	Endif

	//-- Valida Parâmetro Almoxarifado
	If lCont
		If ValType(::xLocal) <> "U"
			cAlm  := PADR( Alltrim( ::xLocal),  TamSx3( "B2_LOCAL" )[1] )
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xLocal] inválido ou não informado!" )
			lCont := .F.
		EndIf
	Endif

	//-- Valida Parâmetro Produto
	If lCont
		If ValType(::xProduto) <> "U"
			xPrd  := PADR( Alltrim( ::xProduto),  TamSx3( "B1_COD" )[1] )
		Else
			aAdd( aVld, .F. )
			aAdd( aVld, "Parametro [xProduto] inválido ou não informado!" )
			lCont := .F.
		EndIf
	Endif

	If lCont
		//-- Validou todas as informacoes
		//-- Finaliza o ambiente corrente
		//-- abre ambiente selecionado
		RESET ENVIRONMENT
		Sleep(1000)
		PREPARE ENVIRONMENT EMPRESA (xEmp) FILIAL (xFil)

		//-- Faz as validacoes especificas da empresa filial selecionados
		//-- Valida existencia do Almoxarifado
		If lCont
			//-- Valida a exitencia do almoxarifado
			DbSelectArea("NNR")
			DbSetOrder(1)
			If DbSeek( FWxFilial("NNR") + cAlm )
				//-- Valida existencia do produto
				DbSelectArea("SB1")
				DbSetOrder(1)
				If DbSeek(FWxFilial("SB1")+xPrd)
					//-- Valida existencia do saldo do produto no almoxarifado selecionado
					DbSelectArea("SB2")
					DbSetOrder(1)
					If DbSeek(FWxFilial("SB2")+xPrd+cAlm) //B2_FILIAL+B2_COD+B2_LOCAL
						nSaldo := saldoSB2()
						aAdd( aVld, .T. )
						aAdd( aVld, "Consulta executada com sucesso!" )
					Else
						aAdd( aVld, .F. )
						aAdd( aVld, "Parametro [xProduto + xLocal] não localizado!" )
						lCont := .F.
					EndIf
				Else
					aAdd( aVld, .F. )
					aAdd( aVld, "Parametro [xProduto] não localizado!" )
					lCont := .F.
				Endif
			Else
				aAdd( aVld, .F. )
				aAdd( aVld, "Parametro [xLocal] não localizado!" )
				lCont := .F.
			EndIf
		Endif

		//-- Se tudo Ok monta a resposta
		If lCont
			oDat[ cValToChar( 1 ) ] := JsonObject():New()
			oDat[ cValToChar( 1 ) ][ "Empresa" ]		:= xEmp
			oDat[ cValToChar( 1 ) ][ "Filial" ]		:= xFil
			oDat[ cValToChar( 1 ) ][ "Produto" ] 		:= xPrd
			oDat[ cValToChar( 1 ) ][ "Almox" ] 		:= cAlm
			oDat[ cValToChar( 1 ) ][ "Saldo" ] 		:= nSaldo
		EndIf

		RESET ENVIRONMENT

	Endif

	oJson[ "valid" ] := aVld
	oJson[ "data" ]  := oDat

	cJson := oJson:ToJson()
	::SetResponse( EncodeUTF8( cJson, "cp1252" ) )

Return lRet

//------------ Funcoes auxiliares
/****************************************************************************/
/** Programa 	| ObtSC                                                    **/
/****************************************************************************/
/** Autor 		| Thalys Augusto                                12/04/2021 **/
/****************************************************************************/
/** Desc.		| Rotina responsável pela obtencao dos dados da SA         **/
/****************************************************************************/
Static Function ObtSC(xEmp, xFil, xNumSC)

	Local aRes := {}
	Local aVld := {}
	Local aDat := {}

	DbSelectArea("SC1")
	DbSetOrder(1)
	If DbSeek(FWxFilial("SC1") + xNumSC)
		aAdd( aVld, .T. )
		aAdd( aVld, "" )
		While !Eof() .And. SC1->C1_NUM == xNumSC
			cSituac := StatSC()
			//Aadd(aDat,{xEmp, xFil, SC1->C1_MANUSIS, Dtoc(SC1->C1_EMISSAO), SC1->C1_NUM, SC1->C1_ITEM, SC1->C1_PRODUTO, SC1->C1_DESCRI, SC1->C1_UM, SC1->C1_LOCAL, SC1->C1_CC, cValToChar(SC1->C1_QUANT), cSituac, SC1->C1_OBS, SC1->C1_SOLICIT, Dtoc(SC1->C1_DATPRF)})
			Aadd(aDat,{xEmp, xFil, Dtoc(SC1->C1_EMISSAO), SC1->C1_NUM, SC1->C1_ITEM, SC1->C1_PRODUTO, SC1->C1_DESCRI, SC1->C1_UM, SC1->C1_LOCAL, SC1->C1_CC, cValToChar(SC1->C1_QUANT), cSituac, SC1->C1_OBS, SC1->C1_SOLICIT, Dtoc(SC1->C1_DATPRF)})
			DbSelectArea("SC1")
			DbSkip()
		End
	Else
		aAdd( aVld, .F. )
		aAdd( aVld, "Solicitação de compra "+xNumSC+" não encontrada!" )
	Endif

	aAdd( aRes, aVld )
	aAdd( aRes, aDat )

Return(aRes)

/****************************************************************************/
/** Programa 	| StatSC                                                   **/
/****************************************************************************/
/** Autor 		| Thalys Augusto                                12/04/2021 **/
/****************************************************************************/
/** Desc.		| Rotina responsável pela obtencao do Status da SC         **/
/****************************************************************************/
Static Function StatSC()

	Local cRet		:= ""
	Local lAProvSI	:= GetNewPar("MV_APROVSI",.F.)
	Local lMkPlace	:= SuperGetMv("MV_MKPLACE",.F.,.F.)
	Local lPrjCni	:= If(FindFunction("ValidaCNI"),ValidaCNI(),.F.)
	Local cTpCto	:= Iif ( lPrjCni, GETMV("MV_TPSCCT"), '')

	If lMkPlace .And. SC1->C1_ACCPROC =="1" .And. SC1->C1_PEDIDO == Space(Len(SC1->C1_PEDIDO))
		cRet := "Solicitao Pendente (MarketPlace)"
	ElseIf lMkPlace .And. SC1->C1_ACCPROC == "1" .And. SC1->C1_PEDIDO == Space(Len(SC1->C1_PEDIDO)) .And. SC1->C1_COTACAO <> Space(Len(SC1->C1_COTACAO))
		cRet := "Solicitao em Processo de Cotao (MarketPlace)"
	ElseIf SC1->C1_RESIDUO == 'S' .And. SC1->C1_COMPRAC == '1'
		cRet := "SC em Compra Centralizada"
	ElseIf lPrjCni .And. SC1->C1_XCLASSI .And. SC1->C1_APROV == "B"
		cRet := "SC proveniente de SA, aguardando classificacao"
	ElseIf lPrjCni .And. Empty(SC1->C1_RESIDUO) .And. SC1->C1_XSTGCT == "1" .And. SC1->C1_APROV $ " ,L" .And. SC1->C1_XTIPOSC == cTpCto
		cRet := "Contrato gerado"
	ElseIf lPrjCni .And. Empty(SC1->C1_RESIDUO) .And. SC1->C1_XSTGCT == "2" .And. SC1->C1_APROV $ " ,L" .And. SC1->C1_XTIPOSC == cTpCto
		cRet := "Contrato nao gerado"
	ElseIf SC1->C1_FLAGGCT == "1" .And. SC1->C1_QUJE < SC1->C1_QUANT
		cRet := "SC Totalmente Atendida pelo SIGAGCT"
	ElseIf SC1->C1_TIPO == 2
		cRet := "Solicitacao de Importacao"
	ElseIf !Empty(SC1->C1_RESIDUO)
		cRet := "SC Eliminada por Residuo"
	ElseIf SC1->C1_QUJE == SC1->C1_QUANT
		cRet := "SC com Pedido Colocado"
	ElseIf SC1->C1_TPSC == "2" .And. SC1->C1_QUJE == 0 .And. !Empty(SC1->C1_CODED)
		cRet := "Solicitao em Processo de Edital"
	ElseIf SC1->C1_QUJE == 0 .And. SC1->C1_APROV $ " ,L" .And. ((SC1->C1_COTACAO == Space(Len(SC1->C1_COTACAO)) .And. SC1->C1_TPSC == "2") .Or. (SC1->C1_COTACAO == "ANALIS"))
		cRet := "Solicitacao para Licitacao"
	ElseIf lPrjCni .And. SC1->C1_XTIPOSC <> cTpCto .And. SC1->C1_QUJE == 0 .And. SC1->C1_COTACAO == Space(Len(SC1->C1_COTACAO)) .And. SC1->C1_APROV $ " ,L"
		cRet := "SC em Aberto"
	ElseIf !lPrjCni .And. SC1->C1_QUJE == 0 .And. SC1->C1_COTACAO == Space(Len(SC1->C1_COTACAO)) .And. SC1->C1_APROV $ " ,L"
		cRet := "SC em Aberto"
	ElseIf lAprovSI .And. SC1->C1_QUJE == 0 .And. (SC1->C1_COTACAO == Space(Len(SC1->C1_COTACAO)) .Or. SC1->C1_COTACAO == "IMPORT") .And. SC1->C1_APROV == "R"
		cRet := "SC Rejeitada"
	ElseIf lAprovSI .And. SC1->C1_QUJE == 0 .And. (SC1->C1_COTACAO == Space(Len(SC1->C1_COTACAO)) .Or. SC1->C1_COTACAO == "IMPORT") .And. SC1->C1_APROV == "B"
		cRet := "SC Bloqueada"
	ElseIf !lAprovSI .And. SC1->C1_QUJE == 0 .And. SC1->C1_COTACAO == Space(Len(SC1->C1_COTACAO)) .And. SC1->C1_APROV == "R"
		cRet := "SC Rejeitada"
	ElseIf !lAprovSI .And. SC1->C1_QUJE == 0 .And. (SC1->C1_COTACAO == Space(Len(SC1->C1_COTACAO)) .Or. SC1->C1_COTACAO == "IMPORT") .And. SC1->C1_APROV == "B"
		cRet := "SC Bloqueada"
	ElseIf SC1->C1_QUJE > 0
		cRet := "SC com Pedido Colocado Parcial"
	ElseIf SC1->C1_TPSC != "2" .And. SC1->C1_QUJE == 0 .And. SC1->C1_COTACAO <> Space(Len(SC1->C1_COTACAO)) .And. SC1->C1_IMPORT <>"S"
		cRet := "SC em Processo de Cotacao"
	ElseIf lAprovSI .And. SC1->C1_QUJE == 0 .And. SC1->C1_COTACAO <> Space(Len(SC1->C1_COTACAO)) .And. SC1->C1_IMPORT == "S" .And. SC1->C1_APROV $ " ,L"
		cRet := "SC com Produto Importado"
	ElseIf !lAprovSI .And. SC1->C1_QUJE == 0 .And. SC1->C1_COTACAO <> Space(Len(SC1->C1_COTACAO)) .And. SC1->C1_IMPORT == "S"
		cRet := "SC com Produto Importado"
	Endif

Return cRet

/****************************************************************************/
/** Programa 	| VlrEst                                                   **/
/****************************************************************************/
/** Autor 		| Thalys Augusto                                12/04/2021 **/
/****************************************************************************/
/** Desc.		| Retorna Valor Estimado do produto, Custo Médio do ultimo **/
/**      		| fechamento ou custo unitario da ultima compra            **/
/****************************************************************************/
Static Function VlrEst(xFil, xCod, xLoc)

	Local cQuery := ""
	Local nRet := 0

	cArqQry:= GetNextAlias()
	cQuery := ""
	cQuery += " SELECT TOP 1 B9_CM1, B9_DATA, D1_CM, D1_DTDIGIT"
	cQuery += " FROM "+RetSqlName("SB9")+ " B9,"
	cQuery += " (SELECT TOP 1 (D1_CUSTO/D1_QUANT) AS D1_CM, D1_DTDIGIT"
	cQuery += " FROM "+RetSqlName("SD1")+" D1"
	cQuery += " INNER JOIN "+RetSqlName("SF4")+" F4 ON F4_FILIAL = '"+FWxFilial("SF4")+"' AND D1_TES = F4_CODIGO AND F4_ESTOQUE = 'S' AND F4.D_E_L_E_T_ = ''"
	cQuery += " WHERE D1_FILIAL = '"+FWxFilial("SD1")+"'"
	cQuery += " AND D1_COD = '"+xCod+"'"
	cQuery += " AND D1_QUANT > 0"
	cQuery += " AND D1_CUSTO > 0"
	cQuery += " AND D1.D_E_L_E_T_ = ''"
	cQuery += " ORDER BY D1_DTDIGIT DESC ) A"
	cQuery += " WHERE B9_FILIAL = '"+FWxFilial("SB9")+"'"
	cQuery += " AND B9_COD = '"+xCod+"'"
	cQuery += " AND B9_CM1 > 0"
	cQuery += " AND B9_LOCAL = '"+xLoc+"'"
	cQuery += " AND B9.D_E_L_E_T_ = ''"
	cQuery += " ORDER BY B9_DATA DESC"
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cArqQry,.F.,.T.)

	Tcsetfield(cArqQry,"D1_DTDIGIT","D")
	Tcsetfield(cArqQry,"B9_DATA","D")

	If &(cArqQry+"->B9_CM1") > 0
		nRet := &(cArqQry+"->B9_CM1")
	Else
		nRet := &(cArqQry+"->D1_CM")
	Endif

	If Select(cArqQry) > 0
		dbselectArea(cArqQry)
		dbCloseArea()
	EndIf

Return(nRet)
