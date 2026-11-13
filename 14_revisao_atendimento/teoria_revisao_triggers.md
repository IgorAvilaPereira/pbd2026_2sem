# **Material de Estudo – Triggers, Functions e Procedures no PostgreSQL**

**Disciplina: Programação e Manipulação de Banco de Dados (PMBD)**

Este material apresenta os principais conceitos relacionados à criação de funções, procedures e triggers no PostgreSQL, utilizando como referência os exemplos de um sistema de apostas esportivas.

O objetivo é compreender não apenas a sintaxe, mas principalmente **como funciona a execução dos comandos, quando utilizar cada recurso e como implementar regras de negócio diretamente no banco de dados.**

# **1. Funções que retornam TRIGGER**

Uma trigger é um mecanismo que permite executar automaticamente uma função quando determinado evento acontece em uma tabela.

No PostgreSQL, uma trigger não contém diretamente a lógica de programação. Ela é associada a uma função que implementa o comportamento desejado.

A estrutura básica é:

```
CREATE OR REPLACE FUNCTION nome_funcao()
RETURNS TRIGGER AS
$$
BEGIN
    -- Instruções executadas pela trigger

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

Depois, criamos a trigger:

```
CREATE TRIGGER nome_trigger
BEFORE INSERT OR UPDATE
ON nome_tabela
FOR EACH ROW
EXECUTE FUNCTION nome_funcao();
```

Observe que existem duas estruturas distintas:

- **FUNCTION:** contém a lógica que será executada.
- **TRIGGER:** determina quando e em qual tabela essa função será executada.

## **1.1. O que significa RETURNS TRIGGER?**

Quando uma função é criada com `RETURNS TRIGGER`, significa que ela será utilizada como função de trigger.

Esse tipo de função possui acesso a informações especiais sobre a operação que está acontecendo.

As principais são:

| Variável        | Significado                                                |
| --------------- | ---------------------------------------------------------- |
| `NEW`           | Novo registro que está sendo inserido ou atualizado.       |
| `OLD`           | Registro existente antes da alteração ou exclusão.         |
| `TG_OP`         | Operação que disparou a trigger: INSERT, UPDATE ou DELETE. |
| `TG_TABLE_NAME` | Nome da tabela que disparou a trigger.                     |
| `TG_WHEN`       | Momento da execução: BEFORE ou AFTER.                      |
| `TG_LEVEL`      | Nível da trigger: ROW ou STATEMENT.                        |

### **Exemplo prático**

Imagine uma tabela `jogo`:

```
CREATE TABLE jogo (
    id SERIAL PRIMARY KEY,
    equipe_casa_id INTEGER,
    equipe_visitante_id INTEGER,
    gols_da_casa INTEGER,
    gols_do_visitante INTEGER
);
```

Quando inserimos um jogo:

```
INSERT INTO jogo (
    equipe_casa_id,
    equipe_visitante_id
)
VALUES (1, 2);
```

A trigger pode acessar os valores que estão sendo inseridos através de `NEW`.

Por exemplo:

```
NEW.equipe_casa_id
NEW.equipe_visitante_id
```

Se estivermos atualizando um registro, podemos comparar os valores antigos e novos:

```
OLD.gols_da_casa
NEW.gols_da_casa
```

Isso permite implementar regras que dependem do estado anterior do registro.

# **2. BEFORE e AFTER: momento de execução**

Uma das decisões mais importantes na criação de triggers é determinar quando a função será executada.

## **2.1. BEFORE**

A trigger é executada antes de a operação ser efetivamente realizada na tabela.

É especialmente útil para:

- Validar informações.
- Impedir operações inválidas.
- Modificar valores antes da gravação.
- Aplicar regras de negócio.

Exemplo:

```
CREATE TRIGGER trigger_email
BEFORE INSERT OR UPDATE
ON usuario
FOR EACH ROW
EXECUTE FUNCTION email_para_minusculo();
```

Nesse caso, o banco executa a função antes de inserir ou atualizar o usuário.

Isso permite modificar os dados de `NEW` antes de sua gravação.

## **2.2. AFTER**

A trigger é executada depois que a operação na tabela foi realizada.

É especialmente útil para:

- Registrar logs.
- Manter histórico.
- Atualizar tabelas auxiliares.
- Registrar movimentações.

Exemplo:

```
CREATE TRIGGER trigger_log
AFTER INSERT OR UPDATE OR DELETE
ON aposta
FOR EACH ROW
EXECUTE FUNCTION registrar_log();
```

Nesse caso, a função será executada depois da operação na tabela `aposta`.

**Importante:** AFTER não significa que a transação já foi confirmada. Se ocorrer um erro posteriormente e a transação sofrer rollback, as alterações feitas pela trigger também serão desfeitas.

# **3. FOR EACH ROW e FOR EACH STATEMENT**

Outro conceito fundamental é determinar quantas vezes a trigger será executada.

## **3.1. FOR EACH ROW**

A função será executada uma vez para cada registro afetado.

Exemplo:

```
CREATE TRIGGER trigger_exemplo
BEFORE UPDATE
ON usuario
FOR EACH ROW
EXECUTE FUNCTION minha_funcao();
```

Imagine o seguinte comando:

```
UPDATE usuario
SET saldo = saldo + 10;
```

Se existirem 100 usuários, a trigger será executada 100 vezes.

Isso acontece porque cada usuário representa uma linha afetada.

Nesse contexto, podemos acessar `OLD` e `NEW`.

## **3.2. FOR EACH STATEMENT**

A função será executada uma única vez para cada comando SQL, independentemente da quantidade de registros afetados.

Exemplo:

```
CREATE TRIGGER trigger_exemplo
AFTER UPDATE
ON usuario
FOR EACH STATEMENT
EXECUTE FUNCTION minha_funcao();
```

Se o comando atualizar 100 usuários, a função será executada apenas uma vez.

Nesse tipo de trigger, não temos acesso individual aos registros através de `OLD` e `NEW`.

Podemos utilizar tabelas de transição (`REFERENCING OLD TABLE` e `NEW TABLE`) em triggers compatíveis, caso seja necessário consultar o conjunto de registros afetados.

## **Comparação**

| Característica | FOR EACH ROW           | FOR EACH STATEMENT         |
| -------------- | ---------------------- | -------------------------- |
| Execução       | Uma vez por registro   | Uma vez por comando        |
| NEW            | Sim, quando aplicável  | Não                        |
| OLD            | Sim, quando aplicável  | Não                        |
| Uso comum      | Validação de registros | Controle geral da operação |

**Exemplo para fixar**

Considere 50 registros atualizados por um único comando SQL:

# **50**

**FOR EACH ROW**

50 execuções

# **1**

**FOR EACH STATEMENT**

1 execução

# **4. NEW e OLD: trabalhando com os registros**

As variáveis `NEW` e `OLD` são fundamentais para implementar regras de negócio.

## **4.1. NEW**

Representa os dados novos que estão sendo inseridos ou atualizados.

Exemplo:

```
IF (NEW.gols_da_casa < 0) THEN
    RETURN NULL;
END IF;
```

Nesse caso, estamos verificando se o novo valor de gols da casa é negativo.

## **4.2. OLD**

Representa os dados existentes antes da operação.

Exemplo:

```
IF (NEW.gols_da_casa != OLD.gols_da_casa) THEN
    -- O resultado foi alterado
END IF;
```

Essa comparação é especialmente importante em operações de UPDATE.

## **4.3. Quando utilizar cada variável?**

| Operação | NEW            | OLD               |
| -------- | -------------- | ----------------- |
| INSERT   | Novo registro  | Não disponível    |
| UPDATE   | Novo registro  | Registro anterior |
| DELETE   | Não disponível | Registro excluído |

Uma forma de memorizar:

- INSERT: temos NEW.
- UPDATE: temos NEW e OLD.
- DELETE: temos OLD.

# **5. RETURN NEW, RETURN OLD e RETURN NULL**

O retorno da função de trigger determina o comportamento da operação, principalmente nas triggers BEFORE FOR EACH ROW.

Esse é um dos conceitos mais importantes do conteúdo.

## **5.1. RETURN NEW**

Permite que a operação continue utilizando o registro novo.

Exemplo:

```
IF (NEW.gols_da_casa >= 0) THEN
    RETURN NEW;
END IF;
```

Se a condição for verdadeira, o registro poderá ser inserido ou atualizado.

Também podemos modificar `NEW` antes de retorná-lo.

## **5.2. RETURN NULL**

Em uma trigger BEFORE FOR EACH ROW, impede que a operação seja realizada para aquele registro.

Exemplo:

```
IF (NEW.gols_da_casa < 0) THEN
    RETURN NULL;
END IF;

RETURN NEW;
```

Se o valor for negativo, o registro não será inserido ou atualizado.

**Atenção:** `RETURN NULL` não é a mesma coisa que inserir um valor NULL na tabela. Ele cancela a operação referente àquela linha.

## **5.3. RETURN OLD**

É utilizado principalmente em triggers AFTER DELETE ou BEFORE DELETE quando se deseja retornar o registro antigo.

Exemplo:

```
IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
END IF;
```

Em triggers AFTER, o valor retornado é ignorado pelo PostgreSQL. Portanto, nesse caso, o retorno serve apenas para atender à estrutura exigida da função.

### **Resumo**

| Retorno       | Comportamento em BEFORE ROW             |
| ------------- | --------------------------------------- |
| `RETURN NEW`  | Permite continuar a operação.           |
| `RETURN OLD`  | Utiliza o registro antigo como retorno. |
| `RETURN NULL` | Ignora a operação naquela linha.        |

# **6. Validando relacionamentos com EXISTS**

O comando `EXISTS` permite verificar se uma consulta retorna pelo menos um registro.

É muito utilizado em triggers para verificar se determinadas informações existem no banco de dados.

Observe a função:

```
CREATE OR REPLACE FUNCTION impede_jogo()
RETURNS TRIGGER AS
$$
BEGIN
    IF (
        EXISTS(
            SELECT *
            FROM equipe
            WHERE id = NEW.equipe_casa_id
        )
        AND
        EXISTS(
            SELECT *
            FROM equipe
            WHERE id = NEW.equipe_visitante_id
        )
    ) THEN

        IF (NEW.equipe_casa_id != NEW.equipe_visitante_id) THEN
            RETURN NEW;
        END IF;

    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

Essa função verifica três condições:

1. A equipe da casa existe?
2. A equipe visitante existe?
3. As duas equipes são diferentes?

Somente quando todas as condições forem verdadeiras o jogo poderá ser inserido ou atualizado.

A trigger associada:

```
CREATE TRIGGER trigger_impede_jogo
BEFORE INSERT OR UPDATE
ON jogo
FOR EACH ROW
EXECUTE FUNCTION impede_jogo();
```

Observe que a regra é aplicada tanto na inserção quanto na atualização.

**Conceito importante:** `EXISTS` não retorna os dados encontrados. Ele retorna um resultado lógico: verdadeiro ou falso.

# **7. IF, AND, OR e IS NULL nas validações**

As estruturas condicionais são utilizadas para implementar regras de negócio.

Considere a função:

```
CREATE OR REPLACE FUNCTION impede_gols_negativos()
RETURNS TRIGGER AS
$$
BEGIN
    IF (
        (NEW.gols_da_casa >= 0 AND NEW.gols_do_visitante >= 0)
        OR
        (NEW.gols_da_casa IS NULL AND NEW.gols_do_visitante IS NULL)
    ) THEN

        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

A função permite duas situações:

- Os dois resultados possuem valores maiores ou iguais a zero.
- Os dois resultados são NULL.

Nos demais casos, a operação é impedida.

## **7.1. Diferença entre AND e OR**

- `AND`: todas as condições precisam ser verdadeiras.
- `OR`: pelo menos uma condição precisa ser verdadeira.

Exemplo:

```
IF (NEW.valor > 0 AND NEW.valor < 100) THEN
```

O valor precisa ser maior que zero e menor que 100.

Já:

```
IF (NEW.valor < 0 OR NEW.valor > 100) THEN
```

O valor será inválido quando estiver fora do intervalo.

## **7.2. Cuidado com NULL**

Em SQL, NULL representa ausência de informação.

Portanto, não devemos verificar NULL utilizando:

```
NEW.valor = NULL
```

O correto é:

```
NEW.valor IS NULL
```

Da mesma forma:

```
NEW.valor IS NOT NULL
```

Verificar NULL é especialmente importante em validações de triggers.

**Observação sobre o exemplo:** a função `impede_gols_negativos()` permite somente os dois campos simultaneamente nulos ou os dois não nulos e positivos. Se a intenção fosse permitir cada campo independentemente como NULL, a condição deveria ser:

```
IF (
    (NEW.gols_da_casa >= 0 OR NEW.gols_da_casa IS NULL)
    AND
    (NEW.gols_do_visitante >= 0 OR NEW.gols_do_visitante IS NULL)
) THEN
    RETURN NEW;
END IF;
```

# **8. Modificando os dados através de NEW**

Uma trigger BEFORE também pode modificar os dados antes que sejam gravados.

Observe:

```
CREATE OR REPLACE FUNCTION email_para_minusculo()
RETURNS TRIGGER AS
$$
BEGIN
    IF (NEW.email IS NOT NULL) THEN
        NEW.email = LOWER(NEW.email);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

A função utiliza `LOWER()` para converter o endereço de e-mail em letras minúsculas.

Imagine a seguinte inserção:

```
INSERT INTO usuario (email)
VALUES ('IGOR@EXEMPLO.COM');
```

O valor armazenado será:

```
igor@exemplo.com
```

Isso acontece porque a trigger modifica `NEW.email` antes da gravação.

**Atenção:** nesse exemplo, não estamos impedindo a inserção. Estamos corrigindo o dado automaticamente.

Essa é uma diferença importante:

- `RETURN NULL`: impede a operação.
- Modificar `NEW` e retornar `NEW`: permite a operação com os dados modificados.

# **9. OLD e NEW: impedindo alterações em jogos encerrados**

Observe a função:

```
CREATE OR REPLACE FUNCTION impedir_alterar_jogo_encerrado()
RETURNS TRIGGER AS
$$
BEGIN
    IF (NEW.data_hora_fim IS NOT NULL) THEN

        IF (
            NEW.gols_da_casa != OLD.gols_da_casa
            OR
            NEW.gols_do_visitante != OLD.gols_do_visitante
        ) THEN
            RETURN NULL;
        END IF;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

A regra de negócio é impedir que o resultado de um jogo encerrado seja alterado.

Para isso, a função verifica:

1. O jogo está encerrado?
2. O resultado novo é diferente do resultado anterior?

Se as duas condições forem satisfeitas, o UPDATE será impedido.

Observe a comparação:

```
NEW.gols_da_casa != OLD.gols_da_casa
```

Estamos comparando o resultado novo com o antigo.

**Ponto de atenção:** essa implementação não impede que um jogo seja marcado como encerrado com uma alteração de resultado no mesmo UPDATE. Também pode apresentar problemas se os gols forem NULL, pois comparações com NULL resultam em UNKNOWN. Uma implementação mais robusta deve considerar esses casos.

# **10. RAISE NOTICE e RAISE EXCEPTION**

O PostgreSQL permite gerar mensagens durante a execução de funções e triggers.

Existem diferentes níveis de mensagens.

## **10.1. RAISE NOTICE**

Exibe uma mensagem informativa.

Exemplo:

```
RAISE NOTICE 'Aposta registrada com sucesso!';
```

Também podemos inserir valores na mensagem:

```
RAISE NOTICE 'Operação realizada: %', TG_OP;
```

O símbolo `%` é substituído pelo valor informado depois da mensagem.

Exemplo:

```
RAISE NOTICE 'Valor recebido: %', NEW.valor;
```

O NOTICE não impede a execução do comando.

## **10.2. RAISE EXCEPTION**

Gera um erro e interrompe a operação.

Exemplo:

```
IF (NEW.valor <= 0) THEN
    RAISE EXCEPTION 'O valor da aposta deve ser positivo!';
END IF;
```

Nesse caso, o banco gera um erro e a operação não é concluída.

### **Comparação**

| Comando         | Finalidade           | Interrompe a operação? |
| --------------- | -------------------- | ---------------------- |
| RAISE NOTICE    | Mensagem informativa | Não                    |
| RAISE WARNING   | Aviso                | Não                    |
| RAISE EXCEPTION | Erro                 | Sim                    |

## **Qual utilizar?**

Quando queremos apenas informar algo, utilizamos `RAISE NOTICE`.

Quando queremos garantir que uma operação inválida não seja executada, `RAISE EXCEPTION` costuma ser a alternativa mais adequada.

Uma diferença importante em relação a `RETURN NULL`: ambos podem impedir uma operação em uma trigger BEFORE ROW, mas `RAISE EXCEPTION` também informa explicitamente o motivo da rejeição e aborta a transação em andamento.

# **11. TG_OP: identificando a operação executada**

A variável especial `TG_OP` informa qual operação disparou a trigger.

Os valores possíveis incluem:

- INSERT
- UPDATE
- DELETE
- TRUNCATE (em triggers de nível de comando).

Observe:

```
CREATE OR REPLACE FUNCTION registrar_log()
RETURNS TRIGGER AS
$$
BEGIN

    INSERT INTO log (comentario)
    VALUES (TG_TABLE_NAME || ':' || TG_OP);

    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        RETURN NEW;
    END IF;

    RETURN OLD;

END;
$$ LANGUAGE plpgsql;
```

A função registra o nome da tabela e o tipo da operação.

O operador `||` realiza a concatenação de strings.

Se a operação for:

```
INSERT INTO aposta (...)
VALUES (...);
```

O log poderá armazenar:

```
aposta:INSERT
```

Se for:

```
DELETE FROM aposta WHERE id = 10;
```

O log poderá armazenar:

```
aposta:DELETE
```

A trigger:

```
CREATE TRIGGER trigger_realizar_log_aposta
AFTER INSERT OR UPDATE OR DELETE
ON aposta
FOR EACH ROW
EXECUTE FUNCTION registrar_log();
```

É executada após cada inserção, atualização ou exclusão.

**Conceito importante:** em triggers AFTER, o retorno NEW ou OLD é ignorado. O registro de log é realizado porque a função executa explicitamente um INSERT na tabela `log`.

# **12. Triggers que executam operações em outras tabelas**

Uma trigger pode executar comandos SQL em outras tabelas.

Isso permite implementar regras de negócio que envolvem múltiplas entidades.

Considere o seguinte exemplo:

```
CREATE OR REPLACE FUNCTION validar_saldo_aposta()
RETURNS TRIGGER AS
$$
DECLARE
    var_saldo money := 0;
BEGIN

    SELECT saldo
    FROM usuario
    WHERE id = NEW.usuario_id
    INTO var_saldo;

    IF (NEW.valor::numeric > var_saldo::numeric) THEN
        RAISE EXCEPTION 'Saldo insuficiente!';
    END IF;

    UPDATE usuario
    SET saldo = CAST(
        (saldo::numeric - NEW.valor::numeric)
        AS money
    )
    WHERE id = NEW.usuario_id;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;
```

Essa função implementa uma regra de negócio:

**Um usuário só pode realizar uma aposta se possuir saldo suficiente.**

O funcionamento é:

1. Recupera o saldo do usuário.
2. Compara o saldo com o valor da aposta.
3. Se não houver saldo suficiente, gera uma exceção.
4. Caso contrário, desconta o valor da aposta.
5. Permite a inserção do registro.

A trigger:

```
CREATE TRIGGER trg_validar_saldo_aposta
BEFORE INSERT OR UPDATE
ON aposta
FOR EACH ROW
EXECUTE FUNCTION validar_saldo_aposta();
```

Observe que a função atualiza a tabela `usuario`, embora a trigger esteja associada à tabela `aposta`.

Isso é perfeitamente possível.

## **12.1. Atenção: INSERT e UPDATE são diferentes**

O exemplo anterior apresenta um problema importante.

Imagine que um usuário tenha R$ 100,00 e realize uma aposta de R$ 20,00.

Após a inserção, terá R$ 80,00.

Agora imagine que o registro da aposta seja atualizado, alterando apenas os gols previstos.

A trigger será executada novamente e poderá descontar mais R$ 20,00.

Isso acontece porque a função não diferencia INSERT de UPDATE.

Uma implementação correta precisa considerar a operação:

```
IF (TG_OP = 'INSERT') THEN
    -- Descontar o valor integral.

ELSIF (TG_OP = 'UPDATE') THEN
    -- Considerar a diferença entre o valor novo e o antigo.
END IF;
```

Também é necessário considerar o caso em que o usuário ou o valor da aposta seja alterado.

**Atenção adicional:** para sistemas com operações concorrentes, a leitura e o desconto do saldo precisam ser protegidos adequadamente, por exemplo, com bloqueio da linha do usuário (`SELECT ... FOR UPDATE`) ou uma atualização condicional e atômica.

# **13. Funções que recebem parâmetros e retornam valores**

Até agora, estudamos funções utilizadas por triggers.

Entretanto, funções também podem ser criadas para receber parâmetros e retornar valores.

Observe:

```
CREATE OR REPLACE FUNCTION realizar_aposta(
    var_usuario_id integer,
    var_jogo_id integer,
    var_valor money,
    var_gols_casa integer,
    var_gols_visitante integer
)
RETURNS BOOLEAN AS
$$
BEGIN

    IF (
        EXISTS(
            SELECT *
            FROM jogo
            WHERE id = var_jogo_id
        )
        AND
        EXISTS(
            SELECT *
            FROM usuario
            WHERE id = var_usuario_id
            AND saldo::numeric >= var_valor::numeric
        )
    ) THEN

        INSERT INTO aposta (
            usuario_id,
            valor,
            jogo_id,
            gols_da_casa,
            gols_do_visitante,
            odd
        )
        VALUES (
            var_usuario_id,
            var_valor,
            var_jogo_id,
            var_gols_casa,
            var_gols_visitante,
            CAST(RANDOM() AS NUMERIC(3,2))
        );

        UPDATE usuario
        SET saldo = CAST(
            (saldo::numeric - var_valor::numeric)
            AS money
        )
        WHERE id = var_usuario_id;

        RETURN TRUE;

    END IF;

    RETURN FALSE;

END;
$$ LANGUAGE plpgsql;
```

Essa função recebe cinco parâmetros e retorna um BOOLEAN.

O retorno poderá ser:

- TRUE: aposta realizada.
- FALSE: aposta não realizada.

Podemos chamar a função utilizando:

```
SELECT realizar_aposta(
    1,
    10,
    20.00::money,
    2,
    1
);
```

Observe que funções podem executar comandos de INSERT, UPDATE e DELETE.

Entretanto, funções não são chamadas com `CALL`, e sim através de expressões SQL, como `SELECT`.

## **13.1. Cuidado com a duplicidade de regras**

No exemplo, a função `realizar_aposta()` desconta o saldo diretamente.

Se também existir uma trigger que desconta o saldo durante o INSERT na tabela `aposta`, o valor poderá ser descontado duas vezes.

Esse é um problema comum quando combinamos funções e triggers.

É importante definir claramente onde cada regra será implementada.

# **14. Procedures: procedimentos armazenados**

Uma procedure é um procedimento armazenado no banco de dados.

Assim como uma função, pode receber parâmetros e executar comandos SQL.

A principal diferença está na forma de chamada e nas possibilidades de controle transacional.

Estrutura básica:

```
CREATE OR REPLACE PROCEDURE nome_procedure(
    parametro tipo
)
AS
$$
BEGIN

    -- Instruções SQL

END;
$$ LANGUAGE plpgsql;
```

Para executar uma procedure, utilizamos:

```
CALL nome_procedure();
```

## **14.1. Exemplo: cancelar uma aposta**

```
CREATE OR REPLACE PROCEDURE cancelar_aposta(
    var_id integer
)
AS
$$
DECLARE
    var_valor money;
    var_usuario integer;
BEGIN

    SELECT valor, usuario_id
    FROM aposta
    WHERE id = var_id
    INTO var_valor, var_usuario;

    UPDATE usuario
    SET saldo = saldo + var_valor
    WHERE id = var_usuario;

    DELETE FROM aposta
    WHERE id = var_id;

END;
$$ LANGUAGE plpgsql;
```

Essa procedure realiza três operações:

1. Recupera o valor da aposta.
2. Recupera o usuário responsável.
3. Devolve o dinheiro ao usuário.
4. Exclui o registro da aposta.

Para executar:

```
CALL cancelar_aposta(10);
```

### **Atenção: interação com triggers**

Existe uma particularidade importante nesse exemplo.

Se a tabela `aposta` possuir uma trigger AFTER DELETE que devolve o saldo automaticamente, a procedure também devolverá o valor diretamente.

Consequentemente, o usuário receberá o dinheiro duas vezes.

Por isso, é importante conhecer todas as triggers associadas às tabelas que uma procedure modifica.

# **15. Procedures com operações em vários registros**

Uma procedure também pode executar operações que afetam vários registros simultaneamente.

Observe:

```
CREATE OR REPLACE PROCEDURE bonus_todos(
    var_valor money
)
AS
$$
BEGIN

    UPDATE usuario
    SET saldo = saldo + var_valor;

END;
$$ LANGUAGE plpgsql;
```

Essa procedure adiciona um bônus ao saldo de todos os usuários.

Para executar:

```
CALL bonus_todos(50.00::money);
```

Se existirem 100 usuários, todos receberão R$ 50,00.

Observe que a operação utiliza um único UPDATE.

Caso exista uma trigger `FOR EACH ROW` associada à tabela `usuario`, ela será executada individualmente para cada usuário.

# **16. TG_TABLE_NAME e registros de log**

Além de identificar a operação, podemos identificar a tabela que disparou a trigger.

Observe:

```
TG_TABLE_NAME
```

Essa variável retorna o nome da tabela.

Podemos combinar as variáveis:

```
RAISE NOTICE 'Tabela: %, Operação: %',
    TG_TABLE_NAME,
    TG_OP;
```

Isso é útil quando queremos criar funções genéricas, que podem ser utilizadas em diferentes tabelas.

Por exemplo, uma única função pode registrar operações em várias tabelas, sem precisar criar uma função diferente para cada uma.

# **17. Regras de negócio envolvendo datas**

Observe a função:

```
CREATE OR REPLACE FUNCTION impedir_datas()
RETURNS TRIGGER AS
$$
BEGIN

    IF (NEW.data_hora >= CURRENT_TIMESTAMP) THEN
        RETURN NEW;
    END IF;

    RETURN NULL;

END;
$$ LANGUAGE plpgsql;
```

Essa função impede a inserção ou atualização de jogos com datas anteriores ao momento atual.

O comando:

```
CURRENT_TIMESTAMP
```

Retorna a data e hora atuais da transação.

Exemplo:

Se o horário atual for 13/11/2026 às 14h:

| Data do jogo      | Resultado |
| ----------------- | --------- |
| 14/11/2026        | Permitido |
| 13/11/2026 às 15h | Permitido |
| 13/11/2026 às 13h | Impedido  |

Observe que a regra depende do horário, não apenas da data.

**Atenção:** essa implementação impede atualizações de jogos antigos mesmo quando a alteração não modifica a data. É importante avaliar se essa é realmente a regra desejada.

# **18. Cancelamento de apostas e NEW/OLD**

Observe a seguinte regra de negócio:

- Jogo ainda não começou: devolve 100% do valor da aposta.
- Jogo começou, mas não terminou: devolve 80%.
- Jogo terminou: não devolve nada.

A implementação:

```
CREATE OR REPLACE FUNCTION trigger_cancela_aposta()
RETURNS TRIGGER AS
$$
BEGIN

    IF (
        EXISTS(
            SELECT *
            FROM jogo
            WHERE id = OLD.jogo_id
            AND data_hora <= CURRENT_TIMESTAMP
            AND data_hora_fim IS NULL
        )
    ) THEN

        UPDATE usuario
        SET saldo = CAST(
            (saldo::numeric + OLD.valor::numeric * 0.8)
            AS money
        )
        WHERE id = OLD.usuario_id;

    ELSIF (
        EXISTS(
            SELECT *
            FROM jogo
            WHERE id = OLD.jogo_id
            AND data_hora >= CURRENT_TIMESTAMP
        )
    ) THEN

        UPDATE usuario
        SET saldo = CAST(
            (saldo::numeric + OLD.valor::numeric)
            AS money
        )
        WHERE id = OLD.usuario_id;

    END IF;

    RETURN OLD;

END;
$$ LANGUAGE plpgsql;
```

A trigger:

```
CREATE TRIGGER trg_cancela_aposta
AFTER DELETE
ON aposta
FOR EACH ROW
EXECUTE FUNCTION trigger_cancela_aposta();
```

## **Por que utilizamos OLD?**

Porque estamos trabalhando com DELETE.

Quando uma aposta é excluída, precisamos recuperar os dados que estavam armazenados nela:

```
OLD.usuario_id
OLD.jogo_id
OLD.valor
```

Essas informações são necessárias para identificar o usuário, o jogo e o valor que deverá ser devolvido.

**Observe:** essa trigger é AFTER DELETE. Portanto, ela executa a devolução após a exclusão do registro.

Um detalhe importante: se o jogo já terminou, a função não executa nenhuma devolução.

# **19. Validações de apostas: comparando diferentes implementações**

Nos exemplos apresentados, existem várias funções que validam apostas.

Vamos analisar as diferenças.

## **19.1. Validar o valor da aposta**

```
CREATE OR REPLACE FUNCTION validar_aposta()
RETURNS TRIGGER AS
$$
BEGIN

    IF (
        NEW.valor IS NULL
        OR NEW.valor::numeric <= 0
    ) THEN

        RAISE NOTICE 'Aposta inválida: %', TG_OP;
        RETURN NULL;

    END IF;

    RAISE NOTICE 'Aposta válida: %', TG_OP;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;
```

A função verifica se o valor da aposta foi informado e se é positivo.

O uso de `TG_OP` permite identificar se a operação foi um INSERT ou UPDATE.

Uma observação: embora a mensagem diga que a aposta foi negativa, a condição também rejeita valores iguais a zero e valores NULL.

## **19.2. Validar o saldo disponível**

```
IF (
    EXISTS(
        SELECT *
        FROM usuario
        WHERE id = NEW.usuario_id
        AND saldo::numeric >= NEW.valor::numeric
    )
) THEN

    RETURN NEW;

END IF;

RETURN NULL;
```

Essa implementação verifica se o usuário possui saldo suficiente.

Diferentemente da anterior, ela não desconta o valor da aposta. Apenas permite ou impede a operação.

## **19.3. Impedir apostas após o início do jogo**

```
IF (
    EXISTS(
        SELECT *
        FROM jogo
        WHERE id = NEW.jogo_id
        AND data_hora < CURRENT_TIMESTAMP
    )
) THEN

    RAISE EXCEPTION 'Apostas encerradas!';

END IF;

RETURN NEW;
```

Essa função verifica se o jogo já começou.

Se a data do jogo for anterior ao momento atual, a aposta será impedida.

**Observe:** essa implementação não verifica se o jogo existe nem se está encerrado. A existência deve ser garantida pela chave estrangeira ou por outra validação.

## **19.4. Impedir gols negativos**

```
IF (
    (NEW.gols_da_casa >= 0 OR NEW.gols_da_casa IS NULL)
    AND
    (NEW.gols_do_visitante >= 0 OR NEW.gols_do_visitante IS NULL)
) THEN

    RETURN NEW;

END IF;

RAISE EXCEPTION 'Os gols devem ser maiores ou iguais a zero!';
```

A função permite:

- Gols iguais a zero.
- Gols positivos.
- Valores NULL.

E impede:

\- Gols negativos.

Essa validação pode ser utilizada tanto na tabela `jogo` quanto na tabela `aposta`, desde que ambas possuam os campos correspondentes.

# **20. Boas práticas e problemas comuns**

Ao desenvolver triggers, functions e procedures, alguns cuidados são fundamentais.

## **20.1. Evite descontar ou devolver valores duas vezes**

Se uma função realiza um UPDATE no saldo e uma trigger também realiza esse UPDATE, o valor poderá ser alterado duas vezes.

Sempre verifique as regras já implementadas nas tabelas envolvidas.

## **20.2. Cuidado com UPDATE**

Uma trigger criada para:

```
BEFORE INSERT OR UPDATE
```

será executada nas duas operações.

Uma validação que funciona corretamente no INSERT pode causar problemas no UPDATE.

Por exemplo, descontar novamente o saldo quando o usuário altera somente o placar de uma aposta.

## **20.3. Prefira RAISE EXCEPTION para validações importantes**

`RETURN NULL` impede a operação, mas não apresenta necessariamente uma mensagem de erro explicativa.

Para regras de negócio importantes, utilizar:

```
RAISE EXCEPTION 'Saldo insuficiente!';
```

pode tornar o comportamento mais claro.

## **20.4. Não confunda funções e procedures**

| Característica               | Function                            | Procedure                                          |
| ---------------------------- | ----------------------------------- | -------------------------------------------------- |
| Criação                      | CREATE FUNCTION                     | CREATE PROCEDURE                                   |
| Chamada                      | SELECT                              | CALL                                               |
| Retorno                      | Obrigatório definir tipo de retorno | Não utiliza RETURNS                                |
| Parâmetros                   | Sim                                 | Sim                                                |
| Executa INSERT/UPDATE/DELETE | Sim                                 | Sim                                                |
| Controle transacional        | Limitado pelas regras de funções    | Pode controlar transações em condições específicas |

## **20.5. Atenção ao tipo MONEY**

Nos exemplos, o saldo e o valor das apostas utilizam o tipo `MONEY`.

Para realizar cálculos, foram utilizadas conversões:

```
saldo::numeric
```

E posteriormente:

```
CAST(valor AS money)
```

Isso permite realizar operações aritméticas utilizando NUMERIC.

Em aplicações financeiras, normalmente é preferível utilizar `NUMERIC(10,2)`, pois permite maior controle sobre a precisão e a representação dos valores monetários.

## **20.6. Não dependa apenas de triggers para garantir integridade**

Regras simples de integridade podem ser implementadas diretamente na estrutura das tabelas:

```
CHECK (valor > 0)
```

```
NOT NULL
```

```
FOREIGN KEY (usuario_id)
REFERENCES usuario(id)
```

As triggers são especialmente úteis quando a regra exige lógica procedural, comparação com valores antigos, atualização de outras tabelas ou registro de eventos.

# **21. Fluxo mental para resolver exercícios de triggers**

Ao receber um exercício, procure responder às seguintes perguntas:

## **Como construir uma trigger?**

1. **Qual tabela será monitorada?**

   Exemplo: usuario, aposta ou jogo.
2. **Qual operação dispara a trigger?**

   INSERT, UPDATE, DELETE ou uma combinação.
3. **Quando a função deve executar?**

   BEFORE ou AFTER.
4. **A execução é por linha ou comando?**

   FOR EACH ROW ou FOR EACH STATEMENT.
5. **Quais informações precisam ser consultadas?**

   NEW, OLD, TG_OP, EXISTS ou consultas SELECT.
6. **Qual é a regra de negócio?**

   Validar, impedir, modificar ou registrar.
7. **Qual será o retorno?**

   RETURN NEW, RETURN OLD ou RETURN NULL.

# **22. Resumo geral para revisão**

| Conceito               | Para que serve                                        |
| ---------------------- | ----------------------------------------------------- |
| `RETURNS TRIGGER`      | Define uma função que será utilizada por uma trigger. |
| `BEFORE`               | Executa antes da operação na tabela.                  |
| `AFTER`                | Executa depois da operação na tabela.                 |
| `FOR EACH ROW`         | Executa para cada registro afetado.                   |
| `FOR EACH STATEMENT`   | Executa uma vez por comando.                          |
| `NEW`                  | Acessa os dados novos.                                |
| `OLD`                  | Acessa os dados anteriores ou excluídos.              |
| `TG_OP`                | Identifica a operação executada.                      |
| `TG_TABLE_NAME`        | Identifica a tabela que disparou a trigger.           |
| `RETURN NEW`           | Permite continuar a operação com os dados novos.      |
| `RETURN OLD`           | Retorna os dados antigos.                             |
| `RETURN NULL`          | Cancela a operação daquela linha em BEFORE ROW.       |
| `EXISTS`               | Verifica se uma consulta retorna registros.           |
| `RAISE NOTICE`         | Exibe uma mensagem informativa.                       |
| `RAISE EXCEPTION`      | Gera um erro e interrompe a operação.                 |
| `LOWER()`              | Converte texto para letras minúsculas.                |
| `CURRENT_TIMESTAMP`    | Obtém o horário atual da transação.                   |
| `CREATE FUNCTION`      | Cria uma função.                                      |
| `CREATE PROCEDURE`     | Cria um procedimento armazenado.                      |
| `CALL`                 | Executa uma procedure.                                |
| `SELECT nome_funcao()` | Executa uma função.                                   |

# **23. Exemplos para memorizar**

**1. Impedir uma inserção quando o valor for negativo:**

```
IF (NEW.valor < 0) THEN
    RETURN NULL;
END IF;

RETURN NEW;
```

**2. Impedir uma operação apresentando uma mensagem de erro:**

```
IF (NEW.saldo < 0) THEN
    RAISE EXCEPTION 'Saldo negativo!';
END IF;

RETURN NEW;
```

**3. Converter um texto para letras minúsculas:**

```
NEW.email = LOWER(NEW.email);
RETURN NEW;
```

**4. Comparar o valor novo com o antigo:**

```
IF (NEW.valor != OLD.valor) THEN
    -- O valor foi alterado.
END IF;
```

**5. Verificar se um registro existe:**

```
IF (EXISTS(SELECT * FROM usuario WHERE id = NEW.usuario_id)) THEN
    RETURN NEW;
END IF;

RETURN NULL;
```

**6. Identificar a operação executada:**

```
IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
END IF;

RETURN NEW;
```

**7. Registrar uma operação:**

```
INSERT INTO log (comentario)
VALUES (TG_TABLE_NAME || ':' || TG_OP);
```

**8. Executar uma procedure:**

```
CALL bonus_todos(50.00::money);
```

## **24. O que você precisa dominar para a avaliação?**

Priorize estes conhecimentos:

1. Criar funções com `RETURNS TRIGGER`.
2. Criar triggers com `BEFORE` e `AFTER`.
3. Diferenciar `FOR EACH ROW` e `FOR EACH STATEMENT`.
4. Utilizar corretamente `NEW` e `OLD`.
5. Entender quando retornar `NEW`, `OLD` ou `NULL`.
6. Implementar validações utilizando `IF`, `AND`, `OR` e `EXISTS`.
7. Utilizar `RAISE NOTICE` e `RAISE EXCEPTION`.
8. Identificar operações utilizando `TG_OP`.
9. Modificar registros de outras tabelas dentro de uma trigger.
10. Criar procedures que executam múltiplos comandos SQL.
11. Compreender a interação entre funções, procedures e triggers.
12. Identificar problemas de execução duplicada de regras de negócio.

**Principal orientação:** mais importante do que decorar a sintaxe é entender o fluxo de execução. Em exercícios de programação com triggers, procure identificar qual operação aconteceu, quais dados estão disponíveis, qual regra precisa ser aplicada e o que deve acontecer com a operação original.
