TURISMOUQ - ENTREGA 1
Bases de Datos II - Oracle XE 21c

ARCHIVOS
--------
01_TurismoUQ_DDL.sql
    Crea las 14 tablas, PK, FK, CHECK, NOT NULL, UNIQUE y comentarios.

02_TurismoUQ_Carga.sql
    Genera la carga mínima/superior a la mínima con PL/SQL + DBMS_RANDOM.
    Incluye verificación final de volúmenes y asimetría.

03_TurismoUQ_Consultas.sql
    Contiene las 7 consultas obligatorias, numeradas y comentadas.

Entrega1_TurismoUQ_Documentacion.docx
    Documento para Word/PDF con MER, cardinalidades, reglas de negocio y las
    dos decisiones de diseño.

MER_TurismoUQ.png
    Imagen del MER para usar como apoyo o como referencia al acomodar el modelo
    en Oracle SQL Developer Data Modeler.

ORDEN DE EJECUCION
------------------
1. Abrir una hoja SQL en SQL Developer conectada al esquema de trabajo.
2. Ejecutar 01_TurismoUQ_DDL.sql.
3. Ejecutar 02_TurismoUQ_Carga.sql.
4. Revisar al final los conteos y la distribución desigual de municipios y habitaciones.
5. Ejecutar 03_TurismoUQ_Consultas.sql.
6. Guardar capturas de las siete consultas para la evidencia.

DATA MODELER
-----------
Opcion A (desde el DDL):
File > Import > DDL File > seleccionar 01_TurismoUQ_DDL.sql.

Opcion B (desde el esquema real):
Ejecutar primero el DDL en Oracle y luego:
File > Import > Data Dictionary > seleccionar la conexion y el esquema.

Despues de importar, acomodar el diagrama, mostrar las cardinalidades y exportar
la imagen para el documento final.

DECISIONES IMPORTANTES
----------------------
1. RESERVA_HABITACION resuelve la reserva de varias habitaciones dentro de una
   misma reserva y permite fechas propias por cada linea.

2. TEMPORADA + TARIFA resuelven una estadia que cruza temporadas. La tarifa se
   guarda por noche y por combinacion habitacion-temporada; en Entrega 2,
   fn_valor_estadia sumara noche por noche.

NOTA SOBRE TEMPORADAS
---------------------
Se usan 21 periodos (7 por año, 2024-2026) en lugar de solo los 6 mínimos,
porque la guía también exige reservas entre 2024 y 2026 y así quedan cubiertas
las fechas usadas para análisis de ingresos.

NOTA SOBRE SERVICIOS
--------------------
Se generan 60 servicios, uno por alojamiento, aunque el mínimo solicitado es 30.
Esto permite que los servicios de las reservas pertenezcan al mismo alojamiento
que las habitaciones reservadas.
