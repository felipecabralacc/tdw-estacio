CREATE OR REPLACE FUNCTION SIA.PRO_OBTEM_CENTRO_RESULTADO(PI_COD_TIPO_CURSO   IN SIA.A_INTERFACE_PAGAMENTO.COD_TIPO_CURSO%TYPE
                                     ,PI_COD_CAMPUS       IN SIA.A_INTERFACE_PAGAMENTO.COD_CAMPUS%TYPE
                                     ,PI_COD_CURSO        IN NUMBER
                                     ,PI_COD_TURNO        IN SIA.A_INTERFACE_PAGAMENTO.COD_TURNO%TYPE
                                     ,PI_NOM_PROCESSO     IN SIA.A_INTERFACE_PAGAMENTO.NOM_PROCESSO%TYPE
                                     ,PI_COD_TIPO_ATUACAO IN SIA.A_INTERFACE_PAGAMENTO.COD_TIPO_ATUACAO%TYPE
                                     ,PI_COD_INSTITUICAO  IN SIA.INSTITUICAO_ENSINO.COD_INSTITUICAO%TYPE) RETURN VARCHAR2 IS
    --
    ERR_PREVISTO EXCEPTION;
    --
    V_SQL                  VARCHAR(1000);
    V_IND_REGULAR_EXTENSAO VARCHAR2(1);
    --
    V_COD_TIPO_CURSO_SAP    SIA.TIPO_CURSO.COD_TIPO_CURSO_SAP%TYPE;
    V_COD_CURSO_SAP         SIA.CURSO.COD_CURSO_SAP%TYPE;
    V_COD_CAMPUS_SAP        SIA.CAMPUS.COD_CAMPUS_SAP%TYPE;
    V_COD_TURNO_SAP         SIA.TURNO.COD_TURNO_SAP%TYPE;
    V_IND_CR_APOIO          SIA.TIPO_ATUACAO.IND_CR_APOIO%TYPE;
    PO_COD_CENTRO_RESULTADO INTERFACE.SAP_CENTRO_RESULTADO.COD_CENTRO_RESULTADO%TYPE;
    V_TXT_PARAMETRO_CR_ATUACAO    	SIA.PARAMETROS_PROFESSOR.TXT_PARAMETRO%TYPE;
    V_TXT_PARAMETRO_CR_APOIO      	SIA.PARAMETROS_PROFESSOR.TXT_PARAMETRO%TYPE;
	  V_TXT_PARAMETRO_CR_ESPECIALIZ 	SIA.PARAMETROS_PROFESSOR.TXT_PARAMETRO%TYPE;


    --
  BEGIN
    --
    --  BUSCA O VALOR DA VARIAVEL V_TXT_PARAMETRO_CR_APOIO
	  --
	  BEGIN
		SELECT SUBSTR(TXT_PARAMETRO, 1, 8)
		  INTO V_TXT_PARAMETRO_CR_APOIO
		  FROM SIA.PARAMETROS_PROFESSOR
		 WHERE COD_PARAMETRO = 10; -- CENTRO DE RESULTADO DE APOIO PARA ATUA��ES FIXAS
	  EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  NULL;
	  END;
	  --
    --  BUSCA O VALOR DA VARIAVEL V_TXT_PARAMETRO_CR_ESPECIALIZ
	  --
	  BEGIN
		SELECT SUBSTR(TXT_PARAMETRO, 1, 8)
		  INTO V_TXT_PARAMETRO_CR_ESPECIALIZ
		  FROM SIA.PARAMETROS_PROFESSOR
		 WHERE COD_PARAMETRO = 16; -- CENTRO DE RESULTADO DA ESPECIALIZA��O PARA ATUA��ES FIXAS
	  EXCEPTION
		WHEN NO_DATA_FOUND THEN
		  NULL;
	  END;
	  --
    --
    --  BUSCA O INDICADOR DE TIPO DO CURSO (REGULAR OU EXTENS�O)
    --
    IF PI_COD_TIPO_CURSO IS NOT NULL
    THEN
      --
      SELECT NVL(IND_REGULAR_EXTENSAO, 'R')
        INTO V_IND_REGULAR_EXTENSAO
        FROM SIA.TIPO_CURSO
       WHERE COD_TIPO_CURSO = PI_COD_TIPO_CURSO;
      --
    ELSIF PI_COD_CURSO IS NOT NULL
    THEN
      --
      SELECT NVL(TC.IND_REGULAR_EXTENSAO, 'R')
        INTO V_IND_REGULAR_EXTENSAO
        FROM SIA.TIPO_CURSO TC
            ,SIA.CURSO      C
       WHERE C.COD_TIPO_CURSO = TC.COD_TIPO_CURSO
         AND C.COD_CURSO = PI_COD_CURSO;
      --
    END IF; -- IF PI_COD_TIPO_CURSO IS NOT NULL THEN

    --
    --  BUSCA O INDICADOR DE CR DE APOIO PARA O TIPO DE ATUA��O
    --
    IF PI_COD_TIPO_ATUACAO IS NOT NULL
    THEN
      --
    BEGIN
      SELECT TA.IND_CR_APOIO
        INTO V_IND_CR_APOIO
        FROM SIA.TIPO_ATUACAO TA
       WHERE TA.COD_TIPO_ATUACAO = PI_COD_TIPO_ATUACAO
         AND TA.IND_FIXO_VARIAVEL = 'F';

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_IND_CR_APOIO := 'N';
      WHEN OTHERS THEN
        RETURN NULL;
    END;
      --
    END IF; -- IF PI_COD_TIPO_ATUACAO IS NOT NULL THEN

    --
    --  BUSCA O C�DIGO DO TIPO CURSO NO SAP PARA COMPOR A ATUA��O
    --
    IF PI_COD_TIPO_CURSO IS NOT NULL
    THEN
      --
      SELECT TC.COD_TIPO_CURSO_SAP
        INTO V_COD_TIPO_CURSO_SAP
        FROM SIA.TIPO_CURSO TC
       WHERE TC.COD_TIPO_CURSO = PI_COD_TIPO_CURSO;
      --
    END IF; -- IF PI_COD_TIPO_CURSO IS NOT NULL

    --
    --  BUSCA O C�DIGO DO CAMPUS NO SAP PARA COMPOR A ATUA��O
    --
    IF PI_COD_CAMPUS IS NOT NULL
    THEN
      --
      SELECT CA.COD_CAMPUS_SAP
        INTO V_COD_CAMPUS_SAP
        FROM SIA.CAMPUS CA
       WHERE CA.COD_CAMPUS = PI_COD_CAMPUS;
      --
    END IF; -- IF PI_COD_CAMPUS IS NOT NULL
      --
      -- SE O TIPO DE ATUA��O UTILIZA O CR DE APOIO OU ESPECIALIZA��O ('A'-Apoio - 'E'-Especializa��o - 'N'-Normal)
      --
    IF V_IND_CR_APOIO <> 'N'
    THEN
      --
      --  PREPARA O PAR�METRO PARA BUSCAR COD_CENTRO_RESULTADO PARA AS ATUA��ES FIXAS
      --
      V_TXT_PARAMETRO_CR_ATUACAO := NULL;
      IF V_IND_CR_APOIO = 'A'
      THEN
        --
        V_TXT_PARAMETRO_CR_ATUACAO := V_TXT_PARAMETRO_CR_APOIO;
      ELSE
        V_TXT_PARAMETRO_CR_ATUACAO := V_TXT_PARAMETRO_CR_ESPECIALIZ;
        --
      END IF; -- V_IND_CR_APOIO = 'A'
      --
      -- BUSCA O COD_CENTRO_RESULTADO DE APOIO DAS ATUA��ES FIXAS
      --
      BEGIN
        --
        SELECT COD_CENTRO_RESULTADO
          INTO PO_COD_CENTRO_RESULTADO
          FROM INTERFACE.SAP_CENTRO_RESULTADO_R3 SCR
         WHERE SCR.COD_CENTRO_RESULTADO = V_COD_CAMPUS_SAP || V_TXT_PARAMETRO_CR_ATUACAO
           AND SYSDATE BETWEEN SCR.DT_VALIDADE_INI AND SCR.DT_VALIDADE_FIM
           AND ROWNUM = 1;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          PO_COD_CENTRO_RESULTADO := NULL;
        WHEN OTHERS THEN
          RETURN NULL;
      END;
    --
    --
    -- SE CHEGAREM OS PAR�METROS B�SICOS, BUSCA O CENTRO DE RESULTADO DA INTERFACE.SAP_CENTRO_RESULTADO_R3
    -- ATRAV�S DA COMPOSI��O (CAMPUS / TIPO CURSO / CURSO / TURNO).
    --
    ELSIF PI_COD_TIPO_CURSO IS NOT NULL AND -- ELSIF V_IND_CR_APOIO <> 'N'
       PI_COD_CAMPUS IS NOT NULL AND
       PI_COD_CURSO IS NOT NULL
    THEN
      --
      IF V_IND_REGULAR_EXTENSAO = 'R' THEN
        --
        SELECT C.COD_CURSO_SAP
          INTO V_COD_CURSO_SAP
          FROM SIA.CURSO C
         WHERE C.COD_CURSO = PI_COD_CURSO;
        --
      ELSE
        --
        SELECT C.COD_CURSO_EXTENSAO_SAP
          INTO V_COD_CURSO_SAP
          FROM SIA.CURSO_EXTENSAO C
         WHERE C.COD_CURSO_EXTENSAO = PI_COD_CURSO;
        --
      END IF; -- IF V_IND_REGULAR_EXTENSAO = 'R' THEN
      --
      BEGIN
        --
        IF PI_COD_TIPO_CURSO IN (3) OR
           V_IND_REGULAR_EXTENSAO <> 'R'
        THEN
          V_COD_TURNO_SAP := '99';
        ELSE
          SELECT T.COD_TURNO_SAP
            INTO V_COD_TURNO_SAP
            FROM SIA.TURNO T
           WHERE T.COD_TURNO = PI_COD_TURNO;
        END IF;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_COD_TURNO_SAP := '99';
        WHEN OTHERS THEN
          RETURN NULL;
      END;
      --
      -- BUSCA O COD_CENTRO_RESULTADO EM COD_CURSO OU COD_CURSO_EXTENSAO
      --
      BEGIN
        --
        SELECT COD_CENTRO_RESULTADO
          INTO PO_COD_CENTRO_RESULTADO
          FROM INTERFACE.SAP_CENTRO_RESULTADO_R3 SCR
         WHERE SCR.COD_CENTRO_RESULTADO = V_COD_CAMPUS_SAP || V_COD_TIPO_CURSO_SAP || V_COD_CURSO_SAP || V_COD_TURNO_SAP
           AND SYSDATE BETWEEN SCR.DT_VALIDADE_INI AND SCR.DT_VALIDADE_FIM
           AND ROWNUM = 1;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          PO_COD_CENTRO_RESULTADO := NULL;
        WHEN OTHERS THEN
          RETURN NULL;
      END;
      --
      -- SE O TIPO DE ATUA��O UTILIZA O CR DE APOIO
      --
    ELSE -- ELSIF PI_COD_TIPO_CURSO IS NOT NULL AND PI_COD_CAMPUS IS NOT NULL AND
      --
      -- SE N�O CHEGAREM TODOS OS PAR�METROS B�SICOS, BUSCA O CENTRO DE RESULTADO
      -- DA INTERFACE.SAP_CENTRO_RESULTADO
      --
      V_SQL := ' SELECT COD_CENTRO_RESULTADO ';
      V_SQL := V_SQL || ' FROM   INTERFACE.SAP_CENTRO_RESULTADO';

      IF PI_COD_CAMPUS IS NULL
      THEN
        V_SQL := V_SQL || ' WHERE COD_CAMPUS            IS NULL';
      ELSE
        V_SQL := V_SQL || ' WHERE COD_CAMPUS            = ' || PI_COD_CAMPUS;
      END IF;

      IF PI_COD_TIPO_CURSO IS NULL
      THEN
        V_SQL := V_SQL || ' AND COD_TIPO_CURSO            IS NULL';
      ELSE
        V_SQL := V_SQL || ' AND COD_TIPO_CURSO            = ' || PI_COD_TIPO_CURSO;
      END IF;

      IF PI_COD_CURSO IS NULL
      THEN
        V_SQL := V_SQL || ' AND COD_CURSO              IS NULL';
        V_SQL := V_SQL || ' AND COD_CURSO_EXTENSAO     IS NULL';
      ELSE
        IF V_IND_REGULAR_EXTENSAO = 'R'
        THEN
          V_SQL := V_SQL || ' AND COD_CURSO              = ' || PI_COD_CURSO;
        ELSIF V_IND_REGULAR_EXTENSAO = 'E'
        THEN
          V_SQL := V_SQL || ' AND COD_CURSO_EXTENSAO     = ' || PI_COD_CURSO;
        END IF;
      END IF;

      IF PI_COD_TURNO IS NULL
      THEN
        V_SQL := V_SQL || ' AND COD_TURNO                 IS NULL';
      ELSE
        V_SQL := V_SQL || ' AND COD_TURNO                 = ' || PI_COD_TURNO;
      END IF;

      V_SQL := V_SQL || ' AND    COD_TIPO_ATUACAO          = :PI_COD_TIPO_ATUACAO';
      V_SQL := V_SQL || ' AND    COD_TIPO_CENTRO_RESULTADO = ''A''';
      V_SQL := V_SQL || ' AND    COD_INSTITUICAO = :PI_COD_INSTITUICAO';
      V_SQL := V_SQL || ' AND    ROWNUM=1';

      EXECUTE IMMEDIATE V_SQL
        INTO PO_COD_CENTRO_RESULTADO
        USING PI_COD_TIPO_ATUACAO, PI_COD_INSTITUICAO;
    END IF; -- IF  PI_COD_TIPO_CURSO NOT IS NULL...
    --
    RETURN PO_COD_CENTRO_RESULTADO;
    --
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END PRO_OBTEM_CENTRO_RESULTADO;
/
