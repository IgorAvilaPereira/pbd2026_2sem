## Guia Avançado de Teoria e Otimização de Código: Subprogramas e Recursos em PL/pgSQL

## ⚙️ 1. Programação Procedural: Functions e Stored Procedures
Bancos de dados relacionais puros trabalham com a lógica de conjuntos (álgebra relacional). No entanto, certas regras de negócio exigem estruturas de controle de fluxo de linguagens de programação tradicionais (como loops FOR/WHILE e condicionais IF/ELSE). É aqui que entra o PL/pgSQL (Procedural Language / PostgreSQL Extended).

## O Ciclo de Execução e Compilação

Quando você executa um comando CREATE FUNCTION, o código contido dentro dos delimitadores textuais ($$) não é compilado imediatamente para código de máquina. Ele é apenas armazenado como texto na tabela do catálogo do sistema (pg_proc).

A compilação real e a geração do Plano de Execução ocorrem na primeira vez que a função é invocada (chamada) em uma sessão de usuário. O motor compila as expressões SQL internas e cria pontos de cache para reutilizar esses planos nas chamadas seguintes daquela mesma sessão, reduzindo o tempo de processamento.

## Diferenças Arquiteturais Cruciais entre Functions e Procedures

| Atributo | FUNCTION (Função) | PROCEDURE (Procedimento) |
|---|---|---|
| Forma de Invocação | SELECT funcao(); | CALL procedimento(); |
| Retorno de Dados | Obrigatório (Scalar, Setof ou Table) | Não possui retorno direto |
| Utilização em Expressões SQL | Pode ser usada em cláusulas WHERE/SELECT | Não pode ser usada em SQL |
| Gerenciamento de Transações | Não permite COMMIT/ROLLBACK internos | Permite COMMIT/ROLLBACK |


* Abordagem Transacional: Uma Function roda inteiramente sob o contexto transacional de quem a chamou. Se uma função executa 10 inserções e falha na 11ª, todo o bloco é revertido pela transação externa. Como ela não é dona da própria transação, comandos de controle como COMMIT são proibidos em seu interior.

* Abordagem de Processamento: Uma Procedure abre e gerencia seu próprio contexto transacional. Se você precisar rodar um processo em lote que modifica 1 milhão de linhas, você pode colocar um loop na Procedure que executa um COMMIT a cada 10.000 linhas processadas. Isso limpa o buffer de memória RAM e evita que os bloqueios de linha (Locks) saturem o banco de dados.

## Retorno de Consultas: RETURNS TABLE e RETURN QUERY

Ao criar funções que retornam conjuntos de dados estruturados (linhas e colunas), o PostgreSQL introduz uma otimização fundamental: o RETURN QUERY.
O RETURN QUERY executa a consulta declarada e envia o resultado diretamente para o canal de saída da função de forma assíncrona e em blocos, economizando memória RAM do servidor de banco de dados e acelerando o tempo de resposta do sistema.


## 🔀 2. Gerenciamento de Transações e Bloco de Exceções em Subprogramas

Para compreender o comportamento transacional no PostgreSQL, é fundamental analisar exemplos práticos de como Procedures lidam com commits em lote e como Functions gerenciam a reversão de estados por meio de blocos de tratamento de erro.

## A. Exemplo em PROCEDURE: Commit em Lote (Batch Processing)

Procedures podem abrir e fechar transações no meio da execução. O exemplo abaixo simula uma rotina de manutenção que zera saldos inativos e consolida a operação a cada linha processada, liberando os recursos do servidor imediatamente.

```sql
CREATE OR REPLACE PROCEDURE limpar_saldos_inativos() AS $$DECLARE
    reg_usuario RECORD;BEGIN
    FOR reg_usuario IN SELECT id, nome FROM usuario WHERE saldo > 0::money LOOP
        
        -- Atualiza o registro do usuario atual
        UPDATE usuario SET saldo = 0::money WHERE id = reg_usuario.id;
        RAISE NOTICE 'Saldo do usuario % zerado.', reg_usuario.nome;
        
        -- EXCLUSIVO DE PROCEDURE: Commita a alteracao de cada usuario individualmente.
        -- Isso impede o acumulo de travas (locks) na tabela inteira.
        COMMIT; 
        
    END LOOP;END;
$$ LANGUAGE plpgsql;
```

## B. Exemplo em FUNCTION: Controle Transacional Indireto (EXCEPTION)

Functions não podem executar o comando COMMIT ou ROLLBACK. Contudo, elas gerenciam transações indiretamente usando subtransações internas através do bloco EXCEPTION. Se um erro ocorre dentro do bloco BEGIN ... EXCEPTION, o PostgreSQL reverte automaticamente apenas as escritas daquele bloco específico, agindo como um Savepoint.

```sql
CREATE OR REPLACE FUNCTION simular_deposito_seguro(var_id integer, var_valor money) RETURNS BOOLEAN AS $$BEGIN
    -- Inicio do bloco com monitoramento de erro
    UPDATE usuario SET saldo = saldo + var_valor WHERE id = var_id;
    
    -- Força um erro se o valor for abusivo (apenas para teste de reversao)
    IF var_valor > 1000000::money THEN
        RAISE EXCEPTION 'Valor acima do limite permitido para transferencia direta.';
    END IF;
    
    RETURN TRUE;
EXCEPTION 
    WHEN OTHERS THEN
        -- O PostgreSQL desfaz o UPDATE anterior automaticamente antes de entrar aqui.
        -- O rollback do bloco interno e implicito.
        RAISE NOTICE 'Transacao abortada internamente. Erro interceptado.';
        RETURN FALSE;END;
$$ LANGUAGE plpgsql;
```

## 🛠️ 3. Diagnóstico de Problemas Ocultos e Otimizações das Funções do Script

Abaixo encontra-se a análise individualizada de cada rotina contida no script original do ecossistema ifbet, detalhando falhas latentes de lógica, segurança e performance.

## A. Função propor_aposta

## ❌ Problemas Identificados e Eventuais Falhas:

   1. Vulnerabilidade à Condição de Corrida (Race Condition): A função lê o saldo atual, avalia o IF e executa o UPDATE. Se o mesmo usuário submeter duas requisições simultâneas ultra-rápidas, ambas as execuções podem ler o saldo antigo positivo antes que qualquer UPDATE termine, gerando saldos negativos não autorizados.
   2. Falta de Tratamento para Jogos Inexistentes: Caso um ID inválido de jogo seja enviado, o sistema inserirá dados inválidos ou quebrará tardiamente por chave estrangeira.
   3. Geração Inadequada de ODDs e Gols: O uso de RANDOM() sem deslocamento gera ODDs com valor inferior a 1.0.

## 💡 Sugestão de Melhoria (Refatorada para PROCEDURE com Bloqueio de Linha Explicito e Validação Estrita):

```sql
CREATE OR REPLACE PROCEDURE registrar_aposta(
    var_usuario_id integer, 
    var_jogo_id integer, 
    var_valor money
) AS $$DECLARE
    param_saldo money;
    nome_equipe_casa text;
    nome_equipe_visitante text; 
    
    -- Ajuste para garantir ODD sempre superior a 1.0 (ex: de 1.05 ate 5.05)
    param_odd real := CAST(1.05 + (RANDOM() * 4.0) AS NUMERIC(3,2));
    
    gols_casa integer := CAST(RANDOM() * 10 AS NUMERIC(1,0));
    gols_visitante integer := CAST(RANDOM() * 10 AS NUMERIC(1,0));    BEGIN
    -- 1. Valida a existencia do jogo e unifica os SELECTs usando INNER JOIN
    SELECT 
        ec.nome, ev.nome 
    FROM jogo j
    INNER JOIN equipe ec ON j.equipe_casa_id = ec.id
    INNER JOIN equipe ev ON j.equipe_visitante_id = ev.id
    WHERE j.id = var_jogo_id 
    INTO nome_equipe_casa, nome_equipe_visitante;

    IF nome_equipe_casa IS NULL THEN
        RAISE EXCEPTION 'Erro: O jogo informado com ID % nao existe.', var_jogo_id;
    END IF;
            
    -- 2. BLOQUEIO DE LINHA (FOR UPDATE): Impede concorrencia simultanea no saldo do usuario
    SELECT saldo FROM usuario WHERE id = var_usuario_id FOR UPDATE INTO param_saldo;        
            
    IF param_saldo IS NULL THEN
        RAISE EXCEPTION 'Erro: Usuario com ID % nao encontrado.', var_usuario_id;
    END IF;

    -- 3. Verificacao financeira de saldo
    IF (var_valor::numeric <= param_saldo::numeric) THEN
        RAISE NOTICE '% (%) vs % (%): Aposta: %, ODD: %', 
            nome_equipe_casa, gols_casa, nome_equipe_visitante, gols_visitante, var_valor, param_odd;        
           
        INSERT INTO aposta (usuario_id, valor, jogo_id, gols_da_casa, gols_do_visitante, odd) 
        VALUES (var_usuario_id, var_valor, var_jogo_id, gols_casa, gols_visitante, param_odd);
    
        UPDATE usuario 
        SET saldo = (saldo::numeric - var_valor::numeric)::money 
        WHERE id = var_usuario_id;
        
        -- Confirma as alteracoes fisicamente liberando o lock do FOR UPDATE
        COMMIT;
    ELSE
        RAISE EXCEPTION 'Saldo insuficiente. Operacao abortada.';    
    END IF;    END;
$$ LANGUAGE plpgsql;
```

## B. Funções obter_saldo, quantidade_apostas e valor_total_apostado## ❌ Problemas Identificados e Eventuais Falhas:

* Abuso de blocos procedurais (Overhead de PL/pgSQL): Instanciar blocos procedurais para rodar agregações atômicas de uma linha força a alocação de contextos de memória desnecessários.
* A Falha Silenciosa do SUM() Nulo: Na rotina valor_total_apostado, se um usuário não tiver apostas, a função agregadora retorna NULL, quebrando cálculos matemáticos posteriores.

## 💡 Sugestão de Melhoria (Otimizadas para SQL Puro / Inline e Protegidas contra Nulos):

```sql
CREATE OR REPLACE FUNCTION obter_saldo(var_usuario_id integer) RETURNS money AS
$$
    SELECT COALESCE(saldo, 0::money) FROM usuario WHERE id = var_usuario_id;
$$ LANGUAGE sql;
CREATE OR REPLACE FUNCTION quantidade_apostas(var_usuario_id integer) RETURNS integer AS
$$
    SELECT COUNT(*)::integer FROM aposta WHERE usuario_id = var_usuario_id;
$$ LANGUAGE sql;
CREATE OR REPLACE FUNCTION valor_total_apostado(var_usuario_id integer) RETURNS money AS
$$
    -- COALESCE intercepta o retorno nulo e o substitui por zero com seguranca
    SELECT COALESCE(SUM(valor), 0::money) FROM aposta WHERE usuario_id = var_usuario_id;
$$ LANGUAGE sql;
```
## C. Funções de Tradução de IDs: nome_equipe e nome_jogo

## ❌ Problemas Identificados e Eventuais Falhas:

* A função nome_jogo executa de forma sequencial duas leituras completas independentes baseadas em cruzamentos (JOIN) para decodificar o ID da casa e do visitante separados, dobrando o custo de I/O.

## 💡 Sugestão de Melhoria (Junção de Varredura de Disco Única):

```sql
CREATE OR REPLACE FUNCTION nome_equipe(var_equipe_id integer) RETURNS text AS 
$$
    SELECT nome FROM equipe WHERE id = var_equipe_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION nome_jogo(var_jogo_id integer) RETURNS text AS
$$
    -- Resolvido com uma unica varredura estruturada usando dois aliases para a tabela equipe
    SELECT ec.nome || ' x ' || ev.nome
    FROM jogo j
    INNER JOIN equipe ec ON j.equipe_casa_id = ec.id
    INNER JOIN equipe ev ON j.equipe_visitante_id = ev.id
    WHERE j.id = var_jogo_id;
$$ LANGUAGE sql;
```

## D. Funções de Tabelas Complexas: liste_jogos e lucro_potencial

## ❌ Problemas Identificados e Eventuais Felhas:

   1. Erro Crítico de Tipagem de Operadores em lucro_potencial: A instrução tenta executar valor + (valor * odd). Como valor é money e odd é real, o PostgreSQL interrompe a execução com um erro fatal de tipagem (operator does not exist: money * real).
   2. Ambiguidade Estática em liste_jogos: O comando mistura a junção física na query externa com subqueries correlacionadas aninhadas no cabeçalho do SELECT.

## 💡 Sugestão de Melhoria (Unificação por Joins Otimizados):

```sql
CREATE OR REPLACE FUNCTION liste_jogos() RETURNS TABLE (var_data_hora timestamp, var_equipe_casa text, var_equipe_visitante text) AS
$$
    SELECT 
        j.data_hora, 
        ec.nome AS equipe_casa, 
        ev.nome AS equipe_visitante 
    FROM jogo j
    INNER JOIN equipe ec ON j.equipe_casa_id = ec.id
    INNER JOIN equipe ev ON j.equipe_visitante_id = ev.id;
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION lucro_potencial(aposta_id integer) RETURNS TABLE (var_valor money, var_odd real, var_lucro money) AS
$$
    SELECT 
        valor, 
        odd, 
        (valor + (valor::numeric * odd::numeric)::money) AS lucro 
    FROM aposta
    WHERE id = aposta_id;
$$ LANGUAGE sql;
```

## E. Função tempo_desde_jogo

## ❌ Problemas Identificados e Eventuais Falhas:

* A rotina força uma varredura dupla no bloco de disco usando a cláusula condicional de existência IF (EXISTS(SELECT...)) para depois disparar o mesmo comando SELECT AGE(...) logo abaixo.

## 💡 Sugestão de Melhoria (Otimização de Projeção Direta):

```sql
CREATE OR REPLACE FUNCTION tempo_desde_jogo(var_jogo_id integer) RETURNS INTERVAL AS
$$
    SELECT AGE(CURRENT_TIMESTAMP, data_hora) FROM jogo WHERE id = var_jogo_id;
$$ LANGUAGE sql;
```



