DROP DATABASE IF EXISTS steam;

CREATE DATABASE steam;

\c steam;

CREATE TABLE jogo (
    id serial PRIMARY KEY,
    nome varchar(200) not null,
    preco numeric(20,2) default 0,
    data_hora_ultima_atualizacao timestamp default current_timestamp    
);

CREATE TABLE usuario (
    id serial primary key,
    email varchar(255) unique,
    senha varchar(255) not null,
    nome varchar(255),
    saldo numeric(20,2) default 0
);

CREATE TABLE compra (
    id serial primary key,
    usuario_id integer references usuario (id),
    jogo_id integer references jogo (id),
    valor_no_momento_da_compra numeric(20,2),
    data_hora timestamp default current_timestamp
);


-- JOGOS
INSERT INTO jogo (nome, preco, data_hora_ultima_atualizacao) VALUES
('The Witcher 3: Wild Hunt', 79.90, '2026-01-10 10:00:00'),
('Cyberpunk 2077', 149.90, '2026-02-15 14:30:00'),
('Stardew Valley', 24.99, '2026-03-20 09:15:00'),
('Red Dead Redemption 2', 199.90, '2026-01-05 16:45:00'),
('Counter-Strike 2', 0.00, '2026-04-12 12:00:00'),
('Hollow Knight', 46.99, '2026-02-22 11:30:00'),
('Elden Ring', 229.90, '2026-03-18 18:00:00'),
('Terraria', 32.99, '2026-01-25 08:00:00'),
('Portal 2', 32.99, '2026-04-01 13:20:00'),
('Baldurs Gate 3', 199.99, '2026-03-30 20:00:00'),
('Dota 2', 0.00, '2026-04-10 15:00:00'),
('Minecraft', 99.90, '2026-02-05 17:30:00'),
('God of War', 199.90, '2026-03-12 10:45:00'),
('Celeste', 36.99, '2026-01-18 19:00:00'),
('Hades', 73.99, '2026-04-05 21:00:00');

-- USUÁRIOS
INSERT INTO usuario (email, senha, nome, saldo) VALUES
('ana@email.com', '123456', 'Ana Silva', 150.00),
('bruno@email.com', '123456', 'Bruno Souza', 50.00),
('carla@email.com', '123456', 'Carla Oliveira', 300.00),
('diego@email.com', '123456', 'Diego Santos', 0.00),
('eduarda@email.com', '123456', 'Eduarda Lima', 75.50),
('felipe@email.com', '123456', 'Felipe Costa', 200.00),
('gabriela@email.com', '123456', 'Gabriela Alves', 500.00),
('henrique@email.com', '123456', 'Henrique Martins', 25.00),
('isabela@email.com', '123456', 'Isabela Rocha', 120.00),
('joao@email.com', '123456', 'João Pereira', 80.00);


CREATE OR REPLACE FUNCTION testar_preco() RETURNS TRIGGER AS
$$ 
BEGIN
    IF (NEW.preco >= 0) THEN
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';
CREATE TRIGGER trigger_testar_preco BEFORE INSERT OR UPDATE ON jogo FOR EACH ROW EXECUTE FUNCTION testar_preco();

CREATE OR REPLACE FUNCTION testar_saldo() RETURNS TRIGGER AS
$$
DECLARE
    var_saldo_atual numeric(20,2);
    var_preco_atual numeric(20,2);
BEGIN
    IF (EXISTS(SELECT * FROM usuario WHERE id = NEW.usuario_id) AND EXISTS(SELECT * FROM jogo WHERE id = NEW.jogo_id)) THEN
        SELECT saldo FROM usuario WHERE id = NEW.usuario_id INTO var_saldo_atual; 
        SELECT preco FROM jogo WHERE id = NEW.jogo_id INTO var_preco_atual;
        
        IF (var_saldo_atual >= var_preco_atual) THEN
            UPDATE usuario SET saldo = saldo - var_preco_atual WHERE id = NEW.usuario_id;
            RETURN NEW;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_testar_saldo BEFORE INSERT ON compra FOR EACH ROW EXECUTE FUNCTION testar_saldo();



