/*/{Protheus.doc} GetMaxDay

    Verifica quantos dias tem no mês

    @author  Nome
    @example Exemplos
    @param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
    @return  Especifica_o_retorno
    @table   Tabelas
    @since   22-07-2024
/*/
User Function GetMaxDay(nMonth, nYear)
    Local nDays := 31

    // Ajuste baseado no mês
    If nMonth == 2
        If (nYear % 4 == 0 .and. nYear % 100 != 0) .or. (nYear % 400 == 0)
            nDays := 29 // Fevereiro em ano bissexto
        Else
            nDays := 28 // Fevereiro em ano não bissexto
        EndIf
    ElseIf nMonth == 4 .or. nMonth == 6 .or. nMonth == 9 .or. nMonth == 11
        nDays := 30 // Abril, Junho, Setembro, Novembro
    EndIf

Return nDays
