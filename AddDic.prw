User Function AddDic(_cPort, _cLanguage)
   Default _cLanguage := 'E'
   If Empty(_cPort)
      Return ''
   EndIf
   //Aciona API de OCR - glogleapis
   cPostUrl      := "https://translation.googleapis.com/language/translate/v2"
   nTimeOut      := 60
   aHeadOut      := {}
   cHeaderRet    := ""
   sPostRet      := ""
   cPostDataI    := '{'                                                 +Chr(10)+Chr(13)
   cPostDataI    += '  "q": "'+EncodeUtf8(_cPort)+'",'                              +Chr(10)+Chr(13)
   cPostDataI    += '  "target": "en"'                                  +Chr(10)+Chr(13)
   cPostDataI    += '}'                                                 +Chr(10)+Chr(13)
   cPostDataE    := '{'                                                 +Chr(10)+Chr(13)
   cPostDataE    += '  "q": "'+EncodeUtf8(_cPort)+'",'                              +Chr(10)+Chr(13)
   cPostDataE    += '  "target": "es"'                                  +Chr(10)+Chr(13)
   cPostDataE    += '}'                                                 +Chr(10)+Chr(13)
   cMens         := "?key="+GetMV('ME_KEYGOOG', .F., "<sua chave google>")

   sPostRet := HttpPost(cPostUrl+cMens,'',cPostDataI,nTimeOut,aHeadOut,@cHeaderRet)
   oRetDic := Nil
   FWJsonDeserialize(NoAcento(sPostRet),@oRetDic)
   //VarInfo('oRet',oRetOCR)
   _cIngles := AllTrim(oRetDic:Data:translations[1]:TranslatedText)

   sPostRet := HttpPost(cPostUrl+cMens,'',cPostDataE,nTimeOut,aHeadOut,@cHeaderRet)
   oRetDic := Nil
   FWJsonDeserialize(NoAcento(sPostRet),@oRetDic)
   //VarInfo('oRet',oRetOCR)
   _cEspanhol := AllTrim(oRetDic:Data:translations[1]:TranslatedText)

   Return If(_cLanguage=='E', _cEspanhol, _cIngles)
