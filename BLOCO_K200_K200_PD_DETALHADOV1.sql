WITH MOVIMENTACOES_DISTINCT AS (
    SELECT DISTINCT
        B6_IDENT,
        TIPO_MOVIMENTACAO,
        PRODUTO,
        CLIENTE_FORNECEDOR,
        LOJA,
        QUANTIDADE
    FROM (
        SELECT 
            SB6.B6_IDENT,
            'REMESSA' AS TIPO_MOVIMENTACAO,
            SB6.B6_PRODUTO AS PRODUTO,
            SB6.B6_CLIFOR AS CLIENTE_FORNECEDOR,
            SB6.B6_LOJA AS LOJA,
            SB6.B6_QUANT AS QUANTIDADE
        FROM SB6010 SB6
        WHERE SB6.B6_FILIAL = '0101'
          AND SB6.B6_PRODUTO BETWEEN 'CHGRPPB20BR' AND 'CHGRPPB20BR'
          AND SB6.B6_TIPO = 'D'
          AND SB6.B6_CLIFOR = '000031'
          AND SB6.B6_LOJA = '01'
          AND SB6.D_E_L_E_T_ = ' '

        UNION ALL

        SELECT 
            SB6REM.B6_IDENT,
            'RETORNO' AS TIPO_MOVIMENTACAO,
            SB6REM.B6_PRODUTO AS PRODUTO,
            SB6REM.B6_CLIFOR AS CLIENTE_FORNECEDOR,
            SB6REM.B6_LOJA AS LOJA,
            SB6REM.B6_QUANT * -1 AS QUANTIDADE
        FROM SB6010 SB6
        INNER JOIN SB6010 SB6REM ON SB6REM.B6_IDENT = SB6.B6_IDENT
        WHERE SB6.B6_FILIAL = '0101'
          AND SB6.B6_PRODUTO BETWEEN 'CHGRPPB20BR' AND 'CHGRPPB20BR'
          AND SB6.B6_TIPO = 'D'
          AND SB6.B6_CLIFOR = '000031'
          AND SB6.B6_LOJA = '01'
          AND SB6.D_E_L_E_T_ = ' '

        UNION ALL

        SELECT 
            D3K.D3K_NUMSEQ,
            'REQUISICAO' AS TIPO_MOVIMENTACAO,
            D3K.D3K_COD AS PRODUTO,
            D3K.D3K_CLIENT AS CLIENTE_FORNECEDOR,
            D3K.D3K_LOJA AS LOJA,
            D3K.D3K_QTDE * -1 AS QUANTIDADE
        FROM D3K010 D3K
        WHERE D3K.D3K_FILIAL = '0101'
          AND D3K.D3K_COD BETWEEN 'CHGRPPB20BR' AND 'CHGRPPB20BR'
          AND D3K.D3K_CLIENT = '000031'
          AND D3K.D3K_LOJA = '01'
          AND D3K.D_E_L_E_T_ = ' '
    ) AS MOVIMENTACOES
)
SELECT 
    B6_IDENT,
    PRODUTO,
    CLIENTE_FORNECEDOR,
    LOJA,
    TIPO_MOVIMENTACAO,
    QUANTIDADE,
    QUANTIDADE - LAG(QUANTIDADE) OVER (PARTITION BY PRODUTO ORDER BY TIPO_MOVIMENTACAO) AS DIFERENCA
FROM MOVIMENTACOES_DISTINCT
ORDER BY PRODUTO, B6_IDENT, TIPO_MOVIMENTACAO;
