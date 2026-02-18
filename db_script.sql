
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
