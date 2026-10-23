# Trabalho Prático de PBD — PostgreSQL e Aplicação Web

**Valor: 7,0 pontos**

## 1. Objetivo

Desenvolver, em duplas, uma aplicação web integrada a um banco de dados PostgreSQL, explorando recursos de programação no banco de dados por meio da implementação de *triggers*, *stored procedures* e *functions*.

O trabalho deverá demonstrar a capacidade de modelar uma base de dados, implementar regras de negócio no próprio banco de dados e integrar essas funcionalidades a uma aplicação web funcional.

## 2. Tema do projeto

O tema é livre, desde que permita implementar regras de negócio relevantes e utilizar adequadamente os recursos exigidos.

Sugestões de temas incluem sistemas de biblioteca, vendas e estoque, agendamentos, eventos e inscrições, gerenciamento acadêmico, locação de equipamentos, delivery e gestão de projetos.

A escolha deverá considerar a possibilidade de implementar operações que justifiquem o uso dos recursos de programação exigidos.

## 3. Requisitos do banco de dados

O projeto deverá atender aos seguintes requisitos:

- Utilizar o PostgreSQL;
- Possuir, no mínimo, **5 tabelas relacionadas**;
- Definir adequadamente chaves primárias, chaves estrangeiras, restrições de integridade e demais *constraints* pertinentes;
- Implementar, no mínimo, **2 triggers, 2 stored procedures e 2 functions**;
- Utilizar PL/pgSQL na implementação das rotinas, quando aplicável;
- Implementar regras de negócio relevantes, evitando rotinas artificiais ou redundantes criadas apenas para cumprir os requisitos.

### 3.1. Triggers

As duas *triggers* deverão implementar regras de negócio ou mecanismos de integridade pertinentes ao sistema.

Exemplos: registrar alterações em uma tabela de auditoria, atualizar o estoque após uma venda ou impedir operações que violem regras específicas do domínio.

### 3.2. Stored procedures

As duas *stored procedures* deverão representar operações relevantes do sistema, podendo envolver múltiplas instruções SQL e regras de negócio.

Exemplos: finalizar uma venda, efetivar uma reserva, processar o cancelamento de um pedido ou executar uma operação que envolva a atualização consistente de várias tabelas.

### 3.3. Functions

As duas *functions* deverão implementar operações úteis para o sistema, retornando valores ou conjuntos de resultados apropriados à sua finalidade.

Exemplos: calcular o valor total de um pedido, consultar a disponibilidade de um recurso, calcular descontos ou produzir indicadores e estatísticas.

**Importante:** as seis rotinas deverão funcionar corretamente e ter finalidades justificáveis no contexto do sistema. A simples criação de objetos sem funcionalidade relevante não será suficiente.

## 4. Requisitos da aplicação web

A aplicação deverá utilizar a seguinte stack:

- **Flask:** implementação da aplicação web e de suas rotas;
- **Jinja:** construção dos templates;
- **psycopg2:** conexão e comunicação com o PostgreSQL;
- **HTML e CSS:** construção das interfaces.

O uso de JavaScript e de outras tecnologias de front-end é opcional.

A aplicação deverá possuir funcionalidades suficientes para demonstrar o funcionamento do sistema e a integração efetiva com o banco de dados. As rotinas implementadas deverão ser utilizadas pela aplicação ou demonstradas por meio de testes que permitam verificar seu funcionamento.

A complexidade visual da interface não é o foco principal da avaliação. Será priorizada a correção das regras de negócio e a utilização adequada dos recursos de programação do PostgreSQL.

## 5. Entrega

A entrega deverá ser realizada **uma única vez, por meio do SIGAA**, respeitando os grupos e as duplas definidos em aula.

A entrega deverá conter:

1. **Código-fonte completo da aplicação**, incluindo arquivos Python, templates, arquivos estáticos e demais componentes necessários.
2. **Script SQL completo**, com a criação das tabelas, restrições, *triggers*, *stored procedures*, *functions* e dados necessários para testar o sistema.
3. **README**, contendo a identificação dos integrantes, a descrição do sistema, as tecnologias utilizadas e as instruções para configurar e executar a aplicação.
4. **Documentação das seis rotinas**, explicando a finalidade de cada uma, a regra de negócio implementada e como seu funcionamento pode ser verificado.

Todos os arquivos necessários à execução e à avaliação deverão ser incluídos na entrega. A dupla deverá verificar previamente se os arquivos enviados estão corretos, completos e acessíveis.

**Importante:** antes de enviar o trabalho pelo SIGAA, removam a pasta do ambiente virtual Python (`.venv` ou `venv`), caso exista, para reduzir o tamanho do arquivo. O ambiente virtual deverá ser recriado a partir das dependências documentadas no `README`. Não incluam arquivos temporários, caches ou outros artefatos desnecessários à execução do projeto.

A responsabilidade pelo envio correto da atividade dentro do prazo é dos integrantes da dupla.

## 6. Apresentação e demonstração

As duplas deverão apresentar o sistema desenvolvido, demonstrando seu funcionamento e explicando as principais decisões de implementação.

A apresentação deverá contemplar:

- A finalidade do sistema e suas principais funcionalidades;
- A modelagem do banco de dados e os relacionamentos entre as tabelas;
- A explicação das duas *triggers*, das duas *stored procedures* e das duas *functions*;
- A demonstração prática da aplicação web em funcionamento;
- A demonstração das operações no banco de dados, evidenciando a execução das rotinas e os resultados produzidos;
- A explicação da integração entre Flask, Jinja, psycopg2 e PostgreSQL.

A apresentação deverá permitir que os professores participantes e o público acompanhem o funcionamento do sistema, formulem questionamentos e, quando pertinente, proponham testes ou situações de uso para verificar as funcionalidades e as regras de negócio implementadas.

Portanto, não basta apresentar slides, código-fonte ou capturas de tela: a dupla deverá estar preparada para **executar a aplicação, demonstrar suas funcionalidades e responder a questionamentos técnicos**.

Ambos os integrantes deverão conhecer o projeto e ser capazes de explicar as decisões tomadas, o funcionamento das rotinas e a integração entre a aplicação e o banco de dados.

## 7. Critérios de avaliação

O trabalho valerá **7,0 pontos**, distribuídos da seguinte forma:

| Critério                                                                              | Pontuação |
| ------------------------------------------------------------------------------------- | --------- |
| Modelagem do banco de dados, relacionamentos e integridade                            | 1,0       |
| Implementação e funcionamento das duas *triggers*                                     | 1,0       |
| Implementação e funcionamento das duas *stored procedures*                            | 1,0       |
| Implementação e funcionamento das duas *functions*                                    | 1,0       |
| Aplicação web e integração efetiva com PostgreSQL, utilizando Flask, Jinja e psycopg2 | 1,0       |
| Apresentação, demonstração prática, testes e respostas aos questionamentos            | 1,5       |
| Organização, documentação e qualidade da entrega                                      | 0,5       |
| **Total**                                                                             | **7,0**   |

A avaliação considerará a correção, a relevância e o funcionamento das soluções desenvolvidas, e não apenas a presença formal dos elementos exigidos.

## 8. Considerações finais

O trabalho deverá ser desenvolvido predominatemente pelos grupos (duplas) definidos em aula, respeitando a organização estabelecida para a atividade (SIGAA).

Recomenda-se que as duplas planejem o desenvolvimento considerando, desde o início, a modelagem do banco de dados, as regras de negócio, as rotinas em PL/pgSQL e a integração com a aplicação web.

A aplicação deverá estar preparada para execução e demonstração durante a apresentação. Os integrantes deverão conhecer o projeto como um todo, inclusive as rotinas implementadas pelo colega.

O objetivo central é demonstrar o uso adequado dos recursos de programação do PostgreSQL em uma aplicação real, coerente e funcional.
