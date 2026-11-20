-- Motor utilizado: SQL Server (SSMS)
-- Pre-entrega M4: Consultas SQL de negocio - RetailPro
-- Base de datos: Ventas_Tech_DB (creada en M3)

USE Ventas_Tech_DB;
GO


-- === CONSULTA 1: Resumen ejecutivo mensual ===
-- Total facturado, cantidad de pedidos y ticket promedio por mes.
-- El total de cada venta se calcula como cantidad * precio_unitario.
SELECT
    YEAR(fecha_venta)                                        AS año,
    MONTH(fecha_venta)                                       AS mes,
    SUM(cantidad * precio_unitario)                          AS total_facturado,
    COUNT(*)                                                 AS cantidad_pedidos,
    CAST(AVG(cantidad * precio_unitario) AS DECIMAL(10,2))   AS ticket_promedio
FROM ventas
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY año, mes;


-- === CONSULTA 2: Ranking de productos ===
-- Top 5 de productos por total facturado, con las unidades vendidas.
SELECT TOP 5
    id_producto,
    SUM(cantidad)                     AS unidades_vendidas,
    SUM(cantidad * precio_unitario)   AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC;


-- === CONSULTA 3: Clientes recurrentes ===
-- Clientes con más de un pedido, con cantidad de pedidos y total gastado.
SELECT
    id_cliente,
    COUNT(*)                          AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)   AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;


-- === CONSULTA 4: Productos por encima / por debajo del promedio ===
-- Paso 1 (WITH): se calcula el total facturado de cada producto.
-- Paso 2: se compara cada total con el promedio de esos totales
--         (promedio por producto, no promedio de las filas de ventas).
WITH totales_producto AS (
    SELECT
        id_producto,
        SUM(cantidad * precio_unitario) AS total_facturado
    FROM ventas
    GROUP BY id_producto
)
SELECT
    id_producto,
    total_facturado,
    CASE
        WHEN total_facturado > (SELECT AVG(total_facturado) FROM totales_producto)
            THEN 'Por encima'
        ELSE 'Por debajo'
    END AS comparacion_promedio
FROM totales_producto
ORDER BY total_facturado DESC;


-- === BLOQUE DE CIERRE: HALLAZGOS ===
-- 1. El producto 1 concentra el 55,9% de la facturación de marzo 2024
--    ($3.600 de $6.444) con solo 3 unidades vendidas. Junto con el
--    producto 3 ($1.350) explican el 76,8% del total: son los únicos
--    dos productos por encima del promedio por producto ($1.074).
--
-- 2. Más unidades no significa más facturación: el producto 2 es el más
--    vendido en unidades (13), pero queda último en el top 5 con $364,
--    apenas el 5,6% del total. Su precio unitario bajo ($28) hace que el
--    volumen no compense.
--
-- 3. Los 5 clientes son recurrentes (2 pedidos cada uno), pero el gasto
--    está muy concentrado: los clientes 1 y 5 suman $4.740, el 73,6% de
--    la facturación, porque ambos compraron el producto 1.
