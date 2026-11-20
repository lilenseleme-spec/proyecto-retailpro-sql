-- Motor utilizado: SQL Server (SSMS)
-- Pre-entrega M5: Consultas con JOINs para el proyecto - RetailPro
-- Base de datos: Ventas_Tech_DB (creada en M3)

USE Ventas_Tech_DB;
GO


-- Consulta 1: Vista base del proyecto (INNER JOIN)
-- Propósito: reunir en una sola tabla cada venta con su cliente, ciudad,
-- producto y categoría. Es la fuente de datos principal para Power BI:
-- categoría sirve para agrupar y ciudad para filtrar.
SELECT
    v.id_venta,
    v.fecha_venta,
    c.nombre                              AS cliente,
    c.ciudad,
    p.nombre_producto                     AS producto,
    cat.nombre_categoria                  AS categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario        AS total_venta
FROM ventas AS v
INNER JOIN clientes   AS c   ON v.id_cliente   = c.id_cliente
INNER JOIN productos  AS p   ON v.id_producto  = p.id_producto
INNER JOIN categorias AS cat ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha_venta;
-- Hallazgo: las 10 ventas cruzan sin pérdida de filas. Computación concentra
-- el 76,8% de la facturación ($4.950 de $6.444), y Buenos Aires y Tucumán
-- suman el 73,6% gracias a dos clientas que compraron laptops.


-- Consulta 2: Clientes sin ventas (LEFT JOIN)
-- Propósito: detectar clientes registrados que nunca compraron, para que
-- el área de CRM los contacte.
SELECT
    c.nombre,
    c.email,
    c.fecha_registro
FROM clientes AS c
LEFT JOIN ventas AS v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL;
-- Hallazgo: 0 clientes sin compras. Los 5 clientes registrados compraron al
-- menos una vez (2 pedidos cada uno), así que CRM no necesita una campaña de
-- activación: la prioridad pasa a ser la retención.


-- Consulta 3: Productos sin ventas (LEFT JOIN)
-- Propósito: identificar artículos del catálogo sin movimiento, para que el
-- área de producto revise stock, precio o continuidad.
SELECT
    p.nombre_producto,
    cat.nombre_categoria AS categoria,
    p.precio
FROM productos AS p
LEFT JOIN categorias AS cat ON p.id_categoria = cat.id_categoria
LEFT JOIN ventas     AS v   ON p.id_producto  = v.id_producto
WHERE v.id_venta IS NULL;
-- Hallazgo: 0 productos sin ventas. Los 6 artículos del catálogo tuvieron
-- movimiento; no hay productos inmovilizados, aunque Audio y Accesorios
-- rotan con baja facturación.


-- Consulta 4: Consolidado por período (UNION ALL)
-- Propósito: comparar la facturación de la primera y la segunda parte del
-- período de ventas. La columna periodo no existe en la base: se crea como
-- texto fijo dentro de cada SELECT para identificar el origen de cada fila.
SELECT
    periodo,
    COUNT(*)    AS cantidad_ventas,
    SUM(total)  AS total_periodo
FROM (
    SELECT fecha_venta, cantidad * precio_unitario AS total,
           '1 al 10 de marzo' AS periodo
    FROM ventas
    WHERE fecha_venta BETWEEN '2024-03-01' AND '2024-03-10'

    UNION ALL

    SELECT fecha_venta, cantidad * precio_unitario AS total,
           '11 al 15 de marzo' AS periodo
    FROM ventas
    WHERE fecha_venta BETWEEN '2024-03-11' AND '2024-03-15'
) AS consolidado
GROUP BY periodo
ORDER BY periodo;
-- Hallazgo: con 5 ventas cada uno, el primer período factura $3.620 (56,2%)
-- contra $2.824 del segundo. La diferencia la explica una sola venta: 2
-- laptops por $2.400 el 5 de marzo.
