-- ****************************************************************
-- ANALISE DOS DADOS
-- https://dev.mysql.com/doc/refman/8.4/en/date-and-time-functions.html
-- ****************************************************************
USE portfolio;
-- ****************************************************************
--  KPIs Essenciais de Vendas com SQL
--  Faturamento total
--  Lucro total
--  Quantidade de pedidos
--  Ticket médio
-- ****************************************************************
SELECT
  COUNT(DISTINCT order_id) AS qtde_pedidos,
  SUM(Amount) AS total_vendas,
  SUM(Profit) AS total_lucro,
  ROUND(SUM(Amount) / COUNT(DISTINCT order_id), 2) AS ticket_medio
FROM itens;


-- Pedidos com maior prejuízo
SELECT 
  Order_id,
  SUM(Profit) AS lucro_total,
  COUNT(*) AS itens,
  ROUND(SUM(Profit) / COUNT(*), 2) AS prejuizo_medio_por_item
FROM itens
GROUP BY Order_id
ORDER BY lucro_total ASC
LIMIT 10;


-- ****************************************************************
--  ANALISES POR CATEGORIA DE PRODUTOS
-- ****************************************************************

-- Margem de lucro por categoria
SELECT 
  i.category,
  SUM(i.amount) AS total_vendas,
  SUM(i.profit) AS lucro_total,
  ROUND((SUM(profit) / SUM(amount)) * 100, 2) AS margem_lucro
FROM itens i
GROUP BY i.category
ORDER BY margem_lucro DESC;

-- Subcategorias Mais Lucrativas
SELECT category, subcategory,
       SUM(profit) AS lucro_total,
       AVG(profit) AS lucro_medio,
       ROUND((SUM(profit) / SUM(amount)) * 100, 2) AS margem_lucro,
       COUNT(*) AS vendas
FROM itens
GROUP BY category, subcategory
ORDER BY margem_lucro DESC;

-- Subcategorias com prejuízo (para alerta gerencial)
SELECT 
  subcategory,
  SUM(profit) AS lucro_total,
  SUM(amount) AS vendas_totais,
  ROUND((SUM(profit) / SUM(amount)) * 100, 2) AS margem_perc
FROM itens
GROUP BY subcategory
HAVING lucro_total < 0
ORDER BY margem_perc ASC;

-- Top subcategorias que geram mais lucro por unidade
-- Quando analisado um produto, mostra quais itens são mais “lucrativos” individualmente (ótimo para alavancagem):
SELECT 
  subcategory,
  SUM(Quantity) AS total_qtd,
  SUM(Profit) AS total_lucro,
  ROUND(SUM(Profit) / SUM(Quantity), 2) AS lucro_unitario
FROM itens
GROUP BY subcategory
HAVING total_qtd > 10
ORDER BY lucro_unitario DESC;


-- ****************************************************************
--  ANALISES POR GEOLOCALIZAÇÃO
-- ****************************************************************
--  Ticket Médio por Estado
SELECT c.state,
       ROUND(SUM(i.amount) / COUNT(DISTINCT o.id), 2) AS ticket_medio
FROM itens i
JOIN orders o ON o.id = i.order_id
JOIN customers c ON o.customer_id = c.id  
GROUP BY c.state
ORDER BY ticket_medio DESC;

-- Ranking de Cidades com Maior Faturamento
SELECT c.city, 
	   c.state, 
	   SUM(i.amount) AS total_vendas, 
       RANK() OVER (ORDER BY SUM(i.Amount) DESC) AS ranking       
FROM orders o
JOIN itens i ON o.id = i.order_id
JOIN customers c ON o.customer_id = c.id
GROUP BY c.city, c.state
LIMIT 10;

-- Ranking de Cidades com Maior Lucro
SELECT c.city, 
	   c.state, 
	   SUM(i.profit) AS total_lucro,	   
       RANK() OVER (ORDER BY SUM(i.profit) DESC) AS ranking       
FROM orders o
JOIN itens i ON o.id = i.order_id
JOIN customers c ON o.customer_id = c.id
GROUP BY c.city, c.state
LIMIT 10;

-- Faturamento, lucro e margem por cidade e categoria
SELECT 
  c.city,
  i.category,
  SUM(i.amount) AS total_vendas,
  SUM(i.profit) AS lucro_total,
  ROUND((SUM(profit) / SUM(amount)) * 100, 2) AS margem
FROM itens i
JOIN orders o ON i.order_id = o.id
JOIN customers c ON o.customer_id = c.id
GROUP BY c.city, i.category
ORDER BY total_vendas DESC;

-- Margem de lucro por cidade e categoria
SELECT 
  c.city,
  i.category,
  SUM(i.amount) AS total_vendas,
  SUM(i.profit) AS lucro_total,
  ROUND(((SUM(i.profit) / SUM(i.amount)) * 100), 2) as margem_lucro 
FROM itens i
JOIN orders o ON i.order_id = o.id
JOIN customers c ON o.customer_id = c.id
GROUP BY c.city, i.category
ORDER BY margem_lucro DESC;

-- ****************************************************************
--  ANALISES POR CLIENTE
-- ****************************************************************
-- Clientes com maior volume de pedidos (fidelidade)
SELECT 
  c.customer_name,
  COUNT(DISTINCT o.id) AS qtde_pedidos,
  SUM(i.amount) AS total_gasto
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN itens i ON i.order_id = o.id
GROUP BY c.id
ORDER BY qtde_pedidos DESC
LIMIT 10;

-- Lucro por cliente
SELECT 
  o.customer_id,
  c.customer_name,
  SUM(i.amount) AS total_gasto,
  SUM(i.profit) AS lucro_gerado,
  COUNT(DISTINCT o.ID) AS pedidos,
  ROUND((SUM(i.profit)/ SUM(i.amount)) * 100,2) as margem_lucro,
  ROUND(SUM(i.Amount) / COUNT(DISTINCT o.ID), 2) AS ticket_medio  
FROM itens i
JOIN orders o ON i.order_id = o.id
JOIN customers c ON o.customer_id = c.id
GROUP BY o.customer_id
ORDER BY lucro_gerado DESC;


-- ****************************************************************
--  ANALISES TEMPORAIS
-- ****************************************************************
-- Evolução de vendas, lucro e margem mês a mês
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') AS mes,
    SUM(i.amount) AS total_vendas,
    SUM(i.profit) AS total_lucro,
    COUNT(DISTINCT o.id) AS total_pedidos,
    ROUND(SUM(i.amount) / COUNT(DISTINCT o.id), 2) AS ticket_medio,
    ROUND((SUM(i.profit) / SUM(i.amount)) * 100, 1) AS margem_perc
  FROM orders o
  JOIN itens i ON o.id = i.order_id
  GROUP BY mes;
  
-- Desempenho de Vendas: Metas x Realizado 
 WITH vendas AS (
  SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS mes,
    o.period,
    i.category,
    SUM(i.amount) AS total_vendas
  FROM itens i
  JOIN orders o ON o.id = i.order_id
  GROUP BY i.Category, DATE_FORMAT(o.order_date, '%Y-%m'), o.period
)
SELECT v.category as categoria, v.period as periodo, v.total_vendas, t.target as meta,
ROUND(v.total_vendas - t.target, 2) AS diferenca,
ROUND((v.total_vendas * 1.0 / t.Target - 1) * 100, 1) AS desempenho_perc,
	CASE 
        WHEN v.total_vendas >= t.target THEN 'Meta Atingida'
        ELSE 'Abaixo da Meta'
    END AS situacao   
FROM vendas v
JOIN targets t ON (t.category = v.category) AND (t.period = v.period)
ORDER BY v.category, v.mes;

  
-- Crescimento de vendas mensal (comparativo com o mes anterior)
WITH crescimento AS (
  SELECT   
    DATE_FORMAT(o.order_date, '%Y-%m') AS ano_mes,
    SUM(i.amount) AS total_vendas
  FROM orders o
  JOIN itens i ON o.id = i.order_id
  GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
anterior AS (
  SELECT 
    ano_mes,
    total_vendas,
    LAG(total_vendas, 1, 0) OVER (ORDER BY ano_mes) AS vendas_anterior
  FROM crescimento
)
SELECT 
  ano_mes,
  total_vendas,
  vendas_anterior,
  COALESCE(ROUND((total_vendas - vendas_anterior) / vendas_anterior * 100, 2), 0) AS variacao
FROM anterior
ORDER BY ano_mes;

-- Crescimento das Vendas Por Categoria mês a mês
WITH vendas_categoria_mes AS (
  SELECT
	DATE_FORMAT(o.order_date, '%Y-%m') AS ano_mes,
    i.category,
    SUM(i.amount) AS vendas
  FROM itens i
  JOIN orders o ON i.order_id = o.id
  GROUP BY i.category, DATE_FORMAT(o.order_date, '%Y-%m')
),
anterior AS (
  SELECT 
    category,
    ano_mes,
    vendas,
    LAG(vendas) OVER (PARTITION BY category ORDER BY ano_mes) AS vendas_anterior
  FROM vendas_categoria_mes
)
SELECT 
  category,
  ano_mes,
  vendas,
  vendas_anterior,
  ROUND(((vendas - vendas_anterior) / vendas_anterior) * 100, 1) AS crescimento_perc
FROM anterior
WHERE vendas_anterior IS NOT NULL
ORDER BY category, ano_mes, crescimento_perc DESC;

-- ****************************************************************
--  VIEW PARA USAR NO POWER BI
-- ****************************************************************

CREATE VIEW vendas AS
SELECT 
	o.id, 
	o.order_date, 
    o.period,
	o.customer_id,
	i.amount,
	i.profit,
	i.quantity,
	i.category,	
	i.subcategory
FROM orders o
JOIN itens i on (o.id = i.order_id);

select * from vendas;