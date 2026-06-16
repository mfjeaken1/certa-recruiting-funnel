--
-- PostgreSQL database dump
--

\restrict atByfljIzheEt38z8MpyHS5I079oMUkGcwc9BuOkscnVQvA7rbUIUFZU89nRnLe

-- Dumped from database version 16.14 (Debian 16.14-1.pgdg13+1)
-- Dumped by pg_dump version 16.14 (Debian 16.14-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bedarfskarte; Type: TABLE; Schema: pga7yket86jj0rl; Owner: certa
--

CREATE TABLE pga7yket86jj0rl.bedarfskarte (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    created_by character varying,
    updated_by character varying,
    nc_order numeric,
    __nc_deleted boolean,
    nc_row_meta jsonb,
    plz_bereich text,
    region text,
    bedarf_status text,
    aktuelle_obs_ bigint,
    gesucht_zusaetzlich bigint,
    notizen text
);


ALTER TABLE pga7yket86jj0rl.bedarfskarte OWNER TO certa;

--
-- Name: bedarfskarte_id_seq; Type: SEQUENCE; Schema: pga7yket86jj0rl; Owner: certa
--

CREATE SEQUENCE pga7yket86jj0rl.bedarfskarte_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pga7yket86jj0rl.bedarfskarte_id_seq OWNER TO certa;

--
-- Name: bedarfskarte_id_seq; Type: SEQUENCE OWNED BY; Schema: pga7yket86jj0rl; Owner: certa
--

ALTER SEQUENCE pga7yket86jj0rl.bedarfskarte_id_seq OWNED BY pga7yket86jj0rl.bedarfskarte.id;


--
-- Name: bewerbungen; Type: TABLE; Schema: pga7yket86jj0rl; Owner: certa
--

CREATE TABLE pga7yket86jj0rl.bewerbungen (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    created_by character varying,
    updated_by character varying,
    nc_order numeric,
    __nc_deleted boolean,
    nc_row_meta jsonb,
    externe_id text,
    name text,
    email text,
    telefon text,
    wohnort text,
    plz_wohnort text,
    abgedeckte_plz text,
    max_fahrtweg_km bigint,
    berufserfahrung_jahre bigint,
    vorheriger_beruf text,
    verfuegbarkeit_stunden_pro_woche bigint,
    iso_zertifizierung boolean DEFAULT false,
    fuehrerschein boolean DEFAULT false,
    kurzmotivation text,
    status_ text,
    score_ bigint,
    ki_empfehlung text,
    ki_begruendung text,
    fehlende_felder text,
    manuelle_entscheidung text,
    im_pool boolean DEFAULT false,
    eingegangen_am timestamp without time zone,
    letzte_aktion timestamp without time zone,
    historie text,
    status__c4k6d8zsc0f6447_backup_vzp7ac text,
    eingegangen_am_cvxa31ak0ye7xbi_backup_bn4xak date,
    letzte_aktion_cw3sfqnbu2sonjf_backup_yfzijo date,
    manuelle_entscheidung_czifcuc9xnpseaz_backup_jstogw text
);


ALTER TABLE pga7yket86jj0rl.bewerbungen OWNER TO certa;

--
-- Name: bewerbungen_id_seq; Type: SEQUENCE; Schema: pga7yket86jj0rl; Owner: certa
--

CREATE SEQUENCE pga7yket86jj0rl.bewerbungen_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pga7yket86jj0rl.bewerbungen_id_seq OWNER TO certa;

--
-- Name: bewerbungen_id_seq; Type: SEQUENCE OWNED BY; Schema: pga7yket86jj0rl; Owner: certa
--

ALTER SEQUENCE pga7yket86jj0rl.bewerbungen_id_seq OWNED BY pga7yket86jj0rl.bewerbungen.id;


--
-- Name: bedarfskarte id; Type: DEFAULT; Schema: pga7yket86jj0rl; Owner: certa
--

ALTER TABLE ONLY pga7yket86jj0rl.bedarfskarte ALTER COLUMN id SET DEFAULT nextval('pga7yket86jj0rl.bedarfskarte_id_seq'::regclass);


--
-- Name: bewerbungen id; Type: DEFAULT; Schema: pga7yket86jj0rl; Owner: certa
--

ALTER TABLE ONLY pga7yket86jj0rl.bewerbungen ALTER COLUMN id SET DEFAULT nextval('pga7yket86jj0rl.bewerbungen_id_seq'::regclass);


--
-- Name: bedarfskarte bedarfskarte_pkey; Type: CONSTRAINT; Schema: pga7yket86jj0rl; Owner: certa
--

ALTER TABLE ONLY pga7yket86jj0rl.bedarfskarte
    ADD CONSTRAINT bedarfskarte_pkey PRIMARY KEY (id);


--
-- Name: bewerbungen bewerbungen_pkey; Type: CONSTRAINT; Schema: pga7yket86jj0rl; Owner: certa
--

ALTER TABLE ONLY pga7yket86jj0rl.bewerbungen
    ADD CONSTRAINT bewerbungen_pkey PRIMARY KEY (id);


--
-- Name: bedarfskarte_deleted_idx; Type: INDEX; Schema: pga7yket86jj0rl; Owner: certa
--

CREATE INDEX bedarfskarte_deleted_idx ON pga7yket86jj0rl.bedarfskarte USING btree (__nc_deleted);


--
-- Name: bedarfskarte_order_idx; Type: INDEX; Schema: pga7yket86jj0rl; Owner: certa
--

CREATE INDEX bedarfskarte_order_idx ON pga7yket86jj0rl.bedarfskarte USING btree (nc_order);


--
-- Name: bewerbungen_deleted_idx; Type: INDEX; Schema: pga7yket86jj0rl; Owner: certa
--

CREATE INDEX bewerbungen_deleted_idx ON pga7yket86jj0rl.bewerbungen USING btree (__nc_deleted);


--
-- Name: bewerbungen_order_idx; Type: INDEX; Schema: pga7yket86jj0rl; Owner: certa
--

CREATE INDEX bewerbungen_order_idx ON pga7yket86jj0rl.bewerbungen USING btree (nc_order);


--
-- PostgreSQL database dump complete
--

\unrestrict atByfljIzheEt38z8MpyHS5I079oMUkGcwc9BuOkscnVQvA7rbUIUFZU89nRnLe

