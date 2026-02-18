
--- esta es la tabla que el sistema propio ya usa para cuando llegan las transmiciones de los dispositivos

CREATE TABLE gis_gps
(
  gps_gid numeric NOT NULL DEFAULT nextval('gis_gps_gps_gid_seq1'::regclass),
  gps_id_dispositivo character varying(20),
  gps_vehiculo character varying(20) NOT NULL,
  gps_fecha date NOT NULL,
  gps_hora time without time zone NOT NULL,
  gps_status character varying(4),
  gps_speed real,
  gps_course real,
  gps_magn_variation real,
  gps_magn_var_direction character varying(4),
  gps_event character varying NOT NULL,
  gps_tstamp timestamp without time zone,
  gps_ubicacion character varying,
  gps_latitud double precision,
  gps_longitud double precision,
  the_geom geometry,
  gps_send_event integer DEFAULT 0,
  gps_ban_ubic boolean DEFAULT false,
  gps_odometer numeric,
  gps_fecha_server timestamp without time zone DEFAULT now(),
  gps_distancia_pp numeric DEFAULT 0,
  gps_distancia_pp_total numeric,
  gps_voltage numeric,
  gps_val_set_cod boolean DEFAULT false,
  gps_data_io character varying,
  gps_ubicacion_zon_code character varying,
  gps_ignition boolean
)
WITH (
  OIDS=TRUE
);


-- Table: public.data_rndc

-- DROP TABLE public.data_rndc;

CREATE TABLE public.data_rndc
(
    id integer NOT NULL DEFAULT nextval('rndc_data_id_seq'::regclass),
    ingresoidmanifiesto character varying(25),
    numnitempresatransporte character varying(25),
    fechaexpedicionmanifiesto date,
    numplaca character varying(25),
    ingresoidremesa character varying(25),
    codmunicipiocargueremesa character varying(25),
    direccioncargueremesa character varying(120),
    codmunicipiodescargueremesa character varying(25),
    direcciondescargueremesa character varying(120),
    fechacitacargue timestamp without time zone,
    horacitacargue character varying(25),
    fechacitadescargue timestamp without time zone,
    horacitadescargue character varying(25),
    latitudcargue character varying(25),
    longitudcargue character varying(25),
    latituddescargue character varying(25),
    longituddescargue character varying(25),
    estado character varying DEFAULT 'NUEVO'::character varying,
    server_date timestamp without time zone DEFAULT now(),
    veh_placa character varying,
    id_cargue character varying,
    id_descargue character varying,
    entrada_cargue timestamp with time zone,
    salida_cargue timestamp with time zone,
    entrada_descargue timestamp with time zone,
    CONSTRAINT rndc_data_pk PRIMARY KEY (id),
    CONSTRAINT rndc_data_uk UNIQUE (ingresoidmanifiesto)

)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.data_rndc
    OWNER to postgres;


-- Table: public.data_rndc_auth

-- DROP TABLE public.data_rndc_auth;

CREATE TABLE public.data_rndc_auth
(
  id integer NOT NULL DEFAULT nextval('rndc_auth_id_seq'::regclass),
  username character varying(45),
  password character varying(45),
  nit character varying(15),
  emails text,
  state boolean,
  group_id integer,
  CONSTRAINT rndc_auth_pk PRIMARY KEY (id),
  CONSTRAINT rndc_auth_uk UNIQUE (username)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.data_rndc_auth
    OWNER to postgres;

-- insert con datos validos
INSERT INTO data_rndc_auth (id, username, password, nit, emails, state, group_id) VALUES (1, 'GEINSYS@6040', 'Wt123456', '9010471411', 'soporte@wt-sos.com', true, NULL);

-- Table: public.data_rndc_geofence

-- DROP TABLE public.data_rndc_geofence;

CREATE TABLE public.data_rndc_geofence
(
  rndc_geofence_id serial NOT NULL,
  rndc_geofence_movil character varying(20),
  rndc_geofence_type numeric(1,0),
  rndc_geofence_date date,
  rndc_geofence_time time without time zone,
  rndc_geofence_timestamp timestamp without time zone,
  rndc_geofence_lat double precision,
  rndc_geofence_lon double precision,
  rndc_geofence_server_date timestamp without time zone DEFAULT now(),
  rndc_geofence_state numeric(1,0) DEFAULT 0,
  CONSTRAINT data_rndc_geofence_pk PRIMARY KEY (rndc_geofence_id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.data_rndc_geofence
    OWNER to postgres;



-- Table: public.data_rndc_log para guardar log de las cosas que se envian y llegan

-- DROP TABLE public.data_rndc_log;

CREATE TABLE public.data_rndc_log
(
  id serial NOT NULL,
  message text,
  date timestamp with time zone DEFAULT now(),
  group_id numeric,
  ingresoidremesa character varying(25),
  CONSTRAINT pk_data_rndc_log PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.data_rndc_log
    OWNER to postgres;

-- =============================================
-- Trigger de evaluación automática desde gis_gps
-- =============================================
-- Este trigger evalúa si el móvil (placa) entra a zona de cargue o descargue
-- según la información sincronizada desde RNDC.

ALTER TABLE public.data_rndc
  ADD COLUMN IF NOT EXISTS salida_descargue timestamp with time zone;

CREATE OR REPLACE FUNCTION public.fn_rndc_haversine_m(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
)
RETURNS double precision
LANGUAGE plpgsql
AS $$
DECLARE
  r double precision := 6371000;
  dlat double precision;
  dlon double precision;
  a double precision;
  c double precision;
BEGIN
  IF lat1 IS NULL OR lon1 IS NULL OR lat2 IS NULL OR lon2 IS NULL THEN
    RETURN NULL;
  END IF;

  dlat := radians(lat2 - lat1);
  dlon := radians(lon2 - lon1);

  a := sin(dlat / 2) * sin(dlat / 2)
       + cos(radians(lat1)) * cos(radians(lat2))
       * sin(dlon / 2) * sin(dlon / 2);
  c := 2 * atan2(sqrt(a), sqrt(1 - a));

  RETURN r * c;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_rndc_eval_from_gps()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  rec record;
  dist_cargue double precision;
  dist_descargue double precision;
  dist_umbral_m double precision := 250;
BEGIN
  FOR rec IN
    SELECT d.*
    FROM data_rndc d
    WHERE d.numplaca = NEW.gps_vehiculo
      AND d.estado IN ('NUEVO', 'EN_CARGUE', 'EN_RUTA', 'EN_DESCARGUE')
    ORDER BY d.server_date DESC
    LIMIT 20
  LOOP
    dist_cargue := public.fn_rndc_haversine_m(
      NEW.gps_latitud,
      NEW.gps_longitud,
      NULLIF(rec.latitudcargue, '')::double precision,
      NULLIF(rec.longitudcargue, '')::double precision
    );

    dist_descargue := public.fn_rndc_haversine_m(
      NEW.gps_latitud,
      NEW.gps_longitud,
      NULLIF(rec.latituddescargue, '')::double precision,
      NULLIF(rec.longituddescargue, '')::double precision
    );

    IF rec.entrada_cargue IS NULL AND dist_cargue IS NOT NULL AND dist_cargue <= dist_umbral_m THEN
      UPDATE data_rndc
      SET entrada_cargue = NEW.gps_tstamp,
          estado = 'EN_CARGUE',
          veh_placa = NEW.gps_vehiculo
      WHERE id = rec.id;

      INSERT INTO data_rndc_log(message, group_id, ingresoidremesa)
      VALUES (
        format('Entrada a cargue detectada para placa %s, manifiesto %s, distancia %.2f m', NEW.gps_vehiculo, rec.ingresoidmanifiesto, dist_cargue),
        1,
        rec.ingresoidremesa
      );
    END IF;

    IF rec.entrada_cargue IS NOT NULL AND rec.salida_cargue IS NULL AND dist_cargue IS NOT NULL AND dist_cargue > dist_umbral_m THEN
      UPDATE data_rndc
      SET salida_cargue = NEW.gps_tstamp,
          estado = 'EN_RUTA',
          veh_placa = NEW.gps_vehiculo
      WHERE id = rec.id;

      INSERT INTO data_rndc_log(message, group_id, ingresoidremesa)
      VALUES (
        format('Salida de cargue detectada para placa %s, manifiesto %s', NEW.gps_vehiculo, rec.ingresoidmanifiesto),
        1,
        rec.ingresoidremesa
      );
    END IF;

    IF rec.salida_cargue IS NOT NULL AND rec.entrada_descargue IS NULL AND dist_descargue IS NOT NULL AND dist_descargue <= dist_umbral_m THEN
      UPDATE data_rndc
      SET entrada_descargue = NEW.gps_tstamp,
          estado = 'EN_DESCARGUE',
          veh_placa = NEW.gps_vehiculo
      WHERE id = rec.id;

      INSERT INTO data_rndc_log(message, group_id, ingresoidremesa)
      VALUES (
        format('Entrada a descargue detectada para placa %s, manifiesto %s, distancia %.2f m', NEW.gps_vehiculo, rec.ingresoidmanifiesto, dist_descargue),
        1,
        rec.ingresoidremesa
      );
    END IF;

    IF rec.entrada_descargue IS NOT NULL AND rec.salida_descargue IS NULL AND dist_descargue IS NOT NULL AND dist_descargue > dist_umbral_m THEN
      UPDATE data_rndc
      SET salida_descargue = NEW.gps_tstamp,
          estado = 'FINALIZADO',
          veh_placa = NEW.gps_vehiculo
      WHERE id = rec.id;

      INSERT INTO data_rndc_log(message, group_id, ingresoidremesa)
      VALUES (
        format('Salida de descargue y finalización detectada para placa %s, manifiesto %s', NEW.gps_vehiculo, rec.ingresoidmanifiesto),
        1,
        rec.ingresoidremesa
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_rndc_eval_from_gps ON public.gis_gps;

CREATE TRIGGER trg_rndc_eval_from_gps
AFTER INSERT ON public.gis_gps
FOR EACH ROW
EXECUTE PROCEDURE public.fn_rndc_eval_from_gps();
