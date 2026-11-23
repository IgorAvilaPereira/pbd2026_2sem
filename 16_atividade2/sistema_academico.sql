-- Remover o banco de dados, caso já exista
DROP DATABASE IF EXISTS sistema_academico;

-- Criar banco de dados
CREATE DATABASE sistema_academico;

-- Conectar ao banco de dados
\c sistema_academico;

-- Tabela aluno
CREATE TABLE aluno (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

-- Tabela disciplina
CREATE TABLE disciplina (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL
);

-- Tabela matricula
CREATE TABLE matricula (
    id SERIAL PRIMARY KEY,
    aluno_id INTEGER REFERENCES aluno(id),
    disciplina_id INTEGER REFERENCES disciplina(id),
    nota NUMERIC(4,2),
    frequencia INTEGER,
    aprovado BOOLEAN DEFAULT FALSE
);

-- Tabela log_matricula
CREATE TABLE log_matricula (
    id SERIAL PRIMARY KEY,
    matricula_id INTEGER,
    operacao TEXT,
    data_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir dados na tabela aluno
-- Os IDs são gerados automaticamente pelo SERIAL.
INSERT INTO aluno (nome, ativo) VALUES
    ('Ana Silva', TRUE),
    ('Bruno Souza', TRUE),
    ('Carla Oliveira', TRUE),
    ('Diego Santos', FALSE),
    ('Eduarda Lima', TRUE);

-- Inserir dados na tabela disciplina
-- Os IDs são gerados automaticamente pelo SERIAL.
INSERT INTO disciplina (nome) VALUES
    ('Banco de Dados'),
    ('Programação'),
    ('Engenharia de Software'),
    ('Sistemas Operacionais');

-- Inserir dados na tabela matricula
-- aluno_id e disciplina_id referenciam os IDs gerados acima.
-- O ID da própria matrícula é gerado automaticamente.
INSERT INTO matricula
    (aluno_id, disciplina_id, nota, frequencia, aprovado)
VALUES
    (1, 1, 8.50, 90, TRUE),
    (1, 2, 7.00, 85, TRUE),
    (2, 1, 5.50, 70, FALSE),
    (2, 3, 9.00, 95, TRUE),
    (3, 1, 6.50, 80, TRUE),
    (3, 4, 4.00, 60, FALSE),
    (4, 2, 7.50, 80, TRUE),
    (5, 3, 8.00, 90, TRUE);

-- Inserir dados na tabela log_matricula
-- O ID do log é gerado automaticamente.
INSERT INTO log_matricula (matricula_id, operacao) VALUES
    (1, 'INSERT'),
    (2, 'INSERT'),
    (3, 'INSERT'),
    (4, 'INSERT'),
    (5, 'INSERT'),
    (6, 'INSERT'),
    (7, 'INSERT'),
    (8, 'INSERT');
