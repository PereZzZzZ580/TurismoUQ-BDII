/*=====================================================================
  TURISMOUQ - ENTREGA 1
  Script 03: 7 consultas de análisis obligatorias
  Oracle XE 21c

  Las consultas están numeradas y comentadas exactamente en el orden de
  la guía: PIVOT, ROLLUP/GROUPING, RANK/PARTITION BY, LAG, bind variables,
  UNPIVOT y una pregunta libre.
=====================================================================*/

SET DEFINE OFF;

/*=====================================================================
  CONSULTA 1 - OCUPACIÓN POR MUNICIPIO Y MES CON PIVOT

  Definición: ocupación 2026 = noches-habitación ocupadas / noches-
  habitación disponibles del municipio. Se consideran reservas
  CONFIRMADAS y COMPLETADAS.
=====================================================================*/
WITH calendario AS (
  SELECT DATE '2026-01-01' + LEVEL - 1 AS dia
  FROM dual
  CONNECT BY LEVEL <= 365
),
meses AS (
  SELECT LEVEL AS mes,
         ADD_MONTHS(DATE '2026-01-01', LEVEL - 1) AS inicio_mes,
         LAST_DAY(ADD_MONTHS(DATE '2026-01-01', LEVEL - 1)) AS fin_mes
  FROM dual
  CONNECT BY LEVEL <= 12
),
dias_ocupados AS (
  SELECT DISTINCT
         h.id_habitacion,
         a.id_municipio,
         c.dia
  FROM calendario c
  JOIN reserva_habitacion rh
    ON c.dia >= rh.fecha_check_in
   AND c.dia < rh.fecha_check_out
  JOIN reserva r
    ON r.id_reserva = rh.id_reserva
  JOIN habitacion h
    ON h.id_habitacion = rh.id_habitacion
  JOIN alojamiento a
    ON a.id_alojamiento = h.id_alojamiento
  WHERE r.estado IN ('CONFIRMADA','COMPLETADA')
),
ocupacion_mensual AS (
  SELECT id_municipio,
         EXTRACT(MONTH FROM dia) AS mes,
         COUNT(*) AS noches_ocupadas
  FROM dias_ocupados
  GROUP BY id_municipio, EXTRACT(MONTH FROM dia)
),
capacidad_mensual AS (
  SELECT a.id_municipio,
         m.mes,
         COUNT(h.id_habitacion) * (m.fin_mes - m.inicio_mes + 1) AS noches_disponibles
  FROM alojamiento a
  JOIN habitacion h
    ON h.id_alojamiento = a.id_alojamiento
  CROSS JOIN meses m
  GROUP BY a.id_municipio, m.mes, m.inicio_mes, m.fin_mes
),
base AS (
  SELECT mu.nombre AS municipio,
         c.mes,
         ROUND(100 * NVL(o.noches_ocupadas,0) / c.noches_disponibles, 2) AS ocupacion_pct
  FROM capacidad_mensual c
  JOIN municipio mu
    ON mu.id_municipio = c.id_municipio
  LEFT JOIN ocupacion_mensual o
    ON o.id_municipio = c.id_municipio
   AND o.mes = c.mes
)
SELECT municipio,
       ENE, FEB, MAR, ABR, MAY, JUN,
       JUL, AGO, SEP, OCT, NOV, DIC
FROM base
PIVOT (
  MAX(ocupacion_pct)
  FOR mes IN (
    1 AS ENE,  2 AS FEB,  3 AS MAR,  4 AS ABR,
    5 AS MAY,  6 AS JUN,  7 AS JUL,  8 AS AGO,
    9 AS SEP, 10 AS OCT, 11 AS NOV, 12 AS DIC
  )
)
ORDER BY municipio;

/*=====================================================================
  CONSULTA 2 - INGRESOS POR MUNICIPIO, TIPO Y TEMPORADA
               CON ROLLUP + GROUPING

  Definición: ingreso = suma de pagos EXITOSOS. La temporada se asigna
  según la fecha efectiva del pago. La subconsulta usa DISTINCT para no
  duplicar un pago cuando una reserva tiene varias habitaciones.
=====================================================================*/
WITH pagos_base AS (
  SELECT DISTINCT
         p.id_pago,
         p.monto,
         p.fecha_pago,
         a.id_municipio,
         a.id_tipo_alojamiento
  FROM pago p
  JOIN reserva r
    ON r.id_reserva = p.id_reserva
  JOIN reserva_habitacion rh
    ON rh.id_reserva = r.id_reserva
  JOIN habitacion h
    ON h.id_habitacion = rh.id_habitacion
  JOIN alojamiento a
    ON a.id_alojamiento = h.id_alojamiento
  WHERE p.estado = 'EXITOSO'
)
SELECT
  CASE WHEN GROUPING(pb.id_municipio) = 1
       THEN 'TOTAL TODOS LOS MUNICIPIOS'
       ELSE m.nombre END AS municipio,
  CASE WHEN GROUPING(pb.id_tipo_alojamiento) = 1
       THEN 'TOTAL TIPO ALOJAMIENTO'
       ELSE ta.nombre END AS tipo_alojamiento,
  CASE WHEN GROUPING(t.tipo_temporada) = 1
       THEN 'TOTAL TEMPORADA'
       ELSE t.tipo_temporada END AS temporada,
  ROUND(SUM(pb.monto), 2) AS ingreso
FROM pagos_base pb
JOIN temporada t
  ON TRUNC(pb.fecha_pago) BETWEEN t.fecha_inicio AND t.fecha_fin
LEFT JOIN municipio m
  ON m.id_municipio = pb.id_municipio
LEFT JOIN tipo_alojamiento ta
  ON ta.id_tipo_alojamiento = pb.id_tipo_alojamiento
GROUP BY ROLLUP (
  pb.id_municipio,
  pb.id_tipo_alojamiento,
  t.tipo_temporada
)
ORDER BY
  GROUPING(pb.id_municipio),
  pb.id_municipio,
  GROUPING(pb.id_tipo_alojamiento),
  pb.id_tipo_alojamiento,
  GROUPING(t.tipo_temporada),
  t.tipo_temporada;

/*=====================================================================
  CONSULTA 3 - TOP 3 ALOJAMIENTOS DE MAYOR INGRESO POR MUNICIPIO
               CON RANK + PARTITION BY
=====================================================================*/
WITH ingresos_alojamiento AS (
  SELECT
    p.id_municipio,
    p.id_alojamiento,
    p.nombre_comercial,
    SUM(p.monto) AS ingreso
  FROM (
    SELECT DISTINCT
           p.id_pago,
           p.monto,
           a.id_alojamiento,
           a.id_municipio,
           a.nombre_comercial
    FROM pago p
    JOIN reserva r
      ON r.id_reserva = p.id_reserva
    JOIN reserva_habitacion rh
      ON rh.id_reserva = r.id_reserva
    JOIN habitacion h
      ON h.id_habitacion = rh.id_habitacion
    JOIN alojamiento a
      ON a.id_alojamiento = h.id_alojamiento
    WHERE p.estado = 'EXITOSO'
  ) p
  GROUP BY id_municipio, id_alojamiento, nombre_comercial
),
ranked AS (
  SELECT ia.*,
         RANK() OVER (
           PARTITION BY id_municipio
           ORDER BY ingreso DESC, id_alojamiento
         ) AS posicion
  FROM ingresos_alojamiento ia
)
SELECT
  m.nombre AS municipio,
  r.nombre_comercial AS alojamiento,
  ROUND(r.ingreso, 2) AS ingreso,
  r.posicion AS ranking
FROM ranked r
JOIN municipio m
  ON m.id_municipio = r.id_municipio
WHERE r.posicion <= 3
ORDER BY m.nombre, r.posicion, r.ingreso DESC;

/*=====================================================================
  CONSULTA 4 - VARIACIÓN DE INGRESOS MES CONTRA MES CON LAG

  Se construye calendario completo 2024-2026 para que también aparezcan
  meses sin pagos exitosos.
=====================================================================*/
WITH meses AS (
  SELECT ADD_MONTHS(DATE '2024-01-01', LEVEL - 1) AS mes
  FROM dual
  CONNECT BY LEVEL <= 36
),
ingresos AS (
  SELECT TRUNC(p.fecha_pago, 'MM') AS mes,
         SUM(p.monto) AS ingreso
  FROM pago p
  WHERE p.estado = 'EXITOSO'
  GROUP BY TRUNC(p.fecha_pago, 'MM')
),
serie AS (
  SELECT m.mes,
         NVL(i.ingreso, 0) AS ingreso
  FROM meses m
  LEFT JOIN ingresos i
    ON i.mes = m.mes
),
con_lag AS (
  SELECT mes,
         ingreso,
         LAG(ingreso) OVER (ORDER BY mes) AS ingreso_mes_anterior
  FROM serie
)
SELECT
  TO_CHAR(mes, 'YYYY-MM') AS periodo,
  ROUND(ingreso, 2) AS ingreso,
  ROUND(ingreso_mes_anterior, 2) AS ingreso_mes_anterior,
  ROUND(ingreso - NVL(ingreso_mes_anterior, 0), 2) AS variacion_absoluta,
  CASE
    WHEN NVL(ingreso_mes_anterior, 0) = 0 THEN NULL
    ELSE ROUND(
      100 * (ingreso - ingreso_mes_anterior) / ingreso_mes_anterior,
      2
    )
  END AS variacion_porcentual
FROM con_lag
ORDER BY mes;

/*=====================================================================
  CONSULTA 5 - CONSULTA PARAMETRIZADA CON VARIABLES DE ENLACE

  En SQL Developer se pueden ejecutar previamente estas variables de
  ejemplo y luego correr la consulta:

    VAR p_fecha_inicio DATE;
    VAR p_fecha_fin DATE;
    EXEC :p_fecha_inicio := DATE '2026-01-01';
    EXEC :p_fecha_fin := DATE '2026-06-30';
=====================================================================*/
SELECT
  r.id_reserva,
  c.nombre_completo AS cliente,
  r.fecha_check_in,
  r.fecha_check_out,
  r.estado,
  COUNT(DISTINCT rh.id_reserva_habitacion) AS habitaciones,
  NVL((
    SELECT SUM(rs.cantidad * rs.precio_unitario)
    FROM reserva_servicio rs
    WHERE rs.id_reserva = r.id_reserva
  ), 0) AS valor_servicios,
  NVL((
    SELECT SUM(p.monto)
    FROM pago p
    WHERE p.id_reserva = r.id_reserva
      AND p.estado = 'EXITOSO'
  ), 0) AS total_pagado
FROM reserva r
JOIN cliente c
  ON c.id_cliente = r.id_cliente
LEFT JOIN reserva_habitacion rh
  ON rh.id_reserva = r.id_reserva
WHERE TRUNC(r.fecha_check_in) BETWEEN TRUNC(:p_fecha_inicio) AND TRUNC(:p_fecha_fin)
GROUP BY
  r.id_reserva,
  c.nombre_completo,
  r.fecha_check_in,
  r.fecha_check_out,
  r.estado
ORDER BY r.fecha_check_in, r.id_reserva;

/*=====================================================================
  CONSULTA 6 - UNPIVOT

  Primero genera la matriz mensual de ocupación y luego la transforma
  a formato fila: municipio, mes, porcentaje.
=====================================================================*/
WITH calendario AS (
  SELECT DATE '2026-01-01' + LEVEL - 1 AS dia
  FROM dual
  CONNECT BY LEVEL <= 365
),
meses AS (
  SELECT LEVEL AS mes,
         ADD_MONTHS(DATE '2026-01-01', LEVEL - 1) AS inicio_mes,
         LAST_DAY(ADD_MONTHS(DATE '2026-01-01', LEVEL - 1)) AS fin_mes
  FROM dual
  CONNECT BY LEVEL <= 12
),
dias_ocupados AS (
  SELECT DISTINCT h.id_habitacion, a.id_municipio, c.dia
  FROM calendario c
  JOIN reserva_habitacion rh
    ON c.dia >= rh.fecha_check_in
   AND c.dia < rh.fecha_check_out
  JOIN reserva r
    ON r.id_reserva = rh.id_reserva
  JOIN habitacion h
    ON h.id_habitacion = rh.id_habitacion
  JOIN alojamiento a
    ON a.id_alojamiento = h.id_alojamiento
  WHERE r.estado IN ('CONFIRMADA','COMPLETADA')
),
ocupacion_mensual AS (
  SELECT id_municipio,
         EXTRACT(MONTH FROM dia) AS mes,
         COUNT(*) AS noches_ocupadas
  FROM dias_ocupados
  GROUP BY id_municipio, EXTRACT(MONTH FROM dia)
),
capacidad_mensual AS (
  SELECT a.id_municipio,
         m.mes,
         COUNT(h.id_habitacion) * (m.fin_mes - m.inicio_mes + 1) AS noches_disponibles
  FROM alojamiento a
  JOIN habitacion h ON h.id_alojamiento = a.id_alojamiento
  CROSS JOIN meses m
  GROUP BY a.id_municipio, m.mes, m.inicio_mes, m.fin_mes
),
base AS (
  SELECT mu.nombre AS municipio,
         c.mes,
         ROUND(100 * NVL(o.noches_ocupadas,0) / c.noches_disponibles, 2) AS ocupacion_pct
  FROM capacidad_mensual c
  JOIN municipio mu ON mu.id_municipio = c.id_municipio
  LEFT JOIN ocupacion_mensual o
    ON o.id_municipio = c.id_municipio
   AND o.mes = c.mes
),
pivotado AS (
  SELECT *
  FROM base
  PIVOT (
    MAX(ocupacion_pct)
    FOR mes IN (
      1 AS ENE,  2 AS FEB,  3 AS MAR,  4 AS ABR,
      5 AS MAY,  6 AS JUN,  7 AS JUL,  8 AS AGO,
      9 AS SEP, 10 AS OCT, 11 AS NOV, 12 AS DIC
    )
  )
)
SELECT municipio, mes, ocupacion_pct
FROM pivotado
UNPIVOT (
  ocupacion_pct FOR mes IN (
    ENE AS 'ENERO', FEB AS 'FEBRERO', MAR AS 'MARZO',
    ABR AS 'ABRIL', MAY AS 'MAYO', JUN AS 'JUNIO',
    JUL AS 'JULIO', AGO AS 'AGOSTO', SEP AS 'SEPTIEMBRE',
    OCT AS 'OCTUBRE', NOV AS 'NOVIEMBRE', DIC AS 'DICIEMBRE'
  )
)
ORDER BY municipio, mes;

/*=====================================================================
  CONSULTA 7 - PREGUNTA LIBRE DE NEGOCIO

  Pregunta: ¿Cuáles son los 10 servicios complementarios que generan
  mayor valor contratado y en qué alojamiento se concentran?

  Se calcula valor contratado = cantidad x precio unitario. Se toman
  reservas no canceladas, porque representan servicios solicitados dentro
  de la operación del negocio.
=====================================================================*/
SELECT
  a.nombre_comercial AS alojamiento,
  m.nombre AS municipio,
  s.nombre AS servicio,
  SUM(rs.cantidad) AS unidades_contratadas,
  ROUND(SUM(rs.cantidad * rs.precio_unitario), 2) AS valor_contratado
FROM reserva_servicio rs
JOIN reserva r
  ON r.id_reserva = rs.id_reserva
JOIN servicio s
  ON s.id_servicio = rs.id_servicio
JOIN alojamiento a
  ON a.id_alojamiento = s.id_alojamiento
JOIN municipio m
  ON m.id_municipio = a.id_municipio
WHERE r.estado IN ('CONFIRMADA','COMPLETADA')
GROUP BY a.nombre_comercial, m.nombre, s.nombre
ORDER BY valor_contratado DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT ================================================================
PROMPT TurismoUQ - 7 consultas listas para ejecutar.
PROMPT ================================================================
