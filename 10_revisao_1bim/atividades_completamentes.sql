DROP DATABASE IF EXISTS atividades_complementares;

CREATE DATABASE atividades_complementares;

\c atividades_complementares;

CREATE TABLE aluno (
    matricula integer primary key,
    nome text not null
);

INSERT INTO aluno (matricula, nome) VALUES
(43622, 'IGOR PEREIRA');

INSERT INTO aluno (matricula, nome) VALUES
(43621, 'MÁRCIO JOSUÉ RAMOS TORRES');

CREATE TABLE tipo_atividade (
    id serial primary key,
    nome text not null,
    max_hora INTERVAL
);

INSERT INTO tipo_atividade (nome, max_hora) VALUES
('ENSINO', '50:00:00'), 
('PESQUISA', '50:00:00'), 
('EXTENSÃO', '50:00:00');

CREATE TABLE atividade_complementar (
    id serial PRIMARY KEY,
    descricao text NOT NULL,    
    aluno_matricula INTEGER REFERENCES aluno (matricula),
    tipo_id integer REFERENCES tipo_atividade (id),
    tempo INTERVAL DEFAULT '00:00:00' 
);
INSERT INTO atividade_complementar (aluno_matricula, descricao, tipo_id, tempo) VALUES
(43622,'BOLSISTA DO MÁRCIO - PROJETO TADSSTREAMING',1 , '35:00:00');

INSERT INTO atividade_complementar (aluno_matricula, descricao, tipo_id, tempo) VALUES
(43622,'BOLSISTA DO TELECKEN - USABILIDADE EM WEBSITES',1 , '35:00:00');

INSERT INTO atividade_complementar (aluno_matricula, descricao, tipo_id, tempo) VALUES
(43621,'BOLSISTA DO TELECKEN - USABILIDADE EM WEBSITES',1 , '35:00:00');


CREATE OR REPLACE FUNCTION saldo_horas(integer) RETURNS TIME AS
$$
DECLARE
    total INTERVAL := '00:00:00';
BEGIN
    IF (EXISTS(SELECT * FROM aluno WHERE matricula = $1)) THEN
        SELECT SUM(tempo) FROM atividade_complementar WHERE 
         aluno_matricula = $1 INTO total;       
    END IF;
    RETURN total; 
END;
$$ LANGUAGE 'plpgsql';

--DROP FUNCTION atingiu_minimo;
CREATE FUNCTION atingiu_minimo(var_matricula integer, var_minimo INTERVAL) RETURNS BOOLEAN AS
$$
DECLARE
    total INTERVAL := '00:00:00';
BEGIN
     IF (EXISTS(SELECT * FROM aluno WHERE matricula = $1)) THEN
        SELECT SUM(tempo) FROM atividade_complementar WHERE 
         aluno_matricula = $1 INTO total;       
    END IF;
    IF (total >= var_minimo) THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF; 
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION relatorio_media_por_tipo() RETURNS TABLE (var_tipo text, var_qtde INTERVAL) AS
$$
DECLARE 
     media_ensino INTERVAL := '00:00:00';
     nome_ensino TEXT;
     
      media_extensao INTERVAL := '00:00:00';
      nome_extensao TEXT;
      
       media_pesquisa INTERVAL := '00:00:00';
       nome_pesquisa TEXT;
BEGIN
    SELECT tipo_atividade.nome, COALESCE(AVG(tempo), '00:00:00') FROM atividade_complementar RIGHT JOIN tipo_atividade ON tipo_atividade.id = atividade_complementar.tipo_id WHERE 
       tipo_atividade.id = 1 GROUP BY tipo_atividade.nome INTO nome_ensino, media_ensino;
       
        SELECT tipo_atividade.nome, COALESCE(AVG(tempo), '00:00:00') FROM atividade_complementar RIGHT JOIN tipo_atividade ON tipo_atividade.id = atividade_complementar.tipo_id WHERE 
       tipo_atividade.id = 2 GROUP BY tipo_atividade.nome INTO nome_extensao, media_extensao;
       
        SELECT tipo_atividade.nome, COALESCE(AVG(tempo), '00:00:00') FROM atividade_complementar RIGHT JOIN tipo_atividade ON tipo_atividade.id = atividade_complementar.tipo_id WHERE 
       tipo_atividade.id = 3 GROUP BY tipo_atividade.nome INTO nome_pesquisa, media_pesquisa;
       
       CREATE TEMPORARY TABLE IF NOT EXISTS temp_relatorio (var_tipo text, var_qtde INTERVAL) ON COMMIT DROP;
       
       INSERT INTO temp_relatorio (var_tipo, var_qtde) VALUES
       (nome_ensino, media_ensino), (nome_pesquisa, media_pesquisa), (nome_extensao, media_extensao);
       
       RETURN QUERY SELECT * FROM temp_relatorio;
END;
$$ LANGUAGE 'plpgsql';



SELECT atingiu_minimo(43622, '66:00:00');
SELECT atingiu_minimo(43621, '66:00:00');
SELECT * from relatorio_media_por_tipo();


