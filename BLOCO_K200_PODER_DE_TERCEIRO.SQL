SELECT
    B6_PRODUTO,
    PESSOA,
    B6_CLIFOR,
    B6_LOJA,
    B6_CLIPROP,
    B6_LJCLIPR,
CASE
        WHEN SUM(REQUISICAO) <= 0
        AND SUM(RETORNO) * -1 >(SUM(REQUISICAO) * -1) THEN SUM(REMESSA) + SUM(RETORNO)
        ELSE SUM(REMESSA) + SUM(REQUISICAO)
    END SALDO,
    SUM(SALDOFIS) SALDOFIS,
    SUM(SALDOVIR) SALDOVIR
FROM
    (
        SELECT
            'A' QRY,
            'D' TERC,
            B6_PRODUTO,
(
                CASE
                    WHEN B6_TPCF = 'C' THEN 'SA1'
                    WHEN B6_TPCF = 'F' THEN 'SA2'
                END
            ) PESSOA,
            B6_CLIFOR,
            B6_LOJA,
            B6_CLIPROP,
            B6_LJCLIPR,
            F4_ESTOQUE,
            B6_QUANT REMESSA,
            0 RETORNO,
            0 REQUISICAO,
(
                CASE
                    WHEN SF4.F4_CODIGO < '501'
                    AND SF4.F4_ESTOQUE = 'S' THEN SB6.B6_QUANT
                    WHEN SF4.F4_CODIGO > '500'
                    AND SF4.F4_ESTOQUE = 'S' THEN SB6.B6_QUANT * -1
                    ELSE 0
                END
            ) SALDOFIS,
(
                CASE
                    WHEN SF4.F4_CODIGO < '501'
                    AND SF4.F4_ESTOQUE = 'N' THEN SB6.B6_QUANT
                    WHEN SF4.F4_CODIGO > '500'
                    AND SF4.F4_ESTOQUE = 'N' THEN SB6.B6_QUANT * -1
                    ELSE 0
                END
            ) SALDOVIR
        FROM
            SB6010 SB6
            INNER JOIN SB1010 SB1 ON SB1.B1_FILIAL = '0101'
            AND SB1.B1_COD = SB6.B6_PRODUTO
            AND SB1.B1_COD NOT LIKE 'MOD%'
            AND SB1.B1_CCCUSTO = ' '
            AND SB1.D_E_L_E_T_ = ' '
            INNER JOIN SF4010 SF4 ON SF4.F4_FILIAL = '0101'
            AND SF4.F4_CODIGO = SB6.B6_TES
            AND SF4.F4_PODER3 = 'R'
            AND SF4.D_E_L_E_T_ = ' '
        WHERE
            SB6.B6_FILIAL = '0101'
            AND SB6.B6_PRODUTO BETWEEN 'CHGRPPB20BR'
            AND 'CHGRPPB20BR'
            AND SB6.B6_TIPO = 'D'
            AND SB6.B6_DTDIGIT <= '20241031'
            AND SB6.D_E_L_E_T_ = ' '
            AND SB1.B1_TIPO IN ('MR', 'MP', 'EM', 'PP', 'PA', 'SP', 'PI', 'OI')
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    D3E010 D3E
                    JOIN SA1010 SA1 ON SA1.A1_FILIAL = '01  '
                    AND SA1.A1_COD = D3E.D3E_CLIENT
                    AND SA1.A1_LOJA = D3E.D3E_LOJA
                    AND SA1.D_E_L_E_T_ = ' '
                WHERE
                    D3E.D3E_FILIAL = '0101'
                    AND D3E.D3E_COD = SB6.B6_PRODUTO
                    AND D3E.D_E_L_E_T_ = ' '
            )
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    SDH010 SDH
                    JOIN SD1010 SD1 ON SD1.D1_FILIAL = '0101'
                    AND SDH.DH_IDENTNF = SD1.D1_NUMSEQ
                    AND SD1.D_E_L_E_T_ = ' '
                WHERE
                    SDH.DH_FILIAL = '0101'
                    AND SB6.B6_DOC = SD1.D1_DOC
                    AND SB6.B6_SERIE = SD1.D1_SERIE
                    AND SD1.D1_FORNECE = SB6.B6_CLIFOR
                    AND SD1.D1_LOJA = SB6.B6_LOJA
                    AND SD1.D1_COD = SB6.B6_PRODUTO
                    AND SD1.D1_QUANT = SB6.B6_QUANT
                    AND SDH.D_E_L_E_T_ = ' '
            )
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    SDH010 SDH
                    JOIN SD2010 SD2 ON SD2.D2_FILIAL = '0101'
                    AND SDH.DH_IDENTNF = SD2.D2_NUMSEQ
                    AND SD2.D_E_L_E_T_ = ' '
                WHERE
                    SDH.DH_FILIAL = '0101'
                    AND SD2.D2_COD = SB6.B6_PRODUTO
                    AND SB6.B6_DOC = SD2.D2_DOC
                    AND SB6.B6_SERIE = SD2.D2_SERIE
                    AND SD2.D2_CLIENTE = SB6.B6_CLIFOR
                    AND SD2.D2_LOJA = SB6.B6_LOJA
                    AND SD2.D2_QUANT = SB6.B6_QUANT
                    AND SDH.D_E_L_E_T_ = ' '
            )
        UNION
        ALL
        SELECT
            'B' QRY,
            'D' TERC,
            SB6.B6_PRODUTO,
(
                CASE
                    WHEN SB6REM.B6_TPCF = 'C' THEN 'SA1'
                    WHEN SB6REM.B6_TPCF = 'F' THEN 'SA2'
                END
            ) PESSOA,
            SB6REM.B6_CLIFOR,
            SB6REM.B6_LOJA,
            SB6REM.B6_CLIPROP,
            SB6REM.B6_LJCLIPR,
            SF4.F4_ESTOQUE,
            0,
            SB6.B6_QUANT * - 1 B6_QUANT,
            0,
(
                CASE
                    WHEN SF4.F4_CODIGO < '501'
                    AND SF4REM.F4_ESTOQUE = 'S' THEN SB6.B6_QUANT
                    WHEN SF4.F4_CODIGO > '500'
                    AND SF4REM.F4_ESTOQUE = 'S' THEN SB6.B6_QUANT * -1
                    ELSE 0
                END
            ) SALDOFIS,
(
                CASE
                    WHEN SF4.F4_CODIGO < '501'
                    AND SF4REM.F4_ESTOQUE = 'N' THEN SB6.B6_QUANT
                    WHEN SF4.F4_CODIGO > '500'
                    AND SF4REM.F4_ESTOQUE = 'N' THEN SB6.B6_QUANT * -1
                    ELSE 0
                END
            ) SALDOVIR
        FROM
            SB6010 SB6
            INNER JOIN SB1010 SB1 ON SB1.B1_FILIAL = '0101'
            AND SB1.B1_COD = SB6.B6_PRODUTO
            AND SB1.B1_COD NOT LIKE 'MOD%'
            AND SB1.B1_CCCUSTO = ' '
            AND SB1.D_E_L_E_T_ = ' '
            LEFT JOIN SB6010 SB6REM ON SB6REM.B6_FILIAL = '0101'
            AND SB6REM.B6_IDENT = SB6.B6_IDENT
            AND SB6REM.B6_TIPO = 'D'
            AND SB6REM.B6_PRODUTO = SB6.B6_PRODUTO
            AND SB6REM.B6_DTDIGIT <= '20241031'
            AND SB6REM.D_E_L_E_T_ = ' '
            INNER JOIN SF4010 SF4REM ON SF4REM.F4_FILIAL = '0101'
            AND SF4REM.F4_CODIGO = SB6REM.B6_TES
            AND SF4REM.F4_PODER3 = 'R'
            AND SF4REM.D_E_L_E_T_ = ' '
            INNER JOIN SF4010 SF4 ON SF4.F4_FILIAL = '0101'
            AND SF4.F4_CODIGO = SB6.B6_TES
            AND SF4.F4_PODER3 = 'D'
            AND SF4.D_E_L_E_T_ = ' '
        WHERE
            SB6.B6_FILIAL = '0101'
            AND SB6.B6_PRODUTO BETWEEN 'CHGRPPB20BR'
            AND 'CHGRPPB20BR'
            AND SB6.B6_TIPO = 'D'
            AND SB6.B6_DTDIGIT <= '20241031'
            AND SB6.D_E_L_E_T_ = ' '
            AND SB1.B1_TIPO IN ('MR', 'MP', 'EM', 'PP', 'PA', 'SP', 'PI', 'OI')
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    D3E010 D3E
                    JOIN SA1010 SA1 ON SA1.A1_FILIAL = '01  '
                    AND SA1.A1_COD = D3E.D3E_CLIENT
                    AND SA1.A1_LOJA = D3E.D3E_LOJA
                    AND SA1.D_E_L_E_T_ = ' '
                WHERE
                    D3E.D3E_FILIAL = '0101'
                    AND D3E.D3E_COD = SB6.B6_PRODUTO
                    AND D3E.D_E_L_E_T_ = ' '
            )
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    SDH010 SDH
                    JOIN SD1010 SD1 ON SD1.D1_FILIAL = '0101'
                    AND SDH.DH_IDENTNF = SD1.D1_NUMSEQ
                    AND SD1.D_E_L_E_T_ = ' '
                WHERE
                    SDH.DH_FILIAL = '0101'
                    AND SB6.B6_DOC = SD1.D1_DOC
                    AND SB6.B6_SERIE = SD1.D1_SERIE
                    AND SD1.D1_FORNECE = SB6.B6_CLIFOR
                    AND SD1.D1_LOJA = SB6.B6_LOJA
                    AND SD1.D1_COD = SB6.B6_PRODUTO
                    AND SD1.D1_QUANT = SB6.B6_QUANT
                    AND SDH.D_E_L_E_T_ = ' '
            )
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    SDH010 SDH
                    JOIN SD2010 SD2 ON SD2.D2_FILIAL = '0101'
                    AND SDH.DH_IDENTNF = SD2.D2_NUMSEQ
                    AND SD2.D_E_L_E_T_ = ' '
                WHERE
                    SDH.DH_FILIAL = '0101'
                    AND SB6.B6_DOC = SD2.D2_DOC
                    AND SB6.B6_SERIE = SD2.D2_SERIE
                    AND SD2.D2_CLIENTE = SB6.B6_CLIFOR
                    AND SD2.D2_LOJA = SB6.B6_LOJA
                    AND SD2.D2_COD = SB6.B6_PRODUTO
                    AND SD2.D2_QUANT = SB6.B6_QUANT
                    AND SDH.D_E_L_E_T_ = ' '
            )
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    SD3010 SD3
                    JOIN D3K010 D3K ON D3K.D3K_FILIAL = '0101'
                    AND D3K.D3K_NUMSEQ = SD3.D3_NUMSEQ
                    AND D3K.D3K_CLIENT = SB6.B6_CLIFOR
                    AND D3K.D3K_LOJA = SB6.B6_LOJA
                    AND D3K.D3K_COD = SD3.D3_COD
                    AND D3K.D_E_L_E_T_ = ' '
                WHERE
                    SD3.D3_FILIAL = '0101'
                    AND SD3.D3_EMISSAO <= '20241031'
                    AND SD3.D3_CF LIKE 'RE%'
                    AND SD3.D3_COD = SB6.B6_PRODUTO
                    AND SD3.D3_OP <> '  '
                    AND SD3.D_E_L_E_T_ = ' '
                    AND NOT EXISTS(
                        SELECT
                            1
                        FROM
                            D3E010 D3E
                            JOIN SA1010 SA1 ON SA1.A1_FILIAL = '01  '
                            AND SA1.A1_COD = D3E.D3E_CLIENT
                            AND SA1.A1_LOJA = D3E.D3E_LOJA
                            AND SA1.D_E_L_E_T_ = ' '
                        WHERE
                            D3E.D3E_FILIAL = '0101'
                            AND D3E.D3E_COD = SD3.D3_COD
                            AND D3E.D_E_L_E_T_ = ' '
                    )
            )
        UNION
        ALL
        SELECT
            'C' QRY,
            'D' TERC,
            SD3.D3_COD,
            'SA1',
            D3K.D3K_CLIENT,
            D3K.D3K_LOJA,
            ' ',
            ' ',
            'S',
            0,
            0,
(D3K.D3K_QTDE * -1),
(D3K.D3K_QTDE * -1),
            0
        FROM
            SD3010 SD3
            JOIN D3K010 D3K ON D3K.D3K_FILIAL = '0101'
            AND D3K.D3K_NUMSEQ = SD3.D3_NUMSEQ
            AND D3K.D3K_COD = SD3.D3_COD
            AND D3K.D_E_L_E_T_ = ' '
            INNER JOIN SB1010 SB1 ON SB1.B1_FILIAL = '0101'
            AND SB1.B1_COD = SD3.D3_COD
            AND SB1.B1_COD NOT LIKE 'MOD%'
            AND SB1.B1_CCCUSTO = ' '
            AND SB1.D_E_L_E_T_ = ' '
        WHERE
            SD3.D3_FILIAL = '0101'
            AND SD3.D3_EMISSAO <= '20241031'
            AND SD3.D3_CF LIKE 'RE%'
            AND SD3.D3_COD BETWEEN 'CHGRPPB20BR'
            AND 'CHGRPPB20BR'
            AND SD3.D3_OP <> '  '
            AND SD3.D_E_L_E_T_ = ' '
            AND SB1.B1_TIPO IN ('MR', 'MP', 'EM', 'PP', 'PA', 'SP', 'PI', 'OI')
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    D3E010 D3E
                    JOIN SA1010 SA1 ON SA1.A1_FILIAL = '01  '
                    AND SA1.A1_COD = D3E.D3E_CLIENT
                    AND SA1.A1_LOJA = D3E.D3E_LOJA
                    AND SA1.D_E_L_E_T_ = ' '
                WHERE
                    D3E.D3E_FILIAL = '0101'
                    AND D3E.D3E_COD = SD3.D3_COD
                    AND D3E.D_E_L_E_T_ = ' '
            )
        UNION
        ALL
        SELECT
            'D' QRY,
            'D' TERC,
            SD3.D3_COD,
            'SA1',
            D3K.D3K_CLIENT,
            D3K.D3K_LOJA,
            ' ',
            ' ',
            'S',
            0,
            0,
            D3K.D3K_QTDE,
            D3K.D3K_QTDE,
            0
        FROM
            SD3010 SD3
            INNER JOIN SB1010 SB1 ON SB1.B1_FILIAL = '0101'
            AND SB1.B1_COD = SD3.D3_COD
            AND SB1.B1_COD NOT LIKE 'MOD%'
            AND SB1.B1_CCCUSTO = ' '
            AND SB1.D_E_L_E_T_ = ' '
            JOIN D3K010 D3K ON D3K.D3K_FILIAL = '0101'
            AND D3K.D3K_NUMSEQ = SD3.D3_NUMSEQ
            AND D3K.D3K_COD = SD3.D3_COD
            AND D3K.D_E_L_E_T_ = ' '
        WHERE
            SD3.D3_FILIAL = '0101'
            AND SD3.D3_EMISSAO <= '20241031'
            AND (
                SD3.D3_CF LIKE 'PR%'
                OR SD3.D3_CF LIKE 'DE%'
            )
            AND SD3.D3_COD BETWEEN 'CHGRPPB20BR'
            AND 'CHGRPPB20BR'
            AND SD3.D3_OP <> '  '
            AND SD3.D_E_L_E_T_ = ' '
            AND SB1.B1_TIPO IN ('MR', 'MP', 'EM', 'PP', 'PA', 'SP', 'PI', 'OI')
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    D3E010 D3E
                    JOIN SA1010 SA1 ON SA1.A1_FILIAL = '01  '
                    AND SA1.A1_COD = D3E.D3E_CLIENT
                    AND SA1.A1_LOJA = D3E.D3E_LOJA
                    AND SA1.D_E_L_E_T_ = ' '
                WHERE
                    D3E.D3E_FILIAL = '0101'
                    AND D3E.D3E_COD = SD3.D3_COD
                    AND D3E.D_E_L_E_T_ = ' '
            )
        UNION
        ALL
        SELECT
            'E' QRY,
            'D' TERC,
            SD2.D2_COD,
            'SA1',
            SD2.D2_CLIENTE,
            SD2.D2_LOJA,
            ' ',
            ' ',
            'S',
            0,
            0,
(SD2.D2_QUANT * -1),
(SD2.D2_QUANT * -1),
            0
        FROM
            SD2010 SD2
            INNER JOIN SB1010 SB1 ON SB1.B1_FILIAL = '0101'
            AND SB1.B1_COD = SD2.D2_COD
            AND SB1.B1_COD NOT LIKE 'MOD%'
            AND SB1.B1_CCCUSTO = ' '
            AND SB1.D_E_L_E_T_ = ' '
            LEFT JOIN SBZ010 SBZ ON SBZ.BZ_FILIAL = '0101'
            AND SBZ.BZ_COD = SB1.B1_COD
            AND SBZ.D_E_L_E_T_ = ' '
        WHERE
            SD2.D2_FILIAL = '0101'
            AND SD2.D2_EMISSAO <= '20241031'
            AND SD2.D2_EMISSAO >= (
                SELECT
                    MIN(SD3.D3_EMISSAO)
                FROM
                    SD3010 SD3
                    JOIN D3K010 D3K ON D3K.D3K_FILIAL = '0101'
                    AND D3K.D3K_NUMSEQ = SD3.D3_NUMSEQ
                    AND D3K.D3K_COD = SD3.D3_COD
                    AND D3K.D_E_L_E_T_ = ' '
                WHERE
                    SD3.D3_FILIAL = '0101'
                    AND D3K.D3K_CLIENT = SD2.D2_CLIENTE
                    AND D3K.D3K_LOJA = SD2.D2_LOJA
                    AND SD3.D3_COD = SD2.D2_COD
                    AND SD3.D3_CF LIKE 'PR%'
                    AND SD3.D3_COD BETWEEN 'CHGRPPB20BR'
                    AND 'CHGRPPB20BR'
                    AND SD3.D_E_L_E_T_ = ' '
            )
            AND SB1.B1_TIPO IN ('MR', 'MP', 'EM', 'PP', 'PA', 'SP', 'PI', 'OI')
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    D3E010 D3E
                    JOIN SA1010 SA1 ON SA1.A1_FILIAL = '01  '
                    AND SA1.A1_COD = D3E.D3E_CLIENT
                    AND SA1.A1_LOJA = D3E.D3E_LOJA
                    AND SA1.D_E_L_E_T_ = ' '
                WHERE
                    D3E.D3E_FILIAL = '0101'
                    AND D3E.D3E_COD = SD2.D2_COD
                    AND D3E.D_E_L_E_T_ = ' '
            )
        UNION
        ALL
        SELECT
            'F' QRY,
            'D' TERC,
            SD1.D1_COD B6_PRODUTO,
            (
                CASE
                    WHEN SDH.DH_CLIENTE = '      '
                    AND SDH.DH_LOJACLI = '  ' THEN 'SA2'
                    ELSE 'SA1'
                END
            ) PESSOA,
            (
                CASE
                    WHEN SDH.DH_CLIENTE = '      ' THEN SDH.DH_FORNECE
                    ELSE SDH.DH_CLIENTE
                END
            ) B6_CLIFOR,
            (
                CASE
                    WHEN SDH.DH_LOJACLI = '  ' THEN SDH.DH_LOJAFOR
                    ELSE SDH.DH_LOJACLI
                END
            ) B6_LOJA,
            ' ',
            ' ',
            F4_ESTOQUE,
            SD1.D1_QUANT REMESSA,
            0 RETORNO,
            0 REQUISICAO,
(
                CASE
                    WHEN SF4.F4_CODIGO < '501'
                    AND SF4.F4_ESTOQUE = 'S' THEN SD1.D1_QUANT
                    WHEN SF4.F4_CODIGO > '500'
                    AND SF4.F4_ESTOQUE = 'S' THEN SD1.D1_QUANT * -1
                    ELSE 0
                END
            ) SALDOFIS,
(
                CASE
                    WHEN SF4.F4_CODIGO < '501'
                    AND SF4.F4_ESTOQUE = 'N' THEN SD1.D1_QUANT * -1
                    WHEN SF4.F4_CODIGO > '500'
                    AND SF4.F4_ESTOQUE = 'N' THEN SD1.D1_QUANT
                    ELSE 0
                END
            ) SALDOVIR
        FROM
            SD1010 SD1
            INNER JOIN SB1010 SB1 ON SB1.B1_FILIAL = '0101'
            AND SB1.B1_COD = SD1.D1_COD
            AND SB1.B1_COD NOT LIKE 'MOD%'
            AND SB1.B1_CCCUSTO = ' '
            AND SB1.D_E_L_E_T_ = ' '
            LEFT JOIN SBZ010 SBZ ON SBZ.BZ_FILIAL = '0101'
            AND SBZ.BZ_COD = SB1.B1_COD
            AND SBZ.D_E_L_E_T_ = ' '
            INNER JOIN SDH010 SDH ON SDH.DH_FILIAL = '0101'
            AND SDH.DH_IDENTNF = SD1.D1_NUMSEQ
            AND SDH.D_E_L_E_T_ = ' '
            INNER JOIN SF4010 SF4 ON SF4.F4_FILIAL = '0101'
            AND SF4.F4_CODIGO = SD1.D1_TES
            AND SF4.F4_PODER3 = 'R'
            AND SF4.D_E_L_E_T_ = ' '
        WHERE
            SD1.D1_DTDIGIT <= '20241031'
            AND SD1.D1_COD BETWEEN 'CHGRPPB20BR'
            AND 'CHGRPPB20BR'
            AND SD1.D_E_L_E_T_ = ' '
            AND SB1.B1_TIPO IN ('MR', 'MP', 'EM', 'PP', 'PA', 'SP', 'PI', 'OI')
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    D3E010 D3E
                    JOIN SA1010 SA1 ON SA1.A1_FILIAL = '01  '
                    AND SA1.A1_COD = D3E.D3E_CLIENT
                    AND SA1.A1_LOJA = D3E.D3E_LOJA
                    AND SA1.D_E_L_E_T_ = ' '
                WHERE
                    D3E.D3E_FILIAL = '0101'
                    AND D3E.D3E_COD = SD1.D1_COD
                    AND D3E.D_E_L_E_T_ = ' '
            )
        UNION
        ALL
        SELECT
            'G' QRY,
            'D' TERC,
            SD2.D2_COD B6_PRODUTO,
            (
                CASE
                    WHEN SDH.DH_CLIENTE = '      '
                    AND SDH.DH_LOJACLI = '  ' THEN 'SA2'
                    ELSE 'SA1'
                END
            ) PESSOA,
            (
                CASE
                    WHEN SDH.DH_CLIENTE = '      ' THEN SDH.DH_FORNECE
                    ELSE SDH.DH_CLIENTE
                END
            ) B6_CLIFOR,
            (
                CASE
                    WHEN SDH.DH_LOJACLI = '  ' THEN SDH.DH_LOJAFOR
                    ELSE SDH.DH_LOJACLI
                END
            ) B6_LOJA,
            ' ',
            ' ',
            'S' F4_ESTOQUE,
            0 REMESSA,
(SD2.D2_QUANT * -1) RETORNO,
            0 REQUISICAO,
(
                CASE
                    WHEN SF4.F4_CODIGO < '501'
                    AND SF4.F4_ESTOQUE = 'S' THEN SD2.D2_QUANT
                    WHEN SF4.F4_CODIGO > '500'
                    AND SF4.F4_ESTOQUE = 'S' THEN SD2.D2_QUANT * -1
                    ELSE 0
                END
            ) SALDOFIS,
(
                CASE
                    WHEN SF4.F4_CODIGO < '501'
                    AND SF4.F4_ESTOQUE = 'N' THEN 0
                    WHEN SF4.F4_CODIGO > '500'
                    AND SF4.F4_ESTOQUE = 'N' THEN SD2.D2_QUANT
                    ELSE 0
                END
            ) SALDOVIR
        FROM
            SD2010 SD2
            INNER JOIN SB1010 SB1 ON SB1.B1_FILIAL = '0101'
            AND SB1.B1_COD = SD2.D2_COD
            AND SB1.B1_COD NOT LIKE 'MOD%'
            AND SB1.B1_CCCUSTO = ' '
            AND SB1.D_E_L_E_T_ = ' '
            LEFT JOIN SBZ010 SBZ ON SBZ.BZ_FILIAL = '0101'
            AND SBZ.BZ_COD = SB1.B1_COD
            AND SBZ.D_E_L_E_T_ = ' '
            INNER JOIN SDH010 SDH ON SDH.DH_FILIAL = '0101'
            AND SDH.DH_IDENTNF = SD2.D2_NUMSEQ
            AND SDH.D_E_L_E_T_ = ' '
            INNER JOIN SF4010 SF4 ON SF4.F4_FILIAL = '0101'
            AND SF4.F4_CODIGO = SD2.D2_TES
            AND SF4.F4_PODER3 = 'D'
            AND SF4.D_E_L_E_T_ = ' '
        WHERE
            SD2.D2_EMISSAO <= '20241031'
            AND SD2.D2_COD BETWEEN 'CHGRPPB20BR'
            AND 'CHGRPPB20BR'
            AND SD2.D_E_L_E_T_ = ' '
            AND SB1.B1_TIPO IN ('MR', 'MP', 'EM', 'PP', 'PA', 'SP', 'PI', 'OI')
            AND NOT EXISTS(
                SELECT
                    1
                FROM
                    D3E010 D3E
                    JOIN SA1010 SA1 ON SA1.A1_FILIAL = '01  '
                    AND SA1.A1_COD = D3E.D3E_CLIENT
                    AND SA1.A1_LOJA = D3E.D3E_LOJA
                    AND SA1.D_E_L_E_T_ = ' '
                WHERE
                    D3E.D3E_FILIAL = '0101'
                    AND D3E.D3E_COD = SD2.D2_COD
                    AND D3E.D_E_L_E_T_ = ' '
            )
    ) SaldoTerceiro
GROUP BY
    B6_PRODUTO,
    PESSOA,
    B6_CLIFOR,
    B6_LOJA,
    B6_CLIPROP,
    B6_LJCLIPR
ORDER BY
    1
