--  link da base de dados
--  https://www.kaggle.com/datasets/benroshan/ecommerce-data

-- funções de data do MySQL
-- https://dev.mysql.com/doc/refman/8.4/en/date-and-time-functions.html


-- Criar banco de dados no MYSQL
CREATE DATABASE portfolio;

-- Usar o banco
USE portfolio;

-- ****************************************************************
-- MODELAGEM DE DADOS
-- ****************************************************************
-- CRIAR AS TABELAS COM A ESTRUTURA INICIAL PARA IMPORTAR OS DADOS

-- Criar a tabela de ordens
CREATE TABLE orders (
    id VARCHAR(20) NOT NULL PRIMARY KEY,
	o_date VARCHAR(10),
	customer_name VARCHAR(50),
	state VARCHAR(30),
	city VARCHAR(50)
);

-- Criar a tabela de detalhe das ordens
CREATE TABLE itens (
	id INT AUTO_INCREMENT NOT NULL,
	order_id VARCHAR(20) NOT NULL,    	
	amount DECIMAL(10,2),
	profit DECIMAL(10,2),	
	quantity INT,
	category VARCHAR(30),	
	subcategory VARCHAR(30),
PRIMARY KEY (id, order_id));


-- Criar a tabela de metas
CREATE TABLE targets (
    period VARCHAR(6),
    category VARCHAR(30),
	target DECIMAL(10,2),
    PRIMARY KEY (period, category)
);


-- ****************************************************************
-- TRATAMENTO E LIMPEZA DOS DADOS
-- ****************************************************************
-- data da ordem em formato DATE
SELECT * FROM orders;


-- excluir linhas em branco ou nulas
DELETE FROM orders WHERE id = '' or id is null;

-- incluir campo com data da venda no formato DATE
ALTER TABLE orders ADD order_date DATE;


select id, SUBSTRING(o_date, 7, 4), CONCAT(state, ' - ', city) as localizacao from orders;

-- incluir data da venda no formato DATE + campo formato mes-ano
UPDATE orders set order_date = CONCAT(
	SUBSTRING(o_date, 7, 4), '-',  -- ano
    SUBSTRING(o_date, 4, 2), '-',  -- mês
    SUBSTRING(o_date, 1, 2)        -- dia
    )       
WHERE id <> '' and order_date IS NULL;

-- data no formato Mes-ano Ex: Apr-18
SELECT * FROM TARGETS;

-- incluir campo na tabela orders o periodo no formato de texto resumido
ALTER TABLE orders ADD period VARCHAR(6);

UPDATE orders SET period = DATE_FORMAT(order_date, '%b-%y') 
WHERE (period IS NULL) and (id <> '');

-- Tratar campos nulos ou vazios:**
UPDATE itens SET amount = 0 WHERE (amount is NULL) AND id <> '';
UPDATE itens SET profit = 0 WHERE (profit IS NULL) AND id <> '';
UPDATE itens SET quantity = 0 WHERE (quantity IS NULL) AND id <> '';

-- eliminar espaço em branco no inicio e final do texto
UPDATE orders SET customer_name = trim(customer_name) WHERE customer_name <> '' and id <> '';
UPDATE orders SET city = trim(city) WHERE city <> '' and id <> '';
UPDATE orders SET state = trim(state) WHERE state <> '' and id <> '';
UPDATE itens SET category = trim(category) WHERE category <> '' and id <> '';
UPDATE itens SET subcategory = trim(subcategory) WHERE subcategory <> '' and id > 0;
UPDATE targets SET period = trim(period) WHERE period <> '' and period <> '';
UPDATE targets SET category = trim(category) WHERE category <> '' and period <> '';

-- SUBSTITUIR TEXTO
-- UPDATE itens SET category = REPLACE(category, '-', '') WHERE id > 0;

-- converter todo o texto para letras MINÚSCULAS ou MAIUSCULAS
-- UPDATE itens SET category = UPPER(category) WHERE category <> '' and id > 0; -- MAIUSCULA
-- UPDATE itens SET subcategory = LOWER(subcategory) WHERE subcategory <> '' and id > 0; -- MINUSCULA

-- verificar categoria/subcategorias nulas nos detalhes das ordens
SELECT COUNT(*) from itens WHERE category is null; 
SELECT COUNT(*) from itens WHERE subcategory is null;

-- VERIFICANDO DISTINTOS
SELECT DISTINCT(subcategory), category FROM itens ORDER BY category, subcategory;


-- ****************************************************************
-- NORMALIZAÇÃO
-- ****************************************************************

-- Criar a tabela de clientes
CREATE TABLE customers (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	customer_name VARCHAR(50),
	state VARCHAR(30),
	city VARCHAR(50)
);

-- ALTERAR TABELA ORDERS
ALTER TABLE orders ADD customer_id INT;

-- Criar as chaves estrangeiras (boa prática para integridade e JOINs rápidos)
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id) REFERENCES customers(id);

ALTER TABLE itens
ADD CONSTRAINT fk_itens_orders
FOREIGN KEY (order_id) REFERENCES orders(id);


-- VERIFICAR CLIENTES QUE COMPRARAM MAIS QUE 1 VEZ
SELECT DISTINCT(customer_name), state, city, count(*) 
FROM orders 
GROUP BY customer_name, state, city 
HAVING count(*) > 1;

select * from orders;

-- INSERIR DADOS NA TABELA CLIENTE
INSERT INTO customers (customer_name, state, city) 
SELECT DISTINCT(customer_name), state, city from orders GROUP BY customer_name, state, city;

-- verificar clientes
SELECT * FROM customers;

-- ATUALIZAR O CODIGO DO CLIENTE NA TABELA DE ORDENS
UPDATE orders SET customer_id = (
    SELECT c.id FROM customers c
    WHERE (c.customer_name = orders.customer_name) AND
          (c.state = orders.state) AND 
          (c.city = orders.City)
)
WHERE customer_id is null;

select * from orders;

-- EXCLUIR AS COLUNAS JÁ NORMALIZADAS DA TABELA DE ORDENS
ALTER TABLE orders DROP customer_name, DROP state, DROP city, DROP o_date;