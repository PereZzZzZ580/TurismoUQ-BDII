/*=====================================================================
  TURISMOUQ - ENTREGA 1
  Script 02: Carga masiva y asimétrica
  Oracle XE 21c

  Este script supera los mínimos de la guía y genera datos reproducibles
  con DBMS_RANDOM, sin depender de Mockaroo.

  Mínimos de la guía que se cubren:
    MUNICIPIO 12
    TIPO_ALOJAMIENTO 4
    ALOJAMIENTO 60
    HABITACION >= 400   (este script genera 400+)
    TEMPORADA >= 6      (este script usa 21 periodos: 7 por año 2024-2026)
    TARIFA cruce habitación x temporada
    CLIENTE 3000
    RESERVA 25000
    RESERVA_HABITACION >= 25000 (30.000 aproximadamente)
    PAGO >= 25000 (aprox. 30.000)
    SERVICIO >= 30 (60, uno por alojamiento)
    RESERVA_SERVICIO 40000
    RESENA >= 40% de reservas completadas
    USUARIO_SISTEMA 10
=====================================================================*/

SET DEFINE OFF;
SET SERVEROUTPUT ON;

BEGIN
  DBMS_RANDOM.SEED(20261001);
END;
/

/*---------------------------------------------------------------------
  1. MUNICIPIOS: los 12 municipios del Quindío.
---------------------------------------------------------------------*/
INSERT ALL
  INTO municipio (id_municipio, nombre, departamento) VALUES (1,  'Armenia',    'Quindío')
  INTO municipio (id_municipio, nombre, departamento) VALUES (2,  'Buenavista', 'Quindío')
  INTO municipio (id_municipio, nombre, departamento) VALUES (3,  'Calarcá',    'Quindío')
  INTO municipio (id_municipio, nombre, departamento) VALUES (4,  'Circasia',   'Quindío')
  INTO municipio (id_municipio, nombre, departamento) VALUES (5,  'Córdoba',    'Quindío')
  INTO municipio (id_municipio, nombre, departamento) VALUES (6,  'Filandia',   'Quindío')
  INTO municipio (id_municipio, nombre, departamento) VALUES (7,  'Génova',     'Quindío')
  INTO municipio (id_municipio, nombre, departamento) VALUES (8,  'La Tebaida', 'Quindío')
  INTO municipio (id_municipio, nombre, departamento) VALUES (9,  'Montenegro', 'Quindío')
  INTO municipio (id_municipio, nombre, departamento) VALUES (10, 'Pijao',      'Quindío')
  INTO municipio (id_municipio, nombre, departamento) VALUES (11, 'Quimbaya',   'Quindío')
  INTO municipio (id_municipio, nombre, departamento) VALUES (12, 'Salento',    'Quindío')
SELECT 1 FROM dual;

/*---------------------------------------------------------------------
  2. TIPOS DE ALOJAMIENTO.
---------------------------------------------------------------------*/
INSERT ALL
  INTO tipo_alojamiento (id_tipo_alojamiento, nombre, descripcion)
    VALUES (1, 'FINCA CAFETERA', 'Alojamiento rural asociado a experiencias cafeteras.')
  INTO tipo_alojamiento (id_tipo_alojamiento, nombre, descripcion)
    VALUES (2, 'HOTEL', 'Alojamiento urbano o turístico con múltiples habitaciones.')
  INTO tipo_alojamiento (id_tipo_alojamiento, nombre, descripcion)
    VALUES (3, 'GLAMPING', 'Alojamiento de naturaleza con comodidades de hotel.')
  INTO tipo_alojamiento (id_tipo_alojamiento, nombre, descripcion)
    VALUES (4, 'HOSTAL', 'Alojamiento de menor escala con habitaciones para viajeros.')
SELECT 1 FROM dual;

/*---------------------------------------------------------------------
  3. ALOJAMIENTOS: 60 repartidos de forma desigual.
     Municipios: Armenia 14, Calarcá 7, Salento 5, Filandia 5,
     Montenegro 4, Quimbaya 4, Circasia 4, La Tebaida 4,
     Buenavista 3, Córdoba 3, Pijao 4, Génova 3.
     Los tipos se equilibran 15-15-15-15 para que el análisis por tipo
     tenga suficiente volumen, mientras la distribución geográfica sí
     queda claramente asimétrica.
---------------------------------------------------------------------*/
DECLARE
  v_municipio NUMBER;
  v_tipo      NUMBER;
  v_nombre    VARCHAR2(120);
BEGIN
  FOR i IN 1..60 LOOP
    v_municipio := CASE
      WHEN i BETWEEN 1  AND 14 THEN 1
      WHEN i BETWEEN 15 AND 21 THEN 3
      WHEN i BETWEEN 22 AND 26 THEN 12
      WHEN i BETWEEN 27 AND 31 THEN 6
      WHEN i BETWEEN 32 AND 35 THEN 9
      WHEN i BETWEEN 36 AND 39 THEN 11
      WHEN i BETWEEN 40 AND 43 THEN 4
      WHEN i BETWEEN 44 AND 47 THEN 8
      WHEN i BETWEEN 48 AND 50 THEN 2
      WHEN i BETWEEN 51 AND 53 THEN 5
      WHEN i BETWEEN 54 AND 57 THEN 10
      ELSE 7
    END;

    v_tipo := MOD(i - 1, 4) + 1;

    v_nombre := CASE v_tipo
      WHEN 1 THEN 'Finca Cafetera Los Andes ' || LPAD(i, 2, '0')
      WHEN 2 THEN 'Hotel Quindío Centro '     || LPAD(i, 2, '0')
      WHEN 3 THEN 'Glamping Montaña Verde '   || LPAD(i, 2, '0')
      ELSE        'Hostal Caminos del Café '  || LPAD(i, 2, '0')
    END;

    INSERT INTO alojamiento (
      id_alojamiento, id_municipio, id_tipo_alojamiento,
      nombre_comercial, direccion, estrellas, telefono, correo
    ) VALUES (
      i,
      v_municipio,
      v_tipo,
      v_nombre,
      'Carrera ' || (MOD(i, 18) + 1) || ' # ' || LPAD(MOD(i * 7, 90) + 10, 2, '0') || '-'
      || LPAD(MOD(i * 11, 90) + 10, 2, '0'),
      MOD(i, 5) + 1,
      '300' || LPAD(1000000 + i * 173, 7, '0'),
      'alojamiento' || LPAD(i, 2, '0') || '@turismouq.co'
    );
  END LOOP;
END;
/

/*---------------------------------------------------------------------
  4. HABITACIONES: más de 400, con fuerte asimetría.
     - 2 hoteles grandes: 35-40 habitaciones.
     - Otros hoteles: 7-9.
     - Fincas: 3-4.
     - Glampings: 5-6.
     - Hostales: 5-7.
---------------------------------------------------------------------*/
DECLARE
  v_total_rooms     NUMBER := 0;
  v_rooms_lodging   NUMBER;
  v_type            NUMBER;
  v_hotel_rank      NUMBER;
  v_tipo_hab        VARCHAR2(20);
  v_capacidad       NUMBER;
BEGIN
  FOR i IN 1..60 LOOP
    v_type := MOD(i - 1, 4) + 1;

    IF v_type = 2 THEN
      v_hotel_rank := FLOOR((i - 2) / 4) + 1;
      IF v_hotel_rank <= 2 THEN
        v_rooms_lodging := 35 + MOD(i, 6);
      ELSE
        v_rooms_lodging := 7 + MOD(i, 3);
      END IF;
    ELSIF v_type = 1 THEN
      v_rooms_lodging := 3 + MOD(i, 2);
    ELSIF v_type = 3 THEN
      v_rooms_lodging := 5 + MOD(i, 2);
    ELSE
      v_rooms_lodging := 5 + MOD(i, 3);
    END IF;

    FOR j IN 1..v_rooms_lodging LOOP
      v_total_rooms := v_total_rooms + 1;

      v_tipo_hab := CASE MOD(j - 1, 4)
        WHEN 0 THEN 'SENCILLA'
        WHEN 1 THEN 'DOBLE'
        WHEN 2 THEN 'SUITE'
        ELSE 'CABAÑA'
      END;

      v_capacidad := CASE v_tipo_hab
        WHEN 'SENCILLA' THEN 1 + MOD(j, 2)
        WHEN 'DOBLE'    THEN 2 + MOD(j, 2)
        WHEN 'SUITE'    THEN 2 + MOD(j, 3)
        ELSE 3 + MOD(j, 4)
      END;

      INSERT INTO habitacion (
        id_habitacion, id_alojamiento, numero_habitacion,
        capacidad_maxima, tipo_habitacion, descripcion
      ) VALUES (
        v_total_rooms,
        i,
        TO_CHAR(j),
        v_capacidad,
        v_tipo_hab,
        'Habitación ' || j || ' del alojamiento ' || i || ', diseñada para ' || v_capacidad || ' huésped(es).'
      );
    END LOOP;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Habitaciones generadas: ' || v_total_rooms);
END;
/

/*---------------------------------------------------------------------
  5. TEMPORADAS: 7 periodos por año, 2024-2026.
     Se supera el mínimo de 6 y se cubren también los años 2024 para
     poder analizar las 25.000 reservas que la guía pide desde 2024.

     1 Alta enero
     2 Baja inicio de año
     3 Alta Semana Santa
     4 Media
     5 Alta mitad de año
     6 Baja
     7 Alta diciembre
---------------------------------------------------------------------*/
DECLARE
  v_id NUMBER := 0;
BEGIN
  FOR y IN 2024..2026 LOOP
    v_id := v_id + 1;
    INSERT INTO temporada VALUES
      (v_id, 'Alta enero ' || y, y, 'ALTA', ADD_MONTHS(DATE '2024-01-01', 12*(y-2024)),
       ADD_MONTHS(DATE '2024-01-15', 12*(y-2024)));

    v_id := v_id + 1;
    INSERT INTO temporada VALUES
      (v_id, 'Baja inicio de año ' || y, y, 'BAJA', ADD_MONTHS(DATE '2024-01-16', 12*(y-2024)),
       ADD_MONTHS(DATE '2024-03-31', 12*(y-2024)));

    v_id := v_id + 1;
    INSERT INTO temporada VALUES
      (v_id, 'Alta Semana Santa ' || y, y, 'ALTA', ADD_MONTHS(DATE '2024-04-01', 12*(y-2024)),
       ADD_MONTHS(DATE '2024-04-20', 12*(y-2024)));

    v_id := v_id + 1;
    INSERT INTO temporada VALUES
      (v_id, 'Media ' || y, y, 'MEDIA', ADD_MONTHS(DATE '2024-04-21', 12*(y-2024)),
       ADD_MONTHS(DATE '2024-06-14', 12*(y-2024)));

    v_id := v_id + 1;
    INSERT INTO temporada VALUES
      (v_id, 'Alta mitad de año ' || y, y, 'ALTA', ADD_MONTHS(DATE '2024-06-15', 12*(y-2024)),
       ADD_MONTHS(DATE '2024-08-31', 12*(y-2024)));

    v_id := v_id + 1;
    INSERT INTO temporada VALUES
      (v_id, 'Baja ' || y, y, 'BAJA', ADD_MONTHS(DATE '2024-09-01', 12*(y-2024)),
       ADD_MONTHS(DATE '2024-11-30', 12*(y-2024)));

    v_id := v_id + 1;
    INSERT INTO temporada VALUES
      (v_id, 'Alta diciembre ' || y, y, 'ALTA', ADD_MONTHS(DATE '2024-12-01', 12*(y-2024)),
       ADD_MONTHS(DATE '2024-12-31', 12*(y-2024)));
  END LOOP;
END;
/

/*---------------------------------------------------------------------
  6. TARIFAS: una por cada combinación HABITACION x TEMPORADA.
---------------------------------------------------------------------*/
INSERT INTO tarifa (
  id_tarifa, id_habitacion, id_temporada, precio_noche
)
SELECT
  ROW_NUMBER() OVER (ORDER BY h.id_habitacion, t.id_temporada) AS id_tarifa,
  h.id_habitacion,
  t.id_temporada,
  ROUND(
    (
      CASE ta.id_tipo_alojamiento
        WHEN 1 THEN 170000 + h.capacidad_maxima * 22000
        WHEN 2 THEN 120000 + h.capacidad_maxima * 18000
        WHEN 3 THEN 210000 + h.capacidad_maxima * 26000
        ELSE 100000 + h.capacidad_maxima * 15000
      END
      * CASE t.tipo_temporada
          WHEN 'ALTA'  THEN 1.25
          WHEN 'MEDIA' THEN 1.05
          ELSE 0.90
        END
    ) + DBMS_RANDOM.VALUE(-15000, 15000)
  , -2)
FROM habitacion h
JOIN alojamiento ta ON ta.id_alojamiento = h.id_alojamiento
CROSS JOIN temporada t;

/*---------------------------------------------------------------------
  7. CLIENTES: 3.000, con ciudades de origen variadas.
---------------------------------------------------------------------*/
DECLARE
  TYPE t_nombres IS TABLE OF VARCHAR2(40) INDEX BY PLS_INTEGER;
  TYPE t_apellidos IS TABLE OF VARCHAR2(40) INDEX BY PLS_INTEGER;
  v_n t_nombres;
  v_a t_apellidos;
  v_ciudad VARCHAR2(80);
BEGIN
  v_n(1):='Juan'; v_n(2):='María'; v_n(3):='Carlos'; v_n(4):='Laura'; v_n(5):='Andrés';
  v_n(6):='Valentina'; v_n(7):='Santiago'; v_n(8):='Camila'; v_n(9):='Daniel'; v_n(10):='Natalia';
  v_n(11):='Sebastián'; v_n(12):='Paula'; v_n(13):='Mateo'; v_n(14):='Sara'; v_n(15):='Nicolás';
  v_n(16):='Alejandra'; v_n(17):='David'; v_n(18):='Juliana'; v_n(19):='Felipe'; v_n(20):='Manuela';

  v_a(1):='Gómez'; v_a(2):='Rodríguez'; v_a(3):='Martínez'; v_a(4):='López'; v_a(5):='García';
  v_a(6):='Pérez'; v_a(7):='Sánchez'; v_a(8):='Ramírez'; v_a(9):='Torres'; v_a(10):='Vargas';
  v_a(11):='Rojas'; v_a(12):='Moreno'; v_a(13):='Díaz'; v_a(14):='Castro'; v_a(15):='Suárez';
  v_a(16):='Navarro'; v_a(17):='Mendoza'; v_a(18):='Jiménez'; v_a(19):='Restrepo'; v_a(20):='Cardona';

  FOR i IN 1..3000 LOOP
    v_ciudad := CASE MOD(i, 20)
      WHEN 0 THEN 'Bogotá D.C.'
      WHEN 1 THEN 'Armenia'
      WHEN 2 THEN 'Medellín'
      WHEN 3 THEN 'Cali'
      WHEN 4 THEN 'Pereira'
      WHEN 5 THEN 'Manizales'
      WHEN 6 THEN 'Ibagué'
      WHEN 7 THEN 'Cartagena'
      WHEN 8 THEN 'Barranquilla'
      WHEN 9 THEN 'Santa Marta'
      WHEN 10 THEN 'Bucaramanga'
      WHEN 11 THEN 'Villavicencio'
      WHEN 12 THEN 'Neiva'
      WHEN 13 THEN 'Popayán'
      WHEN 14 THEN 'Tunja'
      WHEN 15 THEN 'Pasto'
      WHEN 16 THEN 'Bogotá D.C.'
      WHEN 17 THEN 'Cartago'
      WHEN 18 THEN 'Tuluá'
      ELSE 'Dosquebradas'
    END;

    INSERT INTO cliente (
      id_cliente, nombre_completo, documento_identidad,
      correo, telefono, ciudad_origen
    ) VALUES (
      i,
      v_n(MOD(i-1,20)+1) || ' ' || v_a(MOD(TRUNC((i-1)/20),20)+1),
      'CC' || LPAD(900000000 + i, 10, '0'),
      'cliente' || LPAD(i,4,'0') || '@correo.com',
      '31' || LPAD(10000000 + i * 37, 8, '0'),
      v_ciudad
    );
  END LOOP;
END;
/

/*---------------------------------------------------------------------
  8. RESERVAS + RESERVA_HABITACION.

  25.000 reservas se reparten durante 2024-2026 con más volumen en
  enero, abril, junio, julio, agosto y diciembre para representar la
  estacionalidad turística indicada en el enunciado.

  Se lleva un control de disponibilidad por habitación en memoria para
  evitar solapamientos durante la carga inicial.
  Aproximadamente 1 de cada 5 reservas contiene una segunda habitación.
---------------------------------------------------------------------*/
DECLARE
  TYPE t_num_array IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  TYPE t_date_array IS TABLE OF DATE INDEX BY PLS_INTEGER;

  v_capacidad       t_num_array;
  v_alojamiento     t_num_array;
  v_disponible      t_date_array;
  v_room_count      NUMBER := 0;
  v_cursor_room     NUMBER := 1;
  v_room            NUMBER;
  v_room_2          NUMBER;
  v_huespedes       NUMBER;
  v_mes_inicio      DATE;
  v_mes_fin         DATE;
  v_dias_mes        NUMBER;
  v_num_reservas_mes NUMBER;
  v_checkin         DATE;
  v_checkout        DATE;
  v_estado          VARCHAR2(15);
  v_reserva_id      NUMBER := 0;
  v_linea_id        NUMBER := 0;
  v_meses_altos     BOOLEAN;
  v_found            BOOLEAN;
  v_stay_days       NUMBER;
BEGIN
  FOR r IN (SELECT id_habitacion, id_alojamiento, capacidad_maxima FROM habitacion ORDER BY id_habitacion) LOOP
    v_room_count := v_room_count + 1;
    v_capacidad(v_room_count) := r.capacidad_maxima;
    v_alojamiento(v_room_count) := r.id_alojamiento;
    v_disponible(v_room_count) := DATE '2024-01-01';
  END LOOP;

  FOR m IN 0..35 LOOP
    v_mes_inicio := ADD_MONTHS(DATE '2024-01-01', m);
    v_mes_fin := LAST_DAY(v_mes_inicio);
    v_dias_mes := v_mes_fin - v_mes_inicio + 1;
    v_meses_altos := MOD(EXTRACT(MONTH FROM v_mes_inicio), 12) IN (1,4,6,7,8,12);

    IF v_meses_altos THEN
      v_num_reservas_mes := 926;
    ELSE
      v_num_reservas_mes := 463;
    END IF;

    /* Ajuste exacto para llegar a 25.000 reservas. */
    IF m = 1 THEN
      v_num_reservas_mes := 461;
    END IF;

    FOR j IN 1..v_num_reservas_mes LOOP
      v_reserva_id := v_reserva_id + 1;
      v_checkin := v_mes_inicio + MOD(j * 17 + m * 13, v_dias_mes);
      v_stay_days := 2 + MOD(v_reserva_id * 5, 4);
      v_checkout := v_checkin + v_stay_days;

      IF v_checkout < DATE '2026-07-01' THEN
        IF DBMS_RANDOM.VALUE(0,1) < 0.12 THEN
          v_estado := 'CANCELADA';
        ELSE
          v_estado := 'COMPLETADA';
        END IF;
      ELSIF v_checkin >= DATE '2026-10-01' THEN
        IF DBMS_RANDOM.VALUE(0,1) < 0.10 THEN
          v_estado := 'CANCELADA';
        ELSIF DBMS_RANDOM.VALUE(0,1) < 0.25 THEN
          v_estado := 'PENDIENTE';
        ELSE
          v_estado := 'CONFIRMADA';
        END IF;
      ELSE
        IF DBMS_RANDOM.VALUE(0,1) < 0.08 THEN
          v_estado := 'CANCELADA';
        ELSE
          v_estado := 'COMPLETADA';
        END IF;
      END IF;

      INSERT INTO reserva (
        id_reserva, id_cliente, fecha_check_in, fecha_check_out,
        estado, fecha_creacion
      ) VALUES (
        v_reserva_id,
        MOD(v_reserva_id - 1, 3000) + 1,
        v_checkin,
        v_checkout,
        v_estado,
        v_checkin - (5 + MOD(v_reserva_id * 3, 45))
      );

      /* Primera habitación: se busca disponibilidad y capacidad. */
      v_huespedes := 1 + MOD(v_reserva_id, 5);
      v_found := FALSE;

      FOR paso IN 0..v_room_count-1 LOOP
        v_room := MOD(v_cursor_room - 1 + paso, v_room_count) + 1;
        IF v_disponible(v_room) <= v_checkin AND v_capacidad(v_room) >= v_huespedes THEN
          v_found := TRUE;
          EXIT;
        END IF;
      END LOOP;

      IF NOT v_found THEN
        RAISE_APPLICATION_ERROR(-20001, 'No se encontró habitación disponible para la reserva ' || v_reserva_id);
      END IF;

      v_linea_id := v_linea_id + 1;
      INSERT INTO reserva_habitacion (
        id_reserva_habitacion, id_reserva, id_habitacion,
        fecha_check_in, fecha_check_out, numero_huespedes
      ) VALUES (
        v_linea_id, v_reserva_id, v_room,
        v_checkin, v_checkout, v_huespedes
      );
      v_disponible(v_room) := v_checkout;
      v_cursor_room := MOD(v_room, v_room_count) + 1;

      /* Segunda habitación en aproximadamente 20% de las reservas. */
      IF MOD(v_reserva_id, 5) = 0 THEN
        v_found := FALSE;
        FOR paso IN 0..v_room_count-1 LOOP
          v_room_2 := MOD(v_room - 1 + paso + 1, v_room_count) + 1;
          IF v_alojamiento(v_room_2) = v_alojamiento(v_room)
             AND v_room_2 <> v_room
             AND v_disponible(v_room_2) <= v_checkin
             AND v_capacidad(v_room_2) >= LEAST(v_huespedes, v_capacidad(v_room_2)) THEN
            v_found := TRUE;
            EXIT;
          END IF;
        END LOOP;

        IF v_found THEN
          v_linea_id := v_linea_id + 1;
          INSERT INTO reserva_habitacion (
            id_reserva_habitacion, id_reserva, id_habitacion,
            fecha_check_in, fecha_check_out, numero_huespedes
          ) VALUES (
            v_linea_id, v_reserva_id, v_room_2,
            v_checkin, v_checkout, LEAST(v_huespedes, v_capacidad(v_room_2))
          );
          v_disponible(v_room_2) := v_checkout;
        END IF;
      END IF;
    END LOOP;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Reservas generadas: ' || v_reserva_id);
  DBMS_OUTPUT.PUT_LINE('Líneas RESERVA_HABITACION generadas: ' || v_linea_id);
END;
/

/*---------------------------------------------------------------------
  9. SERVICIOS: 60, uno por cada alojamiento, superando el mínimo de 30.
---------------------------------------------------------------------*/
INSERT INTO servicio (
  id_servicio, id_alojamiento, nombre, descripcion, precio, activo
)
SELECT
  a.id_alojamiento,
  a.id_alojamiento,
  CASE MOD(a.id_alojamiento - 1, 10)
    WHEN 0 THEN 'Desayuno campesino'
    WHEN 1 THEN 'Tour guiado cafetero'
    WHEN 2 THEN 'Transporte al aeropuerto'
    WHEN 3 THEN 'Alquiler de bicicletas'
    WHEN 4 THEN 'Spa y relajación'
    WHEN 5 THEN 'Caminata ecológica'
    WHEN 6 THEN 'Cata de café'
    WHEN 7 THEN 'Cena de pareja'
    WHEN 8 THEN 'Senderismo con guía'
    ELSE 'Fogata nocturna'
  END,
  'Servicio complementario propio de ' || a.nombre_comercial,
  ROUND(50000 + DBMS_RANDOM.VALUE(0, 180000), -2),
  'S'
FROM alojamiento a;

/*---------------------------------------------------------------------
  10. RESERVA_SERVICIO: 40.000 líneas.
      Cada servicio pertenece al mismo alojamiento de la primera
      habitación de la reserva, respetando la regla del negocio.
---------------------------------------------------------------------*/
INSERT INTO reserva_servicio (
  id_reserva_servicio, id_reserva, id_servicio,
  fecha_servicio, cantidad, precio_unitario
)
SELECT
  g.n,
  r.id_reserva,
  s.id_servicio,
  r.fecha_check_in + FLOOR((g.n - 1) / 25000),
  1 + MOD(g.n, 3),
  s.precio
FROM (
  SELECT LEVEL n FROM dual CONNECT BY LEVEL <= 40000
) g
JOIN reserva r
  ON r.id_reserva = MOD(g.n - 1, 25000) + 1
JOIN (
  SELECT id_reserva, MIN(id_reserva_habitacion) id_rh
  FROM reserva_habitacion
  GROUP BY id_reserva
) pr
  ON pr.id_reserva = r.id_reserva
JOIN reserva_habitacion rh
  ON rh.id_reserva_habitacion = pr.id_rh
JOIN habitacion h
  ON h.id_habitacion = rh.id_habitacion
JOIN servicio s
  ON s.id_alojamiento = h.id_alojamiento
WHERE r.fecha_check_in + FLOOR((g.n - 1) / 25000) < r.fecha_check_out;

/*---------------------------------------------------------------------
  11. PAGOS: al menos uno por reserva y un segundo abono cada 5 reservas.
---------------------------------------------------------------------*/
DECLARE
  v_pago_id NUMBER := 0;
  v_monto   NUMBER;
  v_estado  VARCHAR2(15);
  v_metodo  VARCHAR2(25);
BEGIN
  FOR r IN (SELECT id_reserva, fecha_check_in, estado FROM reserva ORDER BY id_reserva) LOOP
    v_pago_id := v_pago_id + 1;

    v_monto := ROUND(80000 + DBMS_RANDOM.VALUE(0, 900000), -2);
    v_metodo := CASE MOD(v_pago_id - 1, 5)
      WHEN 0 THEN 'TARJETA_CREDITO'
      WHEN 1 THEN 'TARJETA_DEBITO'
      WHEN 2 THEN 'PSE'
      WHEN 3 THEN 'TRANSFERENCIA'
      ELSE 'EFECTIVO'
    END;

    IF r.estado = 'CANCELADA' THEN
      v_estado := CASE WHEN MOD(r.id_reserva, 2) = 0 THEN 'REEMBOLSADO' ELSE 'FALLIDO' END;
    ELSIF r.estado = 'PENDIENTE' THEN
      v_estado := CASE WHEN MOD(r.id_reserva, 3) = 0 THEN 'PENDIENTE' ELSE 'EXITOSO' END;
    ELSE
      v_estado := CASE WHEN MOD(r.id_reserva, 11) = 0 THEN 'PENDIENTE' ELSE 'EXITOSO' END;
    END IF;

    INSERT INTO pago (
      id_pago, id_reserva, fecha_pago, monto, metodo, estado
    ) VALUES (
      v_pago_id,
      r.id_reserva,
      r.fecha_check_in - (1 + MOD(r.id_reserva, 20)),
      v_monto,
      v_metodo,
      v_estado
    );

    IF MOD(r.id_reserva, 5) = 0 THEN
      v_pago_id := v_pago_id + 1;
      INSERT INTO pago (
        id_pago, id_reserva, fecha_pago, monto, metodo, estado
      ) VALUES (
        v_pago_id,
        r.id_reserva,
        r.fecha_check_in - (MOD(r.id_reserva, 5)),
        ROUND(v_monto * 0.55, -2),
        'TRANSFERENCIA',
        CASE WHEN v_estado = 'EXITOSO' THEN 'EXITOSO' ELSE 'PENDIENTE' END
      );
    END IF;
  END LOOP;
END;
/

/*---------------------------------------------------------------------
  12. RESEÑAS: >= 40% de reservas completadas.
      Se usa una reseña por cliente + alojamiento. Solo se toman
      reservas COMPLETADAS, nunca canceladas o pendientes.
---------------------------------------------------------------------*/
DECLARE
  v_completadas NUMBER;
  v_objetivo    NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_completadas
  FROM reserva
  WHERE estado = 'COMPLETADA';

  v_objetivo := CEIL(v_completadas * 0.45);

  INSERT INTO resena (
    id_resena, id_cliente, id_alojamiento, id_reserva,
    calificacion, comentario, fecha_resena
  )
  WITH base AS (
    SELECT r.id_reserva, r.id_cliente, a.id_alojamiento,
           r.fecha_check_out
    FROM reserva r
    JOIN (
      SELECT id_reserva, MIN(id_reserva_habitacion) id_rh
      FROM reserva_habitacion
      GROUP BY id_reserva
    ) pr ON pr.id_reserva = r.id_reserva
    JOIN reserva_habitacion rh ON rh.id_reserva_habitacion = pr.id_rh
    JOIN habitacion h ON h.id_habitacion = rh.id_habitacion
    JOIN alojamiento a ON a.id_alojamiento = h.id_alojamiento
    WHERE r.estado = 'COMPLETADA'
  ), unicas AS (
    SELECT id_reserva, id_cliente, id_alojamiento, fecha_check_out
    FROM (
      SELECT b.*,
             ROW_NUMBER() OVER (
               PARTITION BY id_cliente, id_alojamiento
               ORDER BY id_reserva
             ) rn_unica
      FROM base b
    )
    WHERE rn_unica = 1
  ), limitadas AS (
    SELECT ROW_NUMBER() OVER (ORDER BY id_reserva) seq_num,
           id_reserva, id_cliente, id_alojamiento, fecha_check_out
    FROM unicas
  )
  SELECT
    seq_num,
    id_cliente,
    id_alojamiento,
    id_reserva,
    MOD(id_reserva, 5) + 1,
    CASE MOD(id_reserva, 5)
      WHEN 0 THEN 'Excelente experiencia y muy buen servicio.'
      WHEN 1 THEN 'La estadía fue cómoda y cumplió las expectativas.'
      WHEN 2 THEN 'Buena atención y ubicación agradable.'
      WHEN 3 THEN 'Experiencia positiva, con algunos detalles por mejorar.'
      ELSE 'Servicio aceptable y ambiente tranquilo.'
    END,
    fecha_check_out + 2
  FROM limitadas
  WHERE seq_num <= v_objetivo;

  DBMS_OUTPUT.PUT_LINE('Reservas completadas: ' || v_completadas);
  DBMS_OUTPUT.PUT_LINE('Reseñas objetivo (45%): ' || v_objetivo);
END;
/

/*---------------------------------------------------------------------
  13. USUARIOS DEL SISTEMA: 2 administradores + 8 encargados.
      Los encargados cubren los 4 tipos de alojamiento (2 por tipo).
---------------------------------------------------------------------*/
INSERT ALL
  INTO usuario_sistema (id_usuario, nombre_usuario, rol, id_alojamiento, activo)
    VALUES (1, 'admin_general', 'ADMINISTRADOR', NULL, 'S')
  INTO usuario_sistema (id_usuario, nombre_usuario, rol, id_alojamiento, activo)
    VALUES (2, 'admin_reportes', 'ADMINISTRADOR', NULL, 'S')
  INTO usuario_sistema (id_usuario, nombre_usuario, rol, id_alojamiento, activo)
    VALUES (3, 'encargado_finca_01', 'ENCARGADO', 1, 'S')
  INTO usuario_sistema (id_usuario, nombre_usuario, rol, id_alojamiento, activo)
    VALUES (4, 'encargado_hotel_02', 'ENCARGADO', 2, 'S')
  INTO usuario_sistema (id_usuario, nombre_usuario, rol, id_alojamiento, activo)
    VALUES (5, 'encargado_glamping_03', 'ENCARGADO', 3, 'S')
  INTO usuario_sistema (id_usuario, nombre_usuario, rol, id_alojamiento, activo)
    VALUES (6, 'encargado_hostal_04', 'ENCARGADO', 4, 'S')
  INTO usuario_sistema (id_usuario, nombre_usuario, rol, id_alojamiento, activo)
    VALUES (7, 'encargado_finca_05', 'ENCARGADO', 5, 'S')
  INTO usuario_sistema (id_usuario, nombre_usuario, rol, id_alojamiento, activo)
    VALUES (8, 'encargado_hotel_06', 'ENCARGADO', 6, 'S')
  INTO usuario_sistema (id_usuario, nombre_usuario, rol, id_alojamiento, activo)
    VALUES (9, 'encargado_glamping_07', 'ENCARGADO', 7, 'S')
  INTO usuario_sistema (id_usuario, nombre_usuario, rol, id_alojamiento, activo)
    VALUES (10, 'encargado_hostal_08', 'ENCARGADO', 8, 'S')
SELECT 1 FROM dual;

COMMIT;

/*---------------------------------------------------------------------
  14. Verificación de volumen. Estos SELECT permiten dejar evidencia.
---------------------------------------------------------------------*/
SELECT 'MUNICIPIO' tabla, COUNT(*) filas FROM municipio
UNION ALL SELECT 'TIPO_ALOJAMIENTO', COUNT(*) FROM tipo_alojamiento
UNION ALL SELECT 'ALOJAMIENTO', COUNT(*) FROM alojamiento
UNION ALL SELECT 'HABITACION', COUNT(*) FROM habitacion
UNION ALL SELECT 'TEMPORADA', COUNT(*) FROM temporada
UNION ALL SELECT 'TARIFA', COUNT(*) FROM tarifa
UNION ALL SELECT 'CLIENTE', COUNT(*) FROM cliente
UNION ALL SELECT 'RESERVA', COUNT(*) FROM reserva
UNION ALL SELECT 'RESERVA_HABITACION', COUNT(*) FROM reserva_habitacion
UNION ALL SELECT 'PAGO', COUNT(*) FROM pago
UNION ALL SELECT 'SERVICIO', COUNT(*) FROM servicio
UNION ALL SELECT 'RESERVA_SERVICIO', COUNT(*) FROM reserva_servicio
UNION ALL SELECT 'RESENA', COUNT(*) FROM resena
UNION ALL SELECT 'USUARIO_SISTEMA', COUNT(*) FROM usuario_sistema
ORDER BY tabla;

/* Asimetría de alojamientos por municipio. */
SELECT m.nombre AS municipio, COUNT(a.id_alojamiento) AS alojamientos
FROM municipio m
LEFT JOIN alojamiento a ON a.id_municipio = m.id_municipio
GROUP BY m.nombre
ORDER BY alojamientos DESC;

/* Asimetría de habitaciones por alojamiento. */
SELECT a.nombre_comercial, ta.nombre AS tipo, COUNT(h.id_habitacion) AS habitaciones
FROM alojamiento a
JOIN tipo_alojamiento ta ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
LEFT JOIN habitacion h ON h.id_alojamiento = a.id_alojamiento
GROUP BY a.nombre_comercial, ta.nombre
ORDER BY habitaciones DESC, a.nombre_comercial;

PROMPT ================================================================
PROMPT TurismoUQ - carga finalizada.
PROMPT ================================================================
