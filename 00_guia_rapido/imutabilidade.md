# Guia Completo de Programação Procedural no PostgreSQL: Stored Procedures e Functions com PL/pgSQL

Este documento reúne de forma estruturada os conceitos, matrizes comparativas, sintaxes oficiais e exemplos avançados de programação procedural utilizando o motor **PL/pgSQL** no **PostgreSQL**.

---

## 1. Conceitos Fundamentais e Arquitetura Básica

Em bancos de dados relacionais, blocos de código reaproveitáveis salvos diretamente no servidor trazem eficiência de rede, centralização de regras de negócio e ganho de performance. O termo "**Procedure**" é a abreviação direta de *Stored Procedure* (Procedimento Armazenado). No PostgreSQL, esses blocos são implementados por padrão via **PL/pgSQL** (Procedural Language/PostgreSQL).

### Anatomia de um Bloco PL/pgSQL
Tanto funções quanto procedimentos compartilham a mesma estrutura delimitada por **Dollar Quoting** (`$$`), recurso que substitui as aspas simples tradicionais e evita a necessidade de escapar strings textuais complexas.

```sql
CREATE [OR REPLACE] [FUNCTION|PROCEDURE] nome_do_objeto(parametros)
[retornos_se_houver] AS $$
DECLARE
    -- Área opcional de declaração de variáveis e tipos
    minha_variavel INT := 10;
BEGIN
    -- Bloco de execução principal (obrigatório)
    -- Lógicas, loops e queries SQL aqui
    
EXCEPTION
    -- Bloco opcional de captura e tratamento de erros
    WHEN OTHERS THEN
        -- Ação caso ocorra uma falha
END;
$$ LANGUAGE plpgsql;
```

---

## 2. Matriz Comparativa Técnica

Abaixo está o mapeamento detalhado das diferenças funcionais e comportamentais entre uma **Function** e uma **Procedure**:

| Característica | **Stored Function** (Função) | **Stored Procedure** (Procedimento) |
| :--- | :--- | :--- |
| **Retorno de Valor** | **Obrigatório**. Sempre retorna exatamente um único valor (escalar) ou uma estrutura de dados (`TABLE`, `SETOF`). | **Não possui retorno formal** no cabeçalho. Pode cuspir dados externamente apenas usando parâmetros `OUT` ou `INOUT`. |
| **Manipulação de Dados (CRUD)** | Permite `INSERT`, `UPDATE` e `DELETE`, mas é conceitualmente restrita a cálculos e consultas. | **Totalmente projetada para escrita**, migrações, automações e manutenções de dados em lote. |
| **Como é invocada** | Incorporada em consultas através do comando **`SELECT`** (no `FROM`, `WHERE`, `JOIN`, etc). | Chamada exclusivamente de forma isolada usando o comando **`CALL`**. |
| **Controle de Transações** | **Não permite**. Roda estritamente no contexto da transação pai. Proíbe comandos `COMMIT` e `ROLLBACK`. | **Permite**. Pode abrir, commitar e reverter transações dinamicamente durante sua execução. |
| **Aninhamento** | Pode invocar outras Functions, mas nunca pode executar um comando `CALL` para uma Procedure. | Pode invocar tanto outras Procedures (`CALL`) quanto Functions (`SELECT`). |

---

## 3. Stored Functions (Funções)

As funções operam de forma isolada, processando argumentos e devolvendo obrigatoriamente um resultado. Elas são ideais para cálculos matemáticos, tratamento de texto e relatórios parametrizados.

### Exemplo 1: Função Escalar (Retorna um Único Valor)
Esta função recebe o salário bruto de um funcionário e calcula o imposto de renda devido baseado em faixas condicionais (`IF/ELSIF`).

```sql
CREATE OR REPLACE FUNCTION calcular_irrf(salario_bruto NUMERIC)
RETURNS NUMERIC AS $$
DECLARE
    imposto NUMERIC := 0.00;
BEGIN
    IF salario_bruto <= 2259.20 THEN
        imposto := 0.00;
    ELSIF salario_bruto <= 2828.65 THEN
        imposto := (salario_bruto * 0.075) - 169.44;
    ELSIF salario_bruto <= 3751.05 THEN
        imposto := (salario_bruto * 0.15) - 381.44;
    ELSE
        imposto := (salario_bruto * 0.225) - 662.77;
    END IF;

    -- Garante que o imposto não seja negativo
    IF imposto < 0 THEN 
        imposto := 0.00; 
    END IF;

    RETURN ROUND(imposto, 2);
END;
$$ LANGUAGE plpgsql;
```
*Invocação:*
```sql
SELECT calcular_irrf(3500.00) AS imposto_retido;
```

### Exemplo 2: Função Tabular (Retorna uma Tabela)
Frequentemente utilizada para encapsular queries complexas, agindo de forma semelhante a uma View Dinâmica estruturada.

```sql
CREATE OR REPLACE FUNCTION obter_produtos_por_categoria(categoria_alvo VARCHAR)
RETURNS TABLE (
    produto_id INT,
    produto_nome VARCHAR,
    preco_atual NUMERIC,
    estoque_disponivel INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT id, nome, preco, estoque
    FROM produtos
    WHERE categoria = categoria_alvo AND ativo = true
    ORDER BY nome ASC;
END;
$$ LANGUAGE plpgsql;
```
*Invocação:*
```sql
SELECT * FROM obter_produtos_por_categoria('Eletrônicos') WHERE preco_atual > 500.00;
```

---

## 4. Stored Procedures (Procedimentos)

Procedures são focadas em ações e automações que alteram estados no banco de dados. Sua principal vantagem é a capacidade de realizar commits parciais em laços de repetição (loops), evitando o travamento estendido de tabelas e minimizando estouros de memória.

### Exemplo 3: Processamento em Lotes com Controle de Transação
O procedimento abaixo itera sobre faturas pendentes, realiza o débito e salva a alteração no banco de dados individualmente por cliente.

```sql
CREATE OR REPLACE PROCEDURE processar_faturamento_diario()
AS $$
DECLARE
    registro_fatura RECORD;
BEGIN
    FOR registro_fatura IN 
        SELECT id, cliente_id, valor_devido FROM faturas WHERE status = 'PENDENTE'
    LOOP
        -- Tenta debitar da conta do cliente
        UPDATE contas_correntes 
        SET saldo = saldo - registro_fatura.valor_devido 
        WHERE cliente_id = registro_fatura.cliente_id AND saldo >= registro_fatura.valor_devido;
        
        IF FOUND THEN
            -- Atualiza o status da fatura
            UPDATE faturas SET status = 'PAGO', processado_em = NOW() WHERE id = registro_fatura.id;
            -- Commita a alteração deste registro imediatamente de forma isolada
            COMMIT;
        ELSE
            -- Registra log de falha por falta de saldo
            INSERT INTO logs_faturamento (fatura_id, erro) 
            VALUES (registro_fatura.id, 'Saldo insuficiente para processamento automático.');
            COMMIT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```
*Invocação:*
```sql
CALL processar_faturamento_diario();
```

---

## 5. Boas Práticas, Performance e Segurança Avançada

### I. Volatilidade de Funções (`IMMUTABLE`, `STABLE`, `VOLATILE`)
Informar explicitamente o nível de volatilidade de uma função permite ao otimizador de consultas decidir se pode cachear o resultado gerado.

*   **`IMMUTABLE`:** A função não lê dados externos e sempre retorna exatamente o mesmo valor para os mesmos argumentos recebidos.
*   **`STABLE`:** Não altera dados, mas faz consultas no banco. O resultado é cacheado e estabilizado durante a execução de uma mesma query.
*   **`VOLATILE` (Padrão):** O valor retornado pode mudar a qualquer instante (ex: logs, randomizações, datas atuais). Obriga o banco a reavaliar a função linha por linha.

#### Exemplo Prático de Volatilidade:
```sql
-- 1. IMMUTABLE: Puramente algorítmica
CREATE OR REPLACE FUNCTION remover_acentos(texto VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN translate(texto, 'áéíóúçÁÉÍÓÚÇ', 'aeioucaeiouc');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 2. STABLE: Consulta tabelas de apoio/parâmetros estáticos
CREATE OR REPLACE FUNCTION obter_percentual_aliquota(uf_destino CHAR(2))
RETURNS NUMERIC AS $$
DECLARE aliquota NUMERIC;
BEGIN
    SELECT percentual INTO aliquota FROM aliquotas_icms WHERE uf = uf_destino;
    RETURN COALESCE(aliquota, 18.00);
END;
$$ LANGUAGE plpgsql STABLE;

-- 3. VOLATILE: Gera hashes e códigos aleatórios a cada linha instanciada
CREATE OR REPLACE FUNCTION gerar_codigo_rastreio(pedido_id INT)
RETURNS VARCHAR AS $$
BEGIN
    RETURN 'BR-' || pedido_id || '-' || FLOOR(RANDOM() * 900000 + 100000)::INT;
END;
$$ LANGUAGE plpgsql VOLATILE;
```

### II. Otimização com a Variável Especial `FOUND`
A variável booleana interna `FOUND` monitora se o último comando executado afetou alguma linha. Ela elimina a necessidade de executar `SELECT COUNT(*)` manuais e ineficientes.

#### Exemplo Prático com `FOUND`:
```sql
CREATE OR REPLACE PROCEDURE gerenciar_limite_cliente(
    p_cliente_id INT, 
    p_novo_limite NUMERIC,
    p_nome_novo_cliente VARCHAR DEFAULT NULL
) AS $$
BEGIN
    -- Tenta atualizar o registro do cliente existente
    UPDATE clientes SET limite_credito = p_novo_limite WHERE id = p_cliente_id;

    -- Avalia se o UPDATE surtiu efeito prático
    IF NOT FOUND THEN
        IF p_nome_novo_cliente IS NULL THEN
            RAISE EXCEPTION 'Cliente não encontrado e nenhum nome foi fornecido.';
        END IF;

        -- Insere novo registro se o cliente não existia anteriormente
        INSERT INTO clientes (id, nome, limite_credito, criado_em)
        VALUES (p_cliente_id, p_nome_novo_cliente, p_novo_limite, NOW());
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### III. Controle de Acesso e Elevação de Privilégios Segura com `SECURITY DEFINER`
Por padrão (`SECURITY INVOKER`), rotinas rodam sob as credenciais de quem as executa. Utilizar `SECURITY DEFINER` permite que um usuário comum execute tarefas restritas temporariamente usando os privilégios do **criador** da função (geralmente o DBA).

#### Exemplo Prático com `SECURITY DEFINER`:
```sql
-- Criada pelo usuário admin/postgres para aplicar aumentos de dissídio
CREATE OR REPLACE PROCEDURE aplicar_dissidio_coletivo(percentual NUMERIC)
AS $$
BEGIN
    IF percentual > 15.00 THEN
        RAISE EXCEPTION 'Aumentos acima de 15%% precisam de aprovação da diretoria.';
    END IF;

    -- Altera tabela restrita que o usuário final não possui acesso direto de escrita
    UPDATE folha_pagamento SET salario_base = salario_base * (1 + (percentual / 100)) WHERE status_contrato = 'ATIVO';
    COMMIT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Concessão pontual apenas para o usuário do setor de RH executar o script de automação
GRANT EXECUTE ON PROCEDURE aplicar_dissidio_coletivo(NUMERIC) TO usuario_rh_comum;
```
