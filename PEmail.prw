/*//#########################################################################################
Projeto : project
Modulo  : module
Fonte   : PEmail
Objetivo: objetivo
*///#########################################################################################

#INCLUDE "TOTVS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "DBSTRUCT.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc}
@version 1.0
@author Thalys Augusto
/*/
//-------------------------------------------------------------------

Class PEmail

	DATA cAlias
	DATA cTitle
	DATA cEmail
	DATA cEmailCC
	DATA cEvent
	DATA cHtml
	DATA cBody
	DATA cMsg
	DATA lEnable

	DATA oMessage

	DATA cPara
	DATA cMensagem
	DATA cAssunto
	DATA aFile

	Method new(cAlias) Constructor
	Method SetBody()
	Method SetTo(cMailto)
	Method SetCC(cMailCC)
	Method SetMensege(cMensagem)
	Method SetTitle(cTitle)
	Method SetAttach(aFile)
	Method SendMail()
	Method SetEnvio()

EndClass

//-------------------------------------------------------------------
/*/{Protheus.doc} new
Metodo Construtor da Classe
@author Thalys Augusto
@version 1.0
/*/
//-------------------------------------------------------------------

Method new(cAlias) Class PEmail

	Self:oMessage := TMailMessage():New()

	Self:cAlias		:= cAlias
	Self:lEnable 	:= .T.
	Self:aFile		:= {}
	Self:cEmail		:= ""
	Self:cEmailCC   := ""
	Self:cMsg 		:= ""
	Self:cBody      := ""

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} function
Setar Titulo para envio de Email, se nao houver sera enviado o padrao
@author Thalys Augusto
@since 16/12/2021
@version version
/*/
//-------------------------------------------------------------------

Method SetTitle(cTitle) Class PEmail
	Self:cTitle := cTitle
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} SetBody
Realizar a montagem da estrutuda da tabela no registro
posicionado e cormpo do email
@author Thalys Augusto
@since 16/12/2021
@version 1.0
/*/
//-------------------------------------------------------------------

Method SetBody() Class PEmail

	Local aStruct    := (Self:cAlias)->(dbStruct())
	Local aIndice	 := StrToArray((Self:cAlias)->(indexkey(1)),'+')
	Local aCampo     := {}
	Local nIdx       := 0
	Local cCadastro  := ""
	Local cValue 	 := ""
	Local cEmail     := ""

	dbSelectArea('SX3')
	SX3->(dbSetOrder(2))

	For nIdx := 1 to Len(aStruct)

		cValue	:= IIf(ValType((Self:cAlias)->&(aStruct[nIdx][1])) == "C" , (Self:cAlias)->&(aStruct[nIdx][1]) , cValToChar((Self:cAlias)->&(aStruct[nIdx][1])) )

		aAdd(aCampo,{aStruct[nIdx][1], IIf(SX3->(dbSeek(aStruct[nIdx][1])) , X3Titulo() ,'' ), cValue })

	Next nIdx

	dbSelectArea('SX2')

	cCadastro := IIf(SX2->(dbSeek(Self:cAlias)), X2Nome(), " <Erro nao localizado!> ")

	For nIdx := 1 to Len(aIndice)

		Self:cMsg += IIf( SX3->(dbSeek(aIndice[nIdx])) , X3Titulo() , aIndice[nIdx] ) + ": "
		Self:cMsg +=  (Self:cAlias)->&(aIndice[nIdx]) + ' <br> '

	Next nIdx

	Self:cMsg += '<br>'
	Self:cMsg += "O Usuario " + Capital(UsrRetName(RetCodUsr()))
	Self:cMsg += " realizou <b>" + cCadastro + "</b> na filial "
	Self:cMsg += cFilAnt + " com os seguintes valores: " + CRLF

	Self:cBody  :=  '<tr>'
	Self:cBody  +=      '<th>Campo</th>'
	Self:cBody  +=      '<th>Titulo</th>'
	Self:cBody  +=      '<th>Conteudo</th>'
	Self:cBody  +=  '</tr>'

	For nIdx:= 1 to Len(aCampo)

		Self:cBody +=  '<tr>'
		Self:cBody +=       '<td>' + aCampo[nIdx][1] + '</td>'
		Self:cBody +=       '<td>' + aCampo[nIdx][2] + '</td>'
		Self:cBody +=       '<td>' + aCampo[nIdx][3] + '</td>'
		Self:cBody +=  '</tr>'

	Next nIdx

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} SetMensege
Caso informado o email sera enviado com o conteudo
@since 16/12/2021
@author Thalys Augusto
@version version
/*/
//-------------------------------------------------------------------

Method SetMensege(cMensagem) Class PEmail
	Self:cMensagem  := cMensagem
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} SendMail
Realiza Envio do email
@since 16/12/2021
@author Thalys Augusto
@version version
/*/
//-------------------------------------------------------------------

Method SendMail() Class PEmail

	If Self:lEnable
		Self:SetEnvio()
	Else
		MsgInfo("Não foi possivel enviar o E-mail !"," Alerta ")
	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} SetEnvio
Recupera todos os parametros para envio de email
@since 16/12/2021
@author Thalys Augusto
@version version
/*/
//-------------------------------------------------------------------

Method SetEnvio() Class PEmail

	Local xRet
	Local oServer
	Local lMailAuth		:= .T.
	Local cServer 		:= GetNewPar("MV_RELSERV")
	Local nPort			:= GetNewPar("MV_PORSMTP")
	Local cMailConta	:= GetNewPar("MV_RELACNT")
	Local cMailSenha	:= GetNewPar("MV_RELPSW")


	If Self:lEnable

		If Empty(Self:cTitle)
			Self:cTitle := " Envio de Email padrão Protheus"
		EndIf

		Self:oMessage:cFrom 	:= cMailConta
		Self:oMessage:cTo 	 	:= Self:cEmail
		Self:oMessage:cSubject	:= Self:cTitle

		If !Empty(Self:cMailCC)
			Self:oMessage:cCc 		:= Self:cMailCC
		EndIf

		If !Empty(Self:cMensagem)
			Self:oMessage:cBody 		:= Self:cMensagem
		EndIf

		oServer := tMailManager():New()

		//Indica se sera utilizara a comunicaaao segura atravas de SSL/TLS (.T.) ou nao (.F.)
		oServer:SetUseTLS( .T. )

		//Indica se sera utilizado SSL
		oServer:setUseSSL( .F. )

		Varinfo('oMessage',Self:oMessage)
		Varinfo('oServer',oServer)

		//inicilizar o servidor
		xRet := oServer:Init( "", cServer , cMailConta, cMailSenha, 0, nPort )
		If xRet != 0
			Alert("O servidor SMTP nao foi inicializado: " + oServer:GetErrorString( xRet ) )
			Return
		EndIf

		//Indica o tempo de espera em segundos.
		xRet := oServer:SetSMTPTimeout( 60 )
		If xRet != 0
			VarInfo("cProtocol", cProtocol )
			Alert("Nao foi possivel definir " + cProtocol + " tempo limite para " + cValToChar( nTimeout ))
		EndIf

		xRet := oServer:SMTPConnect()
		If xRet != 0
			Alert("Nao foi possivel conectar ao servidor SMTP: " + oServer:GetErrorString( xRet ))
			Return
		EndIf

		If lMailAuth
			//O matodo SMTPAuth ao tentar realizar a autenticaaao do
			//usuario no servidor de e-mail, verIfica a configuraaao
			//da chave AuthSmtp, na seaao [Mail], no arquivo de
			//configuraaao (INI) do TOTVS Application Server, para determinar o valor.
			xRet := oServer:SmtpAuth( cMailConta, cMailSenha )
			If xRet != 0
				Self:cMsg := "Could not authenticate on SMTP server: " + oServer:GetErrorString( xRet )
				Alert( Self:cMsg )
				oServer:SMTPDisconnect()
				Return
			EndIf
		EndIf

		xRet := Self:oMessage:Send( oServer )
		If xRet != 0
			Alert("Nao foi possivel enviar mensagem: " + oServer:GetErrorString( xRet ))
		EndIf

		xRet := oServer:SMTPDisconnect()
		If xRet != 0
			Alert("Nao foi possivel desconectar o servidor SMTP: " + oServer:GetErrorString( xRet ))
		EndIf

	EndIf

	Self:oMessage:Clear()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} SetAttach
Realiza anexo de arquivos
@since 16/12/2021
@author Thalys Augusto
@version version
/*/
//-------------------------------------------------------------------

Method SetAttach(aFile) Class PEmail

	Local xRet := 0
	Local nArq := 0

	If Len(aFile) > 0

		For nArq := 1 To Len(aFile)

			xRet := Self:oMessage:AttachFile( aFile[nArq] )

			If xRet < 0
				Self:cMsg := "O arquivo " + aFile[nArq] + " nao foi anexado!"
				Alert( Self:cMsg )
				Return
			EndIf

		Next nArq

	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} SetEvent
Para envio de copia informa o metodo 
@since 16/12/2021
@author Thalys Augusto
@version version
/*/
//-------------------------------------------------------------------

Method SetCC(cMailCC) Class PEmail
	Self:cMailCC := cMailCC
Return 

//-------------------------------------------------------------------
/*/{Protheus.doc} SetEvent
Email a ser enviado 
@since 16/12/2021
@author Thalys Augusto
@version version
/*/
//-------------------------------------------------------------------

Method SetTo(cMailto) Class PEmail
	Self:cEmail := cMailto
Return


//-------------------------------------------------------------------
/*/{Protheus.doc} function
description  Exemplo
@since 16/12/2021
@author Thalys Augusto
@version version
/*/
//-------------------------------------------------------------------

User Function PEmail()

	Local oPEmail := PEmail():New('SA1')
	Local cMsg	  := ''
	Local cFile   := 'C:\Temp\email.html'


	If File(cFile)

		cMsg += MemoRead(cFile)

	EndIf

	dbSelectArea('SA1')
	dbSetOrder(1)

	SA1->(dbSeek(xFilial('SA1')+'000009'))

	oPEmail:SetBody()
	//oPEmail:SetMensege(cMsg)
	oPEmail:SetTitle("Cadastro de Clientes")
	oPEmail:SetEvent('P01')
	oPEmail:SendMail()

Return
