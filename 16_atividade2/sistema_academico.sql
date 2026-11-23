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
