--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.5
-- Dumped by pg_dump version 9.5.5

-- Started on 2017-03-06 09:57:09

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 1 (class 3079 OID 12355)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

-- CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2354 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

-- COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- TOC entry 228 (class 1255 OID 32781)
-- Name: datediff(character varying, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: sinergi
--

CREATE FUNCTION datediff(units character varying, start_t timestamp without time zone, end_t timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$

DECLARE

    diff_interval INTERVAL; 

    diff INT = 0;

    years_diff INT = 0;

BEGIN

    IF units IN ('yy', 'yyyy', 'year', 'mm', 'm', 'month') THEN

        years_diff = DATE_PART('year', end_t) - DATE_PART('year', start_t);

        IF units IN ('yy', 'yyyy', 'year') THEN

            RETURN years_diff;

        ELSE

            RETURN years_diff * 12 + (DATE_PART('month', end_t) - DATE_PART('month', start_t)); 

        END IF;

    END IF;

    diff_interval = end_t - start_t;

    diff = diff + DATE_PART('day', diff_interval);

    IF units IN ('wk', 'ww', 'week') THEN

        diff = diff/7;

        RETURN diff;

    END IF;

    IF units IN ('dd', 'd', 'day') THEN

        RETURN diff;

    END IF;

    diff = diff * 24 + DATE_PART('hour', diff_interval);

    IF units IN ('hh', 'hour') THEN

        RETURN diff;

    END IF;

    diff = diff * 60 + DATE_PART('minute', diff_interval);

    IF units IN ('mi', 'n', 'minute') THEN

        RETURN diff;

    END IF;

    diff = diff * 60 + DATE_PART('second', diff_interval);

     RETURN diff;

END;

$$;


ALTER FUNCTION public.datediff(units character varying, start_t timestamp without time zone, end_t timestamp without time zone) OWNER TO sinergi;

--
-- TOC entry 229 (class 1255 OID 32782)
-- Name: datedifftime(character varying, time without time zone, time without time zone); Type: FUNCTION; Schema: public; Owner: sinergi
--

CREATE FUNCTION datedifftime(units character varying, start_t time without time zone, end_t time without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$

DECLARE

    diff_interval INTERVAL; 

    diff INT = 0;

BEGIN

    diff_interval = end_t - start_t;

    diff = DATE_PART('hour', diff_interval);

    IF units IN ('hh', 'hour') THEN

        RETURN diff;

    END IF;

    diff = diff * 60 + DATE_PART('minute', diff_interval);

    IF units IN ('mi', 'n', 'minute') THEN

        RETURN diff;

    END IF;

    diff = diff * 60 + DATE_PART('second', diff_interval);

    RETURN diff;

END;

$$;


ALTER FUNCTION public.datedifftime(units character varying, start_t time without time zone, end_t time without time zone) OWNER TO sinergi;

--
-- TOC entry 230 (class 1255 OID 32783)
-- Name: run_hour_node(integer, date); Type: FUNCTION; Schema: public; Owner: sinergi
--

CREATE FUNCTION run_hour_node(_node_id integer, _ddate date) RETURNS real
    LANGUAGE plpgsql
    AS $$

    DECLARE 

        _run_time REAL = 0;

        _data RECORD;

        _start TIMESTAMP;

        _stop TIMESTAMP;

        _curr_status SMALLINT;

        _old_status SMALLINT;

    BEGIN

        IF NOT EXISTS(SELECT id FROM running_hour WHERE node_id = _node_id AND ddate = _ddate) THEN

            INSERT INTO running_hour(node_id, ddate) VALUES (_node_id, _ddate);

        END IF;

        _curr_status := 0;

        _old_status  := 0;

        _start := NULL;

        _stop  := NULL;

        FOR _data IN SELECT * FROM data_log WHERE node_id = _node_id AND dtime::DATE = _ddate ORDER BY dtime ASC LOOP 

            _curr_status := _data.genset_status;

            IF _curr_status = 1 AND _start IS NULL THEN 

                _start := _data.dtime;

            END IF;

            IF _curr_status = 0 AND _old_status = 1 THEN

                _stop := _data.dtime;

                _run_time := _run_time + DATEDIFF('second', _start, _stop);

                _start := NULL;

                _stop  := NULL; 

            END IF;

            _old_status  := _curr_status;

        END LOOP;

        SELECT dtime INTO _stop

        FROM data_log

        WHERE node_id = _node_id 

        AND dtime::DATE = _ddate ORDER BY dtime DESC 

        LIMIT 1;

        IF _start != _stop THEN

            _run_time := _run_time + DATEDIFF('second', _start, _stop);

        END IF;

        _run_time := _run_time / 3600;

        UPDATE running_hour 

        SET val = _run_time

        WHERE node_id = _node_id 

        AND ddate = _ddate;

        RETURN _run_time;

    END;

    $$;


ALTER FUNCTION public.run_hour_node(_node_id integer, _ddate date) OWNER TO sinergi;

--
-- TOC entry 231 (class 1255 OID 32784)
-- Name: trg_alarm_delete(); Type: FUNCTION; Schema: public; Owner: sinergi
--

CREATE FUNCTION trg_alarm_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    DECLARE 

        -- Trigger alarm delete log

        -- 

        -- Author : Asep Maryana

        -- Email  : maryana@hariff.com

        -- Website: www.asepmaryana.net

        -- Created: 29 Sept 2016 12:00 WIB

    BEGIN

        UPDATE alarm_log SET dtime_end = now() WHERE id = old.id;

        RETURN OLD;

    END;

    $$;


ALTER FUNCTION public.trg_alarm_delete() OWNER TO sinergi;

--
-- TOC entry 232 (class 1255 OID 32785)
-- Name: trg_alarm_insert(); Type: FUNCTION; Schema: public; Owner: sinergi
--

CREATE FUNCTION trg_alarm_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

    DECLARE 

        -- Trigger alarm log

        -- 

        -- Author : Asep Maryana

        -- Email  : maryana@hariff.com

        -- Website: www.asepmaryana.net

        -- Created: 29 Sept 2016 12:00 WIB

    BEGIN

        INSERT INTO alarm_log (id,node_id,dtime,alarm_list_id,alarm_label,severity_id) 

        VALUES (new.id,new.node_id,new.dtime,new.alarm_list_id,new.alarm_label,new.severity_id);

        RETURN NEW;

    END;

    $$;


ALTER FUNCTION public.trg_alarm_insert() OWNER TO sinergi;

--
-- TOC entry 233 (class 1255 OID 32786)
-- Name: trg_node_update(); Type: FUNCTION; Schema: public; Owner: sinergi
--

CREATE FUNCTION trg_node_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE 

        -- Trigger data log

        -- 

        -- Author : Asep Maryana

        -- Email  : maryana@hariff.com

        -- Website: www.asepmaryana.net

        -- Created: 29 Sept 2016 12:00 WIB

        _alarm_list_id      INT;

        _alarm_name         VARCHAR(50);

        _alarm_severity_id  INT;

    BEGIN

        IF new.updated_at <> old.updated_at AND new.updated_at IS NOT NULL THEN 

            INSERT INTO data_log (node_id,dtime,genset_vr,genset_vs,genset_vt,genset_cr,genset_cs,genset_ct,batt_volt,batt_curr,genset_batt_volt,genset_status,recti_status,breaker_status,genset_fail,low_fuel,recti_fail,batt_low,cdc_mode) 

            VALUES (new.id,new.updated_at,new.genset_vr,new.genset_vs,new.genset_vt,new.genset_cr,new.genset_cs,new.genset_ct,new.batt_volt,new.batt_curr,new.genset_batt_volt,new.genset_status,new.recti_status,new.breaker_status,new.genset_fail,new.low_fuel,new.recti_fail,new.batt_low,new.cdc_mode);

        END IF;

        IF new.genset_fail <> old.genset_fail THEN

            _alarm_list_id  := 1;

            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;

            IF new.genset_fail = 1 THEN

                INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 

                VALUES (new.id,now(),_alarm_list_id,_alarm_name,_alarm_severity_id);

            ELSE

                DELETE FROM alarm_temp WHERE node_id=new.id AND alarm_list_id=_alarm_list_id;

            END IF;

        END IF;

        IF new.low_fuel <> old.low_fuel THEN

            _alarm_list_id  := 2;

            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;

            IF new.low_fuel = 1 THEN

                INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 

                VALUES (new.id,now(),_alarm_list_id,_alarm_name,_alarm_severity_id);

            ELSE

                DELETE FROM alarm_temp WHERE node_id=new.id AND alarm_list_id=_alarm_list_id;

            END IF;

        END IF;

        IF new.recti_fail <> old.recti_fail THEN

            _alarm_list_id  := 3;

            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;

            IF new.recti_fail = 1 THEN

                INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 

                VALUES (new.id,now(),_alarm_list_id,_alarm_name,_alarm_severity_id);

            ELSE

                DELETE FROM alarm_temp WHERE node_id=new.id AND alarm_list_id=_alarm_list_id;

            END IF;

        END IF;

        IF new.batt_low <> old.batt_low THEN

            _alarm_list_id  := 4;

            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;

            IF new.batt_low = 1 THEN

                INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 

                VALUES (new.id,now(),_alarm_list_id,_alarm_name,_alarm_severity_id);

            ELSE

                DELETE FROM alarm_temp WHERE node_id=new.id AND alarm_list_id=_alarm_list_id;

            END IF;

        END IF;

        IF new.genset_status <> old.genset_status THEN

            PERFORM run_hour_node(new.id, new.updated_at::DATE);

        END IF;

        RETURN NEW;

    END;

    $$;


ALTER FUNCTION public.trg_node_update() OWNER TO sinergi;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 181 (class 1259 OID 32787)
-- Name: alarm_list; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE alarm_list (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    severity_id integer
);


ALTER TABLE alarm_list OWNER TO sinergi;

--
-- TOC entry 182 (class 1259 OID 32790)
-- Name: alarm_list_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE alarm_list_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE alarm_list_id_seq OWNER TO sinergi;

--
-- TOC entry 2355 (class 0 OID 0)
-- Dependencies: 182
-- Name: alarm_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE alarm_list_id_seq OWNED BY alarm_list.id;


--
-- TOC entry 183 (class 1259 OID 32792)
-- Name: alarm_log; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE alarm_log (
    id bigint NOT NULL,
    node_id integer NOT NULL,
    dtime timestamp without time zone NOT NULL,
    dtime_end timestamp without time zone,
    alarm_list_id integer NOT NULL,
    alarm_label character varying(50),
    severity_id integer
);


ALTER TABLE alarm_log OWNER TO sinergi;

--
-- TOC entry 184 (class 1259 OID 32795)
-- Name: node; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE node (
    id integer NOT NULL,
    phone character varying(20) NOT NULL,
    name character varying(50),
    subnet_id integer,
    customer_id integer,
    genset_vr numeric,
    genset_vs numeric,
    genset_vt numeric,
    genset_cr numeric,
    genset_cs numeric,
    genset_ct numeric,
    batt_volt numeric,
    batt_curr numeric,
    genset_batt_volt numeric,
    genset_status smallint DEFAULT 0,
    recti_status smallint DEFAULT 0,
    genset_fail smallint DEFAULT 0,
    low_fuel smallint DEFAULT 0,
    recti_fail smallint DEFAULT 0,
    batt_low smallint DEFAULT 0,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    latitude numeric,
    longitude numeric,
    cdc_mode smallint DEFAULT 0,
    breaker_status smallint DEFAULT 0
);


ALTER TABLE node OWNER TO sinergi;

--
-- TOC entry 185 (class 1259 OID 32809)
-- Name: severity; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE severity (
    id integer NOT NULL,
    name character varying(10),
    color character varying(7)
);


ALTER TABLE severity OWNER TO sinergi;

--
-- TOC entry 186 (class 1259 OID 32812)
-- Name: subnet; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE subnet (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    parent_id integer,
    customer_id integer
);


ALTER TABLE subnet OWNER TO sinergi;

--
-- TOC entry 187 (class 1259 OID 32815)
-- Name: alarm_log_view; Type: VIEW; Schema: public; Owner: sinergi
--

CREATE VIEW alarm_log_view AS
 SELECT alt.id,
    alt.node_id,
    alt.dtime,
    alt.dtime_end,
    alt.alarm_list_id,
    alt.alarm_label,
    alt.severity_id,
    als.name AS severity,
    node.name AS site,
    node.phone,
    subnet.name AS area,
    ( SELECT subnet_1.id
           FROM subnet subnet_1
          WHERE (subnet_1.id = ( SELECT subnet_2.parent_id
                   FROM subnet subnet_2
                  WHERE (subnet_2.id = ( SELECT node_1.subnet_id
                           FROM node node_1
                          WHERE (node_1.id = alt.node_id)))))) AS region_id,
    ( SELECT subnet_1.name
           FROM subnet subnet_1
          WHERE (subnet_1.id = ( SELECT subnet_2.parent_id
                   FROM subnet subnet_2
                  WHERE (subnet_2.id = ( SELECT node_1.subnet_id
                           FROM node node_1
                          WHERE (node_1.id = alt.node_id)))))) AS region,
    to_char(alt.dtime, 'DD-MON-YY HH24:MI'::text) AS ddtime,
    to_char(alt.dtime_end, 'DD-MON-YY HH24:MI'::text) AS ddtime_end
   FROM ((((alarm_log alt
     LEFT JOIN node ON ((alt.node_id = node.id)))
     LEFT JOIN subnet ON ((node.subnet_id = subnet.id)))
     LEFT JOIN alarm_list al ON ((alt.alarm_list_id = al.id)))
     LEFT JOIN severity als ON ((alt.severity_id = als.id)));


ALTER TABLE alarm_log_view OWNER TO sinergi;

--
-- TOC entry 188 (class 1259 OID 32820)
-- Name: alarm_temp; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE alarm_temp (
    id bigint NOT NULL,
    node_id integer NOT NULL,
    dtime timestamp without time zone NOT NULL,
    alarm_list_id integer NOT NULL,
    alarm_label character varying(50),
    severity_id integer
);


ALTER TABLE alarm_temp OWNER TO sinergi;

--
-- TOC entry 189 (class 1259 OID 32823)
-- Name: alarm_temp_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE alarm_temp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE alarm_temp_id_seq OWNER TO sinergi;

--
-- TOC entry 2356 (class 0 OID 0)
-- Dependencies: 189
-- Name: alarm_temp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE alarm_temp_id_seq OWNED BY alarm_temp.id;


--
-- TOC entry 190 (class 1259 OID 32825)
-- Name: alarm_temp_view; Type: VIEW; Schema: public; Owner: sinergi
--

CREATE VIEW alarm_temp_view AS
 SELECT alt.id,
    alt.node_id,
    alt.dtime,
    alt.alarm_list_id,
    alt.alarm_label,
    alt.severity_id,
    als.name AS severity,
    node.name AS site,
    node.subnet_id,
    node.phone,
    subnet.name AS area,
    ( SELECT subnet_1.id
           FROM subnet subnet_1
          WHERE (subnet_1.id = ( SELECT subnet_2.parent_id
                   FROM subnet subnet_2
                  WHERE (subnet_2.id = ( SELECT node_1.subnet_id
                           FROM node node_1
                          WHERE (node_1.id = alt.node_id)))))) AS region_id,
    ( SELECT subnet_1.name
           FROM subnet subnet_1
          WHERE (subnet_1.id = ( SELECT subnet_2.parent_id
                   FROM subnet subnet_2
                  WHERE (subnet_2.id = ( SELECT node_1.subnet_id
                           FROM node node_1
                          WHERE (node_1.id = alt.node_id)))))) AS region,
    to_char(alt.dtime, 'DD-MON-YY HH24:MI'::text) AS ddtime
   FROM ((((alarm_temp alt
     LEFT JOIN node ON ((alt.node_id = node.id)))
     LEFT JOIN subnet ON ((node.subnet_id = subnet.id)))
     LEFT JOIN alarm_list al ON ((alt.alarm_list_id = al.id)))
     LEFT JOIN severity als ON ((alt.severity_id = als.id)));


ALTER TABLE alarm_temp_view OWNER TO sinergi;

--
-- TOC entry 191 (class 1259 OID 32830)
-- Name: area_view; Type: VIEW; Schema: public; Owner: sinergi
--

CREATE VIEW area_view AS
 SELECT area.id,
    area.name,
    area.parent_id,
    area.customer_id,
    region.name AS region
   FROM (subnet area
     LEFT JOIN subnet region ON ((area.parent_id = region.id)))
  WHERE (area.parent_id IN ( SELECT subnet.id
           FROM subnet
          WHERE (subnet.parent_id IS NULL)));


ALTER TABLE area_view OWNER TO sinergi;

--
-- TOC entry 192 (class 1259 OID 32834)
-- Name: customer; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE customer (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    phone character varying(20),
    email character varying(100)
);


ALTER TABLE customer OWNER TO sinergi;

--
-- TOC entry 193 (class 1259 OID 32837)
-- Name: customer_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE customer_id_seq OWNER TO sinergi;

--
-- TOC entry 2357 (class 0 OID 0)
-- Dependencies: 193
-- Name: customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE customer_id_seq OWNED BY customer.id;


--
-- TOC entry 194 (class 1259 OID 32839)
-- Name: data_log; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE data_log (
    id bigint NOT NULL,
    node_id integer NOT NULL,
    dtime timestamp without time zone NOT NULL,
    genset_vr numeric,
    genset_vs numeric,
    genset_vt numeric,
    genset_cr numeric,
    genset_cs numeric,
    genset_ct numeric,
    batt_volt numeric,
    batt_curr numeric,
    genset_batt_volt numeric,
    genset_status smallint DEFAULT 0,
    recti_status smallint DEFAULT 0,
    breaker_status smallint DEFAULT 0,
    genset_fail smallint DEFAULT 0,
    low_fuel smallint DEFAULT 0,
    recti_fail smallint DEFAULT 0,
    batt_low smallint DEFAULT 0,
    cdc_mode smallint DEFAULT 0
);


ALTER TABLE data_log OWNER TO sinergi;

--
-- TOC entry 195 (class 1259 OID 32853)
-- Name: data_log_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE data_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE data_log_id_seq OWNER TO sinergi;

--
-- TOC entry 2358 (class 0 OID 0)
-- Dependencies: 195
-- Name: data_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE data_log_id_seq OWNED BY data_log.id;


--
-- TOC entry 196 (class 1259 OID 32855)
-- Name: site_view; Type: VIEW; Schema: public; Owner: sinergi
--

CREATE VIEW site_view AS
 SELECT site.id,
    site.name,
    site.parent_id,
    site.customer_id,
    area.id AS area_id,
    area.name AS area,
    region.id AS region_id,
    region.name AS region
   FROM ((subnet site
     LEFT JOIN subnet area ON ((site.parent_id = area.id)))
     LEFT JOIN subnet region ON ((area.parent_id = region.id)))
  WHERE (site.parent_id IN ( SELECT subnet.id
           FROM subnet
          WHERE (subnet.parent_id IN ( SELECT subnet_1.id
                   FROM subnet subnet_1
                  WHERE (subnet_1.parent_id IS NULL)))));


ALTER TABLE site_view OWNER TO sinergi;

--
-- TOC entry 197 (class 1259 OID 32860)
-- Name: node_view; Type: VIEW; Schema: public; Owner: sinergi
--

CREATE VIEW node_view AS
 SELECT node.id,
    node.phone,
    node.name,
    node.subnet_id,
    node.customer_id,
    node.genset_vr,
    node.genset_vs,
    node.genset_vt,
    node.genset_cr,
    node.genset_cs,
    node.genset_ct,
    node.batt_volt,
    node.batt_curr,
    node.genset_batt_volt,
    node.genset_status,
    node.recti_status,
    node.genset_fail,
    node.low_fuel,
    node.recti_fail,
    node.batt_low,
    node.created_at,
    node.updated_at,
    node.latitude,
    node.longitude,
    node.cdc_mode,
    node.breaker_status,
    site.name AS site,
    site.area_id,
    site.area,
    site.region_id,
    site.region,
    cust.name AS customer
   FROM ((node
     LEFT JOIN site_view site ON ((node.subnet_id = site.id)))
     LEFT JOIN customer cust ON ((node.customer_id = cust.id)));


ALTER TABLE node_view OWNER TO sinergi;

--
-- TOC entry 198 (class 1259 OID 32865)
-- Name: data_log_view; Type: VIEW; Schema: public; Owner: sinergi
--

CREATE VIEW data_log_view AS
 SELECT p.id,
    p.node_id,
    p.dtime,
    p.genset_vr,
    p.genset_vs,
    p.genset_vt,
    p.genset_cr,
    p.genset_cs,
    p.genset_ct,
    p.batt_volt,
    p.batt_curr,
    p.genset_batt_volt,
    p.genset_status,
    p.recti_status,
    p.breaker_status,
    p.genset_fail,
    p.low_fuel,
    p.recti_fail,
    p.batt_low,
    p.cdc_mode,
    n.name,
    n.site,
    to_char(p.dtime, 'DD-MON-YY HH24:MI'::text) AS ddtime,
    to_char(p.dtime, 'Month DD, YYYY HH24:MI:SS'::text) AS jsdate
   FROM (data_log p
     LEFT JOIN node_view n ON ((p.node_id = n.id)));


ALTER TABLE data_log_view OWNER TO sinergi;

--
-- TOC entry 199 (class 1259 OID 32870)
-- Name: inbox; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE inbox (
    id bigint NOT NULL,
    sender character varying(16),
    message_date timestamp without time zone,
    receive_date timestamp without time zone,
    text character varying(1000),
    request_id character varying(12),
    gateway_id character varying(30),
    message_type character(1),
    encoding character(1) DEFAULT '7'::bpchar
);


ALTER TABLE inbox OWNER TO sinergi;

--
-- TOC entry 200 (class 1259 OID 32877)
-- Name: inbox_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE inbox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inbox_id_seq OWNER TO sinergi;

--
-- TOC entry 2359 (class 0 OID 0)
-- Dependencies: 200
-- Name: inbox_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE inbox_id_seq OWNED BY inbox.id;


--
-- TOC entry 201 (class 1259 OID 32879)
-- Name: modem; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE modem (
    id integer NOT NULL,
    name character varying(30),
    phone character varying(20),
    port character varying(30),
    baud_rate integer DEFAULT 19200,
    pin character varying(4) DEFAULT '0000'::character varying,
    brand character varying(30),
    model character varying(20),
    enabled boolean DEFAULT true
);


ALTER TABLE modem OWNER TO sinergi;

--
-- TOC entry 202 (class 1259 OID 32885)
-- Name: modem_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE modem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE modem_id_seq OWNER TO sinergi;

--
-- TOC entry 2360 (class 0 OID 0)
-- Dependencies: 202
-- Name: modem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE modem_id_seq OWNED BY modem.id;


--
-- TOC entry 203 (class 1259 OID 32887)
-- Name: node_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE node_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE node_id_seq OWNER TO sinergi;

--
-- TOC entry 2361 (class 0 OID 0)
-- Dependencies: 203
-- Name: node_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE node_id_seq OWNED BY node.id;


--
-- TOC entry 204 (class 1259 OID 32889)
-- Name: outbox; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE outbox (
    id bigint NOT NULL,
    recipient character varying(16),
    text character varying(1000),
    create_date timestamp without time zone,
    sent_date timestamp without time zone,
    reply_date timestamp without time zone,
    reply_text character varying(1000),
    request_id character varying(12),
    status character(1) DEFAULT 'U'::bpchar,
    gateway_id character varying(30),
    message_type character(1) DEFAULT 'G'::bpchar
);


ALTER TABLE outbox OWNER TO sinergi;

--
-- TOC entry 205 (class 1259 OID 32897)
-- Name: outbox_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE outbox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE outbox_id_seq OWNER TO sinergi;

--
-- TOC entry 2362 (class 0 OID 0)
-- Dependencies: 205
-- Name: outbox_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE outbox_id_seq OWNED BY outbox.id;


--
-- TOC entry 206 (class 1259 OID 32899)
-- Name: region_view; Type: VIEW; Schema: public; Owner: sinergi
--

CREATE VIEW region_view AS
 SELECT subnet.id,
    subnet.name,
    subnet.parent_id,
    subnet.customer_id
   FROM subnet
  WHERE (subnet.parent_id IS NULL);


ALTER TABLE region_view OWNER TO sinergi;

--
-- TOC entry 207 (class 1259 OID 32903)
-- Name: role; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE role (
    id integer NOT NULL,
    name character varying(20)
);


ALTER TABLE role OWNER TO sinergi;

--
-- TOC entry 208 (class 1259 OID 32906)
-- Name: role_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE role_id_seq OWNER TO sinergi;

--
-- TOC entry 2363 (class 0 OID 0)
-- Dependencies: 208
-- Name: role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE role_id_seq OWNED BY role.id;


--
-- TOC entry 209 (class 1259 OID 32908)
-- Name: running_hour; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE running_hour (
    id bigint NOT NULL,
    node_id integer NOT NULL,
    ddate date NOT NULL,
    val real DEFAULT 0 NOT NULL
);


ALTER TABLE running_hour OWNER TO sinergi;

--
-- TOC entry 210 (class 1259 OID 32912)
-- Name: running_hour_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE running_hour_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE running_hour_id_seq OWNER TO sinergi;

--
-- TOC entry 2364 (class 0 OID 0)
-- Dependencies: 210
-- Name: running_hour_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE running_hour_id_seq OWNED BY running_hour.id;


--
-- TOC entry 211 (class 1259 OID 32914)
-- Name: severity_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE severity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE severity_id_seq OWNER TO sinergi;

--
-- TOC entry 2365 (class 0 OID 0)
-- Dependencies: 211
-- Name: severity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE severity_id_seq OWNED BY severity.id;


--
-- TOC entry 212 (class 1259 OID 32916)
-- Name: subnet_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE subnet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE subnet_id_seq OWNER TO sinergi;

--
-- TOC entry 2366 (class 0 OID 0)
-- Dependencies: 212
-- Name: subnet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE subnet_id_seq OWNED BY subnet.id;


--
-- TOC entry 213 (class 1259 OID 32918)
-- Name: test; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE test (
    id uuid NOT NULL,
    name character varying(20),
    val real
);


ALTER TABLE test OWNER TO sinergi;

--
-- TOC entry 214 (class 1259 OID 32921)
-- Name: users; Type: TABLE; Schema: public; Owner: sinergi
--

CREATE TABLE users (
    id integer NOT NULL,
    username character varying(30),
    password character varying(100),
    name character varying(100),
    role_id integer,
    customer_id integer
);


ALTER TABLE users OWNER TO sinergi;

--
-- TOC entry 215 (class 1259 OID 32924)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: sinergi
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO sinergi;

--
-- TOC entry 2367 (class 0 OID 0)
-- Dependencies: 215
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sinergi
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- TOC entry 2099 (class 2604 OID 32926)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_list ALTER COLUMN id SET DEFAULT nextval('alarm_list_id_seq'::regclass);


--
-- TOC entry 2111 (class 2604 OID 32927)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_temp ALTER COLUMN id SET DEFAULT nextval('alarm_temp_id_seq'::regclass);


--
-- TOC entry 2112 (class 2604 OID 32928)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY customer ALTER COLUMN id SET DEFAULT nextval('customer_id_seq'::regclass);


--
-- TOC entry 2113 (class 2604 OID 32929)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY data_log ALTER COLUMN id SET DEFAULT nextval('data_log_id_seq'::regclass);


--
-- TOC entry 2122 (class 2604 OID 32930)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY inbox ALTER COLUMN id SET DEFAULT nextval('inbox_id_seq'::regclass);


--
-- TOC entry 2124 (class 2604 OID 32931)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY modem ALTER COLUMN id SET DEFAULT nextval('modem_id_seq'::regclass);


--
-- TOC entry 2100 (class 2604 OID 32932)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY node ALTER COLUMN id SET DEFAULT nextval('node_id_seq'::regclass);


--
-- TOC entry 2128 (class 2604 OID 32933)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY outbox ALTER COLUMN id SET DEFAULT nextval('outbox_id_seq'::regclass);


--
-- TOC entry 2131 (class 2604 OID 32934)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY role ALTER COLUMN id SET DEFAULT nextval('role_id_seq'::regclass);


--
-- TOC entry 2132 (class 2604 OID 32935)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY running_hour ALTER COLUMN id SET DEFAULT nextval('running_hour_id_seq'::regclass);


--
-- TOC entry 2109 (class 2604 OID 32936)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY severity ALTER COLUMN id SET DEFAULT nextval('severity_id_seq'::regclass);


--
-- TOC entry 2110 (class 2604 OID 32937)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY subnet ALTER COLUMN id SET DEFAULT nextval('subnet_id_seq'::regclass);


--
-- TOC entry 2134 (class 2604 OID 32938)
-- Name: id; Type: DEFAULT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- TOC entry 2319 (class 0 OID 32787)
-- Dependencies: 181
-- Data for Name: alarm_list; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY alarm_list (id, name, severity_id) FROM stdin;
1	Genset Fail	1
2	Low Fuel	2
3	Rectifier Fail	1
4	Low Battery	2
\.


--
-- TOC entry 2368 (class 0 OID 0)
-- Dependencies: 182
-- Name: alarm_list_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('alarm_list_id_seq', 4, true);


--
-- TOC entry 2321 (class 0 OID 32792)
-- Dependencies: 183
-- Data for Name: alarm_log; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY alarm_log (id, node_id, dtime, dtime_end, alarm_list_id, alarm_label, severity_id) FROM stdin;
1	1	2016-09-29 00:30:04.846	2016-09-29 00:56:54.76	2	Low Fuel	2
3	1	2016-09-29 00:30:04.846	2016-09-29 00:57:21.613	3	Rectifier Fail	1
4	1	2016-09-29 00:30:04.846	2016-09-29 01:15:34.28	4	Low Battery	2
5	1	2016-09-29 00:30:04.846	2016-09-29 02:31:17.422	2	Low Fuel	2
6	1	2016-09-29 01:14:58.208	2016-09-29 02:31:17.422	3	Rectifier Fail	1
7	1	2016-09-29 02:42:51.519	2016-09-29 03:00:53.38	4	Low Battery	2
8	1	2016-09-29 07:40:29.873	2016-09-29 07:41:05.192	3	Rectifier Fail	1
9	1	2016-09-29 07:41:05.192	2016-09-29 07:46:01.473	2	Low Fuel	2
10	1	2016-09-29 08:45:16.649	2016-10-06 10:35:53.666985	2	Low Fuel	2
11	2	2016-10-11 01:50:13.052145	2016-10-11 03:51:02.606733	3	Rectifier Fail	1
12	2	2016-10-11 03:52:17.974712	2016-10-11 03:52:28.425151	3	Rectifier Fail	1
13	2	2016-10-11 21:41:23.384333	2016-10-11 21:49:34.091396	3	Rectifier Fail	1
14	2	2016-10-11 22:06:38.935984	2016-10-11 22:07:37.269151	3	Rectifier Fail	1
15	2	2016-10-11 22:08:35.131903	2016-10-11 22:09:20.556057	3	Rectifier Fail	1
16	2	2016-10-11 22:10:23.919808	2016-10-11 22:19:36.76633	3	Rectifier Fail	1
17	2	2016-10-12 01:55:41.241716	2016-10-12 01:55:55.675728	2	Low Fuel	2
18	2	2016-10-12 02:30:50.856338	2016-10-12 02:34:36.457918	3	Rectifier Fail	1
19	2	2016-10-12 02:35:17.730668	2016-10-12 02:36:35.321466	3	Rectifier Fail	1
20	2	2016-10-12 02:38:57.631592	2016-10-12 02:42:27.953536	3	Rectifier Fail	1
21	2	2016-10-12 14:18:04.822633	2016-10-12 14:20:55.018842	3	Rectifier Fail	1
22	2	2016-10-13 11:25:20.849212	2016-10-13 12:18:23.153397	3	Rectifier Fail	1
23	2	2016-10-13 12:35:28.249927	2016-10-13 12:36:37.299001	3	Rectifier Fail	1
24	2	2016-10-13 14:17:10.5511	2016-10-13 14:22:06.241585	3	Rectifier Fail	1
25	2	2016-10-13 15:49:48.845876	2016-10-13 15:51:28.314605	3	Rectifier Fail	1
26	2	2016-10-13 17:28:40.813517	2016-10-13 17:29:37.976024	3	Rectifier Fail	1
27	2	2016-12-07 10:35:50.250291	2016-12-07 10:39:11.015075	3	Rectifier Fail	1
28	2	2016-12-07 10:39:22.205738	2016-12-07 10:40:15.91146	3	Rectifier Fail	1
30	2	2016-12-07 10:43:18.827839	2016-12-07 10:44:21.30937	3	Rectifier Fail	1
29	2	2016-12-07 10:40:14.914801	2016-12-07 17:34:32.395351	4	Low Battery	2
31	2	2016-12-07 17:34:33.579514	2016-12-07 17:34:34.376371	3	Rectifier Fail	1
33	2	2016-12-07 18:11:13.345663	2017-01-10 11:48:09.864349	1	Genset Fail	1
34	2	2016-12-07 18:11:41.632643	2017-01-10 11:48:41.578613	3	Rectifier Fail	1
35	2	2017-01-10 13:49:49.500634	2017-01-10 13:50:20.986399	3	Rectifier Fail	1
36	2	2017-01-10 13:51:56.081339	2017-01-10 13:53:56.591996	3	Rectifier Fail	1
37	2	2017-01-10 13:54:26.808095	2017-01-10 13:55:27.796406	3	Rectifier Fail	1
32	2	2016-12-07 18:10:40.321729	2017-01-11 14:20:10.33563	4	Low Battery	2
39	1	2017-02-22 14:50:38.19688	2017-02-22 14:54:08.638321	4	Low Battery	2
40	1	2017-02-22 15:09:10.257185	2017-02-22 15:23:11.913295	4	Low Battery	2
41	1	2017-02-22 15:42:45.108334	2017-02-22 15:50:46.250784	4	Low Battery	2
42	1	2017-02-22 16:26:53.535991	2017-02-22 16:43:56.440767	4	Low Battery	2
43	1	2017-02-22 16:48:58.211686	2017-02-22 16:53:59.248069	4	Low Battery	2
45	1	2017-02-22 17:04:25.410631	2017-02-22 17:13:02.590005	4	Low Battery	2
46	1	2017-02-22 18:19:04.168197	2017-02-22 18:20:11.658808	4	Low Battery	2
38	2	2017-01-11 14:20:10.33563	2017-02-23 12:39:17.173467	1	Genset Fail	1
47	2	2017-02-23 14:20:54.319435	2017-02-23 14:21:24.815173	4	Low Battery	2
48	1	2017-02-23 14:59:05.614248	2017-02-23 15:28:12.466653	4	Low Battery	2
49	1	2017-02-24 10:22:04.074527	2017-02-24 10:34:37.249561	4	Low Battery	2
50	1	2017-02-24 10:48:40.759912	2017-02-24 10:53:11.861548	4	Low Battery	2
51	1	2017-02-24 11:06:15.278543	2017-02-24 11:07:15.574562	4	Low Battery	2
52	1	2017-02-24 13:44:00.735301	2017-02-24 13:52:33.13204	4	Low Battery	2
53	1	2017-02-24 14:20:10.889916	2017-02-24 14:23:11.595506	4	Low Battery	2
54	1	2017-02-24 15:07:24.962743	2017-02-24 15:09:25.571355	4	Low Battery	2
\.


--
-- TOC entry 2325 (class 0 OID 32820)
-- Dependencies: 188
-- Data for Name: alarm_temp; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY alarm_temp (id, node_id, dtime, alarm_list_id, alarm_label, severity_id) FROM stdin;
\.


--
-- TOC entry 2369 (class 0 OID 0)
-- Dependencies: 189
-- Name: alarm_temp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('alarm_temp_id_seq', 54, true);


--
-- TOC entry 2327 (class 0 OID 32834)
-- Dependencies: 192
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY customer (id, name, phone, email) FROM stdin;
2	PT. XL Axiata	\N	\N
1	PT. Telkom Infra	\N	sales@telkominfra.com
\.


--
-- TOC entry 2370 (class 0 OID 0)
-- Dependencies: 193
-- Name: customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('customer_id_seq', 2, true);


--
-- TOC entry 2329 (class 0 OID 32839)
-- Dependencies: 194
-- Data for Name: data_log; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY data_log (id, node_id, dtime, genset_vr, genset_vs, genset_vt, genset_cr, genset_cs, genset_ct, batt_volt, batt_curr, genset_batt_volt, genset_status, recti_status, breaker_status, genset_fail, low_fuel, recti_fail, batt_low, cdc_mode) FROM stdin;
1	1	2016-09-28 16:51:20	220.21	221.02	219.48	2.32	3.3	3.23	48.21	3.45	20.34	0	0	1	0	0	0	0	1
2	1	2016-09-29 00:30:04.846	220.22	220.25	220.48	2.35	3.36	3.29	49.21	3.65	24.34	1	1	1	0	0	1	0	1
3	1	2016-09-29 07:08:49	0	0	0	0	0	0	49.5	0	11.4	0	0	0	0	0	0	0	1
4	1	2016-09-29 07:13:02	0	0	0	0	0	0	49.5	0	11.4	0	0	0	0	0	0	0	1
5	1	2016-09-29 07:18:02	0	0	0	0	0	0	49.5	0	11.4	0	0	0	0	0	0	0	1
7	1	2016-09-29 07:29:14	0	0	0	0	0	0	48.9	0	10.9	0	0	0	0	0	0	0	1
6	1	2016-09-29 07:20:07	0	0	0	0	0	0	49.5	0	11.4	0	0	0	0	0	0	0	1
8	1	2016-09-29 07:36:19	193	194.5	193.7	0	0	0	49.3	0	10.9	1	1	1	0	0	0	0	1
9	1	2016-09-29 07:36:27	198.7	200.1	201.2	0	0	0	49.6	0	10.9	1	1	1	0	0	0	0	1
10	1	2016-09-29 07:36:33	200.5	200.5	201.3	0	0	0	49.4	0	11	1	1	1	0	0	0	0	1
11	1	2016-09-29 07:36:41	199.4	200	199.5	0	0	0	49.3	0	10.7	1	1	1	0	0	0	0	1
12	1	2016-09-29 07:36:48	198.7	198.1	201.9	0	0	0	50	0	11	1	1	1	0	0	0	0	1
13	1	2016-09-29 07:36:54	198.9	199.4	199.3	0	0	0	49.6	0	10.6	1	1	1	0	0	0	0	1
14	1	2016-09-29 07:37:02	197.3	201.5	199.9	0	0	0	49.7	0	10.6	1	1	1	0	0	0	0	1
15	1	2016-09-29 07:37:17	198.8	197.9	199.7	0	0	0	49.7	0	10.9	1	1	1	0	0	0	0	1
16	1	2016-09-29 07:37:24	205.3	203.4	202.8	0	0	0	49.3	0	10.9	1	1	1	0	0	0	0	1
17	1	2016-09-29 07:37:31	200.1	198.7	199.3	0	0	0	49.4	0	10.7	1	1	1	0	0	0	0	1
18	1	2016-09-29 07:37:38	204.4	202.9	200.7	0	0	0	49.2	0	10.6	1	1	1	0	0	0	0	1
19	1	2016-09-29 07:37:44	200	198.5	200	0	0	0	49.4	0	11.5	1	1	1	0	0	0	0	1
20	1	2016-09-29 07:37:53	203.5	204	202.3	0	0	0	49.6	0	10.7	1	1	1	0	0	0	0	1
21	1	2016-09-29 07:38:00	198.1	198.3	198.2	0	0	0	49.3	0	10.6	1	1	1	0	0	0	0	1
22	1	2016-09-29 07:38:13	198.2	199.4	199	0	0	0	49.7	0	10.6	1	1	1	0	0	1	0	1
23	1	2016-09-29 07:38:22	198.6	199.9	201.3	0	0	0	49.2	0	10.9	1	1	1	0	0	1	0	1
24	1	2016-09-29 07:38:28	201.8	199.1	200.3	0	0	0	49.6	0	10.5	1	1	1	0	0	1	0	1
25	1	2016-09-29 07:38:34	207.3	20	197.1	0	0	0	49.8	0	10.9	1	1	1	0	0	1	0	1
26	1	2016-09-29 07:38:43	199.8	202.7	202.3	0	0	0	49.5	0	10.6	1	1	1	0	0	1	0	1
27	1	2016-09-29 07:38:49	199.6	195.6	200.5	0	0	0	49.5	0	10.7	1	1	1	0	1	0	0	1
28	1	2016-09-29 07:38:57	197.6	196.7	197.4	0	0	0	49.2	0	10.7	1	1	1	0	1	0	0	1
29	1	2016-09-29 07:39:03	206.4	202.6	203.1	0	0	0	49.3	0	10.8	1	1	1	0	1	0	0	1
30	1	2016-09-29 07:39:11	196.5	196.9	197.2	0	0	0	49.3	0	10.7	1	1	1	0	1	0	0	1
31	1	2016-09-29 07:39:18	200	199.3	197.4	0	0	0	49.4	0	11	1	1	1	0	1	0	0	1
32	1	2016-09-29 07:39:24	204.3	203.2	201.9	0	0	0	49.4	0	10.8	1	1	1	0	1	0	0	1
33	1	2016-09-29 07:39:32	198	197.1	197.6	0	0	0	49.3	0	10.7	1	1	1	0	1	0	0	1
34	1	2016-09-29 07:39:47	195.7	197.3	197.9	0	0	0	49.3	0	10.9	1	1	1	0	1	0	0	1
35	1	2016-09-29 07:39:53	198	200.4	19.1	0	0	0	49.3	0	10.8	1	1	1	0	1	0	0	1
36	1	2016-09-29 07:40:01	196.5	195.2	197.5	0	0	0	49.6	0	10.8	1	1	1	0	1	0	0	1
37	1	2016-09-29 07:40:08	195.9	198.2	196.4	0	0	0	49.8	0	10.8	1	1	1	0	1	0	0	1
38	1	2016-09-29 07:40:21	196.3	198.6	197.8	0	0	0	49.8	0	10.7	1	1	1	0	1	0	0	1
39	1	2016-09-29 07:40:28	200.9	200.1	200.4	0	0	0	49.6	0	10.5	1	1	1	0	1	0	0	1
40	1	2016-09-29 07:40:34	196.9	198.7	203.1	0	0	0	49.8	0	10.9	1	1	1	0	1	0	0	1
41	1	2016-09-29 07:40:49	195.5	196.6	197.6	0	0	0	49.5	0	10.8	1	1	1	0	1	0	0	1
42	1	2016-09-29 07:41:03	195.7	195.5	197	0	0	0	49.6	0	10.9	1	1	1	0	1	0	0	1
43	1	2016-09-29 07:41:11	197.1	196.1	199.2	0	0	0	49.3	0	11.2	1	1	1	0	1	0	0	1
44	1	2016-09-29 07:41:18	197	200	198.7	0	0	0	49.3	0	10.9	1	1	1	0	1	0	0	1
45	1	2016-09-29 07:41:32	196.9	197.3	197.4	0	0	0	49.7	0	10.7	1	1	1	0	1	0	0	1
46	1	2016-09-29 07:41:39	200.4	199.6	198.2	0	0	0	49.3	0	11	1	1	1	0	1	0	0	1
47	1	2016-09-29 07:41:47	198.2	196.3	197.7	0	0	0	49.4	0	11.2	1	1	1	0	1	0	0	1
48	1	2016-09-29 07:42:01	199.7	200.1	199.2	0	0	0	49.5	0	10.8	1	1	1	0	1	0	0	1
49	1	2016-09-29 07:42:08	198.9	200.8	202.4	0	0	0	49	0	10.6	1	1	1	0	1	0	0	1
50	1	2016-09-29 07:42:14	200.5	203.7	199.1	0	0	0	49	0	11	1	1	1	0	1	0	0	1
51	1	2016-09-29 07:42:22	200.5	203.7	199.1	0	0	0	49.8	0	10.8	1	1	1	0	1	0	0	1
52	1	2016-09-29 07:42:29	204.2	201.5	204.6	0	0	0	49.2	0	11	1	1	1	0	1	0	0	1
53	1	2016-09-29 07:42:58	195.2	195.6	195.7	0	0	0	49.5	0	11	1	1	1	0	1	0	0	1
54	1	2016-09-29 07:43:12	195.7	195.2	196.2	0	0	0	49.4	0	10.7	1	1	1	0	1	0	0	1
55	1	2016-09-29 07:43:27	195.2	192.5	194.1	0	0	0	49.4	0	10.5	1	1	1	0	1	0	0	1
58	1	2016-09-29 07:43:34	194.2	195.4	194.2	0	0	0	49.6	0	11.3	1	1	1	0	1	0	0	1
59	1	2016-09-29 07:43:41	196.7	195.1	194.9	0	0	0	49.5	0	11	1	1	1	0	0	0	0	1
60	1	2016-09-29 07:43:56	193.8	194.1	195.5	0	0	0	49.6	0	11	1	1	1	0	0	0	0	1
61	1	2016-09-29 07:44:02	197.9	195	196.2	0	0	0	49.6	0	1.3	1	1	1	0	0	0	0	1
62	1	2016-09-29 07:44:09	198.8	199.9	194.7	0	0	0	49.4	0	10.7	1	1	1	0	0	0	0	1
63	1	2016-09-29 07:44:17	193.4	192.2	193.9	0	0	0	49.4	0	10.8	1	1	1	0	0	0	0	1
64	1	2016-09-29 07:44:24	194.6	194.3	202.1	0	0	0	49.1	0	10.4	1	1	1	0	0	0	0	1
65	1	2016-09-29 07:44:38	198.4	200.4	196.8	0	0	0	49.4	0	11.3	1	1	1	0	0	0	0	1
66	1	2016-09-29 07:44:46	195.7	195.5	196.3	0	0	0	49.4	0	10.8	1	1	1	0	0	0	0	1
67	1	2016-09-29 07:44:53	201	195	197.6	0	0	0	49.1	0	10.9	1	1	1	0	0	0	0	1
68	1	2016-09-29 07:45:07	194.3	195	194.3	0	0	0	49.5	0	11	1	1	1	0	0	0	0	1
69	1	2016-09-29 07:45:19	196.7	201.6	199.2	0	0	0	49.7	0	11.3	1	1	1	0	0	0	0	1
70	1	2016-09-29 07:45:27	195.6	194.9	193.8	0	0	0	49.5	0	10.6	1	1	1	0	0	0	0	1
71	1	2016-09-29 07:45:33	201.5	197.8	198.1	0	0	0	49.4	0	10.8	1	1	1	0	0	0	0	1
72	1	2016-09-29 07:45:48	195	196	199.8	0	0	0	49.4	0	10.7	1	1	1	0	0	0	0	1
74	1	2016-09-29 07:46:09	201.8	193.9	197.1	0	0	0	49.1	0	10.6	1	1	1	0	0	0	0	1
75	1	2016-09-29 07:46:17	195.1	194.8	194.2	0	0	0	49.7	0	11.1	1	1	1	0	0	0	0	1
78	1	2016-09-29 07:46:46	194.5	192.6	194.6	0	0	0	49.4	0	11.2	1	1	1	0	0	0	0	1
80	1	2016-09-29 07:47:00	195.1	195.4	195.7	0	0	0	49.5	0	10.8	1	1	1	0	0	0	0	1
81	1	2016-09-29 07:47:07	200.9	194.5	198.4	0	0	0	49.4	0	10.7	1	1	1	0	0	0	0	1
82	1	2016-09-29 07:47:14	200	202.6	199	0	0	0	49.3	0	11.2	1	1	1	0	0	0	0	1
83	1	2016-09-29 07:47:22	200.4	202.4	201.9	0	0	0	49.3	0	10.8	1	1	1	0	0	0	0	1
94	1	2016-09-29 07:49:08	200.6	201.7	201.1	0	0	0	0	0	10.8	1	1	1	0	0	0	0	1
95	1	2016-09-29 07:49:23	200.9	200.7	201.6	0	0	0	49.3	0	10.5	1	1	1	0	0	0	0	1
96	1	2016-09-29 07:49:44	204.9	202.1	201.4	0	0	0	49.8	0	11.1	1	1	1	0	0	0	0	1
97	1	2016-09-29 07:49:52	205.6	206.7	205.9	0	0	0	49.1	0	10.7	1	1	1	0	0	0	0	1
99	1	2016-09-29 07:50:13	200.8	200.8	201.9	0	0	0	488	0	10.6	1	1	1	0	0	0	0	1
100	1	2016-09-29 07:50:21	202.9	202	203.9	0	0	0	49.1	0	10.4	1	1	1	0	0	0	0	1
101	1	2016-09-29 07:50:28	206.5	209.4	210.8	0	0	0	49	0	11	1	1	1	0	0	0	0	1
102	1	2016-09-29 07:51:24	203	202.8	201.7	0	0	0	49.3	0	10.9	1	1	1	0	0	0	0	1
73	1	2016-09-29 07:45:56	195.1	193.3	193.5	0	0	0	49.7	0	10.7	1	1	1	0	0	0	0	1
76	1	2016-09-29 07:46:31	193.6	195.2	193.8	0	0	0	49.7	0	10.8	1	1	1	0	0	0	0	1
77	1	2016-09-29 07:46:38	198.2	196.6	194.4	0	0	0	49.6	0	10.7	1	1	1	0	0	0	0	1
79	1	2016-09-29 07:46:53	196.8	198	197.2	0	0	0	49.4	0	10.7	1	1	1	0	0	0	0	1
84	1	2016-09-29 07:47:28	203.9	203.7	205	0	0	0	49.1	0	10.9	1	1	1	0	0	0	0	1
87	1	2016-09-29 07:48:12	201.9	202.5	200.5	0	0	0	49.5	0	10.4	1	1	1	0	0	0	0	1
88	1	2016-09-29 07:48:18	205.8	202.1	204.3	0	0	0	49.4	0	105	1	1	1	0	0	0	0	1
89	1	2016-09-29 07:48:26	200.2	201.1	201.5	0	0	0	49.2	0	10.7	1	1	1	0	0	0	0	1
98	1	2016-09-29 07:50:00	199.9	202.7	202.2	0	0	0	49.1	0	10.6	1	1	1	0	0	0	0	1
103	1	2016-09-29 07:51:38	204.3	203.6	201.7	0	0	0	49.7	0	10.8	1	1	1	0	0	0	0	1
104	1	2016-09-29 07:51:14	0	0	0	0	0	0	49.2	0	10.8	0	0	0	0	0	0	0	1
85	1	2016-09-29 07:47:43	199.6	201	201.8	0	0	0	49.3	0	10.9	1	1	1	0	0	0	0	1
86	1	2016-09-29 07:48:04	200.2	202	200.8	0	0	0	49.4	0	11.3	1	1	1	0	0	0	0	1
90	1	2016-09-29 07:48:33	206.1	199.1	201.1	0	0	0	49.5	0	10.9	1	1	1	0	0	0	0	1
91	1	2016-09-29 07:48:39	206.5	202.5	201.6	0	0	0	49.1	0	10.7	1	1	1	0	0	0	0	1
92	1	2016-09-29 07:48:47	201.1	202	205.6	0	0	0	49.1	0	11.1	1	1	1	0	0	0	0	1
93	1	2016-09-29 07:48:54	207.8	200.4	202.3	0	0	0	49.5	0	10.7	1	1	1	0	0	0	0	1
105	1	2016-09-29 08:00:49	203.7	204.1	202.4	0	0	0	49.4	0	10.6	1	1	1	0	0	0	0	1
106	1	2016-09-29 08:04:14	0	0	0	0	0	0	0	0	11.3	0	0	0	0	0	0	0	1
107	1	2016-09-29 08:04:39	203.2	203.9	203	0	0	0	49.5	0	11.1	1	1	1	0	0	0	0	1
108	1	2016-09-29 08:04:47	206.1	204.7	206.7	0	0	0	49.8	0	11	1	1	1	0	0	0	0	1
109	1	2016-09-29 08:04:53	212.5	210.9	213	1.2	1.2	1.2	49.4	0	11	1	1	1	0	0	0	0	1
110	1	2016-09-29 08:05:01	203.7	203.9	202.4	0	0	0	49.3	0	10.9	1	1	1	0	0	0	0	1
111	1	2016-09-29 08:05:08	208.6	211.7	206.1	0	0	0	49.4	0	10.9	1	1	1	0	0	0	0	1
112	1	2016-09-29 08:13:53	207.9	207.7	207.6	0	0	0	49.7	0	11	1	1	0	0	0	0	0	1
113	1	2016-09-29 08:14:13	0	0	0	0	0	0	49.5	0	11.3	0	0	0	0	0	0	0	1
114	1	2016-09-29 08:24:13	0	0	0	0	0	0	49.4	0	11.2	0	0	0	0	1	0	0	1
115	1	2016-09-29 16:51:20	220.21	221.02	219.48	2.32	3.30	3.23	48.21	3.45	20.34	0	1	1	0	0	0	0	1
116	1	2016-09-29 16:55:20	221.21	220.02	219.50	3.32	3.30	3.23	48.50	3.40	20.34	0	1	1	0	0	0	0	1
117	1	2016-09-29 17:00:00	220.25	220.02	219.50	3.32	3.30	3.23	48.55	3.40	20.34	0	1	1	0	0	0	0	1
118	2	2016-10-11 11:23:14	204.6	199.6	206.4	0.0	0.0	0.0	48.66	0.0	0.0	1	1	1	0	0	0	0	2
119	2	2016-10-11 12:39:56	197.7	193.2	201.3	0.0	0.0	0.0	48.33	0.0	0.0	1	1	1	0	0	1	0	2
120	2	2016-10-11 13:19:00	204.5	196.6	203.5	0.0	0.0	0.0	48.30	0.0	0.0	1	1	1	0	0	0	0	2
121	2	2016-10-11 14:21:00	0.0	0.0	0.0	0.0	0.0	0.0	48.48	0.0	0.0	0	0	0	0	0	0	0	2
122	2	2016-10-11 14:50:46	202.1	195.9	202.7	0.0	0.0	0.0	48.43	0.0	0.0	1	1	0	0	0	0	0	2
123	2	2016-10-11 14:51:11	202.3	196.5	205.5	0.0	0.0	0.0	48.58	0.0	0.0	1	1	1	0	0	0	0	2
124	2	2016-10-11 14:51:56	205.0	199.9	209.1	0.0	0.0	0.0	48.46	0.0	0.0	1	1	1	0	0	1	0	2
125	2	2016-10-11 14:52:04	208.8	201.2	208.0	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
126	2	2016-10-11 15:50:01	202.9	198.5	203.3	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
127	2	2016-10-11 16:50:01	201.7	195.3	205.5	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
128	2	2016-10-11 16:51:11	200.7	195.7	203.4	0.0	0.0	0.0	48.68	0.0	0.0	1	1	0	0	0	0	0	2
129	2	2016-10-11 16:51:31	0.0	0.0	0.0	0.0	0.0	0.0	48.41	0.0	0.0	0	0	0	0	0	0	0	2
130	2	2016-10-11 17:50:01	0.0	0.0	0.0	0.0	0.0	0.0	48.54	0.0	0.0	0	0	0	0	0	0	0	2
131	2	2016-10-11 19:50:00	204.4	201.0	205.9	0.0	0.0	0.0	48.76	0.0	0.0	1	1	1	0	0	0	0	2
132	2	2016-10-11 20:50:01	200.8	196.5	201.7	0.0	0.0	0.0	48.56	0.0	0.0	1	1	1	0	0	0	0	2
133	2	2016-10-11 20:51:41	201.4	196.1	203.7	0.0	0.0	0.0	48.29	0.0	0.0	1	1	0	0	0	0	0	2
134	2	2016-10-11 20:52:06	0.0	0.0	0.0	0.0	0.0	0.0	48.63	0.0	0.0	0	0	0	0	0	0	0	2
135	2	2016-10-11 21:50:01	0.0	0.0	0.0	0.0	0.0	0.0	48.76	0.0	0.0	0	0	0	0	0	0	0	2
136	2	2016-10-11 22:50:01	0.0	0.0	0.0	0.0	0.0	0.0	48.78	0.0	0.0	0	0	0	0	0	0	0	2
137	2	2016-10-11 22:51:46	210.1	207.5	212.0	0.0	0.0	0.0	48.11	0.0	0.0	1	1	0	0	0	0	0	2
139	2	2016-10-11 22:52:11	211.8	207.1	220.4	0.0	0.0	0.0	48.18	0.0	0.0	1	1	1	0	0	0	0	2
141	2	2016-10-12 00:50:01	215.0	213.6	218.2	0.0	0.0	0.0	48.48	0.0	0.0	1	1	1	0	0	0	0	2
142	2	2016-10-11 23:50:00	214.7	208.2	214.3	0.0	0.0	0.0	48.64	0.0	0.0	1	1	1	0	0	0	0	2
153	2	2016-10-12 04:53:06	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
145	2	2016-10-12 00:52:11	212.6	209.6	216.0	0.0	0.0	0.0	48.53	0.0	0.0	1	1	0	0	0	0	0	2
150	2	2016-10-12 02:52:41	213.8	209.1	217.7	0.0	0.0	0.0	49.05	0.0	0.0	1	1	1	0	0	0	0	2
146	2	2016-10-12 00:52:31	0.0	0.0	0.0	0.0	0.0	0.0	48.24	0.0	0.0	0	0	0	0	0	0	0	2
147	2	2016-10-12 01:50:01	0.0	0.0	0.0	0.0	0.0	0.0	48.64	0.0	0.0	0	0	0	0	0	0	0	2
148	2	2016-10-12 02:50:01	0.0	0.0	0.0	0.0	0.0	0.0	48.31	0.0	0.0	0	0	0	0	0	0	0	2
149	2	2016-10-12 02:52:16	216.9	210.1	216.6	0.0	0.0	0.0	48.74	0.0	0.0	1	1	0	0	0	0	0	2
151	2	2016-10-12 04:50:01	195.8	191.6	199.3	0.0	0.0	0.0	48.80	0.0	1.1	1	1	1	0	0	0	0	2
152	2	2016-10-12 04:52:41	197.7	194.3	199.4	0.0	0.0	0.0	48.55	0.0	0.0	1	1	0	0	0	0	0	2
154	2	2016-10-12 05:50:01	0.0	0.0	0.0	0.0	0.0	0.0	48.85	0.0	0.0	0	0	0	0	0	0	0	2
155	2	2016-10-12 06:42:46	0.0	0.0	0.0	0.0	0.0	0.0	48.74	0.0	0.0	0	0	0	0	0	1	0	2
156	2	2016-10-12 06:50:02	0.0	0.0	0.0	0.0	0.0	0.0	48.62	0.0	0.0	0	0	0	0	0	0	0	2
157	2	2016-10-12 06:52:46	201.5	195.1	204.8	0.0	0.0	0.0	49.39	0.0	0.0	1	1	0	0	0	0	0	2
158	2	2016-10-12 06:53:11	201.8	198.2	202.7	0.0	0.0	0.0	48.73	0.0	0.0	1	1	1	0	0	0	0	2
159	2	2016-10-12 09:04:26	200.1	197.2	202.7	0.0	0.0	0.0	48.70	0.0	0.0	1	1	0	0	0	0	0	2
160	2	2016-10-12 09:06:03	200.2	197.0	203.0	0.0	0.0	0.0	48.69	0.0	0.0	1	1	1	0	0	1	0	2
161	2	2016-10-12 09:07:01	204.6	199.1	204.2	0.0	0.0	0.0	47.96	0.0	1.1	1	1	1	0	0	0	0	2
162	2	2016-10-12 09:07:39	200.2	196.2	202.1	0.0	0.0	0.0	48.77	0.0	0.0	1	1	1	0	0	1	0	2
163	2	2016-10-12 09:08:36	202.9	197.2	204.5	0.0	0.0	0.0	48.75	0.0	0.0	1	1	1	0	0	0	0	2
164	2	2016-10-12 09:09:32	202.6	195.9	203.1	0.0	0.0	0.0	48.62	0.0	1.2	1	1	1	0	0	1	0	2
165	2	2016-10-12 09:17:39	193.6	191.3	197.1	0.0	0.0	0.0	48.57	0.0	0.0	1	1	1	0	0	0	0	2
166	2	2016-10-12 10:04:01	198.3	195.3	201.9	0.0	0.0	0.0	49.05	0.0	0.0	1	1	1	0	0	0	0	2
167	2	2016-10-12 11:04:01	196.2	193.9	201.1	0.0	0.0	0.0	47.79	0.0	0.0	1	1	1	0	0	0	0	2
168	2	2016-10-12 11:04:28	196.3	190.3	197.9	0.0	0.0	0.0	48.11	0.0	0.0	1	1	0	0	0	0	0	2
169	2	2016-10-12 11:04:51	0.0	0.0	0.0	0.0	0.0	0.0	48.44	0.0	0.0	0	0	0	0	0	0	0	2
170	2	2016-10-12 12:04:01	0.0	0.0	0.0	0.0	0.0	0.0	48.76	0.0	0.0	0	0	0	0	0	0	0	2
171	2	2016-10-12 12:29:35	0.0	0.0	0.0	0.0	0.0	0.0	48.21	0.0	0.0	0	0	0	0	1	0	0	2
172	2	2016-10-12 12:29:46	0.0	0.0	0.0	0.0	0.0	0.0	48.20	0.0	0.0	0	0	0	0	0	0	0	2
173	2	2016-10-12 13:00:50	0.0	0.0	0.0	0.0	0.0	0.0	48.50	0.0	0.0	0	0	0	0	0	1	0	2
174	2	2016-10-12 13:04:01	0.0	0.0	0.0	0.0	0.0	0.0	48.06	0.0	0.0	0	0	0	0	0	1	0	2
175	2	2016-10-12 13:04:09	0.0	0.0	0.0	0.0	0.0	0.0	48.06	0.0	0.0	0	0	0	0	0	0	0	2
176	2	2016-10-12 13:04:36	202.5	196.9	205.2	0.0	0.0	0.0	48.85	0.0	0.0	1	1	0	0	0	0	0	2
177	2	2016-10-12 13:04:46	202.8	198.9	207.9	0.0	0.0	0.0	48.61	0.0	0.0	1	1	1	0	0	1	0	2
178	2	2016-10-12 13:05:55	201.5	196.9	202.6	0.0	0.0	0.0	48.56	0.0	0.0	1	1	1	0	0	0	0	2
179	2	2016-10-12 13:08:02	205.8	200.3	208.7	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	1	0	2
180	2	2016-10-12 13:41:14	0.0	0.0	0.0	0.0	0.0	0.0	48.52	0.0	0.0	0	0	0	0	0	1	0	2
181	2	2016-10-12 13:41:24	199.5	194.8	201.0	0.0	0.0	0.0	48.48	0.0	0.0	1	1	1	0	0	1	0	2
182	2	2016-10-12 13:41:39	200.9	195.4	202.3	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
183	2	2016-10-12 14:13:46	198.6	194.3	204.4	0.0	0.0	0.0	48.31	0.0	0.0	1	1	1	0	0	1	0	2
184	2	2016-10-12 14:16:18	198.5	190.3	201.8	0.0	0.0	0.0	48.17	0.0	0.0	1	1	1	0	0	0	0	2
185	2	2016-10-12 14:41:00	201.3	196.7	206.6	0.0	0.0	0.0	48.18	0.0	0.0	1	1	1	0	0	0	0	2
186	2	2016-10-12 15:41:01	202.4	200.7	205.1	0.0	0.0	0.0	48.82	0.0	0.0	1	1	1	0	0	0	0	2
187	2	2016-10-12 15:41:24	202.2	195.6	205.1	0.0	0.0	0.0	48.24	0.0	0.0	1	1	0	0	0	0	0	2
188	2	2016-10-12 15:41:46	0.0	0.0	0.0	0.0	0.0	0.0	49.17	0.0	0.0	0	0	0	0	0	0	0	2
189	2	2016-10-12 17:17:00	197.4	193.8	200.3	0.0	0.0	0.0	49.01	0.0	0.0	1	1	1	0	0	0	0	2
190	2	2016-10-12 18:17:01	191.1	184.3	191.1	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
191	2	2016-10-12 18:18:00	192.9	186.0	192.3	0.0	0.0	0.0	48.71	0.0	0.0	1	1	0	0	0	0	0	2
192	2	2016-10-12 18:18:21	0.0	0.0	0.0	0.0	0.0	0.0	48.29	0.0	0.0	0	0	0	0	0	0	0	2
193	2	2016-10-12 19:17:01	0.0	0.0	0.0	0.0	0.0	0.0	48.04	0.0	0.0	0	0	0	0	0	0	0	2
194	2	2016-10-12 20:17:01	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	0	0	2
195	2	2016-10-12 20:18:06	201.8	195.5	203.5	0.0	0.0	0.0	48.59	0.0	0.0	1	1	0	0	0	0	0	2
196	2	2016-10-13 11:10:01	205.0	201.1	206.0	0.0	0.0	0.0	48.62	0.0	0.0	1	1	1	0	0	1	0	2
197	2	2016-10-13 11:10:36	209.0	204.6	210.9	0.0	0.0	0.0	48.43	0.0	0.0	1	1	0	0	0	1	0	2
198	2	2016-10-13 11:10:56	0.0	0.0	0.0	0.0	0.0	0.0	48.59	0.0	0.0	0	0	0	0	0	1	0	2
199	2	2016-10-13 11:56:56	0.0	0.0	0.0	0.0	0.0	0.0	48.23	0.0	0.0	0	0	0	0	0	0	0	2
200	2	2016-10-13 12:31:16	212.3	206.1	214.0	0.0	0.0	0.0	48.34	0.0	0.0	1	1	0	0	0	0	0	2
201	2	2016-10-13 12:35:08	211.9	204.7	209.9	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	1	0	2
202	2	2016-10-13 12:36:00	212.2	205.1	212.0	0.0	0.0	0.0	48.41	0.0	0.0	1	1	1	0	0	0	0	2
203	2	2016-10-13 13:31:00	203.0	198.8	203.5	0.0	0.0	0.0	48.26	0.0	0.0	1	1	1	0	0	0	0	2
204	2	2016-10-13 14:05:18	204.9	197.3	203.6	0.0	0.0	0.0	48.93	0.0	0.0	1	1	1	0	0	1	0	2
205	2	2016-10-13 14:09:48	207.3	203.6	211.2	0.0	0.0	0.0	48.44	0.0	0.0	1	1	1	0	0	0	0	2
206	2	2016-10-13 14:31:01	198.0	194.0	201.8	0.0	0.0	0.0	48.19	0.0	0.0	1	1	1	0	0	0	0	2
207	2	2016-10-13 14:31:51	199.9	194.9	199.9	0.0	0.0	0.0	48.35	0.0	0.0	1	1	0	0	0	0	0	2
208	2	2016-10-13 14:32:11	0.0	0.0	0.0	0.0	0.0	0.0	49.05	0.0	0.0	0	0	0	0	0	0	0	2
209	2	2016-10-13 15:27:42	0.0	0.0	0.0	0.0	0.0	0.0	48.59	0.0	0.0	0	0	0	0	0	1	0	2
210	2	2016-10-13 15:29:02	0.0	0.0	0.0	0.0	0.0	0.0	48.35	0.0	0.0	0	0	0	0	0	0	0	2
211	2	2016-10-13 15:31:01	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	0	0	2
212	2	2016-10-13 16:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.77	0.0	0.0	0	0	0	0	0	0	0	2
213	2	2016-10-13 16:56:46	201.7	196.5	202.5	0.0	0.0	0.0	48.49	0.0	0.0	1	1	0	0	0	0	0	2
214	2	2016-10-13 17:20:17	196.5	191.1	198.8	0.0	0.0	0.0	48.63	0.0	0.0	1	1	1	0	0	1	0	2
215	2	2016-10-13 17:20:51	199.6	195.9	203.7	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
216	2	2016-10-13 17:56:00	196.6	191.2	203.3	0.0	0.0	0.0	48.74	0.0	0.0	1	1	1	0	0	0	0	2
217	2	2016-10-13 18:56:00	208.3	201.6	207.0	0.0	0.0	0.0	48.79	0.0	0.0	1	1	1	0	0	0	0	2
218	2	2016-10-13 18:56:49	206.4	201.2	207.2	0.0	0.0	0.0	48.22	0.0	0.0	1	1	0	0	0	0	0	2
219	2	2016-10-13 18:57:11	0.0	0.0	0.0	0.0	0.0	0.0	48.87	0.0	0.0	0	0	0	0	0	0	0	2
220	2	2016-10-13 19:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
221	2	2016-10-13 20:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.33	0.0	0.0	0	0	0	0	0	0	0	2
222	2	2016-10-13 20:56:56	198.1	192.8	201.5	0.0	0.0	0.0	48.64	0.0	0.0	1	1	0	0	0	0	0	2
223	2	2016-10-13 21:56:00	210.8	204.6	215.5	0.0	0.0	0.0	48.93	0.0	0.0	1	1	1	0	0	0	0	2
224	2	2016-10-13 22:56:01	217.5	209.6	219.2	0.0	0.0	0.0	48.96	0.0	0.0	1	1	1	0	0	0	0	2
225	2	2016-10-13 22:56:58	217.6	211.2	217.1	0.0	0.0	0.0	48.57	0.0	0.0	1	1	0	0	0	0	0	2
227	2	2016-10-13 23:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.60	0.0	0.0	0	0	0	0	0	0	0	2
229	2	2016-10-14 00:57:06	213.9	208.4	217.0	0.0	0.0	0.0	48.68	0.0	0.0	1	1	0	0	0	0	0	2
231	2	2016-10-14 02:56:01	210.4	205.6	212.9	0.0	0.0	0.0	48.47	0.0	0.0	1	1	1	0	0	0	0	2
232	2	2016-10-14 02:57:08	214.0	207.7	214.9	0.0	0.0	0.0	48.46	0.0	0.0	1	1	0	0	0	0	0	2
236	2	2016-10-14 04:57:16	194.0	188.4	197.8	0.0	0.0	0.0	48.24	0.0	0.0	1	1	0	0	0	0	0	2
237	2	2016-10-14 05:56:01	199.4	197.1	201.7	0.0	0.0	0.0	49.09	0.0	0.0	1	1	1	0	0	0	0	2
226	2	2016-10-13 22:57:21	0.0	0.0	0.0	0.0	0.0	0.0	48.20	0.0	0.0	0	0	0	0	0	0	0	2
230	2	2016-10-14 01:56:01	215.6	213.4	221.5	0.0	0.0	0.0	48.10	0.0	0.0	1	1	1	0	0	0	0	2
233	2	2016-10-14 02:57:31	0.0	0.0	0.0	0.0	0.0	0.0	48.28	0.0	0.0	0	0	0	0	0	0	0	2
228	2	2016-10-14 00:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.77	0.0	0.0	0	0	0	0	0	0	0	2
234	2	2016-10-14 03:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.32	0.0	0.0	0	0	0	0	0	0	0	2
239	2	2016-10-14 06:57:19	198.7	188.2	194.7	0.0	0.0	0.0	48.66	0.0	0.0	1	1	0	0	0	0	0	2
240	2	2016-10-14 06:57:41	0.0	0.0	0.0	0.0	0.0	0.0	48.41	0.0	0.0	0	0	0	0	0	0	0	2
241	2	2016-10-14 07:56:00	0.0	0.0	0.0	0.0	0.0	0.0	48.29	0.0	0.0	0	0	0	0	0	0	0	2
235	2	2016-10-14 04:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.45	0.0	0.0	0	0	0	0	0	0	0	2
238	2	2016-10-14 06:56:01	193.4	188.1	194.9	0.0	0.0	0.0	48.35	0.0	0.0	1	1	1	0	0	0	0	2
242	2	2016-10-14 08:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.18	0.0	0.0	0	0	0	0	0	0	0	2
243	2	2016-10-14 08:57:26	204.3	197.8	206.9	0.0	0.0	0.0	48.67	0.0	0.0	1	1	0	0	0	0	0	2
244	2	2016-10-14 10:56:01	202.1	198.5	202.4	0.0	0.0	0.0	48.29	0.0	0.0	1	1	1	0	0	0	0	2
245	2	2016-10-14 09:56:01	210.0	204.0	209.9	0.0	0.0	0.0	48.91	0.0	0.0	1	1	1	0	0	0	0	2
246	2	2016-10-14 10:57:29	197.9	193.3	200.9	0.0	0.0	0.0	48.66	0.0	0.0	1	1	0	0	0	0	0	2
247	2	2016-10-14 10:57:51	0.0	0.0	0.0	0.0	0.0	0.0	48.42	0.0	0.0	0	0	0	0	0	0	0	2
248	2	2016-10-14 11:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.68	0.0	0.0	0	0	0	0	0	0	0	2
249	2	2016-10-14 12:56:00	0.0	0.0	0.0	0.0	0.0	0.0	47.71	0.0	0.0	0	0	0	0	0	0	0	2
250	2	2016-10-14 12:57:36	198.0	193.4	199.1	0.0	0.0	0.0	48.29	0.0	0.0	1	1	0	0	0	0	0	2
251	2	2016-10-14 13:56:01	203.6	196.5	206.2	0.0	0.0	0.0	48.68	0.0	0.0	1	1	1	0	0	0	0	2
252	2	2016-10-14 14:56:00	201.5	197.8	203.1	0.0	0.0	0.0	48.47	0.0	0.0	1	1	1	0	0	0	0	2
253	2	2016-10-14 14:57:39	205.2	200.6	205.5	0.0	0.0	0.0	47.81	0.0	0.0	1	1	0	0	0	0	0	2
254	2	2016-10-14 14:58:00	0.0	0.0	0.0	0.0	0.0	0.0	48.02	0.0	0.0	0	0	0	0	0	0	0	2
255	2	2016-10-14 15:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.28	0.0	0.0	0	0	0	0	0	0	0	2
256	2	2016-10-15 02:56:01	195.7	189.5	194.4	0.0	0.0	0.0	48.31	0.0	0.0	1	1	1	0	0	0	0	2
257	2	2016-10-15 02:58:09	199.4	192.8	200.0	0.0	0.0	0.0	48.17	0.0	0.0	1	1	0	0	0	0	0	2
258	2	2016-10-15 02:58:31	0.0	0.0	0.0	0.0	0.0	0.0	48.11	0.0	0.0	0	0	0	0	0	0	0	2
259	2	2016-10-15 03:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.08	0.0	0.0	0	0	0	0	0	0	0	2
260	2	2016-10-15 04:56:00	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
261	2	2016-10-15 04:58:16	183.2	180.5	186.8	0.0	0.0	0.0	48.10	0.0	0.0	1	1	0	0	0	0	0	2
262	2	2016-10-15 05:56:01	193.7	189.6	194.8	0.0	0.0	0.0	48.96	0.0	0.0	1	1	1	0	0	0	0	2
263	2	2016-10-15 06:56:01	204.3	201.8	205.3	0.0	0.0	0.0	48.61	0.0	0.0	1	1	1	0	0	0	0	2
264	2	2016-10-15 06:58:19	203.0	199.6	206.2	0.0	0.0	0.0	48.51	0.0	0.0	1	1	0	0	0	0	0	2
265	2	2016-10-15 06:58:41	0.0	0.0	0.0	0.0	0.0	0.0	48.60	0.0	0.0	0	0	0	0	0	0	0	2
266	2	2016-10-15 07:56:00	0.0	0.0	0.0	0.0	0.0	0.0	48.60	0.0	0.0	0	0	0	0	0	0	0	2
267	2	2016-10-15 08:56:00	0.0	0.0	0.0	0.0	0.0	0.0	48.53	0.0	0.0	0	0	0	0	0	0	0	2
268	2	2016-10-15 08:58:26	200.0	193.6	200.8	0.0	0.0	0.0	48.55	0.0	0.0	1	1	0	0	0	0	0	2
269	2	2016-10-15 09:56:01	199.9	196.1	204.6	0.0	0.0	0.0	47.64	0.0	0.0	1	1	1	0	0	0	0	2
270	2	2016-10-15 10:56:00	205.7	200.7	208.1	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
271	2	2016-10-15 10:58:51	0.0	0.0	0.0	0.0	0.0	0.0	48.21	0.0	0.0	0	0	0	0	0	0	0	2
272	2	2016-10-15 11:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.67	0.0	0.0	0	0	0	0	0	0	0	2
273	2	2016-10-15 18:58:56	207.2	200.1	204.8	0.0	0.0	0.0	48.68	0.0	0.0	1	0	0	0	0	0	0	2
274	2	2016-10-15 18:59:18	204.4	198.9	206.4	0.0	0.0	0.0	48.46	0.0	0.0	1	1	1	0	0	0	0	2
275	2	2016-10-15 20:58:01	198.6	194.1	204.5	0.0	0.0	0.0	48.73	0.0	0.0	1	1	1	0	0	0	0	2
276	2	2016-10-15 19:58:01	202.7	196.9	205.1	0.0	0.0	0.0	48.07	0.0	0.0	1	1	1	0	0	0	0	2
277	2	2016-10-15 20:59:22	195.5	190.7	198.3	0.0	0.0	0.0	48.61	0.0	0.0	1	0	0	0	0	0	0	2
278	2	2016-10-15 20:59:46	0.0	0.0	0.0	0.0	0.0	0.0	48.74	0.0	0.0	0	0	0	0	0	0	0	2
279	2	2016-10-15 21:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.81	0.0	0.0	0	0	0	0	0	0	0	2
280	2	2016-10-15 22:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.44	0.0	0.0	0	0	0	0	0	0	0	2
281	2	2016-10-15 22:59:36	212.3	206.1	214.9	0.0	0.0	0.0	48.14	0.0	0.0	1	0	0	0	0	0	0	2
282	2	2016-10-15 23:58:01	214.6	208.2	215.1	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
283	2	2016-10-16 00:58:01	220.2	215.3	221.7	0.0	0.0	0.0	48.32	0.0	0.0	1	1	1	0	0	0	0	2
284	2	2016-10-16 01:00:12	218.6	212.4	223.2	0.0	0.0	0.0	48.48	0.0	0.0	1	0	0	0	0	0	0	2
285	2	2016-10-16 01:00:36	0.0	0.0	0.0	0.0	0.0	0.0	48.42	0.0	0.0	0	0	0	0	0	0	0	2
286	2	2016-10-16 01:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.33	0.0	0.0	0	0	0	0	0	0	0	2
287	2	2016-10-16 02:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
288	2	2016-10-16 03:00:26	220.9	214.6	221.7	0.0	0.0	0.0	48.28	0.0	0.0	1	0	0	0	0	0	0	2
289	2	2016-10-16 03:00:50	222.0	216.0	220.9	0.0	0.0	0.0	48.47	0.0	0.0	1	1	1	0	0	0	0	2
290	2	2016-10-16 03:58:01	218.1	213.8	220.1	0.0	0.0	0.0	48.34	0.0	0.0	1	1	1	0	0	0	0	2
291	2	2016-10-16 04:58:01	200.5	195.0	202.6	0.0	0.0	0.0	48.82	0.0	0.0	1	1	1	0	0	0	0	2
292	2	2016-10-16 05:00:58	193.9	189.6	199.0	0.0	0.0	0.0	48.94	0.0	0.0	1	0	0	0	0	0	0	2
293	2	2016-10-16 05:01:21	0.0	0.0	0.0	0.0	0.0	0.0	48.37	0.0	0.0	0	0	0	0	0	0	0	2
294	2	2016-10-16 05:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.92	0.0	0.0	0	0	0	0	0	0	0	2
295	2	2016-10-16 06:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.73	0.0	0.0	0	0	0	0	0	0	0	2
296	2	2016-10-16 07:01:11	200.6	197.8	204.7	0.0	0.0	0.0	48.67	0.0	0.0	1	0	0	0	0	0	0	2
297	2	2016-10-16 07:01:36	203.6	196.9	204.9	0.0	0.0	0.0	48.59	0.0	0.0	1	1	1	0	0	0	0	2
298	2	2016-10-16 07:58:01	183.2	176.6	183.0	0.0	0.0	0.0	48.41	0.0	0.0	1	1	1	0	0	0	0	2
299	2	2016-10-16 08:58:01	182.6	178.1	184.4	0.0	0.0	0.0	48.25	0.0	0.0	1	1	1	0	0	0	0	2
300	2	2016-10-16 09:01:44	188.4	183.8	193.7	0.0	0.0	0.0	48.59	0.0	0.0	1	0	0	0	0	0	0	2
301	2	2016-10-16 09:02:06	0.0	0.0	0.0	0.0	0.0	0.0	48.35	0.0	0.0	0	0	0	0	0	0	0	2
302	2	2016-10-16 09:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.32	0.0	0.0	0	0	0	0	0	0	0	2
303	2	2016-10-16 10:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.38	0.0	0.0	0	0	0	0	0	0	0	2
304	2	2016-10-16 11:02:00	203.7	198.8	206.0	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
305	2	2016-10-16 11:02:22	204.6	200.0	206.6	0.0	0.0	0.0	48.77	0.0	0.0	1	1	1	0	0	0	0	2
306	2	2016-10-16 11:58:01	205.8	200.9	207.2	0.0	0.0	0.0	48.47	0.0	0.0	1	1	1	0	0	0	0	2
307	2	2016-10-16 13:02:30	199.6	193.9	199.5	0.0	0.0	0.0	49.05	0.0	1.1	1	0	0	0	0	0	0	2
308	2	2016-10-16 13:02:51	0.0	0.0	0.0	0.0	0.0	0.0	48.35	0.0	0.0	0	0	0	0	0	0	0	2
309	2	2016-10-16 14:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.98	0.0	0.0	0	0	0	0	0	0	0	2
310	2	2016-10-16 13:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
311	2	2016-10-16 15:02:46	208.2	200.0	207.2	0.0	0.0	0.0	48.38	0.0	0.0	1	0	0	0	0	0	0	2
312	2	2016-10-16 15:03:08	204.3	199.0	209.2	0.0	0.0	0.0	48.44	0.0	0.0	1	1	1	0	0	0	0	2
313	2	2016-10-16 15:58:01	204.5	199.6	205.3	0.0	0.0	0.0	48.61	0.0	0.0	1	1	1	0	0	0	0	2
314	2	2016-10-16 16:58:01	202.8	199.9	207.7	0.0	0.0	0.0	48.62	0.0	0.0	1	1	1	0	0	0	0	2
316	2	2016-10-16 17:03:41	0.0	0.0	0.0	0.0	0.0	0.0	48.90	0.0	0.0	0	0	0	0	0	0	0	2
327	2	2016-10-16 23:04:21	214.5	208.3	219.6	0.0	0.0	0.0	48.52	0.0	0.0	1	0	0	0	0	0	0	2
315	2	2016-10-16 17:03:19	205.5	198.0	205.3	0.0	0.0	0.0	48.62	0.0	0.0	1	0	0	0	0	0	0	2
317	2	2016-10-16 17:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.50	0.0	0.0	0	0	0	0	0	0	0	2
318	2	2016-10-16 18:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.32	0.0	0.0	0	0	0	0	0	0	0	2
319	2	2016-10-16 19:03:36	197.0	192.4	199.7	0.0	0.0	0.0	47.94	0.0	0.0	1	0	0	0	0	0	0	2
320	2	2016-10-16 19:03:57	198.7	192.9	198.1	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
321	2	2016-10-16 19:58:01	192.6	187.7	195.2	0.0	0.0	0.0	48.37	0.0	0.0	1	1	1	0	0	0	0	2
322	2	2016-10-16 20:58:01	201.3	194.7	204.8	0.0	0.0	0.0	48.68	0.0	1.3	1	1	1	0	0	0	0	2
323	2	2016-10-16 21:04:05	203.8	199.4	207.8	0.0	0.0	0.0	48.42	0.0	0.0	1	0	0	0	0	0	0	2
324	2	2016-10-16 21:04:26	0.0	0.0	0.0	0.0	0.0	0.0	48.55	0.0	0.0	0	0	0	0	0	0	0	2
325	2	2016-10-16 21:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.72	0.0	0.0	0	0	0	0	0	0	0	2
326	2	2016-10-16 22:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
328	2	2016-10-16 23:04:43	212.7	209.0	218.4	0.0	0.0	0.0	48.64	0.0	0.0	1	1	1	0	0	0	0	2
329	2	2016-10-16 23:58:01	215.8	211.9	218.2	0.0	0.0	0.0	48.76	0.0	0.0	1	1	1	0	0	0	0	2
330	2	2016-10-17 01:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.17	0.0	0.0	0	0	0	0	0	0	0	2
331	2	2016-10-17 02:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.18	0.0	0.0	0	0	0	0	0	0	0	2
332	2	2016-10-17 03:05:06	218.1	214.4	220.9	0.0	0.0	0.0	48.21	0.0	0.0	1	0	0	0	0	0	0	2
333	2	2016-10-17 03:05:29	218.6	212.5	220.7	0.0	0.0	0.0	48.69	0.0	0.0	1	1	1	0	0	0	0	2
334	2	2016-10-17 03:58:01	216.5	213.5	221.4	0.0	0.0	0.0	48.78	0.0	0.0	1	1	1	0	0	0	0	2
335	2	2016-10-17 04:58:01	186.6	181.4	189.1	0.0	0.0	0.0	49.18	0.0	0.0	1	1	1	0	0	0	0	2
336	2	2016-10-17 05:05:37	192.2	185.7	195.2	0.0	0.0	0.0	48.49	0.0	0.0	1	0	0	0	0	0	0	2
337	2	2016-10-17 05:06:00	0.0	0.0	0.0	0.0	0.0	0.0	48.64	0.0	0.0	0	0	0	0	0	0	0	2
338	2	2016-10-17 05:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.27	0.0	0.0	0	0	0	0	0	0	0	2
339	2	2016-10-17 06:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.97	0.0	0.0	0	0	0	0	0	0	0	2
340	2	2016-10-17 07:05:51	198.5	190.7	198.3	0.0	0.0	0.0	48.73	0.0	0.0	1	0	0	0	0	0	0	2
341	2	2016-10-17 07:06:15	197.0	192.8	198.2	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
342	2	2016-10-17 07:58:01	186.4	179.2	189.6	0.0	0.0	0.0	48.98	0.0	0.0	1	1	1	0	0	0	0	2
343	2	2016-10-17 08:58:01	201.9	194.3	200.8	0.0	0.0	0.0	48.85	0.0	0.0	1	1	1	0	0	0	0	2
344	2	2016-10-17 09:06:23	200.9	194.9	200.6	0.0	0.0	0.0	48.91	0.0	0.0	1	0	0	0	0	0	0	2
345	2	2016-10-17 09:06:46	0.0	0.0	0.0	0.0	0.0	0.0	48.43	0.0	0.0	0	0	0	0	0	0	0	2
346	2	2016-10-17 20:58:01	202.2	193.8	201.7	0.0	0.0	0.0	48.83	0.0	0.0	1	1	1	0	0	0	0	2
347	2	2016-10-17 21:58:01	207.2	199.4	206.6	0.0	0.0	0.0	48.72	0.0	0.0	1	1	1	0	0	0	0	2
348	2	2016-10-17 22:08:45	205.7	200.9	206.3	0.0	0.0	0.0	48.61	0.0	0.0	1	0	0	0	0	0	0	2
350	2	2016-10-17 22:09:06	0.0	0.0	0.0	0.0	0.0	0.0	48.79	0.0	0.0	0	0	0	0	0	0	0	2
351	2	2016-10-17 22:58:01	0.0	0.0	0.0	0.0	0.0	0.0	48.68	0.0	0.0	0	0	0	0	0	0	0	2
352	2	2016-10-18 11:12:31	203.9	198.0	204.4	0.0	0.0	0.0	48.30	0.0	0.0	1	0	0	0	0	0	0	2
353	2	2016-10-18 11:12:56	200.7	194.7	201.2	0.0	0.0	0.0	48.37	0.0	0.0	1	1	1	0	0	0	0	2
354	2	2016-10-18 15:01:01	203.2	195.3	204.1	0.0	0.0	0.0	48.34	0.0	0.0	1	1	1	0	0	0	0	2
355	2	2016-10-18 16:01:01	195.2	190.1	198.7	0.0	0.0	0.0	48.66	0.0	0.0	1	1	1	0	0	0	0	2
356	2	2016-10-18 17:01:01	209.3	203.6	209.3	0.0	0.0	0.0	48.74	0.0	0.0	1	1	1	0	0	0	0	2
357	2	2016-10-18 17:02:40	204.7	199.0	206.6	0.0	0.0	0.0	48.51	0.0	0.0	1	0	0	0	0	0	0	2
358	2	2016-10-18 17:03:00	0.0	0.0	0.0	0.0	0.0	0.0	49.01	0.0	0.0	0	0	0	0	0	0	0	2
359	2	2016-10-18 18:01:01	0.0	0.0	0.0	0.0	0.0	0.0	48.63	0.0	0.0	0	0	0	0	0	0	0	2
360	2	2016-10-18 19:01:01	0.0	0.0	0.0	0.0	0.0	0.0	48.99	0.0	0.0	0	0	0	0	0	0	0	2
362	2	2016-10-18 19:02:56	188.9	182.3	190.3	0.0	0.0	0.0	48.26	0.0	0.0	1	0	0	0	0	0	0	2
363	2	2016-10-18 19:03:18	189.7	185.1	190.1	0.0	0.0	0.0	48.39	0.0	0.0	1	1	1	0	0	0	0	2
364	2	2016-10-18 20:01:01	196.0	190.3	201.1	0.0	0.0	0.0	48.63	0.0	0.0	1	1	1	0	0	0	0	2
365	2	2016-10-18 21:01:01	199.7	193.6	201.8	0.0	0.0	0.0	49.17	0.0	0.0	1	1	1	0	0	0	0	2
366	2	2016-10-18 22:01:01	195.8	193.0	199.4	0.0	0.0	0.0	48.72	0.0	0.0	1	1	1	0	0	0	0	2
367	2	2016-10-18 22:03:30	194.8	192.7	195.6	0.0	0.0	0.0	48.15	0.0	0.0	1	0	0	0	0	0	0	2
368	2	2016-10-18 22:03:51	0.0	0.0	0.0	0.0	0.0	0.0	48.72	0.0	0.0	0	0	0	0	0	0	0	2
369	2	2016-10-18 23:01:01	0.0	0.0	0.0	0.0	0.0	0.0	48.40	0.0	0.0	0	0	0	0	0	0	0	2
370	2	2016-10-19 00:01:01	0.0	0.0	0.0	0.0	0.0	0.0	48.81	0.0	0.0	0	0	0	0	0	0	0	2
371	2	2016-10-19 00:03:46	209.9	205.6	210.5	0.0	0.0	0.0	48.59	0.0	0.0	1	0	0	0	0	0	0	2
372	2	2016-10-19 00:04:08	210.8	204.8	209.7	0.0	0.0	0.0	48.34	0.0	0.0	1	1	1	0	0	0	0	2
373	2	2016-10-19 01:01:01	209.6	202.6	210.9	0.0	0.0	0.0	48.70	0.0	0.0	1	1	1	0	0	0	0	2
374	2	2016-10-19 02:01:01	213.5	209.0	215.9	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
375	2	2016-10-19 03:01:01	217.2	212.5	219.0	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
376	2	2016-10-19 03:04:20	212.4	207.4	217.2	0.0	0.0	0.0	48.34	0.0	0.0	1	0	0	0	0	0	0	2
377	2	2016-10-19 03:04:41	0.0	0.0	0.0	0.0	0.0	0.0	48.54	0.0	0.0	0	0	0	0	0	0	0	2
378	2	2016-10-19 04:01:01	0.0	0.0	0.0	0.0	0.0	0.0	48.66	0.0	0.0	0	0	0	0	0	0	0	2
379	2	2016-10-19 05:01:01	0.0	0.0	0.0	0.0	0.0	0.0	48.71	0.0	0.0	0	0	0	0	0	0	0	2
380	2	2016-10-19 05:04:36	191.1	184.9	190.1	0.0	0.0	0.0	48.52	0.0	0.0	1	0	0	0	0	0	0	2
381	2	2016-10-19 05:04:58	192.2	186.7	193.4	0.0	0.0	0.0	48.37	0.0	0.0	1	1	1	0	0	0	0	2
382	2	2016-10-19 06:01:01	188.2	184.2	193.4	0.0	0.0	0.0	49.07	0.0	0.0	1	1	1	0	0	0	0	2
383	2	2016-10-19 07:01:01	197.6	191.6	197.4	0.0	0.0	0.0	48.42	0.0	0.0	1	1	1	0	0	0	0	2
384	2	2016-10-19 09:01:01	0.0	0.0	0.0	0.0	0.0	0.0	48.14	0.0	0.0	0	0	0	0	0	0	0	2
385	2	2016-10-19 11:03:01	194.3	192.2	197.9	0.0	0.0	0.0	48.82	0.0	0.0	1	1	1	0	0	0	0	2
386	2	2016-10-19 12:03:01	205.7	200.8	208.8	0.0	0.0	0.0	48.27	0.0	0.0	1	1	1	0	0	0	0	2
387	2	2016-10-19 12:04:17	206.3	201.7	211.5	0.0	0.0	0.0	48.78	0.0	0.0	1	0	0	0	0	0	0	2
388	2	2016-10-19 12:04:41	0.0	0.0	0.0	0.0	0.0	0.0	48.23	0.0	0.0	0	0	0	0	0	0	0	2
390	2	2016-10-19 13:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
391	2	2016-10-19 14:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.49	0.0	0.0	0	0	0	0	0	0	0	2
392	2	2016-10-19 14:04:31	203.8	198.8	205.9	0.0	0.0	0.0	48.86	0.0	0.0	1	0	0	0	0	0	0	2
393	2	2016-10-19 14:04:55	204.9	199.8	206.1	0.0	0.0	0.0	48.26	0.0	0.0	1	1	1	0	0	0	0	2
394	2	2016-10-19 15:03:01	201.6	194.5	202.6	0.0	0.0	0.0	48.73	0.0	0.0	1	1	1	0	0	0	0	2
395	2	2016-10-19 16:03:01	202.2	198.2	205.8	0.0	0.0	0.0	48.89	0.0	0.0	1	1	1	0	0	0	0	2
396	2	2016-10-19 17:03:01	202.3	194.4	201.3	0.0	0.0	0.0	48.49	0.0	0.0	1	1	1	0	0	0	0	2
397	2	2016-10-19 17:05:07	206.7	198.6	205.5	0.0	0.0	0.0	48.44	0.0	0.0	1	0	0	0	0	0	0	2
398	2	2016-10-19 17:05:31	0.0	0.0	0.0	0.0	0.0	0.0	48.22	0.0	0.0	0	0	0	0	0	0	0	2
399	2	2016-10-19 18:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.62	0.0	0.0	0	0	0	0	0	0	0	2
400	2	2016-10-19 19:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.48	0.0	1.0	0	0	0	0	0	0	0	2
401	2	2016-10-19 19:05:21	194.0	188.4	198.5	0.0	0.0	0.0	48.63	0.0	0.0	1	0	0	0	0	0	0	2
402	2	2016-10-19 19:05:45	193.1	187.9	196.0	0.0	0.0	0.0	48.64	0.0	0.0	1	1	1	0	0	0	0	2
403	2	2016-10-19 20:03:01	193.8	187.5	193.9	0.0	0.0	0.0	48.45	0.0	0.0	1	1	1	0	0	0	0	2
404	2	2016-10-19 21:03:01	196.3	191.4	200.8	0.0	0.0	0.0	48.28	0.0	0.0	1	1	1	0	0	0	0	2
405	2	2016-10-19 22:06:21	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
406	2	2016-10-19 22:03:01	195.3	189.2	198.4	0.0	0.0	0.0	48.49	0.0	0.0	1	1	1	0	0	0	0	2
407	2	2016-10-19 22:05:57	199.1	195.0	199.9	0.0	0.0	0.0	48.53	0.0	0.0	1	0	0	0	0	0	0	2
408	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
409	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
410	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
411	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
412	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
413	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
414	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
415	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
416	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
417	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
418	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
419	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
420	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
421	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
422	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
423	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
424	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
425	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
426	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
427	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
428	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
429	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
430	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
431	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
432	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
433	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
434	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
435	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
436	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
437	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
438	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
439	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
440	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
441	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
442	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
443	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
444	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
445	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
446	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
447	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
448	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
449	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
450	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
451	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
452	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
453	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
454	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
455	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
456	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
457	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
458	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
459	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
460	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
461	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
462	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
463	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
464	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
465	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
466	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
467	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
468	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
469	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
470	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
471	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
472	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
473	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
474	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
489	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
504	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
511	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
475	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
476	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
478	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
479	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
483	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
492	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
496	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
505	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
513	2	2016-10-20 00:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.63	0.0	0.0	0	0	0	0	0	0	0	2
477	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
491	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
494	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
509	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
514	2	2016-10-20 00:06:11	200.1	194.5	203.5	0.0	0.0	0.0	48.67	0.0	0.0	1	0	0	0	0	0	0	2
480	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
484	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
488	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
501	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
506	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
481	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
495	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
510	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
482	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
497	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
500	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
485	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
498	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
502	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
512	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
486	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
490	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
493	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
507	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
487	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
499	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
503	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
508	2	2016-10-19 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.25	0.0	0.0	0	0	0	0	0	0	0	2
515	2	2016-10-20 00:06:11	200.1	194.5	203.5	0.0	0.0	0.0	48.67	0.0	0.0	1	0	0	0	0	0	0	2
516	2	2016-10-20 00:06:35	200.8	198.4	202.2	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
517	2	2016-10-20 06:03:01	186.7	182.5	192.2	0.0	0.0	0.0	48.13	0.0	0.0	1	1	1	0	0	0	0	2
518	2	2016-10-20 07:03:01	199.9	198.8	203.2	0.0	0.0	0.0	48.46	0.0	0.0	1	1	1	0	0	0	0	2
519	2	2016-10-20 08:03:01	193.6	189.4	196.3	0.0	0.0	0.0	48.84	0.0	0.0	1	1	1	0	0	0	0	2
520	2	2016-10-20 08:07:37	198.6	196.4	203.8	0.0	0.0	0.0	48.65	0.0	0.0	1	0	0	0	0	0	0	2
521	2	2016-10-20 08:08:00	0.0	0.0	0.0	0.0	0.0	0.0	48.40	0.0	0.0	0	0	0	0	0	0	0	2
522	2	2016-10-20 09:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	0	0	2
523	2	2016-10-20 17:03:01	202.9	197.9	208.1	0.0	0.0	0.0	48.93	0.0	0.0	1	1	1	0	0	0	0	2
524	2	2016-10-20 18:03:01	193.5	188.3	195.8	0.0	0.0	0.0	48.66	0.0	0.0	1	1	1	0	0	0	0	2
525	2	2016-10-20 18:09:17	196.8	193.2	200.8	0.0	0.0	0.0	48.49	0.0	0.0	1	0	0	0	0	0	0	2
526	2	2016-10-20 18:09:41	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	0	0	2
527	2	2016-10-20 19:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.34	0.0	0.0	0	0	0	0	0	0	0	2
528	2	2016-10-20 20:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.78	0.0	0.0	0	0	0	0	0	0	0	2
676	2	2016-10-25 09:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.59	0.0	0.0	0	0	0	0	0	0	0	2
529	2	2016-10-20 20:09:31	202.7	197.2	203.3	0.0	0.0	0.0	48.39	0.0	0.0	1	0	0	0	0	0	0	2
530	2	2016-10-20 20:09:55	200.7	194.9	202.4	0.0	0.0	0.0	48.41	0.0	0.0	1	1	1	0	0	0	0	2
531	2	2016-10-20 21:03:01	202.9	196.5	204.6	0.0	0.0	0.0	48.36	0.0	0.0	1	1	1	0	0	0	0	2
532	2	2016-10-20 22:03:01	204.7	196.3	202.1	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
533	2	2016-10-21 06:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.50	0.0	0.0	0	0	0	0	0	0	0	2
534	2	2016-10-21 06:11:11	200.8	194.9	202.2	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
535	2	2016-10-21 06:11:35	204.0	196.9	204.2	0.0	0.0	0.0	48.61	0.0	0.0	1	1	1	0	0	0	0	2
536	2	2016-10-21 07:03:01	199.8	195.7	198.7	0.0	0.0	0.0	48.58	0.0	0.0	1	1	1	0	0	0	0	2
537	2	2016-10-21 08:03:01	199.8	193.4	200.8	0.0	0.0	0.0	48.56	0.0	0.0	1	1	1	0	0	0	0	2
538	2	2016-10-21 08:03:01	199.8	193.4	200.8	0.0	0.0	0.0	48.56	0.0	0.0	1	1	1	0	0	0	0	2
539	2	2016-10-21 09:03:01	203.2	199.6	204.7	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
540	2	2016-10-21 09:11:47	208.4	200.0	207.9	0.0	0.0	0.0	48.39	0.0	0.0	1	0	0	0	0	0	0	2
541	2	2016-10-21 09:12:11	0.0	0.0	0.0	0.0	0.0	0.0	48.51	0.0	0.0	0	0	0	0	0	0	0	2
542	2	2016-10-21 10:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.63	0.0	0.0	0	0	0	0	0	0	0	2
543	2	2016-10-21 10:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.63	0.0	0.0	0	0	0	0	0	0	0	2
544	2	2016-10-21 11:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.30	0.0	0.0	0	0	0	0	0	0	0	2
545	2	2016-10-21 11:12:00	212.1	206.5	214.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
546	2	2016-10-21 11:12:25	214.6	208.3	214.5	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
547	2	2016-10-21 12:03:01	212.3	208.2	214.3	0.0	0.0	0.0	48.99	0.0	0.0	1	1	1	0	0	0	0	2
548	2	2016-10-21 13:03:01	204.6	197.0	205.2	0.0	0.0	0.0	48.99	0.0	0.0	1	1	1	0	0	0	0	2
549	2	2016-10-21 14:03:01	205.2	201.3	210.9	0.0	0.0	0.0	48.73	0.0	0.0	1	1	1	0	0	0	0	2
550	2	2016-10-21 14:12:37	206.8	199.8	210.1	0.0	0.0	0.0	48.82	0.0	0.0	1	0	0	0	0	0	0	2
551	2	2016-10-21 14:13:00	0.0	0.0	0.0	0.0	0.0	0.0	48.11	0.0	0.0	0	0	0	0	0	0	0	2
552	2	2016-10-21 15:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.12	0.0	0.0	0	0	0	0	0	0	0	2
553	2	2016-10-21 16:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.76	0.0	0.0	0	0	0	0	0	0	0	2
554	2	2016-10-21 16:12:51	206.5	201.5	208.0	0.0	0.0	0.0	48.45	0.0	0.0	1	0	0	0	0	0	0	2
555	2	2016-10-21 16:13:15	205.2	200.0	207.6	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
556	2	2016-10-29 19:00:00	221.25	222.02	218.50	3.32	3.30	3.23	48.55	3.40	20.34	0	1	1	0	0	0	0	1
557	2	2016-10-21 17:00:00	221.25	222.02	218.50	3.32	3.30	3.23	48.55	3.40	20.34	0	1	1	0	0	0	0	1
558	2	2016-10-21 17:03:01	213.1	207.6	214.8	0.0	0.0	0.0	48.10	0.0	0.0	1	1	1	0	0	0	0	2
559	2	2016-10-21 18:03:01	200.0	194.8	202.6	0.0	0.0	0.0	48.38	0.0	0.0	1	1	1	0	0	0	0	2
560	2	2016-10-21 19:03:01	200.8	196.3	203.7	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
561	2	2016-10-21 19:13:27	204.6	200.0	206.2	0.0	0.0	0.0	48.29	0.0	0.0	1	0	0	0	0	0	0	2
562	2	2016-10-21 19:13:51	0.0	0.0	0.0	0.0	0.0	0.0	49.06	0.0	0.0	0	0	0	0	0	0	0	2
563	2	2016-10-22 05:15:07	199.9	195.7	203.5	0.0	0.0	0.0	48.36	0.0	0.0	1	0	0	0	0	0	0	2
564	2	2016-10-22 05:15:31	0.0	0.0	0.0	0.0	0.0	0.0	48.62	0.0	0.0	0	0	0	0	0	0	0	2
565	2	2016-10-22 06:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.69	0.0	0.0	0	0	0	0	0	0	0	2
566	2	2016-10-22 07:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	0	0	2
567	2	2016-10-22 07:15:21	186.4	184.2	189.8	0.0	0.0	0.0	48.28	0.0	0.0	1	0	0	0	0	0	0	2
568	2	2016-10-22 07:15:45	188.6	184.7	192.1	0.0	0.0	0.0	48.92	0.0	0.0	1	1	1	0	0	0	0	2
569	2	2016-10-22 08:03:01	198.2	190.5	196.7	0.0	0.0	0.0	48.62	0.0	0.0	1	1	1	0	0	0	0	2
570	2	2016-10-22 09:03:01	201.4	195.9	204.9	0.0	0.0	0.0	48.87	0.0	0.0	1	1	1	0	0	0	0	2
571	2	2016-10-22 10:03:01	192.7	188.9	195.2	0.0	0.0	0.0	48.66	0.0	0.0	1	1	1	0	0	0	0	2
572	2	2016-10-22 10:15:57	201.9	196.4	207.3	0.0	0.0	0.0	48.02	0.0	0.0	1	0	0	0	0	0	0	2
573	2	2016-10-22 10:16:21	0.0	0.0	0.0	0.0	0.0	0.0	48.42	0.0	0.0	0	0	0	0	0	0	0	2
574	2	2016-10-22 11:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.51	0.0	0.0	0	0	0	0	0	0	0	2
575	2	2016-10-22 13:03:01	205.1	202.7	210.7	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
576	2	2016-10-22 14:03:01	210.8	204.6	211.9	0.0	0.0	0.0	48.74	0.0	0.0	1	1	1	0	0	0	0	2
577	2	2016-10-22 15:03:01	207.8	202.2	210.5	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
578	2	2016-10-22 15:16:47	206.0	200.8	208.2	0.0	0.0	0.0	48.75	0.0	0.0	1	0	0	0	0	0	0	2
579	2	2016-10-22 15:17:11	0.0	0.0	0.0	0.0	0.0	0.0	48.39	0.0	0.0	0	0	0	0	0	0	0	2
580	2	2016-10-22 16:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.68	0.0	0.0	0	0	0	0	0	0	0	2
581	2	2016-10-22 17:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.54	0.0	0.0	0	0	0	0	0	0	0	2
582	2	2016-10-22 17:17:00	211.1	205.5	214.8	0.0	0.0	0.0	48.45	0.0	0.0	1	0	0	0	0	0	0	2
583	2	2016-10-22 17:17:25	211.8	210.0	214.4	0.0	0.0	0.0	49.08	0.0	0.0	1	1	1	0	0	0	0	2
584	2	2016-10-22 18:03:01	198.2	192.6	200.0	0.0	0.0	0.0	48.68	0.0	0.0	1	1	1	0	0	0	0	2
585	2	2016-10-22 19:03:01	211.7	204.0	212.0	0.0	0.0	0.0	48.79	0.0	0.0	1	1	1	0	0	0	0	2
586	2	2016-10-22 20:03:01	208.5	205.4	209.5	0.0	0.0	0.0	49.12	0.0	0.0	1	1	1	0	0	0	0	2
587	2	2016-10-22 20:17:37	207.9	203.9	211.2	0.0	0.0	0.0	48.24	0.0	0.0	1	0	0	0	0	0	0	2
588	2	2016-10-23 07:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.62	0.0	0.0	0	0	0	0	0	0	0	2
589	2	2016-10-23 08:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.43	0.0	0.0	0	0	0	0	0	0	0	2
590	2	2016-10-23 08:19:31	185.9	179.6	187.0	0.0	0.0	0.0	48.51	0.0	0.0	1	0	0	0	0	0	0	2
591	2	2016-10-23 08:19:55	187.8	184.1	186.6	0.0	0.0	0.0	48.91	0.0	0.0	1	1	1	0	0	0	0	2
592	2	2016-10-23 09:03:01	192.1	186.1	192.7	0.0	0.0	0.0	48.61	0.0	0.0	1	1	1	0	0	0	0	2
593	2	2016-10-23 10:03:01	192.1	187.9	191.9	0.0	0.0	0.0	48.79	0.0	0.0	1	1	1	0	0	0	0	2
594	2	2016-10-23 11:03:01	187.6	184.1	187.5	0.0	0.0	0.0	48.48	0.0	0.0	1	1	1	0	0	0	0	2
595	2	2016-10-23 11:03:01	187.6	184.1	187.5	0.0	0.0	0.0	48.48	0.0	0.0	1	1	1	0	0	0	0	2
596	2	2016-10-23 11:20:07	187.2	181.4	188.5	0.0	0.0	0.0	48.96	0.0	0.0	1	0	0	0	0	0	0	2
597	2	2016-10-23 11:20:31	0.0	0.0	0.0	0.0	0.0	0.0	48.62	0.0	0.0	0	0	0	0	0	0	0	2
598	2	2016-10-23 12:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.51	0.0	0.0	0	0	0	0	0	0	0	2
599	2	2016-10-23 13:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.37	0.0	0.0	0	0	0	0	0	0	0	2
600	2	2016-10-23 13:20:21	205.6	201.7	208.9	0.0	0.0	0.0	48.51	0.0	1.1	1	0	0	0	0	0	0	2
601	2	2016-10-23 13:20:45	207.1	202.7	209.9	0.0	0.0	0.0	48.73	0.0	0.0	1	1	1	0	0	0	0	2
602	2	2016-10-23 14:03:01	200.7	197.8	201.8	0.0	0.0	0.0	48.56	0.0	0.0	1	1	1	0	0	0	0	2
603	2	2016-10-23 15:03:01	201.5	196.5	206.5	0.0	0.0	0.0	48.97	0.0	0.0	1	1	1	0	0	0	0	2
604	2	2016-10-23 16:03:01	204.0	199.2	208.9	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
605	2	2016-10-23 16:20:57	209.1	204.3	208.8	0.0	0.0	0.0	48.64	0.0	0.0	1	0	0	0	0	0	0	2
606	2	2016-10-23 16:21:21	0.0	0.0	0.0	0.0	0.0	0.0	48.26	0.0	0.0	0	0	0	0	0	0	0	2
607	2	2016-10-23 17:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.48	0.0	0.0	0	0	0	0	0	0	0	2
608	2	2016-10-23 18:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.60	0.0	0.0	0	0	0	0	0	0	0	2
609	2	2016-10-23 18:21:11	203.4	199.7	205.3	0.0	0.0	0.0	48.66	0.0	0.0	1	0	0	0	0	0	0	2
610	2	2016-10-23 18:21:35	201.9	196.7	207.9	0.0	0.0	0.0	48.77	0.0	0.0	1	1	1	0	0	0	0	2
611	2	2016-10-23 19:03:01	201.0	193.6	202.2	0.0	0.0	0.0	48.39	0.0	0.0	1	1	1	0	0	0	0	2
612	2	2016-10-23 21:03:01	200.5	198.2	204.0	0.0	0.0	0.0	47.95	0.0	0.0	1	1	1	0	0	0	0	2
613	2	2016-10-23 21:21:47	201.2	195.8	201.3	0.0	0.0	0.0	48.77	0.0	0.0	1	0	0	0	0	0	0	2
614	2	2016-10-23 21:22:11	0.0	0.0	0.0	0.0	0.0	0.0	48.50	0.0	0.0	0	0	0	0	0	0	0	2
615	2	2016-10-23 22:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.71	0.0	0.0	0	0	0	0	0	0	0	2
616	2	2016-10-23 22:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.71	0.0	0.0	0	0	0	0	0	0	0	2
617	2	2016-10-23 23:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.50	0.0	0.0	0	0	0	0	0	0	0	2
618	2	2016-10-23 23:22:00	210.4	206.4	214.5	0.0	0.0	0.0	48.63	0.0	0.0	1	0	0	0	0	0	0	2
619	2	2016-10-23 23:22:25	212.0	206.4	214.9	0.0	0.0	0.0	48.32	0.0	0.0	1	1	1	0	0	0	0	2
620	2	2016-10-24 00:03:01	217.2	213.1	221.8	0.0	0.0	0.0	48.31	0.0	0.0	1	1	1	0	0	0	0	2
621	2	2016-10-24 01:03:01	216.6	215.7	221.3	0.0	0.0	0.0	48.46	0.0	0.0	1	1	1	0	0	0	0	2
622	2	2016-10-24 02:03:01	216.8	213.2	220.9	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
623	2	2016-10-24 02:22:37	212.5	206.2	213.4	0.0	0.0	0.0	48.38	0.0	0.0	1	0	0	0	0	0	0	2
624	2	2016-10-24 02:23:00	0.0	0.0	0.0	0.0	0.0	0.0	48.40	0.0	0.0	0	0	0	0	0	0	0	2
625	2	2016-10-24 03:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.39	0.0	0.0	0	0	0	0	0	0	0	2
626	2	2016-10-24 04:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.07	0.0	0.0	0	0	0	0	0	0	0	2
627	2	2016-10-24 04:22:51	209.6	204.3	210.6	0.0	0.0	0.0	48.68	0.0	0.0	1	0	0	0	0	0	0	2
628	2	2016-10-24 04:23:15	208.8	203.1	209.8	0.0	0.0	0.0	49.21	0.0	0.0	1	1	1	0	0	0	0	2
629	2	2016-10-24 05:03:01	203.9	195.1	204.2	0.0	0.0	0.0	48.73	0.0	0.0	1	1	1	0	0	0	0	2
630	2	2016-10-24 06:03:01	198.1	193.6	200.0	0.0	0.0	0.0	49.16	0.0	0.0	1	1	1	0	0	0	0	2
631	2	2016-10-24 07:03:01	204.9	201.0	209.2	0.0	0.0	0.0	47.76	0.0	0.0	1	1	1	0	0	0	0	2
632	2	2016-10-24 07:23:27	205.5	199.2	209.4	0.0	0.0	0.0	48.53	0.0	0.0	1	0	0	0	0	0	0	2
633	2	2016-10-24 07:23:51	0.0	0.0	0.0	0.0	0.0	0.0	48.68	0.0	0.0	0	0	0	0	0	0	0	2
634	2	2016-10-24 08:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.38	0.0	0.0	0	0	0	0	0	0	0	2
635	2	2016-10-24 09:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.74	0.0	0.0	0	0	0	0	0	0	0	2
636	2	2016-10-24 10:03:01	196.9	192.4	201.8	0.0	0.0	0.0	49.07	0.0	0.0	1	1	1	0	0	0	0	2
637	2	2016-10-24 11:03:01	201.2	192.9	199.5	0.0	0.0	0.0	48.21	0.0	0.0	1	1	1	0	0	0	0	2
638	2	2016-10-24 12:03:01	203.4	199.2	204.9	0.0	0.0	0.0	48.65	0.0	0.0	1	1	1	0	0	0	0	2
639	2	2016-10-24 12:24:17	199.3	194.5	204.4	0.0	0.0	0.0	48.55	0.0	0.0	1	0	0	0	0	0	0	2
640	2	2016-10-24 12:24:41	0.0	0.0	0.0	0.0	0.0	0.0	48.38	0.0	0.0	0	0	0	0	0	0	0	2
641	2	2016-10-24 13:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.30	0.0	0.0	0	0	0	0	0	0	0	2
642	2	2016-10-24 14:03:01	0.0	0.0	0.0	0.0	0.0	0.0	48.85	0.0	0.0	0	0	0	0	0	0	0	2
643	2	2016-10-24 14:24:31	197.7	193.9	199.4	0.0	0.0	0.0	48.78	0.0	0.0	1	0	0	0	0	0	0	2
644	2	2016-10-24 14:24:55	197.7	193.5	201.0	0.0	0.0	0.0	48.44	0.0	0.0	1	1	1	0	0	0	0	2
645	2	2016-10-24 15:39:01	204.8	198.7	204.6	0.0	0.0	0.0	49.02	0.0	0.0	1	1	1	0	0	0	0	2
646	2	2016-10-24 16:39:01	199.9	193.8	200.8	0.0	0.0	0.0	48.96	0.0	0.0	1	1	1	0	0	0	0	2
647	2	2016-10-24 17:39:01	193.9	188.8	194.3	0.0	0.0	0.0	48.85	0.0	0.0	1	1	1	0	0	0	0	2
648	2	2016-10-24 17:40:36	192.2	186.1	194.6	0.0	0.0	0.0	48.74	0.0	0.0	1	0	0	0	0	0	0	2
649	2	2016-10-24 17:40:56	0.0	0.0	0.0	0.0	0.0	0.0	49.01	0.0	0.0	0	0	0	0	0	0	0	2
650	2	2016-10-24 19:23:01	202.6	198.8	207.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
651	2	2016-10-24 20:23:01	197.8	192.5	201.0	0.0	0.0	0.0	49.02	0.0	0.0	1	1	1	0	0	0	0	2
652	2	2016-10-24 21:23:01	209.1	199.9	209.9	0.0	0.0	0.0	48.76	0.0	0.0	1	1	1	0	0	0	0	2
653	2	2016-10-24 21:24:40	204.0	198.9	208.0	0.0	0.0	0.0	48.81	0.0	0.0	1	0	0	0	0	0	0	2
654	2	2016-10-24 21:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.33	0.0	0.0	0	0	0	0	0	0	0	2
655	2	2016-10-24 22:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.73	0.0	0.0	0	0	0	0	0	0	0	2
656	2	2016-10-24 23:24:56	211.8	209.0	214.7	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
657	2	2016-10-24 23:25:19	214.1	206.9	218.1	0.0	0.0	0.0	48.16	0.0	1.1	1	1	1	0	0	0	0	2
658	2	2016-10-25 00:23:01	213.8	207.5	214.2	0.0	0.0	0.0	48.15	0.0	0.0	1	1	1	0	0	0	0	2
659	2	2016-10-25 01:23:01	210.6	207.6	216.1	0.0	0.0	0.0	48.28	0.0	0.0	1	1	1	0	0	0	0	2
660	2	2016-10-25 02:23:01	209.7	204.1	211.7	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
661	2	2016-10-25 02:25:30	212.3	206.4	215.6	0.0	0.0	0.0	48.41	0.0	0.0	1	0	0	0	0	0	0	2
662	2	2016-10-25 02:25:51	0.0	0.0	0.0	0.0	0.0	0.0	48.32	0.0	0.0	0	0	0	0	0	0	0	2
663	2	2016-10-25 03:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.60	0.0	0.0	0	0	0	0	0	0	0	2
664	2	2016-10-25 04:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.32	0.0	0.0	0	0	0	0	0	0	0	2
665	2	2016-10-25 04:25:46	209.4	205.3	212.1	0.0	0.0	0.0	48.65	0.0	0.0	1	0	0	0	0	0	0	2
666	2	2016-10-25 04:26:09	208.6	204.3	212.8	0.0	0.0	0.0	48.30	0.0	0.0	1	1	1	0	0	0	0	2
667	2	2016-10-25 05:23:01	200.0	195.0	202.1	0.0	0.0	0.0	48.79	0.0	0.0	1	1	1	0	0	0	0	2
668	2	2016-10-25 06:23:01	206.0	201.1	208.0	0.0	0.0	0.0	48.42	0.0	0.0	1	1	1	0	0	0	0	2
669	2	2016-10-25 07:23:01	197.0	193.4	197.5	0.0	0.0	0.0	48.17	0.0	0.0	1	1	1	0	0	0	0	2
670	2	2016-10-25 07:23:01	197.0	193.4	197.5	0.0	0.0	0.0	48.17	0.0	0.0	1	1	1	0	0	0	0	2
671	2	2016-10-25 07:26:21	201.3	196.2	202.0	0.0	0.0	0.0	48.41	0.0	0.0	1	0	0	0	0	0	0	2
672	2	2016-10-25 07:26:21	201.3	196.2	202.0	0.0	0.0	0.0	48.41	0.0	0.0	1	0	0	0	0	0	0	2
673	2	2016-10-25 07:26:42	0.0	0.0	0.0	0.0	0.0	0.0	48.65	0.0	0.0	0	0	0	0	0	0	0	2
674	2	2016-10-25 08:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.63	0.0	0.0	0	0	0	0	0	0	0	2
675	2	2016-10-25 09:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.59	0.0	0.0	0	0	0	0	0	0	0	2
677	2	2016-10-25 09:26:36	202.7	198.9	201.8	0.0	0.0	0.0	48.88	0.0	0.0	1	0	0	0	0	0	0	2
678	2	2016-10-25 09:26:59	200.5	194.0	202.1	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
679	2	2016-10-25 10:23:01	207.3	202.3	208.8	0.0	0.0	0.0	48.79	0.0	0.0	1	1	1	0	0	0	0	2
680	2	2016-10-25 11:23:01	199.0	193.1	201.3	0.0	0.0	0.0	48.46	0.0	0.0	1	1	1	0	0	0	0	2
681	2	2016-10-25 12:23:01	204.0	198.6	206.3	0.0	0.0	0.0	49.05	0.0	0.0	1	1	1	0	0	0	0	2
682	2	2016-10-25 12:23:01	204.0	198.6	206.3	0.0	0.0	0.0	49.05	0.0	0.0	1	1	1	0	0	0	0	2
683	2	2016-10-25 12:27:11	202.9	196.5	205.5	0.0	0.0	0.0	48.34	0.0	0.0	1	0	0	0	0	0	0	2
684	2	2016-10-25 12:27:31	0.0	0.0	0.0	0.0	0.0	0.0	48.76	0.0	0.0	0	0	0	0	0	0	0	2
685	2	2016-10-25 13:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.33	0.0	0.0	0	0	0	0	0	0	0	2
686	2	2016-10-26 10:23:01	206.3	200.7	209.3	0.0	0.0	0.0	48.50	0.0	0.0	1	1	1	0	0	0	0	2
687	2	2016-10-26 10:26:47	200.0	195.0	205.0	0.0	0.0	0.0	48.90	0.0	0.0	1	0	0	0	0	0	0	2
688	2	2016-10-26 10:27:11	0.0	0.0	0.0	0.0	0.0	0.0	48.37	0.0	0.0	0	0	0	0	0	0	0	2
689	2	2016-10-26 11:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.38	0.0	0.0	0	0	0	0	0	0	0	2
690	2	2016-10-26 12:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.61	0.0	0.0	0	0	0	0	0	0	0	2
691	2	2016-10-26 12:27:00	198.5	192.3	200.3	0.0	0.0	0.0	48.36	0.0	0.0	1	0	0	0	0	0	0	2
692	2	2016-10-26 12:27:25	200.7	195.0	202.0	0.0	0.0	0.0	48.46	0.0	0.0	1	1	1	0	0	0	0	2
693	2	2016-10-26 13:23:01	203.9	198.8	206.2	0.0	0.0	0.0	48.88	0.0	0.0	1	1	1	0	0	0	0	2
694	2	2016-10-26 14:23:01	204.8	202.3	207.4	0.0	0.0	0.0	48.66	0.0	0.0	1	1	1	0	0	0	0	2
695	2	2016-10-26 15:23:01	200.0	195.1	200.5	0.0	0.0	0.0	48.91	0.0	0.0	1	1	1	0	0	0	0	2
696	2	2016-10-26 15:27:37	196.3	190.9	199.1	0.0	0.0	0.0	48.33	0.0	0.0	1	0	0	0	0	0	0	2
697	2	2016-10-26 15:28:00	0.0	0.0	0.0	0.0	0.0	0.0	48.52	0.0	0.0	0	0	0	0	0	0	0	2
698	2	2016-10-26 16:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.53	0.0	0.0	0	0	0	0	0	0	0	2
699	2	2016-10-26 17:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.30	0.0	0.0	0	0	0	0	0	0	0	2
700	2	2016-10-26 17:27:51	199.8	194.9	201.6	0.0	0.0	0.0	48.67	0.0	0.0	1	0	0	0	0	0	0	2
701	2	2016-10-26 17:28:15	200.2	199.1	203.8	0.0	0.0	0.0	48.98	0.0	0.0	1	1	1	0	0	0	0	2
702	2	2016-10-26 17:28:15	200.2	199.1	203.8	0.0	0.0	0.0	48.98	0.0	0.0	1	1	1	0	0	0	0	2
703	2	2016-10-26 18:23:01	195.7	190.2	198.3	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
704	2	2016-10-26 18:23:01	195.7	190.2	198.3	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
705	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
706	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
707	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
708	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
709	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
710	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
711	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
712	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
713	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
714	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
715	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
716	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
717	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
718	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
719	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
720	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
721	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
722	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
723	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
724	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
725	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
726	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
727	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
728	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
729	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
730	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
731	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
732	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
733	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
734	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
735	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
736	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
737	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
738	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
739	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
740	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
741	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
742	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
743	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
744	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
745	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
746	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
747	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
748	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
749	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
750	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
751	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
752	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
753	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
754	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
755	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
756	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
757	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
758	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
759	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
760	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
761	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
762	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
763	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
764	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
765	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
766	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
767	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
768	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
769	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
770	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
771	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
772	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
773	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
774	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
775	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
776	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
777	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
778	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
779	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
780	2	2016-10-26 19:23:01	201.3	198.8	204.1	0.0	0.0	0.0	48.22	0.0	0.0	1	1	1	0	0	0	0	2
781	2	2016-10-26 20:23:01	199.3	197.6	203.0	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
782	2	2016-10-26 20:28:27	203.0	195.7	202.6	0.0	0.0	0.0	48.28	0.0	0.0	1	0	0	0	0	0	0	2
783	2	2016-10-26 20:28:51	0.0	0.0	0.0	0.0	0.0	0.0	48.31	0.0	0.0	0	0	0	0	0	0	0	2
784	2	2016-10-26 21:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.71	0.0	0.0	0	0	0	0	0	0	0	2
785	2	2016-10-26 22:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.69	0.0	0.0	0	0	0	0	0	0	0	2
786	2	2016-10-26 22:28:41	205.2	199.0	209.1	0.0	0.0	0.0	48.66	0.0	0.0	1	0	0	0	0	0	0	2
787	2	2016-10-26 22:29:05	207.6	201.7	208.6	0.0	0.0	0.0	48.56	0.0	0.0	1	1	1	0	0	0	0	2
788	2	2016-10-26 23:23:01	208.4	204.8	214.3	0.0	0.0	0.0	48.36	0.0	0.0	1	1	1	0	0	0	0	2
789	2	2016-10-27 00:23:01	217.3	211.2	218.2	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
790	2	2016-10-27 01:23:01	217.2	212.1	220.2	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
791	2	2016-10-27 01:29:17	217.2	213.0	220.3	0.0	0.0	0.0	48.40	0.0	1.1	1	0	0	0	0	0	0	2
792	2	2016-10-27 01:29:41	0.0	0.0	0.0	0.0	0.0	0.0	48.29	0.0	0.0	0	0	0	0	0	0	0	2
793	2	2016-10-27 01:29:41	0.0	0.0	0.0	0.0	0.0	0.0	48.29	0.0	0.0	0	0	0	0	0	0	0	2
794	2	2016-10-27 02:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.26	0.0	0.0	0	0	0	0	0	0	0	2
795	2	2016-10-27 02:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.26	0.0	0.0	0	0	0	0	0	0	0	2
796	2	2016-10-27 03:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.42	0.0	0.0	0	0	0	0	0	0	0	2
797	2	2016-10-27 03:29:31	220.8	214.0	221.4	0.0	0.0	0.0	48.43	0.0	0.0	1	0	0	0	0	0	0	2
798	2	2016-10-27 03:29:55	218.5	213.1	219.8	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
799	2	2016-10-27 04:23:01	215.0	210.3	217.7	0.0	0.0	0.0	48.14	0.0	0.0	1	1	1	0	0	0	0	2
800	2	2016-10-27 04:23:01	215.0	210.3	217.7	0.0	0.0	0.0	48.14	0.0	0.0	1	1	1	0	0	0	0	2
801	2	2016-10-27 05:23:01	188.9	183.8	191.2	0.0	0.0	0.0	48.40	0.0	0.0	1	1	1	0	0	0	0	2
802	2	2016-10-27 06:23:01	198.0	191.7	202.5	0.0	0.0	0.0	48.49	0.0	0.0	1	1	1	0	0	0	0	2
803	2	2016-10-27 06:30:07	203.9	198.7	206.6	0.0	0.0	0.0	48.54	0.0	0.0	1	0	0	0	0	0	0	2
804	2	2016-10-27 06:30:31	0.0	0.0	0.0	0.0	0.0	0.0	48.79	0.0	0.0	0	0	0	0	0	0	0	2
805	2	2016-10-27 06:30:31	0.0	0.0	0.0	0.0	0.0	0.0	48.79	0.0	0.0	0	0	0	0	0	0	0	2
806	2	2016-10-27 07:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.83	0.0	0.0	0	0	0	0	0	0	0	2
807	2	2016-10-27 08:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.43	0.0	0.0	0	0	0	0	0	0	0	2
808	2	2016-10-27 08:30:21	196.5	189.7	198.2	0.0	0.0	0.0	48.44	0.0	0.0	1	0	0	0	0	0	0	2
809	2	2016-10-27 08:30:45	197.6	195.8	201.4	0.0	0.0	0.0	48.35	0.0	0.0	1	1	1	0	0	0	0	2
810	2	2016-10-27 09:23:01	200.0	196.5	204.9	0.0	0.0	0.0	48.28	0.0	0.0	1	1	1	0	0	0	0	2
811	2	2016-10-27 10:23:01	200.8	199.3	206.5	0.0	0.0	0.0	49.24	0.0	0.0	1	1	1	0	0	0	0	2
812	2	2016-10-27 11:23:01	206.1	199.8	206.7	0.0	0.0	0.0	48.90	0.0	0.0	1	1	1	0	0	0	0	2
813	2	2016-10-27 11:30:57	206.0	201.8	209.1	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
814	2	2016-10-27 11:31:21	0.0	0.0	0.0	0.0	0.0	0.0	48.55	0.0	0.0	0	0	0	0	0	0	0	2
815	2	2016-10-27 12:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.62	0.0	0.0	0	0	0	0	0	0	0	2
816	2	2016-10-27 13:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.66	0.0	0.0	0	0	0	0	0	0	0	2
817	2	2016-10-27 13:31:11	200.9	196.4	202.0	0.0	0.0	0.0	48.53	0.0	0.0	1	0	0	0	0	0	0	2
818	2	2016-10-27 13:31:35	200.0	197.3	201.3	0.0	0.0	0.0	48.38	0.0	0.0	1	1	1	0	0	0	0	2
819	2	2016-10-27 14:23:01	206.3	203.7	209.4	0.0	0.0	0.0	48.39	0.0	0.0	1	1	1	0	0	0	0	2
820	2	2016-10-27 15:23:01	203.2	200.6	206.3	0.0	0.0	0.0	48.68	0.0	0.0	1	1	1	0	0	0	0	2
821	2	2016-10-27 16:23:01	202.5	194.0	202.4	0.0	0.0	0.0	48.78	0.0	0.0	1	1	1	0	0	0	0	2
822	2	2016-10-27 16:31:47	207.2	201.0	205.9	0.0	0.0	0.0	48.57	0.0	0.0	1	0	0	0	0	0	0	2
823	2	2016-10-27 16:31:47	207.2	201.0	205.9	0.0	0.0	0.0	48.57	0.0	0.0	1	0	0	0	0	0	0	2
824	2	2016-10-27 16:32:11	0.0	0.0	0.0	0.0	0.0	0.0	48.72	0.0	0.0	0	0	0	0	0	0	0	2
825	2	2016-10-27 16:32:11	0.0	0.0	0.0	0.0	0.0	0.0	48.72	0.0	0.0	0	0	0	0	0	0	0	2
826	2	2016-10-27 17:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	0	0	2
827	2	2016-10-27 18:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.14	0.0	0.0	0	0	0	0	0	0	0	2
828	2	2016-10-27 18:32:00	196.9	191.2	197.9	0.0	0.0	0.0	48.79	0.0	0.0	1	0	0	0	0	0	0	2
829	2	2016-10-27 18:32:25	195.7	191.9	198.8	0.0	0.0	0.0	48.40	0.0	1.0	1	1	1	0	0	0	0	2
830	2	2016-10-27 19:23:01	198.0	192.4	198.6	0.0	0.0	0.0	48.13	0.0	0.0	1	1	1	0	0	0	0	2
831	2	2016-10-27 20:23:01	200.9	195.3	206.2	0.0	0.0	0.0	49.13	0.0	0.0	1	1	1	0	0	0	0	2
832	2	2016-10-27 20:23:01	200.9	195.3	206.2	0.0	0.0	0.0	49.13	0.0	0.0	1	1	1	0	0	0	0	2
833	2	2016-10-27 21:23:01	212.3	204.5	211.5	0.0	0.0	0.0	48.70	0.0	0.0	1	1	1	0	0	0	0	2
834	2	2016-10-27 21:32:37	199.5	194.7	203.3	0.0	0.0	0.0	48.69	0.0	0.0	1	0	0	0	0	0	0	2
835	2	2016-10-27 21:32:37	199.5	194.7	203.3	0.0	0.0	0.0	48.69	0.0	0.0	1	0	0	0	0	0	0	2
836	2	2016-10-27 21:33:00	0.0	0.0	0.0	0.0	0.0	0.0	48.43	0.0	0.0	0	0	0	0	0	0	0	2
837	2	2016-10-27 22:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.52	0.0	0.0	0	0	0	0	0	0	0	2
838	2	2016-10-27 23:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.67	0.0	0.0	0	0	0	0	0	0	0	2
839	2	2016-10-27 23:32:51	212.1	206.4	212.2	0.0	0.0	0.0	48.40	0.0	0.0	1	0	0	0	0	0	0	2
840	2	2016-10-27 23:33:15	210.8	205.2	212.0	0.0	0.0	0.0	48.41	0.0	0.0	1	1	1	0	0	0	0	2
841	2	2016-10-28 00:23:01	211.0	205.0	213.8	0.0	0.0	0.0	49.00	0.0	0.0	1	1	1	0	0	0	0	2
842	2	2016-10-28 01:23:01	217.2	214.7	221.2	0.0	0.0	0.0	48.29	0.0	0.0	1	1	1	0	0	0	0	2
843	2	2016-10-28 02:23:01	217.7	211.9	220.2	0.0	0.0	0.0	48.23	0.0	0.0	1	1	1	0	0	0	0	2
844	2	2016-10-28 02:33:27	213.5	208.4	216.0	0.0	0.0	0.0	48.45	0.0	0.0	1	0	0	0	0	0	0	2
845	2	2016-10-28 02:33:51	0.0	0.0	0.0	0.0	0.0	0.0	48.66	0.0	0.0	0	0	0	0	0	0	0	2
846	2	2016-10-28 03:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.45	0.0	0.0	0	0	0	0	0	0	0	2
847	2	2016-10-28 04:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.27	0.0	0.0	0	0	0	0	0	0	0	2
848	2	2016-10-28 04:33:41	204.7	201.4	208.1	0.0	0.0	0.0	48.66	0.0	0.0	1	0	0	0	0	0	0	2
849	2	2016-10-28 04:34:05	205.7	200.0	206.7	0.0	0.0	0.0	48.45	0.0	0.0	1	1	1	0	0	0	0	2
850	2	2016-10-28 05:23:01	190.7	186.7	194.0	0.0	0.0	0.0	48.82	0.0	0.0	1	1	1	0	0	0	0	2
851	2	2016-10-28 05:23:01	190.7	186.7	194.0	0.0	0.0	0.0	48.82	0.0	0.0	1	1	1	0	0	0	0	2
852	2	2016-10-28 06:23:01	191.1	188.8	195.2	0.0	0.0	0.0	48.51	0.0	0.0	1	1	1	0	0	0	0	2
853	2	2016-10-28 07:23:01	205.8	199.4	206.3	0.0	0.0	0.0	48.72	0.0	0.0	1	1	1	0	0	0	0	2
854	2	2016-10-28 07:34:17	195.2	188.4	196.4	0.0	0.0	0.0	48.78	0.0	0.0	1	0	0	0	0	0	0	2
855	2	2016-10-28 07:34:41	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
856	2	2016-10-28 07:34:41	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
857	2	2016-10-28 08:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.54	0.0	0.0	0	0	0	0	0	0	0	2
858	2	2016-10-28 09:23:01	0.0	0.0	0.0	0.0	0.0	0.0	48.61	0.0	0.0	0	0	0	0	0	0	0	2
859	2	2016-10-28 09:34:31	189.4	184.4	191.0	0.0	0.0	0.0	48.58	0.0	0.0	1	0	0	0	0	0	0	2
860	2	2016-10-28 09:34:55	190.1	184.3	192.6	0.0	0.0	0.0	48.81	0.0	0.0	1	1	1	0	0	0	0	2
861	2	2016-10-28 10:23:01	199.8	197.0	201.2	0.0	0.0	0.0	48.98	0.0	0.0	1	1	1	0	0	0	0	2
862	2	2016-10-28 17:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.54	0.0	0.0	0	0	0	0	0	0	0	2
863	2	2016-10-30 06:25:01	196.5	190.1	200.0	0.0	0.0	0.0	48.73	0.0	0.0	1	1	1	0	0	0	0	2
864	2	2016-10-30 07:25:01	197.2	190.7	201.1	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
865	2	2016-10-30 08:25:01	201.0	196.1	203.3	0.0	0.0	0.0	48.20	0.0	0.0	1	1	1	0	0	0	0	2
866	2	2016-10-30 08:32:26	202.9	196.9	206.2	0.0	0.0	0.0	48.46	0.0	0.0	1	0	0	0	0	0	0	2
867	2	2016-10-30 08:32:46	0.0	0.0	0.0	0.0	0.0	0.0	48.81	0.0	0.0	0	0	0	0	0	0	0	2
868	2	2016-10-30 09:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.37	0.0	0.0	0	0	0	0	0	0	0	2
869	2	2016-10-30 10:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.89	0.0	0.0	0	0	0	0	0	0	0	2
870	2	2016-10-30 10:32:41	194.4	186.8	193.2	0.0	0.0	0.0	48.46	0.0	0.0	1	0	0	0	0	0	0	2
871	2	2016-10-30 10:33:04	192.4	186.5	193.7	0.0	0.0	0.0	48.89	0.0	0.0	1	1	1	0	0	0	0	2
872	2	2016-10-30 11:25:01	205.6	200.3	206.3	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
873	2	2016-10-30 12:25:01	192.2	186.0	190.1	0.0	0.0	0.0	48.61	0.0	0.0	1	1	1	0	0	0	0	2
874	2	2016-10-30 12:25:01	192.2	186.0	190.1	0.0	0.0	0.0	48.61	0.0	0.0	1	1	1	0	0	0	0	2
875	2	2016-10-30 13:25:01	202.1	199.4	205.5	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
1095	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
876	2	2016-10-30 13:33:11	202.7	197.9	204.2	0.0	0.0	0.0	48.55	0.0	0.0	1	0	0	0	0	0	0	2
877	2	2016-10-30 13:33:31	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
878	2	2016-10-30 14:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
879	2	2016-10-30 15:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.65	0.0	0.0	0	0	0	0	0	0	0	2
880	2	2016-10-30 15:33:26	202.6	197.6	204.2	0.0	0.0	0.0	48.05	0.0	0.0	1	0	0	0	0	0	0	2
881	2	2016-10-30 15:33:26	202.6	197.6	204.2	0.0	0.0	0.0	48.05	0.0	0.0	1	0	0	0	0	0	0	2
882	2	2016-10-30 15:33:49	205.3	201.5	205.1	0.0	0.0	0.0	48.37	0.0	0.0	1	1	1	0	0	0	0	2
883	2	2016-10-30 16:25:01	200.2	194.7	202.8	0.0	0.0	0.0	47.89	0.0	0.0	1	1	1	0	0	0	0	2
884	2	2016-10-30 17:25:01	196.2	188.8	195.9	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
885	2	2016-10-30 18:25:01	198.9	194.1	204.0	0.0	0.0	0.0	48.34	0.0	0.0	1	1	1	0	0	0	0	2
886	2	2016-10-30 18:34:01	196.9	193.8	198.9	0.0	0.0	0.0	48.44	0.0	0.0	1	0	0	0	0	0	0	2
887	2	2016-10-30 18:34:21	0.0	0.0	0.0	0.0	0.0	0.0	49.05	0.0	0.0	0	0	0	0	0	0	0	2
888	2	2016-10-30 18:34:21	0.0	0.0	0.0	0.0	0.0	0.0	49.05	0.0	0.0	0	0	0	0	0	0	0	2
889	2	2016-10-30 19:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.21	0.0	0.0	0	0	0	0	0	0	0	2
890	2	2016-10-30 19:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.21	0.0	0.0	0	0	0	0	0	0	0	2
891	2	2016-10-30 20:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.64	0.0	0.0	0	0	0	0	0	0	0	2
892	2	2016-10-30 20:34:16	196.8	190.9	199.3	0.0	0.0	0.0	48.56	0.0	0.0	1	0	0	0	0	0	0	2
893	2	2016-10-30 20:34:39	199.3	194.5	200.2	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
894	2	2016-10-30 21:25:01	198.4	194.1	199.9	0.0	0.0	0.0	48.97	0.0	0.0	1	1	1	0	0	0	0	2
895	2	2016-10-30 22:25:01	209.0	205.5	209.9	0.0	0.0	0.0	48.50	0.0	0.0	1	1	1	0	0	0	0	2
896	2	2016-10-30 23:25:01	217.4	213.3	217.2	0.0	0.0	0.0	48.82	0.0	0.0	1	1	1	0	0	0	0	2
897	2	2016-10-30 23:34:51	208.1	204.5	211.9	0.0	0.0	0.0	48.65	0.0	0.0	1	0	0	0	0	0	0	2
898	2	2016-10-30 23:35:11	0.0	0.0	0.0	0.0	0.0	0.0	48.43	0.0	0.0	0	0	0	0	0	0	0	2
899	2	2016-10-31 00:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.09	0.0	0.0	0	0	0	0	0	0	0	2
900	2	2016-10-31 01:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.35	0.0	0.0	0	0	0	0	0	0	0	2
901	2	2016-10-31 01:35:06	217.0	210.8	218.8	0.0	0.0	0.0	48.62	0.0	0.0	1	0	0	0	0	0	0	2
902	2	2016-10-31 01:35:06	217.0	210.8	218.8	0.0	0.0	0.0	48.62	0.0	0.0	1	0	0	0	0	0	0	2
903	2	2016-10-31 01:35:29	216.0	211.1	218.2	0.0	0.0	0.0	48.40	0.0	0.0	1	1	1	0	0	0	0	2
904	2	2016-10-31 01:35:29	216.0	211.1	218.2	0.0	0.0	0.0	48.40	0.0	0.0	1	1	1	0	0	0	0	2
905	2	2016-10-31 02:25:01	222.1	215.5	222.3	0.0	0.0	0.0	48.48	0.0	0.0	1	1	1	0	0	0	0	2
906	2	2016-10-31 03:25:01	220.0	217.1	224.5	0.0	0.0	0.0	48.49	0.0	0.0	1	1	1	0	0	0	0	2
907	2	2016-10-31 04:25:01	221.0	213.0	219.2	0.0	0.0	0.0	48.66	0.0	0.0	1	1	1	0	0	0	0	2
908	2	2016-10-31 04:35:41	210.6	207.1	215.7	0.0	0.0	0.0	48.36	0.0	0.0	1	0	0	0	0	0	0	2
909	2	2016-10-31 04:36:06	0.0	0.0	0.0	0.0	0.0	0.0	48.59	0.0	0.0	0	0	0	0	0	0	0	2
910	2	2016-10-31 05:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.71	0.0	0.0	0	0	0	0	0	0	0	2
911	2	2016-10-31 06:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.45	0.0	0.0	0	0	0	0	0	0	0	2
912	2	2016-10-31 06:35:56	204.7	198.1	207.8	0.0	0.0	0.0	48.31	0.0	0.0	1	0	0	0	0	0	0	2
913	2	2016-10-31 06:36:19	205.3	197.6	204.2	0.0	0.0	0.0	48.72	0.0	0.0	1	1	1	0	0	0	0	2
914	2	2016-10-31 07:25:01	195.6	193.5	197.2	0.0	0.0	0.0	48.34	0.0	0.0	1	1	1	0	0	0	0	2
915	2	2016-10-31 08:25:01	202.5	197.0	203.3	0.0	0.0	0.0	48.57	0.0	0.0	1	1	1	0	0	0	0	2
916	2	2016-10-31 09:25:01	203.3	194.8	205.4	0.0	0.0	0.0	48.26	0.0	0.0	1	1	1	0	0	0	0	2
917	2	2016-10-31 09:36:31	201.3	195.4	202.8	0.0	0.0	0.0	48.66	0.0	0.0	1	0	0	0	0	0	0	2
918	2	2016-10-31 09:36:51	0.0	0.0	0.0	0.0	0.0	0.0	48.45	0.0	0.0	0	0	0	0	0	0	0	2
919	2	2016-10-31 10:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.63	0.0	0.0	0	0	0	0	0	0	0	2
920	2	2016-10-31 11:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.46	0.0	0.0	0	0	0	0	0	0	0	2
921	2	2016-10-31 11:36:46	196.9	192.2	199.7	0.0	0.0	0.0	49.36	0.0	0.0	1	0	0	0	0	0	0	2
922	2	2016-10-31 11:37:09	202.2	194.7	200.3	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
923	2	2016-10-31 12:25:01	203.7	198.9	209.2	0.0	0.0	0.0	48.36	0.0	0.0	1	1	1	0	0	0	0	2
924	2	2016-10-31 13:25:01	201.3	196.2	202.7	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
925	2	2016-10-31 14:25:01	201.7	199.2	205.4	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
926	2	2016-10-31 14:37:21	203.6	199.6	206.3	0.0	0.0	0.0	48.52	0.0	1.1	1	0	0	0	0	0	0	2
927	2	2016-10-31 14:37:41	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
928	2	2016-10-31 15:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.92	0.0	0.0	0	0	0	0	0	0	0	2
929	2	2016-10-31 16:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.97	0.0	0.0	0	0	0	0	0	0	0	2
930	2	2016-10-31 16:37:36	204.1	198.2	208.4	0.0	0.0	0.0	48.15	0.0	0.0	1	0	0	0	0	0	0	2
931	2	2016-10-31 16:37:59	203.8	199.2	208.0	0.0	0.0	0.0	48.70	0.0	0.0	1	1	1	0	0	0	0	2
932	2	2016-10-31 17:25:01	202.3	196.8	203.9	0.0	0.0	0.0	48.99	0.0	0.0	1	1	1	0	0	0	0	2
933	2	2016-10-31 18:25:01	203.2	198.0	204.6	0.0	0.0	0.0	48.30	0.0	0.0	1	1	1	0	0	0	0	2
934	2	2016-10-31 19:25:01	199.1	193.6	203.0	0.0	0.0	0.0	49.30	0.0	0.0	1	1	1	0	0	0	0	2
935	2	2016-10-31 19:38:11	197.3	192.0	199.1	0.0	0.0	0.0	48.64	0.0	0.0	1	0	0	0	0	0	0	2
936	2	2016-10-31 19:38:31	0.0	0.0	0.0	0.0	0.0	0.0	48.83	0.0	0.0	0	0	0	0	0	0	0	2
937	2	2016-10-31 21:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.53	0.0	0.0	0	0	0	0	0	0	0	2
938	2	2016-10-31 20:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	0	0	2
939	2	2016-10-31 21:38:26	209.0	200.6	210.8	0.0	0.0	0.0	48.13	0.0	0.0	1	0	0	0	0	0	0	2
940	2	2016-10-31 21:38:49	206.1	202.3	210.6	0.0	0.0	0.0	48.25	0.0	0.0	1	1	1	0	0	0	0	2
941	2	2016-10-31 22:25:01	210.0	203.4	211.0	0.0	0.0	0.0	48.90	0.0	0.0	1	1	1	0	0	0	0	2
942	2	2016-10-31 23:25:01	217.5	212.0	220.0	0.0	0.0	0.0	48.51	0.0	0.0	1	1	1	0	0	0	0	2
943	2	2016-11-01 00:25:01	216.0	212.1	217.0	0.0	0.0	0.0	48.46	0.0	0.0	1	1	1	0	0	0	0	2
944	2	2016-11-01 00:39:01	216.0	211.5	218.4	0.0	0.0	0.0	48.56	0.0	0.0	1	0	0	0	0	0	0	2
945	2	2016-11-01 00:39:21	0.0	0.0	0.0	0.0	0.0	0.0	48.94	0.0	0.0	0	0	0	0	0	0	0	2
946	2	2016-11-01 01:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.43	0.0	0.0	0	0	0	0	0	0	0	2
947	2	2016-11-01 02:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.72	0.0	0.0	0	0	0	0	0	0	0	2
948	2	2016-11-01 02:39:16	217.7	211.0	218.0	0.0	0.0	0.0	48.42	0.0	0.0	1	0	0	0	0	0	0	2
949	2	2016-11-01 02:39:39	215.7	210.3	218.5	0.0	0.0	0.0	48.70	0.0	1.3	1	1	1	0	0	0	0	2
950	2	2016-11-01 03:25:01	215.8	212.0	221.0	0.0	0.0	0.0	48.16	0.0	0.0	1	1	1	0	0	0	0	2
951	2	2016-11-01 04:25:01	206.5	200.3	207.2	0.0	0.0	0.0	48.08	0.0	0.0	1	1	1	0	0	0	0	2
952	2	2016-11-01 05:25:01	195.3	187.7	193.7	0.0	0.0	0.0	48.68	0.0	0.0	1	1	1	0	0	0	0	2
953	2	2016-11-01 05:25:01	195.3	187.7	193.7	0.0	0.0	0.0	48.68	0.0	0.0	1	1	1	0	0	0	0	2
954	2	2016-11-01 05:39:51	192.6	187.5	193.4	0.0	0.0	0.0	48.17	0.0	0.0	1	0	0	0	0	0	0	2
955	2	2016-11-01 05:39:51	192.6	187.5	193.4	0.0	0.0	0.0	48.17	0.0	0.0	1	0	0	0	0	0	0	2
956	2	2016-11-01 05:40:11	0.0	0.0	0.0	0.0	0.0	0.0	48.39	0.0	0.0	0	0	0	0	0	0	0	2
957	2	2016-11-01 05:40:11	0.0	0.0	0.0	0.0	0.0	0.0	48.39	0.0	0.0	0	0	0	0	0	0	0	2
958	2	2016-11-01 06:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
959	2	2016-11-01 06:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
960	2	2016-11-01 07:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.64	0.0	0.0	0	0	0	0	0	0	0	2
961	2	2016-11-01 07:25:01	0.0	0.0	0.0	0.0	0.0	0.0	48.64	0.0	0.0	0	0	0	0	0	0	0	2
962	2	2016-11-01 07:40:06	194.2	190.5	202.7	0.0	0.0	0.0	48.45	0.0	0.0	1	0	0	0	0	0	0	2
963	2	2016-11-01 07:40:06	194.2	190.5	202.7	0.0	0.0	0.0	48.45	0.0	0.0	1	0	0	0	0	0	0	2
964	2	2016-11-01 07:40:29	197.0	193.1	198.7	0.0	0.0	0.0	48.23	0.0	0.0	1	1	1	0	0	0	0	2
965	2	2016-11-01 07:40:29	197.0	193.1	198.7	0.0	0.0	0.0	48.23	0.0	0.0	1	1	1	0	0	0	0	2
966	2	2016-11-01 08:25:01	199.7	191.3	199.0	0.0	0.0	0.0	47.82	0.0	0.0	1	1	1	0	0	0	0	2
967	2	2016-11-01 08:25:01	199.7	191.3	199.0	0.0	0.0	0.0	47.82	0.0	0.0	1	1	1	0	0	0	0	2
1040	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1041	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1042	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1043	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1044	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1045	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1046	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1047	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1048	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1049	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1050	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1051	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1052	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1053	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1054	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1055	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1056	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1057	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1058	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1059	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1060	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
1061	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1062	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
1063	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1064	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
1065	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1066	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
1067	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1068	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
1069	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1070	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
1071	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1072	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
1073	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1074	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
1075	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1076	2	2016-11-02 16:47:01	194.9	191.6	198.6	0.0	0.0	0.0	48.08	0.0	0.0	1	1	1	0	0	0	0	2
1077	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1078	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1079	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1080	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1081	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1082	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1083	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1084	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1085	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1086	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1087	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1088	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1089	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1090	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1091	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1092	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1093	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1094	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
968	2	2016-11-01 09:25:01	203.8	199.0	206.4	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
969	2	2016-11-01 09:25:01	203.8	199.0	206.4	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
970	2	1999-12-08 01:35:01	201.2	196.5	202.3	0.0	0.0	0.0	48.81	0.0	0.0	1	1	1	0	0	0	0	2
971	2	1999-12-08 01:35:01	201.2	196.5	202.3	0.0	0.0	0.0	48.81	0.0	0.0	1	1	1	0	0	0	0	2
972	2	1999-12-08 01:50:36	200.0	193.5	200.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
973	2	1999-12-08 01:50:36	200.0	193.5	200.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
974	2	2016-11-02 03:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.40	0.0	0.0	0	0	0	0	0	0	0	2
975	2	2016-11-02 03:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.40	0.0	0.0	0	0	0	0	0	0	0	2
976	2	2016-11-02 04:50:06	199.8	193.5	202.5	0.0	0.0	0.0	48.61	0.0	0.0	1	0	0	0	0	0	0	2
977	2	2016-11-02 04:50:06	199.8	193.5	202.5	0.0	0.0	0.0	48.61	0.0	0.0	1	0	0	0	0	0	0	2
978	2	2016-11-02 04:50:28	202.0	196.3	199.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
979	2	2016-11-02 04:50:28	202.0	196.3	199.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
980	2	2016-11-02 05:47:01	181.9	177.4	186.2	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
981	2	2016-11-02 05:47:01	181.9	177.4	186.2	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
982	2	2016-11-02 06:47:01	206.6	200.3	206.9	0.0	0.0	0.0	48.66	0.0	0.0	1	1	1	0	0	0	0	2
983	2	2016-11-02 06:47:01	206.6	200.3	206.9	0.0	0.0	0.0	48.66	0.0	0.0	1	1	1	0	0	0	0	2
984	2	2016-11-01 23:49:38	217.8	210.3	219.1	0.0	0.0	0.0	48.33	0.0	0.0	1	1	1	0	0	0	0	2
985	2	2016-11-01 23:49:38	217.8	210.3	219.1	0.0	0.0	0.0	48.33	0.0	0.0	1	1	1	0	0	0	0	2
986	2	2016-11-02 00:47:01	213.5	207.2	214.0	0.0	0.0	0.0	48.61	0.0	0.0	1	1	1	0	0	0	0	2
987	2	2016-11-02 00:47:01	213.5	207.2	214.0	0.0	0.0	0.0	48.61	0.0	0.0	1	1	1	0	0	0	0	2
988	2	2016-11-02 01:47:01	218.8	215.0	223.0	0.0	0.0	0.0	48.35	0.0	0.0	1	1	1	0	0	0	0	2
989	2	2016-11-02 01:47:01	218.8	215.0	223.0	0.0	0.0	0.0	48.35	0.0	0.0	1	1	1	0	0	0	0	2
990	2	2016-11-02 02:47:01	218.6	210.9	219.9	0.0	0.0	0.0	48.79	0.0	0.0	1	1	1	0	0	0	0	2
991	2	2016-11-02 02:47:01	218.6	210.9	219.9	0.0	0.0	0.0	48.79	0.0	0.0	1	1	1	0	0	0	0	2
992	2	2016-11-02 02:49:50	218.2	214.6	218.4	0.0	0.0	0.0	48.50	0.0	0.0	1	0	0	0	0	0	0	2
993	2	2016-11-02 02:49:50	218.2	214.6	218.4	0.0	0.0	0.0	48.50	0.0	0.0	1	0	0	0	0	0	0	2
994	2	2016-11-02 02:50:11	0.0	0.0	0.0	0.0	0.0	0.0	48.60	0.0	0.0	0	0	0	0	0	0	0	2
995	2	2016-11-02 02:50:11	0.0	0.0	0.0	0.0	0.0	0.0	48.60	0.0	0.0	0	0	0	0	0	0	0	2
996	2	2016-11-02 04:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.06	0.0	0.0	0	0	0	0	0	0	0	2
997	2	2016-11-02 04:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.06	0.0	0.0	0	0	0	0	0	0	0	2
998	2	2016-11-02 07:47:01	204.7	199.2	207.8	0.0	0.0	0.0	47.85	0.0	0.0	1	1	1	0	0	0	0	2
999	2	2016-11-02 07:50:40	210.2	204.5	211.9	0.0	0.0	0.0	48.81	0.0	0.0	1	0	0	0	0	0	0	2
1000	2	2016-11-02 07:51:00	0.0	0.0	0.0	0.0	0.0	0.0	48.06	0.0	0.0	0	0	0	0	0	0	0	2
1001	2	2016-11-02 08:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.59	0.0	0.0	0	0	0	0	0	0	0	2
1002	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1003	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1004	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1005	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1006	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1007	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1008	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1009	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1010	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1011	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1012	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1013	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1014	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1015	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1016	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1017	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1018	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1019	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1020	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1021	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1022	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1023	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1024	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1025	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1026	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1027	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1028	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1029	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1030	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1031	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1032	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1033	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1034	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1035	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1036	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1037	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1038	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1039	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1096	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1097	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1098	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1099	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1100	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1101	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1102	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1103	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1104	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1105	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1106	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1107	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1108	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1109	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1110	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1111	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1112	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1113	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1114	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1115	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1116	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1117	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1118	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1119	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1120	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1121	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1122	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1123	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1124	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1125	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1126	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1127	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1128	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1129	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1130	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1131	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1132	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1133	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1134	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1135	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1136	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1137	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1138	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1139	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1140	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1141	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1142	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1143	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1144	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1145	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1146	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1147	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1148	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1149	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1150	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1151	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1152	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1153	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1154	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1155	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1156	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1157	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1158	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1159	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1160	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1161	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1162	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1163	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1164	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1165	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1166	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1167	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1168	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1169	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1170	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1171	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1172	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1173	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1174	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1175	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1176	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1177	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1178	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1179	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1180	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1181	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1182	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1183	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1184	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1185	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1186	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1187	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1188	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1189	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1190	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1191	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1192	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1193	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1194	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1195	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1196	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1197	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1198	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1199	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1200	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1201	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1202	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1203	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1204	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1205	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1206	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1207	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1208	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1209	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1210	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1211	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1212	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1213	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1214	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1215	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1216	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1217	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1218	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1219	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1220	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1221	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1222	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1223	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1224	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1225	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1226	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1227	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1228	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1229	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1230	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1231	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1232	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1233	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1234	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1235	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1236	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1237	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1238	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1239	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1240	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1241	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1242	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1243	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1244	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1245	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1246	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1247	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1248	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1437	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1249	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1250	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1251	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1252	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1253	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1254	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1255	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1256	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1257	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1258	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1259	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1260	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1261	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1262	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1263	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1264	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1265	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1266	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1267	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1268	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1269	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1270	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1271	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1272	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1273	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1274	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1275	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1276	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1277	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1278	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1279	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1280	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1281	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1282	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1283	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1284	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1285	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1286	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1287	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1288	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1289	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1290	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1291	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1292	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1293	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1294	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1295	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1296	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1297	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1298	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1299	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1300	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1301	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1302	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1303	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1304	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1305	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1306	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1307	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1308	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1309	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1310	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1311	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1312	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1313	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1314	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1315	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1316	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1317	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1318	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1319	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1320	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1321	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1322	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1323	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1324	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1325	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1326	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1327	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1328	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1329	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1330	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1331	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1332	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1333	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1334	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1335	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1336	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1337	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1338	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1339	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1340	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1341	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1342	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1343	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1344	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1345	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1346	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1347	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1348	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1349	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1350	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1351	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1352	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1353	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1354	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1355	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1356	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1357	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1358	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1359	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1360	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1361	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1362	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1363	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1364	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1365	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1366	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1367	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1368	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1369	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1370	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1371	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1372	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1373	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1374	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1375	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1376	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1377	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1378	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1379	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1380	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1381	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1382	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1383	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1384	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1385	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1386	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1387	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1388	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1389	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1390	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1391	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1392	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1393	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1394	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1395	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1396	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1397	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1398	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1399	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1400	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1401	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1402	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1403	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1404	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1405	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1406	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1407	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1408	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1409	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1410	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1411	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1412	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1413	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1414	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1415	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1416	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1417	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1418	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1419	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1420	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1421	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1422	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1423	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1424	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1425	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1426	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1427	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1428	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1429	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1430	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1431	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1432	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1433	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1434	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1435	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1436	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1511	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1512	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1513	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1514	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1515	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1516	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1517	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1518	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1519	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1520	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1521	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1522	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1542	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1543	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1544	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1545	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1546	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1547	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1548	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1549	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1550	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1551	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1552	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1553	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1554	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1579	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1580	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1581	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1582	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1583	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1438	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1439	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1440	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1441	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1442	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1443	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1444	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1445	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1446	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1447	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1448	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1449	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1450	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1451	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1452	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1453	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1454	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1455	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1456	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1457	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1458	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1459	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1460	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1461	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1462	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1463	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1464	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1465	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1466	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1467	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1468	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1469	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1470	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1471	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1472	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1473	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1474	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1475	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1476	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1477	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1478	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1479	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1480	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1481	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1482	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1483	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1484	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1485	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1486	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1487	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1488	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1489	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1490	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1491	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1492	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1493	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1494	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1495	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1496	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1497	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1498	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1499	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1500	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1501	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1502	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1503	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1504	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1505	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1506	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1507	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1508	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1509	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1584	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1510	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1523	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1524	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1525	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1526	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1527	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1528	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1529	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1530	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1531	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1532	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1533	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1534	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1535	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1536	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1537	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1538	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1539	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1540	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1541	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1555	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1556	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1557	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1558	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1559	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1560	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1561	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1562	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1563	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1564	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1565	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1566	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1567	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1568	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1569	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1570	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1571	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1572	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1573	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1574	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1575	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1576	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1577	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1578	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1585	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1586	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1587	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1588	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1589	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1590	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1591	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1592	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1593	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1594	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1595	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1596	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1597	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1598	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1599	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1600	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1601	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1602	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1603	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1604	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1605	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1606	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1607	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1608	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1609	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1610	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1611	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1612	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1613	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1614	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1615	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1616	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1617	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1618	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1619	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1620	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1621	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1622	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1623	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1624	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1954	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1625	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1626	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1627	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1628	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1629	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1630	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1631	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1632	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1633	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1634	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1635	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1636	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1637	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1638	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1639	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1640	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1641	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1642	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1643	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1644	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1645	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1646	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1647	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1648	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1649	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1650	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1651	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1652	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1653	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1654	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1655	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1656	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1660	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1657	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1658	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1659	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1670	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1671	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1672	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1673	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1674	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1675	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1676	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1677	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1678	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1679	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1680	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1681	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1682	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1683	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1684	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1685	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1706	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1707	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1708	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1709	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1710	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1711	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1712	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1713	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1714	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1715	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1716	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1717	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1734	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1735	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1736	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1737	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1738	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1739	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1740	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1741	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2139	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1742	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1743	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1744	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1745	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1746	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1747	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1748	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1749	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1750	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1751	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1752	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1753	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1754	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1755	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1756	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1757	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1758	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1764	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1774	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1775	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1776	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1788	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1789	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1790	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1791	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1792	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1796	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1797	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1798	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1799	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1823	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1829	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1661	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1662	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1663	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1664	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1665	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1666	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1667	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1668	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1669	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1686	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1687	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1688	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1689	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1690	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1691	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1692	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1693	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1694	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1695	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1696	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1697	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1698	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1699	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1700	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1701	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1702	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1703	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1704	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1705	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1718	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1719	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1720	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1721	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1722	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1723	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1724	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1725	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1726	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1727	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1728	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1729	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1730	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1731	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1732	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1733	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1759	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1760	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1761	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1762	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1763	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1765	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1766	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1767	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1768	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1769	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1770	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1771	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1772	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1773	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1777	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1778	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1779	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1780	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1781	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1782	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1783	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1784	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1785	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1786	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1787	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1793	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1794	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1795	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1800	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1801	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1802	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1803	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1804	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1805	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1806	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1807	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1808	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1809	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1810	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1811	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1812	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1813	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1814	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1815	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1816	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1817	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1818	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1819	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1820	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1821	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1822	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1824	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1825	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1826	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1827	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1828	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1830	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1831	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1832	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1833	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1834	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1835	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1836	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1837	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1838	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1839	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1840	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1841	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1842	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1843	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1844	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1845	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1846	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1847	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1848	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1849	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1850	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1851	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1852	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1853	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1854	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1855	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1856	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1857	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1858	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1859	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1860	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1861	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1862	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1863	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1864	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1865	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1866	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1867	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1868	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1869	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1870	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1871	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1872	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1873	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1874	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1875	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1876	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1877	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1878	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1879	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1880	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1881	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1882	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1883	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1884	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1885	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1886	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1887	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1888	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1889	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1890	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1891	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1892	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1893	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1894	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1895	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1896	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1897	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1898	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1899	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1900	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1901	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1902	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1903	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1904	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1905	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1906	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1907	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1908	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1909	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1910	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1911	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1912	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1956	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1957	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1965	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1976	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1977	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1978	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1979	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1980	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1981	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1982	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1983	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1984	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1985	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1986	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1987	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1988	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1998	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1999	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2000	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2001	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2002	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2003	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2004	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2005	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2006	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2007	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2016	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2017	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2018	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2019	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2020	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2021	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1913	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1914	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1915	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1916	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1917	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1918	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1919	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1920	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1921	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1922	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1923	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1924	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1925	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1926	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1927	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1928	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1929	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1930	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1931	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1932	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1933	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1934	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1935	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1936	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1937	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1938	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1939	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1940	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1941	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1942	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1943	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1944	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1945	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1946	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1947	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1948	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1949	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1950	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1951	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1952	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1953	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1955	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1958	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1959	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1960	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1961	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1962	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1963	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1964	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1966	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1967	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1968	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1969	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1970	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1971	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1972	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1973	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1974	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1975	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1989	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1990	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1991	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1992	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
1993	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
1994	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
1995	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
1996	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
1997	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2008	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2009	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2010	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2011	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2012	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2013	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2014	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2015	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2036	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2037	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2038	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2039	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2040	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2041	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2042	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2043	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2044	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2045	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2046	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2047	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2048	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2049	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2050	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2051	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2052	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2053	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2054	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2055	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2056	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2057	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2058	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2059	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2060	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2061	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2062	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2063	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2022	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2023	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2024	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2025	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2026	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2027	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2028	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2029	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2030	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2031	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2032	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2033	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2034	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2035	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2064	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2065	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2066	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2067	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2068	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2069	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2070	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2071	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2072	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2073	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2074	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2075	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2076	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2077	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2078	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2079	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2080	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2081	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2082	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2083	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2084	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2085	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2086	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2087	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2088	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2089	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2090	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2091	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2092	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2093	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2094	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2095	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2096	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2097	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2098	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2099	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2100	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2101	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2102	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2103	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2104	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2105	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2106	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2107	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2108	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2109	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2110	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2111	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2112	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2113	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2114	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2115	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2116	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2117	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2118	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2119	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2120	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2121	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2122	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2123	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2132	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2133	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2134	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2135	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2136	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2137	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2145	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2146	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2147	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2148	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2149	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2150	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2151	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2152	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2153	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2187	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2188	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2189	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2190	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2191	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2192	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2208	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2209	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2210	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2211	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2212	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2227	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2228	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2229	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2231	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2244	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2245	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2252	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2253	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2254	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2255	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2256	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2257	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2258	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2259	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2260	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2265	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2274	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2275	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2276	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2277	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2278	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2279	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2280	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2281	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2282	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2283	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2284	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2285	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2286	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2287	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2288	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2289	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2290	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2293	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2294	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2295	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2296	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2297	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2298	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2299	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2300	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2301	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2302	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2303	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2124	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2125	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2126	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2127	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2128	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2129	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2130	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2131	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2138	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2140	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2141	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2142	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2143	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2144	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2154	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2155	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2156	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2157	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2158	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2159	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2160	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2161	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2162	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2163	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2164	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2165	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2166	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2167	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2168	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2169	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2170	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2171	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2172	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2173	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2174	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2175	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2176	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2177	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2178	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2179	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2180	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2181	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2182	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2183	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2184	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2185	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2186	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2193	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2194	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2195	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2196	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2197	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2198	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2199	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2200	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2201	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2202	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2203	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2204	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2205	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2206	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2207	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2213	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2214	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2215	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2216	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2217	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2218	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2219	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2220	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2221	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2222	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2223	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2224	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2225	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2226	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2230	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2232	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2233	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2234	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2235	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2236	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2237	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2238	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2239	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2240	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2241	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2242	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2243	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2246	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2247	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2248	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2249	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2250	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2251	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2261	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2262	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2263	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2264	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2266	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2267	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2268	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2269	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2270	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2271	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2272	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2273	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2291	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2292	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2334	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2335	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2336	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2337	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2338	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2339	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2340	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2348	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2349	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2350	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2351	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2352	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2353	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2354	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2355	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2356	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2357	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2358	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2359	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2360	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2361	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2362	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2363	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2364	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2365	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2366	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2367	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2368	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2369	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2370	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2371	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2372	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2373	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2374	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2304	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2305	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2306	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2307	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2308	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2309	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2310	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2311	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2312	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2313	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2314	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2315	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2316	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2317	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2318	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2319	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2320	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2321	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2322	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2323	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2324	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2325	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2326	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2327	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2328	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2329	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2330	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2331	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2332	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2333	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2341	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2342	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2343	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2344	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2345	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2346	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2347	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2382	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2383	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2384	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2385	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2386	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2387	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2388	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2389	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2390	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2391	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2392	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2393	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2394	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2395	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2396	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2397	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2400	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2406	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2407	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2408	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2409	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2410	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2411	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2412	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2413	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2414	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2416	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2417	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2418	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2419	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2420	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2421	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2422	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2423	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2424	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2375	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2376	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2377	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2378	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2379	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2380	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2381	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2398	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2399	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2401	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2402	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2403	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2404	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2405	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2415	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2428	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2429	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2430	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2431	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2432	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2433	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2434	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2435	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2436	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2437	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2438	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2425	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2426	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2427	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2439	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2440	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2441	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2442	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2443	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2444	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2445	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2446	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2447	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2448	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2449	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2450	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2451	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2452	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2453	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2454	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2455	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2456	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2457	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2458	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2459	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2460	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2461	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2462	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2463	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2464	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2465	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2466	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2467	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2468	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2469	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2470	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2471	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2472	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2473	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2474	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2475	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2476	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2477	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2478	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2479	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2480	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2481	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2482	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2483	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2484	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2485	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2486	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2487	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2488	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2489	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2490	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2491	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2492	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2493	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2494	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2495	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2496	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2497	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2498	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2499	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2500	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2501	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2502	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2503	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2504	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2505	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2506	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2507	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2508	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2509	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2510	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2511	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2512	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2513	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2514	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2515	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2516	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2517	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2518	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2531	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2532	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2547	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2550	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2551	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2562	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2563	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2587	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2593	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2607	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2608	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2609	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2610	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2611	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2612	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2613	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2614	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2615	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2616	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2626	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2627	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2628	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2649	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2650	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2651	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2656	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2657	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2658	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2659	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2660	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2661	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2663	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2672	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2673	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2674	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2675	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2676	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2677	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2678	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2679	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2680	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2685	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2686	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2687	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2688	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2702	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2703	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2704	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2705	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2706	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2707	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2708	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2709	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2710	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2711	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2712	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2713	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2714	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2740	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2741	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2742	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2743	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2519	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2520	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2521	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2522	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2523	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2524	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2525	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2526	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2527	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2528	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2529	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2530	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2533	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2534	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2535	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2536	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2537	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2538	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2539	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2540	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2541	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2542	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2543	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2544	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2545	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2546	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2548	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2549	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2552	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2553	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2554	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2555	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2556	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2557	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2558	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2559	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2560	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2561	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2564	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2565	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2566	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2567	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2568	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2569	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2570	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2571	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2572	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2573	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2574	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2575	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2576	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2577	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2578	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2579	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2580	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2581	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2582	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2583	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2584	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2585	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2586	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2588	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2589	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2590	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2591	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2592	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2594	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2595	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2596	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2597	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2598	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2599	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2600	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2601	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2602	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2603	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2604	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2605	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2606	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2617	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2618	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2619	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2620	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2621	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2622	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2623	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2624	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2625	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2629	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2630	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2631	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2632	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2633	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2634	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2635	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2636	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2637	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2638	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2639	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2640	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2641	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2642	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2643	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2644	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2645	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2646	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2647	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2648	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2652	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2653	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2654	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2655	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2662	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2664	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2665	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2666	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2667	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2668	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2669	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2670	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2671	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2681	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2682	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2683	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2684	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2689	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2690	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2691	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2692	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2693	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2694	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2695	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2696	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2697	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2698	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2699	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2700	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2701	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2715	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2716	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2717	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2718	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2719	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2720	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2721	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2722	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2723	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2724	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2725	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2726	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2727	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2728	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2729	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2730	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2731	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2732	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2733	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2734	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2735	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2736	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2737	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2738	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2739	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2748	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2749	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2778	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2779	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2780	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2786	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2787	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2788	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2791	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2792	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2793	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2796	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2797	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2798	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2799	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2800	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2801	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2802	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2803	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2804	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2805	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2744	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2745	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2746	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2747	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2750	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2751	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2752	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2753	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2754	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2755	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2756	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2757	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2758	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2759	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2760	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2761	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2762	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2763	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2764	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2765	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2766	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2767	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2768	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2769	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2770	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2771	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2772	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2773	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2774	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2775	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2776	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2777	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2781	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2782	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2783	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2784	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2785	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2789	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2790	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2794	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2795	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2806	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2807	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2808	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2809	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2810	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2811	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2812	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2813	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2814	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2815	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2816	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2817	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2818	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2819	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2820	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2821	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2822	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2823	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2824	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2825	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2826	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2827	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2828	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2829	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2830	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2831	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2832	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2833	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2834	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2835	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2836	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3002	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2837	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2838	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2839	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2840	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2841	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2842	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2843	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2844	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2854	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2855	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2856	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2857	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2869	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2870	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2871	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2872	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2873	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2874	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2875	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2876	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2877	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2878	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2879	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2880	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2881	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2882	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2883	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2884	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2885	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2899	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2900	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2909	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2910	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2911	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2912	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2913	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2914	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2915	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2917	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2918	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2922	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2923	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2924	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2925	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2926	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2937	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2938	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2939	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2945	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2946	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2947	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2948	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2949	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2950	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2951	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2952	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2953	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2954	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2955	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2956	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2957	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2958	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2959	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2960	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2961	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2962	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2963	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2965	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2966	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2967	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2968	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2973	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2974	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2845	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2846	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2847	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2848	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2849	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2850	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2851	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2852	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2853	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2858	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2859	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2860	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2861	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2862	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2863	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2864	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2865	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2866	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2867	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2868	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2886	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2887	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2888	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2889	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2890	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2891	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2892	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2893	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2894	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2895	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2896	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2897	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2898	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2901	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2902	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2903	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2904	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2905	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2906	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2907	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2908	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2916	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2919	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2920	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2921	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2927	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2928	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2929	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2930	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2931	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2932	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2933	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2934	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2935	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2936	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2940	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2941	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2942	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2943	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2944	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2964	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2969	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2970	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2971	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2972	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2983	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2984	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2985	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2986	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2987	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2988	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3001	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2975	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2976	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2977	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2978	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2979	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2980	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2981	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2982	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2989	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2990	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2991	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
2992	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
2993	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
2994	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
2995	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
2996	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
2997	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
2998	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
2999	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3000	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3009	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3010	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3011	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3012	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3013	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3014	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3016	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3028	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3029	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3030	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3031	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3032	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3033	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3034	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3035	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3036	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3037	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3038	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3039	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3052	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3053	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3054	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3055	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3056	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3057	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3058	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3075	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3096	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3097	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3098	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3099	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3100	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3101	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3102	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3103	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3104	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3105	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3106	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3107	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3108	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3109	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3110	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3111	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3112	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3113	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3114	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3115	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3116	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3117	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3118	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3119	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3123	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3003	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3004	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3005	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3006	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3007	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3008	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3015	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3017	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3018	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3019	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3020	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3021	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3022	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3023	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3024	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3025	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3026	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3027	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3040	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3041	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3042	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3043	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3044	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3045	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3046	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3047	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3048	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3049	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3050	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3051	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3059	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3060	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3061	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3062	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3063	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3064	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3065	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3066	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3067	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3068	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3069	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3070	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3071	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3072	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3073	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3074	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3076	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3077	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3078	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3079	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3080	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3081	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3082	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3083	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3084	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3085	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3086	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3087	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3088	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3089	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3090	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3091	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3092	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3093	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3094	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3095	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3120	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3121	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3122	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3147	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3148	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3156	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3162	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3124	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3125	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3126	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3127	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3128	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3129	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3130	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3131	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3132	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3133	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3134	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3135	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3136	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3137	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3138	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3139	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3140	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3141	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3142	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3143	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3144	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3145	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3146	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3149	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3150	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3151	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3152	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3153	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3154	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3155	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3157	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3158	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3159	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3160	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3161	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3163	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3164	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3165	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3166	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3167	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3168	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3169	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3170	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3171	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3172	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3173	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3174	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3175	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3176	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3177	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3178	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3179	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3180	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3181	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3182	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3183	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3184	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3185	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3186	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3187	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3188	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3189	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3190	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3191	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3192	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3193	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3194	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3195	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3196	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3197	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3198	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3199	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3200	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3201	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3202	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3203	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3204	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3205	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3206	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3207	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3208	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3209	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3210	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3211	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3212	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3213	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3214	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3215	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3216	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3217	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3218	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3219	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3220	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3221	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3222	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3223	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3224	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3225	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3226	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3227	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3228	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3229	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3230	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3231	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3232	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3233	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3234	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3235	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3236	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3237	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3238	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3239	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3240	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3241	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3242	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3243	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3244	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3245	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3246	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3247	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3248	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3249	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3250	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3251	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3252	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3268	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3269	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3270	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3271	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3272	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3284	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3285	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3286	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3287	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3288	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3289	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3290	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3291	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3292	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3293	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3294	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3295	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3296	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3297	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3298	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3299	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3300	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3301	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3302	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3304	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3305	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3306	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3316	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3317	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3318	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3319	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3325	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3330	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3331	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3332	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3333	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3334	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3335	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3343	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3344	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3346	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3347	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3348	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3349	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3350	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3351	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3352	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3359	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3360	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3361	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3362	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3363	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3364	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3370	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3371	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3253	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3254	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3255	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3256	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3257	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3258	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3259	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3260	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3261	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3262	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3263	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3264	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3265	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3266	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3267	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3273	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3274	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3275	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3276	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3277	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3278	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3279	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3280	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3281	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3282	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3283	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3303	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3307	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3308	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3309	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3310	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3311	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3312	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3313	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3314	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3315	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3320	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3321	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3322	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3323	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3324	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3326	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3327	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3328	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3329	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3336	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3337	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3338	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3339	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3340	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3341	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3342	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3345	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3353	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3354	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3355	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3356	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3357	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3358	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3365	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3366	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3367	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3368	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3369	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3376	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3377	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3378	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3379	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3380	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3381	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3382	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3383	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3384	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3394	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3372	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3373	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3374	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3375	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3385	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3386	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3387	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3388	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3389	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3390	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3391	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3392	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3393	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3397	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3398	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3399	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3400	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3401	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3402	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3411	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3412	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3418	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3425	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3426	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3427	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3428	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3429	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3430	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3431	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3448	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3449	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3450	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3451	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3452	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3453	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3454	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3455	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3456	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3457	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3458	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3459	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3460	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3461	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3462	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3463	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3464	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3465	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3466	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3467	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3468	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3469	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3470	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3471	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3472	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3473	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3474	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3475	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3476	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3477	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3478	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3479	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3482	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3483	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3484	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3485	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3486	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3487	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3488	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3490	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3491	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3492	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3500	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3501	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3502	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3395	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3396	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3403	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3404	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3405	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3406	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3407	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3408	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3409	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3410	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3413	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3414	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3415	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3416	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3417	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3419	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3420	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3421	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3422	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3423	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3424	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3432	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3433	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3434	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3435	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3436	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3437	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3438	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3439	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3440	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3441	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3442	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3443	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3444	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3445	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3446	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3447	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3480	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3481	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3489	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3493	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3494	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3495	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3496	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3497	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3498	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3499	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3510	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3511	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3512	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3513	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3514	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3515	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3516	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3517	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3518	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3522	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3523	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3524	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3525	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3528	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3529	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3530	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3532	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3533	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3534	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3535	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3536	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3537	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3538	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3503	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3504	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3505	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3506	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3507	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3508	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3509	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3519	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3520	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3521	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3526	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3527	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3531	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3539	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3540	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3541	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3542	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3543	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3544	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3545	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3546	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3547	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3548	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3549	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3550	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3551	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3552	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3553	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3554	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3555	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3556	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3557	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3558	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3559	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3560	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3561	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3562	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3563	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3564	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3565	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3566	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3567	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3568	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3569	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3570	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3571	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3572	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3573	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3574	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3575	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3576	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3577	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3578	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3579	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3580	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3581	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3582	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3583	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3584	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3585	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3586	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3587	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3588	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3589	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3590	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3591	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3592	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3593	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3594	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3595	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3596	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3597	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3598	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3599	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3601	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3602	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3608	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3609	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3610	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3611	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3612	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3614	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3615	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3617	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3618	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3637	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3638	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3639	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3640	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3642	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3643	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3644	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3651	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3653	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3655	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3656	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3657	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3658	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3660	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3662	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3663	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3664	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3665	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3666	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3667	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3668	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3669	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3670	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3671	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3672	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3673	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3674	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3675	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3676	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3677	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3678	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3679	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3681	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3682	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3683	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3684	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3685	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3686	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3687	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3688	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3689	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3690	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3691	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3692	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3693	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3712	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3713	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3714	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3715	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3716	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3717	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3718	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3729	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3732	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3733	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3734	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3735	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3736	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3737	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3738	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3739	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3740	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3600	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3603	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3604	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3605	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3606	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3607	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3613	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3616	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3619	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3620	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3621	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3622	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3623	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3624	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3625	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3626	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3627	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3628	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3629	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3630	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3631	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3632	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3633	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3634	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3635	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3636	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3641	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3645	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3646	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3647	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3648	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3649	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3650	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3652	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3654	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3659	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3661	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3680	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3694	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3695	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3696	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3697	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3698	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3699	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3700	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3701	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3702	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3703	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3704	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3705	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3706	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3707	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3708	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3709	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3710	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3711	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3719	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3720	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3721	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3722	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3723	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3724	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3725	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3726	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3727	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3728	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3730	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3731	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3746	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3747	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3748	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3749	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3750	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3741	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3742	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3743	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3744	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3745	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3768	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3769	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3770	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3771	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3772	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3773	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3776	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3777	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3778	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3779	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3780	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3783	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3784	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3785	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3786	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3787	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3795	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3796	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3797	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3799	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3800	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3812	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3814	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3819	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3820	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3821	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3827	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3828	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3829	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3830	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3831	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3832	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3833	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3834	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3835	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3836	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3837	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3838	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3839	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3840	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3841	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3842	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3843	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3844	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3848	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3857	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3858	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3859	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3860	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3861	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3862	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3863	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3864	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3865	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3866	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3867	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3868	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3869	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3870	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3871	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3872	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3873	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3874	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3875	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3876	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3877	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3878	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3879	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3751	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3752	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3753	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3754	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3755	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3756	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3757	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3758	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3759	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3760	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3761	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3762	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3763	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3764	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3765	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3766	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3767	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3774	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3775	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3781	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3782	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3788	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3789	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3790	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3791	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3792	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3793	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3794	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3798	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3801	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3802	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3803	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3804	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3805	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3806	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3807	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3808	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3809	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3810	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3811	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3813	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3815	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3816	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3817	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3818	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3822	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3823	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3824	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3825	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3826	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3845	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3846	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3847	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3849	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3850	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3851	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3852	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3853	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3854	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3855	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3856	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3884	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3890	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3891	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3892	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3893	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3894	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3896	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3897	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3898	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3899	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3900	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3901	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3902	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3880	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3881	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3882	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3883	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3885	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3886	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3887	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3888	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3889	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3895	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3906	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3908	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3909	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3910	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3911	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3912	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3913	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3914	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3915	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3916	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3917	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3918	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3919	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3920	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3921	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3922	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3923	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3924	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3925	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3926	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3927	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3928	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3929	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3930	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3931	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3932	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3933	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3934	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3935	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3936	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3937	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3938	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3958	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3959	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3960	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3961	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3962	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3963	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3964	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3967	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3968	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3969	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3970	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3971	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3972	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4249	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3973	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3974	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3975	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3976	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3977	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3978	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3979	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3980	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3981	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3982	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3983	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3984	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3985	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3986	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3987	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3995	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3996	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3997	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3998	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3903	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3904	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3905	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3907	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3939	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3940	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3941	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3942	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3943	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3944	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3945	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3946	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3947	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3948	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3949	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3950	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
3951	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
3952	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3953	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3954	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3955	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3956	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3957	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3965	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3966	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3988	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
3989	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
3990	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
3991	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
3992	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
3993	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
3994	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4027	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4028	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4029	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4030	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4031	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4032	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4033	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4040	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4041	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4042	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4043	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4047	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4048	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
3999	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4000	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4001	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4002	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4003	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4004	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4005	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4006	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4007	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4008	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4009	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4010	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4011	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4012	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4013	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4014	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4015	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4016	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4017	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4018	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4019	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4020	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4021	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4022	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4023	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4024	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4025	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4026	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4034	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4035	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4036	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4037	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4038	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4039	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4044	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4045	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4046	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4049	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4050	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4051	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4052	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4053	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4054	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4055	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4056	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4057	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4058	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4059	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4060	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4061	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4062	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4063	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4064	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4065	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4066	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4067	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4068	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4069	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4070	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4071	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4072	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4073	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4074	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4075	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4076	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4077	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4078	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4079	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4080	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4081	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4082	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4083	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4084	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4085	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4086	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4098	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4099	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4100	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4102	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4103	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4104	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4105	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4107	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4108	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4109	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4110	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4111	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4112	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4114	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4115	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4116	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4117	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4118	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4119	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4120	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4121	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4122	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4123	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4124	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4125	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4126	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4127	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4139	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4140	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4141	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4142	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4147	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4148	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4149	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4150	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4151	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4152	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4153	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4154	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4155	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4156	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4157	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4158	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4159	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4160	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4161	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4162	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4182	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4183	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4184	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4185	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4186	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4187	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4188	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4191	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4192	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4193	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4194	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4195	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4196	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4212	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4213	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4214	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4215	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4216	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4217	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4218	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4219	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4220	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4221	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4222	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4223	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4087	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4088	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4089	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4090	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4091	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4092	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4093	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4094	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4095	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4096	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4097	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4101	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4106	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4113	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4128	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4129	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4130	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4131	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4132	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4133	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4134	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4135	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4136	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4137	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4138	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4143	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4144	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4145	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4146	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4163	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4164	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4165	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4166	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4167	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4168	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4169	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4170	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4171	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4172	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4173	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4174	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4175	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4176	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4177	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4178	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4179	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4180	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4181	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4189	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4190	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4197	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4198	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4199	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4200	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4201	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4202	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4203	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4204	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4205	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4206	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4207	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4208	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4209	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4210	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4211	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4230	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4231	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4232	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4233	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4234	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4236	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4237	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4238	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4224	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4225	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4226	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4227	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4228	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4229	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4235	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4257	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4258	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4259	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4260	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4261	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4271	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4275	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4276	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4277	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4285	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4286	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4287	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4288	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4289	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4290	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4298	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4299	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4300	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4303	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4304	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4305	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4306	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4307	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4308	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4309	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4310	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4311	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4312	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4313	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4322	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4323	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4324	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4325	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4330	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4331	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4332	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4333	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4334	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4335	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4336	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4337	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4338	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4344	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4353	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4354	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4355	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4356	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4357	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4358	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4360	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4361	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4362	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4363	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4364	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4365	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4366	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4367	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4368	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4369	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4370	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4373	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4374	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4375	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4376	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4377	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4378	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4239	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4240	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4241	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4242	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4243	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4244	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4245	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4246	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4247	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4248	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4250	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4251	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4252	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4253	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4254	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4255	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4256	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4262	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4263	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4264	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4265	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4266	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4267	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4268	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4269	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4270	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4272	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4273	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4274	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4278	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4279	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4280	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4281	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4282	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4283	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4284	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4291	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4292	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4293	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4294	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4295	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4296	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4297	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4301	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4302	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4314	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4315	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4316	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4317	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4318	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4319	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4320	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4321	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4326	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4327	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4328	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4329	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4339	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4340	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4341	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4342	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4343	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4345	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4346	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4347	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4348	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4349	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4350	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4351	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4352	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4359	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4371	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4372	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4379	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4380	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4381	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4382	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4383	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4385	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4386	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4387	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4388	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4389	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4390	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4391	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4407	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4408	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4409	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4410	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4411	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4412	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4413	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4414	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4415	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4431	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4432	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4433	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4434	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4435	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4436	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4437	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4446	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4447	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4448	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4449	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4450	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4451	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4452	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4453	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4454	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4457	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4458	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4459	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4460	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4461	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4462	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4463	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4464	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4469	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4470	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4471	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4472	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4473	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4474	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4475	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4476	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4477	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4478	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4507	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4508	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4509	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4510	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4511	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4512	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4513	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4514	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4515	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4518	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4529	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4530	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4531	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4532	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4533	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4534	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4535	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4384	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4392	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4393	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4394	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4395	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4396	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4397	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4398	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4399	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4400	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4401	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4402	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4403	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4404	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4405	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4406	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4416	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4417	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4418	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4419	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4420	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4421	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4422	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4423	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4424	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4425	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4426	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4427	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4428	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4429	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4430	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4438	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4439	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4440	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4441	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4442	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4443	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4444	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4445	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4455	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4456	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4465	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4466	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4467	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4468	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4479	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4480	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4481	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4482	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4483	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4484	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4485	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4486	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4487	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4488	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4489	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4490	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4491	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4492	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4493	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4494	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4495	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4496	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4497	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4498	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4499	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4500	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4501	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4502	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4503	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4504	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4505	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4506	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4516	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4517	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4519	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4520	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4521	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4522	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4523	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4524	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4525	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4526	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4527	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4528	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4536	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4537	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4538	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4539	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4540	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4541	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4542	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4543	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4544	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4545	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4546	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4547	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4548	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4549	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4550	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4551	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4552	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4553	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4554	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4555	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4556	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4557	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4558	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4559	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4560	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4561	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4562	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4563	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4564	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4565	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4566	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4567	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4568	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4569	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4570	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4571	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4572	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4573	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4574	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4575	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4576	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4577	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4578	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4579	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4580	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4581	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4582	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4583	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4584	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4585	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4586	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4587	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4588	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4589	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4590	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4591	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4592	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4593	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4594	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4595	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4596	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4597	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4598	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4599	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4624	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4625	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4626	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4631	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4632	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4633	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4634	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4635	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4636	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4637	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4638	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4643	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4644	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4645	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4646	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4647	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4648	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4649	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4650	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4651	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4652	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4653	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4654	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4655	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4656	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4657	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4658	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4659	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4660	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4661	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4662	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4665	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4666	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4673	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4679	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4680	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4681	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4682	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4710	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4711	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4712	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4713	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4714	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4715	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4716	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4717	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4718	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4719	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4720	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4721	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4722	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4723	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4724	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4726	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4727	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4728	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4729	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4730	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4731	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4732	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4733	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4734	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4735	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4744	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4745	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4746	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4747	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4748	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4749	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4750	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4751	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4752	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4753	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4600	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4601	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4602	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4603	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4604	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4605	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4606	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4607	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4608	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4609	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4610	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4611	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4612	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4613	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4614	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4615	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4616	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4617	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4618	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4619	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4620	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4621	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4622	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4623	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4627	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4628	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4629	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4630	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4639	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4640	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4641	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4642	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4663	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4664	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4667	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4668	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4669	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4670	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4671	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4672	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4674	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4675	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4676	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4677	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4678	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4683	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4684	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4685	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4686	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4687	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4688	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4689	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4690	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4691	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4692	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4693	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4694	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4695	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4696	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4697	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4698	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4699	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4700	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4701	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4702	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4703	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4704	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4705	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4706	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4707	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4708	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4709	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4725	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4736	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4737	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4738	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4739	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4740	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4741	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4742	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4743	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4757	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4759	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4760	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4761	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4762	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4763	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4764	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4765	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4766	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4767	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4782	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4783	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4784	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4785	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4786	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4787	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4788	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4789	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4790	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4791	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4792	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4799	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4800	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4801	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4856	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4857	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4860	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4861	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4871	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4873	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4874	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4875	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4876	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4877	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4878	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4879	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4880	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4881	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4882	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4883	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4884	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4885	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4903	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4904	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4905	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4906	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4907	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4908	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4920	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4921	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4922	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4923	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4924	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4925	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4926	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4927	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4928	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4929	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4930	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4931	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4932	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4933	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4934	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4935	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4936	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4937	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4754	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4755	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4756	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4758	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4768	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4769	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4770	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4771	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4772	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4773	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4774	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4775	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4776	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4777	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4778	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4779	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4780	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4781	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4793	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4794	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4795	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4796	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4797	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4798	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4802	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4803	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4804	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4805	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4806	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4807	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4808	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4809	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4810	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4811	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4812	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4813	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4814	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4815	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4816	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4817	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4818	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4819	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4820	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4821	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4822	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4823	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4824	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4825	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4826	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4827	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4828	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4829	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4830	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4831	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4832	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4833	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4834	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4835	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4836	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4837	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4838	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4839	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4840	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4841	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4842	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4843	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4844	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4845	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4846	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4847	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4848	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4849	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4850	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4851	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4852	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4853	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4854	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4855	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4858	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4859	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4862	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4863	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4864	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4865	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4866	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4867	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4868	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4869	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4870	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4872	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4886	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4887	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4888	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4889	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4890	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4891	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4892	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4893	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4894	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4895	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4896	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4897	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4898	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4899	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4900	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4901	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4902	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4909	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4910	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4911	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4912	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4913	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4914	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4915	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4916	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4917	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4918	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4919	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4941	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4942	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4943	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4944	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4945	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4946	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4947	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4948	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4949	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4950	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4951	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4952	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4953	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4954	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4958	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4959	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4960	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4961	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4962	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4963	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4964	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4965	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4966	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4967	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4971	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4972	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4973	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4974	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4975	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4976	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5182	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4938	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4939	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4940	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4955	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4956	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4957	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4968	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4969	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4970	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4984	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4985	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
4986	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4998	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
4999	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5000	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5001	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5002	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5003	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5004	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5005	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5006	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5007	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5018	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5019	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5020	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5021	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5022	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5023	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5024	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5025	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5026	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5028	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5035	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5036	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5037	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5038	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5039	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5040	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5041	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5042	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5043	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5044	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5045	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5046	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5048	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5049	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5053	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5054	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5055	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5056	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5058	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5059	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5060	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5061	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5062	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5063	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5066	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5067	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5068	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5069	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5074	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5075	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5076	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5077	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5078	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5079	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5080	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5081	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5082	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5083	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5084	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5085	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5089	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5090	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4977	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
4978	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4979	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4980	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4981	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4982	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4983	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4987	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
4988	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4989	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5230	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
4990	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
4991	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
4992	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
4993	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
4994	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
4995	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
4996	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
4997	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5008	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5009	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5010	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5011	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5012	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5013	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5014	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5015	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5016	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5017	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5027	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5029	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5030	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5031	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5032	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5033	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5034	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5047	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5050	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5051	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5052	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5057	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5064	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5065	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5070	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5071	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5072	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5073	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5086	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5087	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5088	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5097	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5098	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5099	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5100	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5101	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5102	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5103	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5104	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5105	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5106	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5107	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5108	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5109	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5110	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5111	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5112	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5113	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5091	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5092	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5093	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5094	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5095	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5096	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5114	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5115	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5116	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5117	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5118	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5119	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5120	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5121	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5122	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5123	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5124	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5125	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5126	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5127	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5128	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5129	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5130	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5131	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5132	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5133	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5134	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5135	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5136	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5137	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5138	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5139	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5140	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5141	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5142	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5143	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5144	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5145	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5146	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5147	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5148	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5149	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5150	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5151	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5152	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5153	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5154	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5155	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5156	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5157	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5158	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5159	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5160	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5161	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5162	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5163	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5164	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5165	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5166	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5167	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5168	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5169	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5170	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5171	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5172	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5173	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5174	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5175	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5176	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5177	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5178	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5179	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5180	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5181	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5183	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5205	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5206	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5207	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5208	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5209	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5210	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5211	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5212	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5215	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5216	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5217	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5224	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5225	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5226	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5227	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5228	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5229	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5231	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5232	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5233	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5234	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5235	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5236	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5240	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5241	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5242	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5243	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5244	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5245	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5246	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5274	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5275	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5276	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5277	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5278	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5280	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5283	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5284	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5285	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5306	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5307	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5308	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5309	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5310	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5311	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5312	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5321	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5322	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5331	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5332	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5333	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5334	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5335	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5336	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5337	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5338	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5339	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5340	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5341	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5342	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5346	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5347	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5348	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5349	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5350	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5355	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5356	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5357	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5358	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5359	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5360	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5361	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5184	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5185	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5186	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5187	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5188	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5189	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5190	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5191	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5192	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5193	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5194	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5195	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5196	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5197	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5198	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5199	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5200	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5201	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5202	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5203	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5204	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5213	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5214	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5218	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5219	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5220	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5221	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5222	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5223	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5237	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5238	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5239	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5247	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5248	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5249	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5250	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5251	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5252	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5253	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5254	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5255	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5256	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5257	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5258	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5259	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5260	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5261	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5262	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5263	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5264	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5265	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5266	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5267	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5268	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5269	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5270	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5271	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5272	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5273	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5279	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5281	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5282	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5286	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5287	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5288	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5289	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5290	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5291	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5292	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5293	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5294	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5295	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5296	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5297	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5298	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5299	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5300	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5301	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5302	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5303	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5304	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5305	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5313	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5314	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5315	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5316	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5317	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5318	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5319	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5320	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5323	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5324	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5325	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5326	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5327	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5328	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5329	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5330	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5343	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5344	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5345	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5351	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5352	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5353	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5354	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5365	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5366	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5367	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5368	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5369	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5370	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5371	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5372	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5373	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5374	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5375	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5376	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5377	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5378	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5379	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5380	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5381	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5382	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5397	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5417	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5420	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5421	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5424	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5425	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5426	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5427	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5428	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5429	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5431	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5442	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5443	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5444	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5446	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5447	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5448	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5449	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5450	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5451	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5452	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5453	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5454	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5455	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5819	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5362	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5363	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5364	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5383	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5384	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5385	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5386	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5387	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5388	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5389	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5390	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5391	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5392	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5393	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5394	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5395	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5396	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5398	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5399	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5400	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5401	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5402	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5403	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5404	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5405	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5406	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5407	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5408	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5409	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5410	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5411	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5412	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5413	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5414	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5415	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5416	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5418	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5419	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5422	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5423	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5430	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5432	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5433	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5434	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5435	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5436	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5437	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5438	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5439	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5440	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5441	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5445	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5461	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5462	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5463	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5464	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5465	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5466	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5467	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5471	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5472	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5473	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5474	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5475	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5476	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5477	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5479	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5480	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5481	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5485	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5486	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5487	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5488	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5456	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5457	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5458	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5459	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5460	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5468	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5469	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5470	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5478	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5482	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5483	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5484	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5489	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5490	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5491	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5492	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5493	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5494	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5507	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5508	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5519	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5541	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5542	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5543	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5544	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5545	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5546	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5547	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5548	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5549	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5550	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5551	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5558	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5559	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5560	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5561	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5562	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5566	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5567	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5571	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5572	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5573	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5574	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5575	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5576	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5577	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5578	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5579	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5580	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5581	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5583	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5584	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5585	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5586	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5587	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5588	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5589	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5590	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5591	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5592	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5594	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5595	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5596	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5597	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5598	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5599	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5600	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5601	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5602	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5603	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5610	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5611	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5612	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5613	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5614	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5495	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5496	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5497	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5498	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5499	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5500	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5501	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5502	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5503	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5504	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5505	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5506	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5509	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5510	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5511	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5512	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5513	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5514	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5515	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5516	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5517	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5518	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5520	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5521	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5522	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5523	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5524	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5525	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5526	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5527	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5528	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5529	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5530	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5531	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5532	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5533	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5534	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5535	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5536	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5537	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5538	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5539	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5540	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5552	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5553	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5554	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5555	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5556	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5557	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5563	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5564	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5565	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5568	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5569	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5570	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5582	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5593	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5604	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5605	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5606	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5607	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5608	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5609	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5627	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5628	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5629	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5630	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5631	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5642	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5647	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5648	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5649	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5650	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5615	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5616	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5617	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5618	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5619	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5620	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5621	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5622	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5623	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5624	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5625	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5626	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5632	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5633	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5634	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5635	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5636	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5637	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5638	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5639	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5640	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5641	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5643	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5644	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5645	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5646	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5660	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5661	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5662	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5676	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5677	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5678	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5679	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5680	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5681	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5682	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5683	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5684	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5685	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5686	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5687	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5688	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5689	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5690	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5691	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5692	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5693	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5694	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5695	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5696	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5697	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5698	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5699	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5700	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5701	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5702	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5703	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5704	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5705	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5706	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5707	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5708	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5709	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5710	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5711	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5712	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5713	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5714	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5715	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5716	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5717	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5723	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5724	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5725	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5651	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5652	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5653	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5654	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5655	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5656	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5657	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5658	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5659	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5663	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5664	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5665	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5666	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5667	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5668	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5669	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5670	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5671	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5672	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5673	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5674	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5675	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5718	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5719	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5720	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5721	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5722	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5726	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5727	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5728	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5729	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5730	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5731	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5732	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5733	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5734	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5735	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5736	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5737	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5738	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5739	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5740	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5741	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5742	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5743	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5744	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5745	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5746	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5747	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5748	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5749	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5750	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5751	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5752	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5753	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5754	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5755	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5756	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5757	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5758	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5759	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5760	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5761	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5762	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5763	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5764	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5765	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5766	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5767	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5768	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5769	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5770	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5771	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5772	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5773	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5774	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5775	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5776	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5777	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5778	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5779	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5780	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5781	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5782	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5783	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5784	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5785	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5786	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5787	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5788	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5789	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5790	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5791	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5792	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5793	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5794	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5795	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5796	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5797	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5798	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5799	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5800	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5801	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5802	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5803	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5804	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5805	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5806	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5807	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5808	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5809	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5810	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5811	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5812	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5813	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5814	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5815	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5816	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5817	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5818	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5823	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5826	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5827	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5828	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5835	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5836	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5837	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5838	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5839	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5840	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5847	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5852	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5853	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5854	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5855	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5862	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5863	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5864	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5865	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5866	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5867	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5868	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5869	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5870	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5871	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5872	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5873	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5874	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5875	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5876	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5877	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5878	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5879	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5880	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5881	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5882	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5883	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5884	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5885	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5886	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5887	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5891	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5892	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5893	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5894	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5895	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5896	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5897	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5901	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5902	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5903	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5904	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5905	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5906	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5820	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5821	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5822	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5824	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5825	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5829	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5830	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5831	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5832	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5833	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5834	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5841	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5842	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5843	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5844	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5845	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5846	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5848	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5849	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5850	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5851	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5856	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5857	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5858	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5859	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5860	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5861	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5888	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5889	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5890	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5898	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5899	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5900	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5950	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5951	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5952	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5953	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5954	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5955	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5960	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5961	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5962	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5963	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5964	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5965	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5975	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5985	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5986	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5987	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5988	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5994	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6003	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6005	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6006	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6007	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6008	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6024	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6025	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6026	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6027	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6033	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6034	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6035	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6036	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6037	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6042	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6043	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6044	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6045	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6046	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6047	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6048	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6049	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6063	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5907	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5908	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5909	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5910	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5911	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5912	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5913	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5914	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5915	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5916	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5917	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5918	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5919	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5920	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5921	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5922	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5923	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5924	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5925	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5926	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5927	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5928	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5929	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5930	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5931	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5932	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5933	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5934	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5935	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5936	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5937	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5938	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5939	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5940	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5941	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5942	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5943	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5944	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5945	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5946	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5947	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5948	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5949	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
5956	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5957	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5958	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5959	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5966	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5967	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5968	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5969	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5970	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5971	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5972	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5973	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
5974	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
5976	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5977	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5978	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5979	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5980	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5981	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
5982	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5983	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5984	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5989	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
5990	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
5991	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
5992	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
5993	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
5995	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
5996	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
5997	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
5998	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
5999	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6000	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6001	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6002	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6004	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6009	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6010	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6011	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6012	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6013	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6014	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6015	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6016	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6017	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6018	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6019	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6020	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6021	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6022	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6023	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6028	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6029	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6030	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6031	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6032	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6038	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6039	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6040	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6041	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6050	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6051	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6052	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6053	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6054	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6055	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6056	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6057	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6058	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6059	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6060	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6061	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6062	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6071	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6072	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6073	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6074	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6075	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6076	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6077	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6078	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6079	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6080	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6081	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6082	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6083	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6084	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6086	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6087	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6099	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6100	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6101	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6102	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6103	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6104	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6105	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6107	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6108	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6109	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6110	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6115	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6117	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6122	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6125	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6064	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6065	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6066	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6067	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6068	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6069	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6070	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6085	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6088	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6089	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6090	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6091	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6092	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6093	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6094	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6095	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6096	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6097	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6098	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6106	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6111	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6112	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6113	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6114	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6116	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6118	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6119	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6120	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6121	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6123	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6124	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6127	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6129	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6130	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6131	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6132	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6133	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6134	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6135	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6137	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6147	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6148	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6149	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6150	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6153	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6154	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6155	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6156	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6157	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6158	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6159	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6160	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6161	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6164	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6165	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6166	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6167	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6168	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6175	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6176	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6177	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6178	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6183	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6184	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6185	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6186	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6188	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6192	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6193	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6194	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6201	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6202	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6208	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6209	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6126	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6128	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6136	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6138	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6139	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6140	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6141	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6142	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6143	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6144	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6145	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6146	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6151	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6152	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6162	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6163	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6169	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6170	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6171	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6172	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6173	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6174	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6179	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6180	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6181	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6182	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6187	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6189	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6190	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6191	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6195	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6196	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6197	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6198	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6199	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6200	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6203	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6204	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6205	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6206	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6207	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6213	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6214	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6223	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6224	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6227	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6235	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6236	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6237	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6239	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6240	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6242	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6243	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6244	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6245	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6246	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6247	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6248	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6249	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6250	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6251	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6253	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6254	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6255	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6256	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6257	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6258	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6259	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6260	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6261	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6262	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6263	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6264	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6265	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6210	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6211	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6212	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6215	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6216	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6217	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6218	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6219	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6220	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6221	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6222	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6225	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6226	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6228	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6229	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6230	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6231	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6232	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6233	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6234	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6238	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6241	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6252	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6274	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6275	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6276	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6278	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6279	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6288	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6290	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6291	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6297	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6298	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6299	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6312	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6313	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6314	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6321	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6322	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6323	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6324	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6326	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6327	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6328	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6329	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6330	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6331	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6332	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6333	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6334	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6335	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6344	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6345	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6346	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6349	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6350	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6351	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6352	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6353	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6354	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6355	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6360	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6382	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6383	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6384	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6385	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6386	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6387	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6393	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6394	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6395	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6397	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6398	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6266	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6267	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6268	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6269	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6270	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6271	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6272	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6273	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6277	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6280	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6281	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6282	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6283	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6284	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6285	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6286	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6287	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6289	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6292	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6293	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6294	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6295	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6296	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6300	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6301	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6302	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6303	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6304	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6305	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6306	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6307	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6308	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6309	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6310	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6311	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6315	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6316	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6317	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6318	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6319	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6320	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6325	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6336	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6337	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6338	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6339	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6340	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6341	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6342	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6343	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6347	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6348	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6356	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6357	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6358	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6359	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6361	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6362	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6363	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6364	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6365	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6366	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6367	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6368	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6369	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6370	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6371	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6372	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6373	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6374	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6375	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6376	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6377	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6378	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6379	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6380	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6381	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6388	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6389	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6390	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6391	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6392	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6396	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6420	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6421	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6422	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6426	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6427	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6428	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6429	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6430	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6431	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6432	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6433	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6434	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6435	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6436	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6437	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6438	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6439	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6440	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6441	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6442	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6443	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6444	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6445	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6448	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6449	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6450	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6451	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6452	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6453	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6454	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6455	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6399	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6400	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6401	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6402	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6403	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6404	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6405	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6406	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6407	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6408	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6409	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6410	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6411	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6412	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6413	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6414	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6415	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6416	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6417	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6418	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6419	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6423	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6424	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6425	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6446	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6447	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6456	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6457	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6458	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6459	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6460	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6461	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6462	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6463	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6464	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6465	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6466	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6467	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6468	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6469	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6470	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6471	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6472	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6473	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6474	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6475	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6476	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6477	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6478	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6479	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6480	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6481	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6482	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6483	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6484	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6485	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6486	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6487	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6488	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6489	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6490	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6491	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6492	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6493	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6494	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6495	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6496	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6497	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6498	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6499	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6500	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6501	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6502	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6669	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6503	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6504	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6505	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6506	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6507	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6508	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6509	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6523	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6524	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6525	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6526	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6527	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6530	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6533	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6534	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6535	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6536	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6537	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6538	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6539	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6540	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6541	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6542	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6543	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6544	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6545	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6546	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6547	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6548	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6549	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6550	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6551	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6552	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6553	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6554	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6555	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6556	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6557	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6558	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6561	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6562	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6563	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6564	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6565	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6566	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6567	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6568	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6569	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6573	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6574	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6575	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6576	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6577	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6578	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6579	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6580	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6581	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6582	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6583	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6584	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6585	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6586	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6587	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6588	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6589	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6590	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6606	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6607	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6608	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6609	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6613	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6615	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6640	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6510	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6511	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6512	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6513	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6514	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6515	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6516	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6517	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6518	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6519	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6520	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6521	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6522	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6528	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6529	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6531	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6532	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6559	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6560	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6570	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6571	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6572	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6591	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6592	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6593	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6594	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6595	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6596	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6597	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6598	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6599	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6600	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6601	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6602	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6603	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6604	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6605	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6610	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6611	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6612	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6614	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6616	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6617	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6618	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6619	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6620	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6621	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6622	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6623	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6624	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6625	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6626	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6627	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6628	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6629	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6630	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6631	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6632	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6633	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6634	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6635	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6636	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6637	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6638	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6639	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6660	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6661	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6662	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6663	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6664	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6665	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6666	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6667	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6668	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6641	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6642	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6643	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6644	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6645	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6646	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6647	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6648	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6649	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6650	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6651	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6652	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6653	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6654	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6655	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6656	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6657	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6658	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6659	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6670	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6671	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6672	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6673	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6674	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6675	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6684	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6685	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6687	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6688	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6694	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6695	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6696	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6697	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6698	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6701	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6702	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6703	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6704	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6705	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6706	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6707	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6708	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6714	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6728	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6729	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6730	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6731	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6732	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6733	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6734	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6735	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6736	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6737	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6738	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6739	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6740	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6741	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6742	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6743	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6744	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6745	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6746	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6784	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6785	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6786	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6787	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6791	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6792	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6793	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6794	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6795	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6796	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6797	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6676	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6677	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6678	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6679	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6680	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6681	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6682	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6683	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6686	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6689	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6690	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6691	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6692	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6693	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6699	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6700	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6709	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6710	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6711	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6712	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6713	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6715	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6716	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6717	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6718	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6719	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6720	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6721	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6722	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6723	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6724	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6725	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6726	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6727	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6747	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6748	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6749	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6750	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6751	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6752	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6753	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6754	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6755	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6756	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6757	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6758	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6759	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6760	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6761	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6762	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6763	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6764	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6765	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6766	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6767	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6768	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6769	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6770	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6771	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6772	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6773	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6774	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6775	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6776	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6777	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6778	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6779	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6780	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6781	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6782	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6783	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6788	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6789	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6937	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6790	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6798	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6799	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6800	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6801	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6815	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6816	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6817	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6823	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6824	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6825	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6826	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6833	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6834	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6835	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6836	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6837	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6838	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6839	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6846	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6847	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6848	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6849	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6850	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6851	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6852	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6853	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6854	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6855	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6856	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6857	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6858	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6859	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6860	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6861	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6862	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6863	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6864	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6865	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6870	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6871	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6872	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6873	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6874	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6875	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6886	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6887	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6888	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6889	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6890	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6891	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6892	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6903	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6904	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6905	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6913	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6914	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6915	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6916	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6917	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6918	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6919	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6920	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6921	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6922	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6923	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6924	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6938	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6939	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6943	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6944	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6947	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6948	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6949	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6802	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6803	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6804	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6805	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6806	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6807	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6808	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6809	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6810	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6811	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6812	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6813	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6814	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6818	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6819	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6820	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6821	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6822	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6827	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6828	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6829	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6830	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6831	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6832	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6840	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6841	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6842	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6843	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6844	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6845	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6866	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6867	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6868	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6869	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6876	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6877	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6878	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6879	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6880	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6881	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6882	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6883	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6884	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6885	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6893	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6894	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6895	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6896	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6897	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6898	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6899	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6900	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6901	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6902	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6906	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6907	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6908	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6909	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6910	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6911	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6912	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6925	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6926	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6927	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6928	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6929	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6930	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6931	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6932	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6933	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6934	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6935	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6936	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6940	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6941	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6942	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6945	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6946	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6950	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6951	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6952	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6953	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6954	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6955	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6960	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6961	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6962	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6963	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6964	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6965	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6966	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6967	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6968	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6969	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6970	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6971	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6972	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6973	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6974	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6975	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6976	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6977	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6978	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6979	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6980	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6981	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7002	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7003	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7004	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7005	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7006	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7007	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7008	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7009	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7010	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7012	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7013	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7014	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7015	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7016	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7017	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7018	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7019	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7024	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7025	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7026	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7027	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7028	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7029	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7030	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7031	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7032	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7035	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7036	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7037	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7038	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7040	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7041	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7042	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7045	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7051	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7052	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7053	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7054	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7055	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7056	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7058	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6956	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6957	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6958	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6959	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6982	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6983	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6984	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6985	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6986	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
6987	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
6988	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
6989	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
6990	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
6991	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
6992	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
6993	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
6994	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
6995	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
6996	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
6997	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
6998	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
6999	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7000	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7001	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7011	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7020	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7021	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7022	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7023	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7033	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7034	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7039	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7043	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7044	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7046	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7047	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7048	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7049	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7050	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7057	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7062	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7063	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7064	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7065	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7066	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7069	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7070	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7076	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7077	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7078	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7079	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7080	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7085	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7086	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7094	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7103	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7108	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7109	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7113	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7114	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7115	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7116	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7146	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7147	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7148	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7149	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7150	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7151	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7152	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7153	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7154	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7155	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7454	2	2016-11-07 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.10	0.0	0.0	0	0	0	0	0	0	0	2
7059	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7060	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7061	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7067	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7068	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7071	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7072	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7073	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7074	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7075	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7081	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7082	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7083	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7084	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7087	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7088	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7089	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7090	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7091	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7092	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7093	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7095	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7096	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7097	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7098	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7099	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7100	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7101	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7102	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7104	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7105	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7106	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7107	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7110	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7111	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7112	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7117	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7118	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7119	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7120	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7121	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7122	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7123	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7124	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7125	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7126	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7127	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7128	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7129	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7130	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7131	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7132	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7133	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7134	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7135	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7136	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7137	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7138	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7139	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7140	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7141	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7142	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7143	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7144	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7145	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7166	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7167	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7168	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7169	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7170	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7171	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7172	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7173	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7174	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7156	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7157	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7158	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7159	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7160	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7161	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7162	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7163	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7164	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7165	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7175	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7176	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7177	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7178	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7179	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7180	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7181	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7182	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7183	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7184	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7185	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7186	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7187	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7188	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7189	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7190	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7191	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7192	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7193	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7194	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7195	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7196	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7197	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7198	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7199	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7200	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7201	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7202	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7203	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7204	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7205	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7206	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7207	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7208	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7209	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7210	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7211	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7212	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7213	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7214	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7215	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7216	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7217	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7218	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7219	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7220	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7221	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7222	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7223	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7224	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7225	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7226	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7227	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7228	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7229	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7230	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7231	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7232	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7233	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7234	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7235	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7236	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7237	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7238	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7239	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7240	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7241	2	2016-11-02 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7242	2	2016-11-02 09:50:56	198.1	192.7	200.3	0.0	0.0	0.0	48.95	0.0	0.0	1	0	0	0	0	0	0	2
7244	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7245	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7246	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7247	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7248	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7249	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7250	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7251	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7252	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7253	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7260	2	2016-11-02 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7261	2	2016-11-02 14:51:46	207.9	200.4	207.2	0.0	0.0	0.0	48.71	0.0	0.0	1	0	0	0	0	0	0	2
7262	2	2016-11-02 14:52:08	206.8	202.0	208.0	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7263	2	2016-11-02 15:47:01	207.0	202.5	208.2	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7264	2	2016-11-02 16:47:01	194.9	191.6	198.6	0.0	0.0	0.0	48.08	0.0	0.0	1	1	1	0	0	0	0	2
7265	2	2016-11-02 17:47:01	190.7	185.4	196.3	0.0	0.0	0.0	48.14	0.0	0.0	1	1	1	0	0	0	0	2
7267	2	2016-11-02 17:52:20	187.8	183.8	190.3	0.0	0.0	0.0	48.31	0.0	0.0	1	0	0	0	0	0	0	2
7269	2	2016-11-02 18:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.40	0.0	0.0	0	0	0	0	0	0	0	2
7270	2	2016-11-02 18:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.40	0.0	0.0	0	0	0	0	0	0	0	2
7273	2	2016-11-02 19:52:36	190.7	184.3	191.8	0.0	0.0	0.0	48.03	0.0	0.0	1	0	0	0	0	0	0	2
7274	2	2016-11-02 19:52:58	191.3	184.9	192.2	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
7275	2	2016-11-02 19:52:58	191.3	184.9	192.2	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
7277	2	2016-11-02 21:47:01	198.0	191.6	202.8	0.0	0.0	0.0	48.89	0.0	0.0	1	1	1	0	0	0	0	2
7278	2	2016-11-02 22:47:01	208.1	203.7	213.2	0.0	0.0	0.0	48.50	0.0	0.0	1	1	1	0	0	0	0	2
7280	2	2016-11-02 22:53:31	0.0	0.0	0.0	0.0	0.0	0.0	48.35	0.0	0.0	0	0	0	0	0	0	0	2
7286	2	2016-11-03 01:47:01	219.8	214.1	222.8	0.0	0.0	0.0	48.32	0.0	0.0	1	1	1	0	0	0	0	2
7287	2	2016-11-03 02:47:01	224.6	218.4	222.9	0.0	0.0	0.0	48.48	0.0	0.0	1	1	1	0	0	0	0	2
7288	2	2016-11-03 03:47:01	220.5	216.7	220.8	0.0	0.0	0.0	48.40	0.0	0.0	1	1	1	0	0	0	0	2
7289	2	2016-11-03 03:54:00	220.3	214.3	221.5	0.0	0.0	0.0	48.91	0.0	0.0	1	0	0	0	0	0	0	2
7290	2	2016-11-03 03:54:21	0.0	0.0	0.0	0.0	0.0	0.0	48.74	0.0	0.0	0	0	0	0	0	0	0	2
7291	2	2016-11-03 04:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.66	0.0	0.0	0	0	0	0	0	0	0	2
7292	2	2016-11-03 05:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.51	0.0	0.0	0	0	0	0	0	0	0	2
7293	2	2016-11-03 05:54:16	204.7	199.8	204.7	0.0	0.0	0.0	48.19	0.0	0.0	1	0	0	0	0	0	0	2
7294	2	2016-11-03 05:54:38	204.5	198.4	206.5	0.0	0.0	0.0	48.28	0.0	0.0	1	1	1	0	0	0	0	2
7295	2	2016-11-03 06:47:01	207.7	201.0	207.4	0.0	0.0	0.0	48.49	0.0	0.0	1	1	1	0	0	0	0	2
7297	2	2016-11-03 07:47:01	204.0	199.8	204.4	0.0	0.0	0.0	48.83	0.0	0.0	1	1	1	0	0	0	0	2
7299	2	2016-11-03 08:47:01	196.9	190.1	197.0	0.0	0.0	0.0	48.30	0.0	0.0	1	1	1	0	0	0	0	2
7300	2	2016-11-03 08:54:50	198.0	192.9	202.8	0.0	0.0	0.0	48.84	0.0	0.0	1	0	0	0	0	0	0	2
7306	2	2016-11-03 10:55:28	200.7	195.1	202.0	0.0	0.0	0.0	48.38	0.0	0.0	1	1	1	0	0	0	0	2
7310	2	2016-11-03 13:47:01	203.8	199.9	204.0	0.0	0.0	0.0	49.17	0.0	0.0	1	1	1	0	0	0	0	2
7243	2	2016-11-02 09:51:18	198.3	195.9	199.6	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7254	2	2016-11-02 10:47:01	202.5	196.9	203.7	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7255	2	2016-11-02 11:47:01	206.7	203.6	208.4	0.0	0.0	0.0	48.80	0.0	0.0	1	1	1	0	0	0	0	2
7256	2	2016-11-02 12:47:01	209.4	205.2	212.9	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7257	2	2016-11-02 12:51:30	207.9	204.4	209.4	0.0	0.0	0.0	48.83	0.0	0.0	1	0	0	0	0	0	0	2
7258	2	2016-11-02 12:51:51	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7259	2	2016-11-02 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7266	2	2016-11-02 17:52:20	187.8	183.8	190.3	0.0	0.0	0.0	48.31	0.0	0.0	1	0	0	0	0	0	0	2
7268	2	2016-11-02 17:52:41	0.0	0.0	0.0	0.0	0.0	0.0	48.53	0.0	0.0	0	0	0	0	0	0	0	2
7271	2	2016-11-02 19:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.92	0.0	0.0	0	0	0	0	0	0	0	2
7272	2	2016-11-02 19:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.92	0.0	0.0	0	0	0	0	0	0	0	2
7276	2	2016-11-02 20:47:01	206.2	201.4	207.7	0.0	0.0	0.0	48.76	0.0	0.0	1	1	1	0	0	0	0	2
7279	2	2016-11-02 22:53:10	208.4	204.6	211.6	0.0	0.0	0.0	48.30	0.0	0.0	1	0	0	0	0	0	0	2
7281	2	2016-11-02 23:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.80	0.0	0.0	0	0	0	0	0	0	0	2
7282	2	2016-11-03 00:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.31	0.0	0.0	0	0	0	0	0	0	0	2
7283	2	2016-11-03 00:53:26	219.5	214.7	223.8	0.0	0.0	0.0	48.54	0.0	0.0	1	0	0	0	0	0	0	2
7284	2	2016-11-03 00:53:48	221.4	214.3	221.6	0.0	0.0	0.0	47.94	0.0	0.0	1	1	1	0	0	0	0	2
7285	2	2016-11-03 00:53:48	221.4	214.3	221.6	0.0	0.0	0.0	47.94	0.0	0.0	1	1	1	0	0	0	0	2
7296	2	2016-11-03 07:47:01	204.0	199.8	204.4	0.0	0.0	0.0	48.83	0.0	0.0	1	1	1	0	0	0	0	2
7298	2	2016-11-03 08:47:01	196.9	190.1	197.0	0.0	0.0	0.0	48.30	0.0	0.0	1	1	1	0	0	0	0	2
7301	2	2016-11-03 08:55:11	0.0	0.0	0.0	0.0	0.0	0.0	48.29	0.0	0.0	0	0	0	0	0	0	0	2
7302	2	2016-11-03 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.54	0.0	0.0	0	0	0	0	0	0	0	2
7303	2	2016-11-03 10:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.61	0.0	0.0	0	0	0	0	0	0	0	2
7304	2	2016-11-03 10:55:06	201.3	195.6	204.7	0.0	0.0	0.0	48.29	0.0	0.0	1	0	0	0	0	0	0	2
7305	2	2016-11-03 10:55:06	201.3	195.6	204.7	0.0	0.0	0.0	48.29	0.0	0.0	1	0	0	0	0	0	0	2
7307	2	2016-11-03 10:55:28	200.7	195.1	202.0	0.0	0.0	0.0	48.38	0.0	0.0	1	1	1	0	0	0	0	2
7308	2	2016-11-03 11:47:01	209.6	200.7	207.6	0.0	0.0	0.0	48.11	0.0	0.0	1	1	1	0	0	0	0	2
7309	2	2016-11-03 12:47:01	210.6	206.1	211.6	0.0	0.0	0.0	49.09	0.0	0.0	1	1	1	0	0	0	0	2
7311	2	2016-11-03 13:55:40	198.6	196.3	203.5	0.0	0.0	0.0	48.65	0.0	0.0	1	0	0	0	0	0	0	2
7312	2	2016-11-03 13:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.59	0.0	0.0	0	0	0	0	0	0	0	2
7313	2	2016-11-03 13:56:01	0.0	0.0	0.0	0.0	0.0	0.0	48.59	0.0	0.0	0	0	0	0	0	0	0	2
7314	2	2016-11-04 13:47:01	198.7	195.9	200.3	0.0	0.0	0.0	48.88	0.0	0.0	1	1	1	0	0	0	0	2
7315	2	2016-11-04 14:47:01	202.3	199.9	206.6	0.0	0.0	0.0	49.00	0.0	0.0	1	1	1	0	0	0	0	2
7316	2	2016-11-04 14:59:49	205.2	196.6	205.8	0.0	0.0	0.0	48.48	0.0	0.0	1	0	0	0	0	0	0	2
7317	2	2016-11-04 15:00:16	0.0	0.0	0.0	0.0	0.0	0.0	48.64	0.0	0.0	0	0	0	0	0	0	0	2
7318	2	2016-11-04 15:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7319	2	2016-11-04 16:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.35	0.0	0.0	0	0	0	0	0	0	0	2
7320	2	2016-11-04 17:00:11	197.9	193.0	201.4	0.0	0.0	0.0	48.97	0.0	0.0	1	0	0	0	0	0	0	2
7321	2	2016-11-04 17:00:32	199.3	194.2	200.7	0.0	0.0	0.0	48.28	0.0	0.0	1	1	1	0	0	0	0	2
7322	2	2016-11-04 17:47:01	204.5	198.2	207.6	0.0	0.0	0.0	48.45	0.0	0.0	1	1	1	0	0	0	0	2
7323	2	2016-11-04 18:47:01	199.3	194.4	204.2	0.0	0.0	0.0	48.26	0.0	0.0	1	1	1	0	0	0	0	2
7324	2	2016-11-04 19:47:01	203.2	198.5	208.7	0.0	0.0	0.0	48.38	0.0	0.0	1	1	1	0	0	0	0	2
7325	2	2016-11-04 20:00:43	202.6	198.8	204.2	0.0	0.0	0.0	49.09	0.0	0.0	1	0	0	0	0	0	0	2
7326	2	2016-11-04 20:01:06	0.0	0.0	0.0	0.0	0.0	0.0	48.33	0.0	0.0	0	0	0	0	0	0	0	2
7327	2	2016-11-04 20:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.66	0.0	0.0	0	0	0	0	0	0	0	2
7328	2	2016-11-04 20:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.66	0.0	0.0	0	0	0	0	0	0	0	2
7329	2	2016-11-04 21:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.43	0.0	0.0	0	0	0	0	0	0	0	2
7330	2	2016-11-04 21:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.43	0.0	0.0	0	0	0	0	0	0	0	2
7331	2	2016-11-04 22:01:00	203.8	199.0	204.3	0.0	0.0	0.0	48.15	0.0	0.0	1	0	0	0	0	0	0	2
7332	2	2016-11-04 22:01:22	203.0	199.1	205.0	0.0	0.0	0.0	48.78	0.0	0.0	1	1	1	0	0	0	0	2
7333	2	2016-11-04 22:01:22	203.0	199.1	205.0	0.0	0.0	0.0	48.78	0.0	0.0	1	1	1	0	0	0	0	2
7334	2	2016-11-04 22:47:01	207.3	202.0	208.3	0.0	0.0	0.0	48.39	0.0	0.0	1	1	1	0	0	0	0	2
7335	2	2016-11-04 23:47:01	208.8	204.7	211.9	0.0	0.0	0.0	48.74	0.0	0.0	1	1	1	0	0	0	0	2
7573	2	2016-11-10 17:08:01	0.0	0.0	0.0	0.0	0.0	0.0	49.06	0.0	0.0	0	0	0	0	0	0	0	2
7336	2	2016-11-05 00:47:01	212.8	207.5	215.0	0.0	0.0	0.0	48.81	0.0	0.0	1	1	1	0	0	0	0	2
7337	2	2016-11-05 01:01:33	216.2	209.9	216.5	0.0	0.0	0.0	48.63	0.0	0.0	1	0	0	0	0	0	0	2
7338	2	2016-11-05 01:01:56	0.0	0.0	0.0	0.0	0.0	0.0	48.30	0.0	0.0	0	0	0	0	0	0	0	2
7339	2	2016-11-05 01:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.37	0.0	0.0	0	0	0	0	0	0	0	2
7340	2	2016-11-05 02:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.52	0.0	0.0	0	0	0	0	0	0	0	2
7341	2	2016-11-05 03:01:51	215.5	213.5	217.9	0.0	0.0	0.0	48.75	0.0	0.0	1	0	0	0	0	0	0	2
7342	2	2016-11-05 03:02:12	215.8	213.5	217.6	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
7343	2	2016-11-05 03:02:12	215.8	213.5	217.6	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
7344	2	2016-11-05 03:47:01	217.8	209.8	216.7	0.0	0.0	0.0	48.44	0.0	0.0	1	1	1	0	0	0	0	2
7345	2	2016-11-05 04:47:01	211.4	202.9	211.1	0.0	0.0	0.0	48.88	0.0	0.0	1	1	1	0	0	0	0	2
7346	2	2016-11-05 05:47:01	204.6	198.0	206.9	0.0	0.0	0.0	48.76	0.0	0.0	1	1	1	0	0	0	0	2
7347	2	2016-11-05 06:02:23	199.4	194.0	200.3	0.0	0.0	0.0	48.19	0.0	0.0	1	0	0	0	0	0	0	2
7348	2	2016-11-05 06:02:46	0.0	0.0	0.0	0.0	0.0	0.0	48.24	0.0	0.0	0	0	0	0	0	0	0	2
7349	2	2016-11-05 06:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.54	0.0	0.0	0	0	0	0	0	0	0	2
7350	2	2016-11-05 07:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.38	0.0	0.0	0	0	0	0	0	0	0	2
7351	2	2016-11-05 07:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.38	0.0	0.0	0	0	0	0	0	0	0	2
7352	2	2016-11-05 08:02:41	193.6	186.9	195.9	0.0	0.0	0.0	48.39	0.0	0.0	1	0	0	0	0	0	0	2
7353	2	2016-11-05 08:03:02	193.3	187.3	192.3	0.0	0.0	0.0	48.58	0.0	0.0	1	1	1	0	0	0	0	2
7354	2	2016-11-05 08:47:01	183.0	177.3	183.8	0.0	0.0	0.0	48.40	0.0	0.0	1	1	1	0	0	0	0	2
7355	2	2016-11-05 09:47:01	201.0	193.2	199.1	0.0	0.0	0.0	48.63	0.0	0.0	1	1	1	0	0	0	0	2
7356	2	2016-11-05 09:47:01	201.0	193.2	199.1	0.0	0.0	0.0	48.63	0.0	0.0	1	1	1	0	0	0	0	2
7357	2	2016-11-05 10:47:01	208.4	204.1	207.7	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
7358	2	2016-11-05 11:03:13	198.6	193.8	202.4	0.0	0.0	0.0	48.69	0.0	0.0	1	0	0	0	0	0	0	2
7359	2	2016-11-05 11:03:36	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7360	2	2016-11-05 11:03:36	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	0.0	0	0	0	0	0	0	0	2
7361	2	2016-11-05 11:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.19	0.0	0.0	0	0	0	0	0	0	0	2
7362	2	2016-11-05 12:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.30	0.0	0.0	0	0	0	0	0	0	0	2
7363	2	2016-11-05 13:03:26	191.5	185.0	191.8	0.0	0.0	0.0	48.24	0.0	0.0	1	0	0	0	0	0	0	2
7364	2	2016-11-05 13:03:26	191.5	185.0	191.8	0.0	0.0	0.0	48.24	0.0	0.0	1	0	0	0	0	0	0	2
7365	2	2016-11-05 13:03:51	191.7	184.7	191.2	0.0	0.0	0.0	48.49	0.0	0.0	1	1	1	0	0	0	0	2
7366	2	2016-11-05 13:47:01	199.4	194.8	201.1	0.0	0.0	0.0	49.16	0.0	0.0	1	1	1	0	0	0	0	2
7367	2	2016-11-05 14:47:01	202.4	199.5	205.4	0.0	0.0	0.0	48.57	0.0	0.0	1	1	1	0	0	0	0	2
7368	2	2016-11-05 15:47:01	191.2	186.7	196.6	0.0	0.0	0.0	48.89	0.0	0.0	1	1	1	0	0	0	0	2
7369	2	2016-11-05 16:04:03	199.2	192.0	199.9	0.0	0.0	0.0	48.49	0.0	0.0	1	0	0	0	0	0	0	2
7370	2	2016-11-05 16:04:26	0.0	0.0	0.0	0.0	0.0	0.0	48.65	0.0	0.0	0	0	0	0	0	0	0	2
7371	2	2016-11-05 16:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.31	0.0	0.0	0	0	0	0	0	0	0	2
7372	2	2016-11-05 17:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.88	0.0	0.0	0	0	0	0	0	0	0	2
7373	2	2016-11-05 18:04:16	187.5	182.8	190.2	0.0	0.0	0.0	48.75	0.0	0.0	1	0	0	0	0	0	0	2
7374	2	2016-11-05 18:04:16	187.5	182.8	190.2	0.0	0.0	0.0	48.75	0.0	0.0	1	0	0	0	0	0	0	2
7375	2	2016-11-05 18:04:41	190.4	184.5	195.2	0.0	0.0	0.0	48.23	0.0	0.0	1	1	1	0	0	0	0	2
7376	2	2016-11-05 18:04:41	190.4	184.5	195.2	0.0	0.0	0.0	48.23	0.0	0.0	1	1	1	0	0	0	0	2
7377	2	2016-11-05 18:47:01	192.1	184.3	190.9	0.0	0.0	0.0	48.66	0.0	0.0	1	1	1	0	0	0	0	2
7378	2	2016-11-05 19:47:01	197.7	191.5	198.3	0.0	0.0	0.0	48.44	0.0	0.0	1	1	1	0	0	0	0	2
7379	2	2016-11-05 20:47:01	203.3	199.2	203.9	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
7380	2	2016-11-05 21:04:53	200.9	195.1	205.3	0.0	0.0	0.0	48.01	0.0	0.0	1	0	0	0	0	0	0	2
7381	2	2016-11-05 21:05:16	0.0	0.0	0.0	0.0	0.0	0.0	47.97	0.0	0.0	0	0	0	0	0	0	0	2
7382	2	2016-11-05 21:05:16	0.0	0.0	0.0	0.0	0.0	0.0	47.97	0.0	0.0	0	0	0	0	0	0	0	2
7383	2	2016-11-05 21:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7384	2	2016-11-05 22:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.27	0.0	0.0	0	0	0	0	0	0	0	2
7385	2	2016-11-05 23:05:06	205.2	200.9	207.7	0.0	0.0	0.0	48.47	0.0	0.0	1	0	0	0	0	0	0	2
7386	2	2016-11-05 23:05:31	206.4	200.8	208.0	0.0	0.0	0.0	48.17	0.0	0.0	1	1	1	0	0	0	0	2
7387	2	2016-11-05 23:47:01	216.1	212.4	215.5	0.0	0.0	0.0	48.71	0.0	1.0	1	1	1	0	0	0	0	2
7388	2	2016-11-06 00:47:01	214.7	207.2	216.5	0.0	0.0	0.0	48.62	0.0	0.0	1	1	1	0	0	0	0	2
7389	2	2016-11-06 01:47:01	213.4	208.7	216.7	0.0	0.0	0.0	49.21	0.0	0.0	1	1	1	0	0	0	0	2
7390	2	2016-11-06 02:05:43	209.4	204.0	210.8	0.0	0.0	0.0	48.47	0.0	0.0	1	0	0	0	0	0	0	2
7391	2	2016-11-06 02:06:06	0.0	0.0	0.0	0.0	0.0	0.0	48.45	0.0	0.0	0	0	0	0	0	0	0	2
7392	2	2016-11-06 02:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.73	0.0	0.0	0	0	0	0	0	0	0	2
7393	2	2016-11-06 03:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.16	0.0	0.0	0	0	0	0	0	0	0	2
7394	2	2016-11-06 04:05:56	215.4	210.2	216.1	0.0	0.0	0.0	48.38	0.0	0.0	1	0	0	0	0	0	0	2
7395	2	2016-11-06 04:06:21	214.4	208.8	217.2	0.0	0.0	0.0	48.57	0.0	0.0	1	1	1	0	0	0	0	2
7396	2	2016-11-06 04:47:01	216.0	210.7	220.4	0.0	0.0	0.0	48.41	0.0	0.0	1	1	1	0	0	0	0	2
7397	2	2016-11-06 05:47:01	205.4	202.6	207.6	0.0	0.0	0.0	48.57	0.0	0.0	1	1	1	0	0	0	0	2
7398	2	2016-11-06 06:47:01	197.6	195.2	200.7	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
7399	2	2016-11-06 07:06:33	190.7	184.6	192.7	0.0	0.0	0.0	48.41	0.0	0.0	1	0	0	0	0	0	0	2
7400	2	2016-11-06 07:06:56	0.0	0.0	0.0	0.0	0.0	0.0	48.33	0.0	0.0	0	0	0	0	0	0	0	2
7401	2	2016-11-06 07:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.84	0.0	0.0	0	0	0	0	0	0	0	2
7402	2	2016-11-06 08:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.53	0.0	0.0	0	0	0	0	0	0	0	2
7403	2	2016-11-06 09:06:46	189.3	183.1	189.5	0.0	0.0	0.0	48.38	0.0	0.0	1	0	0	0	0	0	0	2
7404	2	2016-11-06 09:06:46	189.3	183.1	189.5	0.0	0.0	0.0	48.38	0.0	0.0	1	0	0	0	0	0	0	2
7405	2	2016-11-06 09:07:11	188.2	182.8	191.2	0.0	0.0	0.0	48.98	0.0	0.0	1	1	1	0	0	0	0	2
7406	2	2016-11-06 09:07:11	188.2	182.8	191.2	0.0	0.0	0.0	48.98	0.0	0.0	1	1	1	0	0	0	0	2
7407	2	2016-11-06 09:47:01	181.8	176.5	181.2	0.0	0.0	0.0	48.59	0.0	0.0	1	1	1	0	0	0	0	2
7408	2	2016-11-06 10:47:01	182.4	176.9	187.1	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
7409	2	2016-11-06 11:47:01	187.6	183.0	189.0	0.0	0.0	0.0	48.67	0.0	0.0	1	1	1	0	0	0	0	2
7410	2	2016-11-06 12:07:23	195.7	187.6	193.8	0.0	0.0	0.0	48.59	0.0	0.0	1	0	0	0	0	0	0	2
7411	2	2016-11-06 12:07:46	0.0	0.0	0.0	0.0	0.0	0.0	48.76	0.0	0.0	0	0	0	0	0	0	0	2
7412	2	2016-11-06 12:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.80	0.0	0.0	0	0	0	0	0	0	0	2
7413	2	2016-11-06 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.59	0.0	0.0	0	0	0	0	0	0	0	2
7414	2	2016-11-06 14:07:36	205.5	200.3	207.4	0.0	0.0	0.0	47.99	0.0	0.0	1	0	0	0	0	0	0	2
7415	2	2016-11-06 14:07:36	205.5	200.3	207.4	0.0	0.0	0.0	47.99	0.0	0.0	1	0	0	0	0	0	0	2
7416	2	2016-11-06 14:08:01	204.8	199.4	207.3	0.0	0.0	0.0	48.13	0.0	0.0	1	1	1	0	0	0	0	2
7417	2	2016-11-06 14:47:01	203.9	195.9	202.5	0.0	0.0	0.0	48.46	0.0	0.0	1	1	1	0	0	0	0	2
7418	2	2016-11-06 15:47:01	200.5	196.4	204.5	0.0	0.0	0.0	48.51	0.0	0.0	1	1	1	0	0	0	0	2
7419	2	2016-11-06 15:47:01	200.5	196.4	204.5	0.0	0.0	0.0	48.51	0.0	0.0	1	1	1	0	0	0	0	2
7420	2	2016-11-06 16:47:01	206.3	203.2	207.2	0.0	0.0	0.0	48.72	0.0	0.0	1	1	1	0	0	0	0	2
7421	2	2016-11-06 17:08:13	191.3	183.0	191.5	0.0	0.0	0.0	48.39	0.0	0.0	1	0	0	0	0	0	0	2
7422	2	2016-11-06 17:08:13	191.3	183.0	191.5	0.0	0.0	0.0	48.39	0.0	0.0	1	0	0	0	0	0	0	2
7423	2	2016-11-06 17:08:36	0.0	0.0	0.0	0.0	0.0	0.0	48.39	0.0	0.0	0	0	0	0	0	0	0	2
7424	2	2016-11-06 17:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.36	0.0	0.0	0	0	0	0	0	0	0	2
7425	2	2016-11-06 18:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.73	0.0	0.0	0	0	0	0	0	0	0	2
7426	2	2016-11-06 19:08:26	188.1	185.3	189.9	0.0	0.0	0.0	48.37	0.0	0.0	1	0	0	0	0	0	0	2
7427	2	2016-11-06 19:08:51	191.0	184.3	190.3	0.0	0.0	0.0	48.60	0.0	0.0	1	1	1	0	0	0	0	2
7428	2	2016-11-06 19:47:01	192.6	186.4	192.9	0.0	0.0	0.0	48.40	0.0	0.0	1	1	1	0	0	0	0	2
7429	2	2016-11-06 20:47:01	198.8	196.2	203.3	0.0	0.0	0.0	48.03	0.0	0.0	1	1	1	0	0	0	0	2
7430	2	2016-11-06 20:47:01	198.8	196.2	203.3	0.0	0.0	0.0	48.03	0.0	0.0	1	1	1	0	0	0	0	2
7431	2	2016-11-06 21:47:01	200.0	198.3	204.1	0.0	0.0	0.0	48.48	0.0	0.0	1	1	1	0	0	0	0	2
7432	2	2016-11-06 22:09:03	206.5	203.1	205.1	0.0	0.0	0.0	47.95	0.0	0.0	1	0	0	0	0	0	0	2
7433	2	2016-11-06 22:09:03	206.5	203.1	205.1	0.0	0.0	0.0	47.95	0.0	0.0	1	0	0	0	0	0	0	2
7434	2	2016-11-06 22:09:26	0.0	0.0	0.0	0.0	0.0	0.0	48.49	0.0	0.0	0	0	0	0	0	0	0	2
7435	2	2016-11-06 22:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.41	0.0	0.0	0	0	0	0	0	0	0	2
7436	2	2016-11-06 23:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.60	0.0	0.0	0	0	0	0	0	0	0	2
7437	2	2016-11-07 00:09:16	217.6	208.3	217.2	0.0	0.0	0.0	48.45	0.0	0.0	1	0	0	0	0	0	0	2
7438	2	2016-11-07 00:09:41	212.4	209.0	218.6	0.0	0.0	0.0	48.30	0.0	0.0	1	1	1	0	0	0	0	2
7439	2	2016-11-07 00:47:01	212.1	208.7	213.2	0.0	0.0	0.0	48.45	0.0	0.0	1	1	1	0	0	0	0	2
7440	2	2016-11-07 01:47:01	214.8	212.4	219.1	0.0	0.0	0.0	48.14	0.0	0.0	1	1	1	0	0	0	0	2
7441	2	2016-11-07 02:47:01	216.8	210.6	218.2	0.0	0.0	0.0	48.24	0.0	0.0	1	1	1	0	0	0	0	2
7442	2	2016-11-07 03:09:53	220.8	214.0	221.7	0.0	0.0	0.0	48.51	0.0	0.0	1	0	0	0	0	0	0	2
7443	2	2016-11-07 03:10:16	0.0	0.0	0.0	0.0	0.0	0.0	48.95	0.0	0.0	0	0	0	0	0	0	0	2
7444	2	2016-11-07 03:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.16	0.0	0.0	0	0	0	0	0	0	0	2
7445	2	2016-11-07 04:47:01	0.0	0.0	0.0	0.0	0.0	0.0	49.00	0.0	0.0	0	0	0	0	0	0	0	2
7446	2	2016-11-07 05:10:06	200.8	193.0	201.2	0.0	0.0	0.0	48.66	0.0	0.0	1	0	0	0	0	0	0	2
7447	2	2016-11-07 05:10:31	196.6	191.6	198.0	0.0	0.0	0.0	48.79	0.0	0.0	1	1	1	0	0	0	0	2
7448	2	2016-11-07 05:47:01	193.1	188.4	195.0	0.0	0.0	0.0	48.71	0.0	0.0	1	1	1	0	0	0	0	2
7449	2	2016-11-07 06:47:01	203.9	196.7	204.7	0.0	0.0	0.0	48.56	0.0	0.0	1	1	1	0	0	0	0	2
7450	2	2016-11-07 07:47:01	200.9	193.3	202.1	0.0	0.0	0.0	48.29	0.0	0.0	1	1	1	0	0	0	0	2
7451	2	2016-11-07 08:10:43	194.4	188.0	198.3	0.0	0.0	0.0	48.50	0.0	0.0	1	0	0	0	0	0	0	2
7452	2	2016-11-07 08:11:06	0.0	0.0	0.0	0.0	0.0	0.0	48.65	0.0	0.0	0	0	0	0	0	0	0	2
7453	2	2016-11-07 08:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.72	0.0	0.0	0	0	0	0	0	0	0	2
7507	2	2016-11-08 14:15:43	195.0	189.4	196.0	0.0	0.0	0.0	48.81	0.0	0.0	1	0	0	0	0	0	0	2
7508	2	2016-11-08 14:16:06	0.0	0.0	0.0	0.0	0.0	0.0	48.37	0.0	0.0	0	0	0	0	0	0	0	2
7509	2	2016-11-08 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.55	0.0	0.0	0	0	0	0	0	0	0	2
7510	2	2016-11-08 15:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.49	0.0	0.0	0	0	0	0	0	0	0	2
7511	2	2016-11-08 16:15:56	205.0	198.4	206.4	0.0	0.0	0.0	48.47	0.0	0.0	1	0	0	0	0	0	0	2
7512	2	2016-11-08 16:15:56	205.0	198.4	206.4	0.0	0.0	0.0	48.47	0.0	0.0	1	0	0	0	0	0	0	2
7513	2	2016-11-08 16:16:21	205.2	200.5	207.9	0.0	0.0	0.0	48.65	0.0	0.0	1	1	1	0	0	0	0	2
7514	2	2016-11-08 16:47:01	200.6	195.4	201.2	0.0	0.0	0.0	48.07	0.0	0.0	1	1	1	0	0	0	0	2
7515	2	2016-11-08 17:47:01	198.4	192.1	200.9	0.0	0.0	0.0	48.47	0.0	0.0	1	1	1	0	0	0	0	2
7516	2	2016-11-08 18:47:01	194.1	189.6	195.6	0.0	0.0	0.0	48.79	0.0	0.0	1	1	1	0	0	0	0	2
7517	2	2016-11-08 19:16:33	195.4	189.8	197.4	0.0	0.0	0.0	48.52	0.0	0.0	1	0	0	0	0	0	0	2
7518	2	2016-11-08 19:16:33	195.4	189.8	197.4	0.0	0.0	0.0	48.52	0.0	0.0	1	0	0	0	0	0	0	2
7519	2	2016-11-08 19:16:56	0.0	0.0	0.0	0.0	0.0	0.0	48.67	0.0	0.0	0	0	0	0	0	0	0	2
7520	2	2016-11-08 19:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.46	0.0	0.0	0	0	0	0	0	0	0	2
7521	2	2016-11-08 20:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.45	0.0	0.0	0	0	0	0	0	0	0	2
7522	2	2016-11-08 21:16:46	199.7	194.2	201.0	0.0	0.0	0.0	48.54	0.0	0.0	1	0	0	0	0	0	0	2
7523	2	2016-11-08 21:17:11	201.4	196.8	202.4	0.0	0.0	0.0	48.41	0.0	0.0	1	1	1	0	0	0	0	2
7524	2	2016-11-08 21:47:01	197.9	195.6	203.1	0.0	0.0	0.0	47.82	0.0	0.0	1	1	1	0	0	0	0	2
7525	2	2016-11-08 22:47:01	209.1	203.2	209.3	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
7526	2	2016-11-08 23:47:01	213.8	208.5	214.5	0.0	0.0	0.0	48.18	0.0	0.0	1	1	1	0	0	0	0	2
7527	2	2016-11-08 23:47:01	213.8	208.5	214.5	0.0	0.0	0.0	48.18	0.0	0.0	1	1	1	0	0	0	0	2
7528	2	2016-11-09 00:17:23	208.6	203.5	211.1	0.0	0.0	0.0	48.61	0.0	0.0	1	0	0	0	0	0	0	2
7529	2	2016-11-09 00:17:46	0.0	0.0	0.0	0.0	0.0	0.0	48.65	0.0	0.0	0	0	0	0	0	0	0	2
7530	2	2016-11-09 00:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.10	0.0	0.0	0	0	0	0	0	0	0	2
7531	2	2016-11-09 01:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.26	0.0	0.0	0	0	0	0	0	0	0	2
7532	2	2016-11-09 02:17:36	216.4	211.6	220.1	0.0	0.0	0.0	48.43	0.0	0.0	1	0	0	0	0	0	0	2
7533	2	2016-11-09 02:18:01	220.2	215.0	222.0	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
7534	2	2016-11-09 02:47:01	221.6	212.6	220.8	0.0	0.0	0.0	48.03	0.0	0.0	1	1	1	0	0	0	0	2
7535	2	2016-11-09 03:47:01	223.2	214.4	224.2	0.0	0.0	0.0	48.49	0.0	0.0	1	1	1	0	0	0	0	2
7536	2	2016-11-09 04:47:01	201.2	195.5	204.0	0.0	0.0	0.0	48.63	0.0	0.0	1	1	1	0	0	0	0	2
7537	2	2016-11-09 05:18:13	188.0	182.0	187.5	0.0	0.0	0.0	48.51	0.0	1.1	1	0	0	0	0	0	0	2
7538	2	2016-11-09 05:18:13	188.0	182.0	187.5	0.0	0.0	0.0	48.51	0.0	1.1	1	0	0	0	0	0	0	2
7539	2	2016-11-09 05:18:36	0.0	0.0	0.0	0.0	0.0	0.0	48.41	0.0	0.0	0	0	0	0	0	0	0	2
7540	2	2016-11-09 05:18:36	0.0	0.0	0.0	0.0	0.0	0.0	48.41	0.0	0.0	0	0	0	0	0	0	0	2
7541	2	2016-11-09 05:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.69	0.0	0.0	0	0	0	0	0	0	0	2
7542	2	2016-11-09 05:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.69	0.0	0.0	0	0	0	0	0	0	0	2
7543	2	2016-11-09 06:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	0	0	2
7544	2	2016-11-09 06:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	0	0	2
7545	2	2016-11-09 07:18:26	206.2	201.7	209.2	0.0	0.0	0.0	48.59	0.0	0.0	1	0	0	0	0	0	0	2
7546	2	2016-11-09 07:18:26	206.2	201.7	209.2	0.0	0.0	0.0	48.59	0.0	0.0	1	0	0	0	0	0	0	2
7547	2	2016-11-09 07:18:51	207.6	199.9	207.1	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
7548	2	2016-11-09 07:18:51	207.6	199.9	207.1	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
7549	2	2016-11-09 07:47:01	198.5	194.8	205.0	0.0	0.0	0.0	48.42	0.0	0.0	1	1	1	0	0	0	0	2
7550	2	2016-11-09 08:47:01	195.7	192.1	200.6	0.0	0.0	0.0	48.63	0.0	0.0	1	1	1	0	0	0	0	2
7551	2	2016-11-09 09:47:01	201.1	194.2	201.8	0.0	0.0	0.0	48.47	0.0	0.0	1	1	1	0	0	0	0	2
7552	2	2016-11-09 10:19:03	203.6	197.1	202.8	0.0	0.0	0.0	48.53	0.0	0.0	1	0	0	0	0	0	0	2
7553	2	2016-11-09 10:19:26	0.0	0.0	0.0	0.0	0.0	0.0	47.96	0.0	0.0	0	0	0	0	0	0	0	2
7554	2	2016-11-09 10:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.61	0.0	0.0	0	0	0	0	0	0	0	2
7555	2	2016-11-09 11:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.59	0.0	0.0	0	0	0	0	0	0	0	2
7556	2	2016-11-09 12:19:16	208.5	203.3	209.4	0.0	0.0	0.0	48.28	0.0	0.0	1	0	0	0	0	0	0	2
7455	2	2016-11-07 10:10:56	201.7	198.3	203.2	0.0	0.0	0.0	48.65	0.0	0.0	1	0	0	0	0	0	0	2
7456	2	2016-11-07 10:11:21	206.1	198.2	206.3	0.0	0.0	0.0	48.78	0.0	0.0	1	1	1	0	0	0	0	2
7457	2	2016-11-07 10:47:01	200.9	193.2	199.3	0.0	0.0	0.0	48.78	0.0	0.0	1	1	1	0	0	0	0	2
7458	2	2016-11-07 11:47:01	205.3	197.7	203.5	0.0	0.0	0.0	48.08	0.0	0.0	1	1	1	0	0	0	0	2
7459	2	2016-11-07 12:47:01	205.0	197.0	202.5	0.0	0.0	0.0	48.47	0.0	0.0	1	1	1	0	0	0	0	2
7460	2	2016-11-07 13:11:33	199.2	194.0	201.1	0.0	0.0	0.0	48.84	0.0	0.0	1	0	0	0	0	0	0	2
7461	2	2016-11-07 13:11:56	0.0	0.0	0.0	0.0	0.0	0.0	48.08	0.0	0.0	0	0	0	0	0	0	0	2
7462	2	2016-11-07 13:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.36	0.0	0.0	0	0	0	0	0	0	0	2
7463	2	2016-11-07 14:47:01	0.0	0.0	0.0	0.0	0.0	0.0	47.93	0.0	0.0	0	0	0	0	0	0	0	2
7464	2	2016-11-07 15:11:46	195.0	190.0	197.9	0.0	0.0	0.0	48.55	0.0	0.0	1	0	0	0	0	0	0	2
7465	2	2016-11-07 15:12:11	194.9	187.0	195.0	0.0	0.0	0.0	48.97	0.0	0.0	1	1	1	0	0	0	0	2
7466	2	2016-11-07 15:47:01	202.1	192.9	204.7	0.0	0.0	0.0	48.03	0.0	0.0	1	1	1	0	0	0	0	2
7467	2	2016-11-07 16:47:01	197.2	192.9	198.7	0.0	0.0	0.0	48.83	0.0	0.0	1	1	1	0	0	0	0	2
7468	2	2016-11-07 17:47:01	202.3	196.7	201.1	0.0	0.0	0.0	48.58	0.0	0.0	1	1	1	0	0	0	0	2
7469	2	2016-11-07 18:12:23	194.4	188.2	198.5	0.0	0.0	0.0	48.57	0.0	0.0	1	0	0	0	0	0	0	2
7470	2	2016-11-07 18:12:46	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7471	2	2016-11-07 18:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	0	0	2
7472	2	2016-11-07 18:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	0	0	2
7473	2	2016-11-07 19:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	0.0	0	0	0	0	0	0	0	2
7474	2	2016-11-07 20:12:36	201.5	195.3	204.3	0.0	0.0	0.0	48.49	0.0	0.0	1	0	0	0	0	0	0	2
7475	2	2016-11-07 20:13:01	202.3	196.0	202.6	0.0	0.0	0.0	48.20	0.0	0.0	1	1	1	0	0	0	0	2
7476	2	2016-11-07 20:47:01	194.8	189.6	197.7	0.0	0.0	0.0	48.36	0.0	0.0	1	1	1	0	0	0	0	2
7477	2	2016-11-07 21:47:01	200.9	198.0	203.4	0.0	0.0	0.0	48.75	0.0	1.5	1	1	1	0	0	0	0	2
7478	2	2016-11-07 22:47:01	201.3	197.6	202.8	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
7479	2	2016-11-07 22:47:01	201.3	197.6	202.8	0.0	0.0	0.0	48.53	0.0	0.0	1	1	1	0	0	0	0	2
7480	2	2016-11-07 23:13:13	206.9	199.1	205.5	0.0	0.0	0.0	48.33	0.0	0.0	1	0	0	0	0	0	0	2
7481	2	2016-11-07 23:13:36	0.0	0.0	0.0	0.0	0.0	0.0	48.33	0.0	0.0	0	0	0	0	0	0	0	2
7482	2	2016-11-07 23:47:01	0.0	0.0	0.0	0.0	0.0	0.0	47.90	0.0	0.0	0	0	0	0	0	0	0	2
7483	2	2016-11-08 00:47:01	0.0	0.0	0.0	0.0	0.0	0.0	47.95	0.0	0.0	0	0	0	0	0	0	0	2
7484	2	2016-11-08 01:13:26	209.5	202.3	210.4	0.0	0.0	0.0	48.04	0.0	0.0	1	0	0	0	0	0	0	2
7485	2	2016-11-08 01:13:51	207.6	202.4	211.6	0.0	0.0	0.0	48.19	0.0	0.0	1	1	1	0	0	0	0	2
7486	2	2016-11-08 01:47:01	214.7	206.7	213.0	0.0	0.0	0.0	48.89	0.0	0.0	1	1	1	0	0	0	0	2
7487	2	2016-11-08 02:47:01	216.0	207.8	214.3	0.0	0.0	0.0	48.56	0.0	0.0	1	1	1	0	0	0	0	2
7488	2	2016-11-08 03:47:01	215.4	209.8	216.5	0.0	0.0	0.0	48.52	0.0	0.0	1	1	1	0	0	0	0	2
7489	2	2016-11-08 04:14:03	207.0	200.1	206.8	0.0	0.0	0.0	48.96	0.0	0.0	1	0	0	0	0	0	0	2
7490	2	2016-11-08 04:14:26	0.0	0.0	0.0	0.0	0.0	0.0	48.43	0.0	0.0	0	0	0	0	0	0	0	2
7491	2	2016-11-08 04:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.71	0.0	0.0	0	0	0	0	0	0	0	2
7492	2	2016-11-08 05:47:01	0.0	0.0	0.0	0.0	0.0	0.0	47.82	0.0	0.0	0	0	0	0	0	0	0	2
7493	2	2016-11-08 06:14:16	201.1	196.0	203.6	0.0	0.0	0.0	48.29	0.0	0.0	1	0	0	0	0	0	0	2
7494	2	2016-11-08 06:14:41	204.0	196.0	207.0	0.0	0.0	0.0	48.43	0.0	0.0	1	1	1	0	0	0	0	2
7495	2	2016-11-08 06:47:01	203.2	199.3	204.6	0.0	0.0	0.0	48.86	0.0	0.0	1	1	1	0	0	0	0	2
7496	2	2016-11-08 07:47:01	194.5	189.2	195.7	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7497	2	2016-11-08 08:47:01	197.9	191.3	198.6	0.0	0.0	0.0	48.58	0.0	0.0	1	1	1	0	0	0	0	2
7498	2	2016-11-08 09:14:53	199.8	193.3	201.2	0.0	0.0	0.0	48.47	0.0	0.0	1	0	0	0	0	0	0	2
7499	2	2016-11-08 09:15:16	0.0	0.0	0.0	0.0	0.0	0.0	48.19	0.0	0.0	0	0	0	0	0	0	0	2
7500	2	2016-11-08 09:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.75	0.0	0.0	0	0	0	0	0	0	0	2
7501	2	2016-11-08 10:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7502	2	2016-11-08 11:15:06	202.4	195.3	203.4	0.0	0.0	0.0	48.48	0.0	0.0	1	0	0	0	0	0	0	2
7503	2	2016-11-08 11:15:31	202.7	195.2	205.4	0.0	0.0	0.0	48.55	0.0	0.0	1	1	1	0	0	0	0	2
7504	2	2016-11-08 11:47:01	204.4	198.3	208.3	0.0	0.0	0.0	48.41	0.0	0.0	1	1	1	0	0	0	0	2
7505	2	2016-11-08 12:47:01	202.6	195.0	202.2	0.0	0.0	0.0	48.54	0.0	0.0	1	1	1	0	0	0	0	2
7506	2	2016-11-08 13:47:01	193.7	191.9	197.9	0.0	0.0	0.0	48.50	0.0	0.0	1	1	1	0	0	0	0	2
7574	2	2016-11-10 18:08:01	0.0	0.0	0.0	0.0	0.0	0.0	48.86	0.0	0.0	0	0	0	0	0	0	0	2
7575	2	2016-11-10 18:09:31	200.2	195.8	203.5	0.0	0.0	0.0	48.58	0.0	0.0	1	0	0	0	0	0	0	2
7576	2	2016-11-10 18:09:54	204.0	195.6	205.4	0.0	0.0	0.0	48.03	0.0	0.0	1	1	1	0	0	0	0	2
7577	2	2016-11-10 19:08:01	198.4	192.4	199.5	0.0	0.0	0.0	48.72	0.0	0.0	1	1	1	0	0	0	0	2
7578	2	2016-11-10 20:08:01	193.5	186.6	193.8	0.0	0.0	0.0	48.48	0.0	0.0	1	1	1	0	0	0	0	2
7579	2	2016-11-10 21:08:01	198.3	192.4	199.2	0.0	0.0	0.0	48.50	0.0	0.0	1	1	1	0	0	0	0	2
7580	2	2016-11-10 21:10:06	195.7	188.8	195.7	0.0	0.0	0.0	48.42	0.0	0.0	1	0	0	0	0	0	0	2
7581	2	2016-11-10 21:10:27	0.0	0.0	0.0	0.0	0.0	0.0	48.72	0.0	0.0	0	0	0	0	0	0	0	2
7582	2	2016-11-10 22:08:01	0.0	0.0	0.0	0.0	0.0	0.0	48.70	0.0	0.0	0	0	0	0	0	0	0	2
7583	2	2016-11-10 23:08:01	0.0	0.0	0.0	0.0	0.0	0.0	48.42	0.0	0.0	0	0	0	0	0	0	0	2
7584	2	2016-11-10 23:10:21	214.4	210.5	217.3	0.0	0.0	0.0	48.43	0.0	0.0	1	0	0	0	0	0	0	2
7585	2	2016-11-10 23:10:44	215.0	210.5	218.5	0.0	0.0	0.0	48.45	0.0	0.0	1	1	1	0	0	0	0	2
7586	2	2016-11-11 00:08:01	213.8	207.9	218.3	0.0	0.0	0.0	48.51	0.0	0.0	1	1	1	0	0	0	0	2
7587	2	2016-11-11 01:08:01	218.7	212.0	220.4	0.0	0.0	0.0	48.28	0.0	0.0	1	1	1	0	0	0	0	2
7588	2	2016-11-11 01:08:01	218.7	212.0	220.4	0.0	0.0	0.0	48.28	0.0	0.0	1	1	1	0	0	0	0	2
7589	2	2016-11-11 02:08:01	224.9	217.6	226.1	0.0	0.0	0.0	48.65	0.0	0.0	1	1	1	0	0	0	0	2
7590	2	2016-11-11 02:08:01	224.9	217.6	226.1	0.0	0.0	0.0	48.65	0.0	0.0	1	1	1	0	0	0	0	2
7591	2	2016-11-11 02:10:56	220.2	215.7	222.2	0.0	0.0	0.0	48.91	0.0	0.0	1	0	0	0	0	0	0	2
7592	2	2016-11-11 02:10:56	220.2	215.7	222.2	0.0	0.0	0.0	48.91	0.0	0.0	1	0	0	0	0	0	0	2
7593	2	2016-11-11 02:11:16	0.0	0.0	0.0	0.0	0.0	0.0	48.64	0.0	0.0	0	0	0	0	0	0	0	2
7557	2	2016-11-09 12:19:41	210.3	203.1	209.6	0.0	0.0	0.0	48.96	0.0	0.0	1	1	1	0	0	0	0	2
7558	2	2016-11-09 12:47:01	208.4	204.6	212.2	0.0	0.0	0.0	48.41	0.0	0.0	1	1	1	0	0	0	0	2
7559	2	2016-11-09 13:47:01	203.3	196.1	202.5	0.0	0.0	0.0	48.48	0.0	0.0	1	1	1	0	0	0	0	2
7560	2	2016-11-09 14:47:01	200.6	198.4	203.9	0.0	0.0	0.0	48.47	0.0	0.0	1	1	1	0	0	0	0	2
7561	2	2016-11-09 15:19:53	201.1	197.3	204.5	0.0	0.0	0.0	48.44	0.0	0.0	1	0	0	0	0	0	0	2
7562	2	2016-11-09 15:20:16	0.0	0.0	0.0	0.0	0.0	0.0	48.29	0.0	0.0	0	0	0	0	0	0	0	2
7563	2	2016-11-09 15:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.39	0.0	0.0	0	0	0	0	0	0	0	2
7564	2	2016-11-09 16:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.49	0.0	0.0	0	0	0	0	0	0	0	2
7565	2	2016-11-09 17:20:06	201.4	196.8	203.7	0.0	0.0	0.0	48.48	0.0	0.0	1	0	0	0	0	0	0	2
7566	2	2016-11-09 17:20:31	202.2	195.7	203.0	0.0	0.0	0.0	48.91	0.0	0.0	1	1	1	0	0	0	0	2
7567	2	2016-11-10 07:47:01	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	0.0	0	0	0	0	0	0	0	2
7568	2	2016-11-10 08:22:36	204.1	200.1	207.2	0.0	0.0	0.0	48.66	0.0	0.0	1	0	0	0	0	0	0	2
7569	2	2016-11-10 08:23:01	205.2	198.6	205.1	0.0	0.0	0.0	48.07	0.0	0.0	1	1	1	0	0	0	0	2
7570	2	2016-11-10 08:47:01	204.5	196.5	203.2	0.0	0.0	0.0	48.64	0.0	0.0	1	1	1	0	0	0	0	2
7571	2	2016-11-10 09:47:01	205.6	200.7	205.4	0.0	0.0	0.0	48.93	0.0	0.0	1	1	1	0	0	0	0	2
7572	2	2016-11-10 10:47:01	203.8	200.5	207.8	0.0	0.0	0.0	48.78	0.0	0.0	1	1	1	0	0	0	0	2
7610	2	2016-12-07 10:38:34	0.0	0.0	0.0	0.0	0.0	0.0	48.56	0.0	0.0	0	0	0	0	0	1	0	2
7611	2	2016-12-07 10:38:42	207.6	208.2	211.5	0.0	0.0	0.0	48.59	0.0	0.0	1	0	0	0	0	1	0	2
7612	2	2016-12-07 10:38:49	210.1	203.5	210.5	0.0	0.0	0.0	48.73	0.0	0.0	1	0	0	0	0	0	0	2
7613	2	2016-12-07 10:39:03	208.5	203.2	210.9	0.0	0.0	0.0	48.59	0.0	0.0	1	1	1	0	0	1	0	2
7614	2	2016-12-07 10:39:47	207.9	202.5	211.0	0.0	0.0	0.0	36.17	0.0	0.0	1	1	1	0	0	1	1	2
7615	2	2016-12-07 10:39:55	208.1	205.6	210.1	0.0	0.0	0.0	39.31	0.0	0.0	1	1	1	0	0	0	1	2
7616	2	2016-12-07 10:42:46	208.8	202.2	214.5	0.0	0.0	0.0	39.55	0.0	0.0	1	1	1	0	0	1	1	2
7617	2	2016-12-07 10:43:47	210.5	201.6	213.9	0.0	0.0	0.0	39.25	0.0	0.0	1	1	1	0	0	0	1	2
7618	2	2016-12-07 11:38:01	204.9	198.6	205.5	0.0	0.0	0.0	39.55	0.0	0.0	1	1	1	0	0	0	1	2
7619	2	2016-12-07 11:38:01	204.9	198.6	205.5	0.0	0.0	0.0	39.55	0.0	0.0	1	1	1	0	0	0	1	2
7620	2	2016-12-07 12:38:01	206.0	202.3	207.6	0.0	0.0	0.0	39.31	0.0	0.0	1	1	1	0	0	0	1	2
7594	2	2016-11-11 02:11:16	0.0	0.0	0.0	0.0	0.0	0.0	48.64	0.0	0.0	0	0	0	0	0	0	0	2
7595	2	2016-11-11 03:08:01	0.0	0.0	0.0	0.0	0.0	0.0	48.66	0.0	0.0	0	0	0	0	0	0	0	2
7596	2	2016-11-11 04:08:01	0.0	0.0	0.0	0.0	0.0	0.0	48.14	0.0	0.0	0	0	0	0	0	0	0	2
7597	2	2016-11-11 04:11:11	215.0	209.5	216.3	0.0	0.0	0.0	48.39	0.0	0.0	1	0	0	0	0	0	0	2
7598	2	2016-11-11 04:11:34	214.5	209.4	217.3	0.0	0.0	0.0	48.48	0.0	0.0	1	1	1	0	0	0	0	2
7599	2	2016-11-11 05:08:01	196.0	190.3	196.1	0.0	0.0	0.0	49.02	0.0	0.0	1	1	1	0	0	0	0	2
7600	2	2016-11-11 06:08:01	189.5	184.9	193.4	0.0	0.0	0.0	48.41	0.0	0.0	1	1	1	0	0	0	0	2
7601	2	2016-11-11 07:08:01	207.2	202.5	208.6	0.0	0.0	0.0	48.88	0.0	0.0	1	1	1	0	0	0	0	2
7602	2	2016-11-11 07:11:46	206.0	200.8	208.0	0.0	0.0	0.0	48.73	0.0	0.0	1	0	0	0	0	0	0	2
7603	2	2016-11-11 07:11:46	206.0	200.8	208.0	0.0	0.0	0.0	48.73	0.0	0.0	1	0	0	0	0	0	0	2
7604	2	2016-11-11 07:12:06	0.0	0.0	0.0	0.0	0.0	0.0	48.68	0.0	0.0	0	0	0	0	0	0	0	2
7605	2	2016-11-11 08:08:01	0.0	0.0	0.0	0.0	0.0	0.0	48.46	0.0	0.0	0	0	0	0	0	0	0	2
7606	2	2016-11-11 09:08:01	0.0	0.0	0.0	0.0	0.0	0.0	48.75	0.0	0.0	0	0	0	0	0	0	0	2
7607	2	2016-11-11 09:12:00	204.6	199.7	206.4	0.0	0.0	0.0	48.61	0.0	0.0	1	0	0	0	0	0	0	2
7608	2	2016-11-11 09:12:24	203.5	198.1	207.9	0.0	0.0	0.0	48.65	0.0	0.0	1	1	1	0	0	0	0	2
7609	2	2016-12-07 10:26:52	209.4	201.9	208.1	0.0	0.0	0.0	48.75	0.0	0.0	1	1	1	0	0	1	0	2
7621	2	2016-12-07 12:39:09	207.4	203.2	208.9	0.0	0.0	0.0	39.53	0.0	0.0	1	0	0	0	0	0	1	2
7622	2	2016-12-07 12:39:31	0.0	0.0	0.0	0.0	0.0	0.0	39.62	0.0	0.0	0	0	0	0	0	0	1	2
7623	2	2016-12-07 13:38:01	0.0	0.0	0.0	0.0	0.0	0.0	39.34	0.0	0.0	0	0	0	0	0	0	1	2
7624	2	2016-12-07 14:38:01	0.0	0.0	0.0	0.0	0.0	0.0	39.32	0.0	0.0	0	0	0	0	0	0	1	2
7625	2	2016-12-07 14:39:26	198.5	192.2	199.4	0.0	0.0	0.0	39.51	0.0	0.0	1	0	0	0	0	0	1	2
7626	2	2016-12-07 14:39:47	197.2	192.9	199.7	0.0	0.0	0.0	39.22	0.0	0.0	1	1	1	0	0	0	1	2
7627	2	2016-12-07 15:36:21	194.0	188.9	196.0	0.0	0.0	0.0	48.24	0.0	0.0	1	1	1	0	0	0	0	2
7628	2	2016-12-07 15:36:54	190.9	188.3	193.1	0.0	0.0	0.0	48.50	0.0	1.1	1	1	1	0	0	1	0	2
7629	2	2016-12-07 15:37:53	191.3	186.1	193.3	0.0	0.0	0.0	48.30	0.0	0.0	1	1	1	0	0	0	0	2
7630	2	2016-12-07 15:37:53	191.3	186.1	193.3	0.0	0.0	0.0	48.30	0.0	0.0	1	1	1	0	0	0	0	2
7631	2	2016-12-07 15:38:01	191.1	187.8	193.2	0.0	0.0	0.0	48.73	0.0	0.0	1	1	1	0	0	0	0	2
7632	2	2016-12-07 15:38:01	191.1	187.8	193.2	0.0	0.0	0.0	48.73	0.0	0.0	1	1	1	0	0	0	0	2
7633	2	2016-12-07 18:10:11	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7634	2	2016-12-07 18:11:01	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	1	0	0	1	2
7635	2	2016-12-07 18:11:14	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	1	0	1	1	2
7636	2	2017-01-10 11:47:40	201.6	195.4	202.0	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	1	1	2
7637	2	2017-01-10 11:48:04	200.5	194.0	201.6	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	1	1	2
7638	2	2017-01-10 11:48:12	198.6	194.0	200.2	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7639	2	2017-01-10 11:50:01	200.6	195.4	201.8	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7640	2	2017-01-10 12:13:48	211.3	205.4	212.2	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7641	2	2017-01-10 12:14:11	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7642	2	2017-01-10 12:50:01	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7643	2	2017-01-10 13:14:00	199.1	194.2	200.8	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7644	2	2017-01-10 13:14:22	201.8	194.9	201.6	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7645	2	2017-01-10 13:45:54	198.8	193.1	199.0	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	1
7646	2	2017-01-10 13:46:16	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	1
7647	2	2017-01-10 13:47:51	202.2	197.0	204.3	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	1
7648	2	2017-01-10 13:48:13	200.4	195.7	201.8	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	1
7649	2	2017-01-10 13:48:13	200.4	195.7	201.8	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	1
7650	2	2017-01-10 13:49:02	201.6	195.4	209.1	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	1	1	1
7651	2	2017-01-10 13:49:02	201.6	195.4	209.1	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	1	1	1
7652	2	2017-01-10 13:50:01	201.8	199.1	203.1	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	1
7653	2	2017-01-10 13:50:01	201.8	199.1	203.1	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	1
7654	2	2017-01-10 13:50:21	203.3	196.9	204.7	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	1
7655	2	2017-01-10 13:50:41	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	1
7656	2	2017-01-10 13:51:10	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	1	1	1
7657	2	2017-01-10 13:51:34	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	1	1	1
7658	2	2017-01-10 13:52:46	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7659	2	2017-01-10 13:54:10	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	1	1	2
7660	2	2017-01-10 13:54:10	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	1	1	2
7661	2	2017-01-10 13:54:43	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7662	2	2017-01-10 14:08:11	40.8	0.0	0.0	0.0	0.0	0.0	0.00	0.0	1.7	1	0	0	0	0	0	1	2
7663	2	2017-01-10 14:08:11	40.8	0.0	0.0	0.0	0.0	0.0	0.00	0.0	1.7	1	0	0	0	0	0	1	2
7664	2	2017-01-10 14:08:21	56.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	1.3	1	0	0	0	0	0	1	2
7665	2	2017-01-10 14:09:06	52.5	0.0	0.0	0.0	0.0	0.0	0.00	0.0	1.7	1	0	0	0	0	0	1	2
7666	2	2017-01-10 14:09:21	54.1	0.0	0.0	0.0	0.0	0.0	0.00	0.0	1.5	1	0	0	0	0	0	1	2
7667	2	2017-01-10 14:11:18	196.6	194.7	198.9	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	1
7668	2	2017-01-10 14:09:56	40.3	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7669	2	2017-01-10 14:10:56	196.9	191.6	199.1	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	1
7670	2	2017-01-10 14:11:58	198.3	193.0	200.2	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	1
7671	2	2017-01-10 14:12:21	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	1
7672	2	2017-01-10 14:14:09	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	1
7673	2	2017-01-10 14:14:31	198.2	193.3	201.1	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	1
7674	2	2017-01-10 14:14:52	199.1	193.9	200.7	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	1
7675	2	2017-01-10 14:17:26	201.5	195.9	202.6	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	1
7676	2	2017-01-10 14:17:46	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	1
7677	2	2017-01-10 16:18:04	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	1
7678	2	2017-01-10 16:18:31	196.6	191.5	199.2	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	1
7679	2	2017-01-10 16:18:54	196.6	191.9	197.7	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	1
7680	2	2017-01-10 16:20:00	196.3	191.5	199.1	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	1
7681	2	2017-01-10 16:20:21	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	1
7682	2	2017-01-10 16:20:46	199.2	193.6	201.0	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7683	2	2017-01-10 16:21:07	198.3	193.3	200.3	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7684	2	2017-01-10 17:18:01	194.9	189.2	196.3	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7685	2	2017-01-10 17:21:09	198.9	193.7	200.7	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7686	2	2017-01-10 17:21:31	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7687	2	2017-01-10 18:18:01	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7688	2	2017-01-10 18:21:21	190.2	185.7	191.8	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7689	2	2017-01-10 18:21:43	190.8	184.4	192.6	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7690	2	2017-01-10 19:18:01	198.2	192.7	201.1	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7691	2	2017-01-10 19:21:47	196.1	190.4	197.2	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7692	2	2017-01-10 19:22:11	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7693	2	2017-01-10 20:18:01	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7694	2	2017-01-10 20:21:56	193.6	188.4	196.9	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7695	2	2017-01-10 20:22:21	193.8	188.0	195.1	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7696	2	2017-01-10 21:18:01	204.1	199.0	206.7	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7697	2	2017-01-10 21:22:25	205.4	200.9	207.2	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7698	2	2017-01-10 21:22:46	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7699	2	2017-01-10 22:18:01	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7700	2	2017-01-10 22:22:36	205.8	200.5	207.4	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7701	2	2017-01-10 22:22:59	207.2	201.7	208.0	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7702	2	2017-01-10 23:18:01	209.0	203.8	211.4	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7703	2	2017-01-10 23:23:03	209.4	203.5	211.4	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7704	2	2017-01-10 23:23:26	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7705	2	2017-01-11 02:18:01	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7706	2	2017-01-11 02:23:51	216.6	211.6	218.9	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7707	2	2017-01-11 02:24:15	217.0	211.8	218.9	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7708	2	2017-01-11 03:18:01	215.7	211.2	217.6	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7709	2	2017-01-11 03:24:19	213.7	207.5	215.9	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7710	2	2017-01-11 03:24:41	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7711	2	2017-01-11 04:18:01	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7712	2	2017-01-11 04:24:31	206.9	201.3	209.4	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7713	2	2017-01-11 04:24:53	206.9	202.0	208.4	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7714	2	2017-01-11 04:24:53	206.9	202.0	208.4	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7715	2	2017-01-11 05:18:01	184.2	178.9	185.2	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7716	2	2017-01-11 05:18:01	184.2	178.9	185.2	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7717	2	2017-01-11 05:24:57	190.0	184.8	190.8	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7718	2	2017-01-11 05:25:21	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7719	2	2017-01-11 05:25:21	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7720	2	2017-01-11 06:18:01	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7721	2	2017-01-11 06:25:06	200.7	195.5	203.3	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7722	2	2017-01-11 06:25:06	200.7	195.5	203.3	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7723	2	2017-01-11 06:25:31	201.7	197.3	205.2	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7724	2	2017-01-11 07:18:01	203.9	198.2	204.9	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7725	2	2017-01-11 07:18:01	203.9	198.2	204.9	0.0	0.0	0.0	0.00	0.0	0.0	1	1	1	0	0	0	1	2
7726	2	2017-01-11 07:25:35	207.7	202.2	210.3	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7727	2	2017-01-11 07:25:35	207.7	202.2	210.3	0.0	0.0	0.0	0.00	0.0	0.0	1	0	0	0	0	0	1	2
7728	2	2017-01-11 07:25:56	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7729	2	2017-01-11 14:19:36	0.0	0.0	0.0	0.0	0.0	0.0	48.77	0.0	12.9	0	0	0	1	0	0	0	2
7730	2	2017-01-11 15:18:01	0.0	0.0	0.0	0.0	0.0	0.0	48.87	0.0	12.6	0	0	0	1	0	0	0	2
7731	2	2017-01-11 16:18:01	0.0	0.0	0.0	0.0	0.0	0.0	48.87	0.0	12.6	0	0	0	1	0	0	0	2
7734	1	2017-02-22 14:44:35	0.0	0.0	0.0	\N	\N	\N	53.42	\N	13.4	0	0	0	0	0	0	0	2
7735	1	2017-02-22 14:48:34	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
7736	1	2017-02-22 14:52:02	0.0	0.0	0.0	\N	\N	\N	53.26	\N	12.7	0	0	0	0	0	0	0	2
7738	1	2017-02-22 15:00:46	0.0	0.0	0.0	\N	\N	\N	53.50	\N	13.2	0	0	0	0	0	0	0	2
7739	1	2017-02-22 15:02:28	0.0	0.0	0.0	\N	\N	\N	53.40	\N	12.8	0	0	0	0	0	0	0	2
7740	1	2017-02-22 15:07:13	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
7743	1	2017-02-22 15:21:04	0.0	0.0	0.0	\N	\N	\N	53.38	\N	12.8	0	0	0	0	0	0	0	2
7747	1	2017-02-22 15:32:31	0.0	0.0	0.0	\N	\N	\N	53.59	\N	13.1	0	0	0	0	0	0	0	2
7748	1	2017-02-22 15:36:02	0.0	0.0	0.0	\N	\N	\N	53.55	\N	0.0	0	0	0	0	0	0	0	2
7749	1	2017-02-22 15:40:28	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
7752	1	2017-02-22 15:48:35	0.0	0.0	0.0	\N	\N	\N	53.57	\N	13.6	0	0	0	0	0	0	0	2
7753	1	2017-02-22 15:50:13	0.0	0.0	0.0	\N	\N	\N	53.68	\N	0.0	0	0	0	0	0	0	0	2
7754	1	2017-02-22 16:24:57	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
7755	1	2017-02-22 16:26:11	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
7756	1	2017-02-22 16:28:10	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
7757	1	2017-02-22 16:33:13	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
7760	1	2017-02-22 16:41:57	0.0	0.0	0.0	\N	\N	\N	53.89	\N	13.3	0	0	0	0	0	0	0	2
7761	1	2017-02-22 16:42:57	0.0	0.0	0.0	\N	\N	\N	54.22	\N	12.9	0	0	0	0	0	0	0	2
7763	1	2017-02-22 16:46:57	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
7766	1	2017-02-22 16:51:56	0.0	0.0	0.0	\N	\N	\N	53.50	\N	0.0	0	0	0	0	0	0	0	2
7767	1	2017-02-22 16:55:02	0.0	0.0	0.0	\N	\N	\N	53.66	\N	0.0	0	0	0	0	0	0	0	2
7769	1	2017-02-22 17:02:19	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
7771	1	2017-02-22 17:11:02	220.6	220.0	220.9	\N	\N	\N	53.61	\N	13.6	1	1	1	0	0	0	0	2
7772	1	2017-02-22 17:38:02	227.4	226.8	227.7	\N	\N	\N	53.25	\N	14.8	1	1	1	0	0	0	0	2
7773	1	2017-02-22 17:42:02	224.6	224.0	224.9	\N	\N	\N	53.63	\N	14.8	1	1	1	0	0	0	0	2
7774	1	2017-02-22 17:43:02	0.0	0.0	0.0	\N	\N	\N	53.69	\N	14.0	0	0	0	0	0	0	0	2
7775	1	2017-02-22 17:47:02	0.0	0.0	0.0	\N	\N	\N	53.55	\N	13.7	0	0	0	0	0	0	0	2
7776	1	2017-02-22 17:48:03	223.5	222.9	223.8	\N	\N	\N	53.53	\N	13.3	1	1	1	0	0	0	0	2
7777	1	2017-02-22 17:52:02	222.9	222.3	223.2	\N	\N	\N	55.05	\N	14.9	1	1	1	0	0	0	0	2
7778	1	2017-02-22 17:55:31	0.0	0.0	0.0	\N	\N	\N	53.72	\N	14.4	0	0	0	0	0	0	0	2
7779	1	2017-02-22 18:00:54	223.7	223.1	224.0	\N	\N	\N	53.68	\N	13.5	1	1	1	0	0	0	0	2
7780	1	2017-02-22 18:02:02	224.0	223.4	224.3	\N	\N	\N	53.66	\N	14.8	1	1	1	0	0	0	0	2
7781	1	2017-02-22 18:06:02	221.6	221.0	221.9	\N	\N	\N	55.15	\N	14.9	1	1	1	0	0	0	0	2
7782	1	2017-02-22 18:08:30	0.0	0.0	0.0	\N	\N	\N	53.98	\N	14.2	0	0	0	0	0	0	0	2
7783	1	2017-02-22 18:11:02	0.0	0.0	0.0	\N	\N	\N	53.68	\N	13.8	0	0	0	0	0	0	0	2
7784	1	2017-02-22 18:16:49	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
7785	1	2017-02-22 18:18:15	218.9	218.3	219.2	\N	\N	\N	53.74	\N	12.9	1	1	1	0	0	0	0	2
7787	1	2017-02-22 18:24:06	0.0	0.0	0.0	\N	\N	\N	53.61	\N	14.2	0	0	0	0	0	0	0	2
7788	1	2017-02-22 18:25:07	0.0	0.0	0.0	\N	\N	\N	53.74	\N	13.9	0	0	0	0	0	0	0	2
7789	1	2017-02-22 18:30:02	0.0	0.0	0.0	\N	\N	\N	53.78	\N	13.7	0	0	0	0	0	0	0	2
7793	1	2017-02-22 18:50:02	0.0	0.0	0.0	\N	\N	\N	53.43	\N	13.4	0	0	0	0	0	0	0	2
7794	1	2017-02-22 18:55:02	0.0	0.0	0.0	\N	\N	\N	53.46	\N	13.3	0	0	0	0	0	0	0	2
7795	1	2017-02-22 19:00:05	0.0	0.0	0.0	\N	\N	\N	53.41	\N	13.3	0	0	0	0	0	0	0	2
7796	1	2017-02-22 19:05:02	0.0	0.0	0.0	\N	\N	\N	53.28	\N	13.3	0	0	0	0	0	0	0	2
7797	1	2017-02-22 19:10:02	0.0	0.0	0.0	\N	\N	\N	53.25	\N	13.2	0	0	0	0	0	0	0	2
7798	1	2017-02-22 19:15:02	0.0	0.0	0.0	\N	\N	\N	53.29	\N	13.2	0	0	0	0	0	0	0	2
7799	1	2017-02-22 19:20:02	0.0	0.0	0.0	\N	\N	\N	53.28	\N	13.2	0	0	0	0	0	0	0	2
7800	1	2017-02-22 19:25:02	0.0	0.0	0.0	\N	\N	\N	53.19	\N	13.2	0	0	0	0	0	0	0	2
7801	1	2017-02-22 19:30:02	0.0	0.0	0.0	\N	\N	\N	53.06	\N	13.2	0	0	0	0	0	0	0	2
7802	1	2017-02-22 19:35:02	0.0	0.0	0.0	\N	\N	\N	53.10	\N	13.1	0	0	0	0	0	0	0	2
7803	1	2017-02-22 19:40:02	0.0	0.0	0.0	\N	\N	\N	53.06	\N	13.1	0	0	0	0	0	0	0	2
7804	1	2017-02-22 19:45:02	0.0	0.0	0.0	\N	\N	\N	53.05	\N	13.1	0	0	0	0	0	0	0	2
7805	1	2017-02-22 19:50:02	0.0	0.0	0.0	\N	\N	\N	52.90	\N	13.1	0	0	0	0	0	0	0	2
7806	1	2017-02-22 19:55:02	0.0	0.0	0.0	\N	\N	\N	52.79	\N	13.1	0	0	0	0	0	0	0	2
7807	1	2017-02-22 20:00:07	0.0	0.0	0.0	\N	\N	\N	52.98	\N	13.1	0	0	0	0	0	0	0	2
7808	1	2017-02-22 20:05:02	0.0	0.0	0.0	\N	\N	\N	52.85	\N	13.1	0	0	0	0	0	0	0	2
7809	1	2017-02-22 20:10:02	0.0	0.0	0.0	\N	\N	\N	52.76	\N	13.1	0	0	0	0	0	0	0	2
7810	1	2017-02-22 20:15:02	0.0	0.0	0.0	\N	\N	\N	52.71	\N	13.1	0	0	0	0	0	0	0	2
7811	1	2017-02-22 20:20:02	0.0	0.0	0.0	\N	\N	\N	52.70	\N	13.1	0	0	0	0	0	0	0	2
7812	1	2017-02-22 20:25:02	0.0	0.0	0.0	\N	\N	\N	52.60	\N	13.1	0	0	0	0	0	0	0	2
7813	1	2017-02-22 20:30:02	0.0	0.0	0.0	\N	\N	\N	52.52	\N	13.1	0	0	0	0	0	0	0	2
7814	1	2017-02-22 21:01:02	0.0	0.0	0.0	\N	\N	\N	51.93	\N	13.1	0	0	0	0	0	0	0	2
7815	1	2017-02-22 21:32:02	0.0	0.0	0.0	\N	\N	\N	51.85	\N	13.0	0	0	0	0	0	0	0	2
7816	1	2017-02-22 22:03:02	0.0	0.0	0.0	\N	\N	\N	51.71	\N	13.0	0	0	0	0	0	0	0	2
7817	1	2017-02-22 22:34:02	0.0	0.0	0.0	\N	\N	\N	51.43	\N	13.0	0	0	0	0	0	0	0	2
7818	1	2017-02-22 23:05:02	0.0	0.0	0.0	\N	\N	\N	51.33	\N	13.0	0	0	0	0	0	0	0	2
7819	1	2017-02-22 23:36:02	0.0	0.0	0.0	\N	\N	\N	51.13	\N	13.0	0	0	0	0	0	0	0	2
7820	1	2017-02-23 00:07:02	0.0	0.0	0.0	\N	\N	\N	51.16	\N	13.0	0	0	0	0	0	0	0	2
7821	1	2017-02-23 00:38:02	0.0	0.0	0.0	\N	\N	\N	50.96	\N	13.0	0	0	0	0	0	0	0	2
7822	1	2017-02-23 01:09:02	0.0	0.0	0.0	\N	\N	\N	50.95	\N	13.0	0	0	0	0	0	0	0	2
7823	1	2017-02-23 01:40:02	0.0	0.0	0.0	\N	\N	\N	50.76	\N	13.0	0	0	0	0	0	0	0	2
7824	1	2017-02-23 02:11:02	0.0	0.0	0.0	\N	\N	\N	50.73	\N	13.0	0	0	0	0	0	0	0	2
7825	1	2017-02-23 02:42:02	0.0	0.0	0.0	\N	\N	\N	50.62	\N	13.0	0	0	0	0	0	0	0	2
7826	1	2017-02-23 03:13:02	0.0	0.0	0.0	\N	\N	\N	50.55	\N	13.0	0	0	0	0	0	0	0	2
7836	1	2017-02-23 07:52:02	220.7	220.1	221.0	\N	\N	\N	52.76	\N	15.0	1	1	1	0	0	0	0	2
7837	1	2017-02-23 08:23:02	231.5	230.9	231.8	\N	\N	\N	54.42	\N	14.9	1	1	1	0	0	0	0	2
7838	1	2017-02-23 08:54:02	227.8	227.2	228.1	\N	\N	\N	55.97	\N	14.9	1	1	1	0	0	0	0	2
7839	1	2017-02-23 09:18:43	0.0	0.0	0.0	\N	\N	\N	55.24	\N	14.5	0	0	0	0	0	0	0	2
7840	1	2017-02-23 09:25:02	0.0	0.0	0.0	\N	\N	\N	55.15	\N	13.8	0	0	0	0	0	0	0	2
7841	1	2017-02-23 09:26:59	224.9	224.3	225.2	\N	\N	\N	55.08	\N	12.9	1	1	1	0	0	0	0	2
7842	1	2017-02-23 09:51:37	0.0	0.0	0.0	\N	\N	\N	55.42	\N	14.5	0	0	0	0	0	0	0	2
7843	1	2017-02-23 09:54:02	0.0	0.0	0.0	\N	\N	\N	55.28	\N	13.9	0	0	0	0	0	0	0	2
7844	1	2017-02-23 09:58:02	224.6	224.0	224.9	\N	\N	\N	55.22	\N	14.8	1	1	1	0	0	0	0	2
7845	1	2017-02-23 10:02:02	227.2	226.6	227.5	\N	\N	\N	55.83	\N	14.9	1	1	1	0	0	0	0	2
7846	1	2017-02-23 10:06:02	221.3	220.7	221.6	\N	\N	\N	55.56	\N	14.8	1	1	1	0	0	0	0	2
7847	1	2017-02-23 10:08:07	0.0	0.0	0.0	\N	\N	\N	55.34	\N	14.3	0	0	0	0	0	0	0	2
7848	1	2017-02-23 10:37:02	0.0	0.0	0.0	\N	\N	\N	55.14	\N	13.4	0	0	0	0	0	0	0	2
7849	1	2017-02-23 11:08:02	0.0	0.0	0.0	\N	\N	\N	54.82	\N	13.2	0	0	0	0	0	0	0	2
7850	1	2017-02-23 11:39:02	0.0	0.0	0.0	\N	\N	\N	54.51	\N	13.1	0	0	0	0	0	0	0	2
7851	1	2017-02-23 12:10:02	0.0	0.0	0.0	\N	\N	\N	54.39	\N	13.1	0	0	0	0	0	0	0	2
7852	2	2017-02-23 12:37:02	0.0	0.0	0.0	0.0	0.0	0.0	54.40	0.0	0.0	0	0	0	0	0	0	0	2
7853	1	2017-02-23 12:41:02	0.0	0.0	0.0	\N	\N	\N	54.11	\N	13.1	0	0	0	0	0	0	0	2
7854	2	2017-02-23 12:43:02	0.0	0.0	0.0	0.0	0.0	0.0	54.23	0.0	0.0	0	0	0	0	0	0	0	2
7855	1	2017-02-23 13:12:02	0.0	0.0	0.0	\N	\N	\N	53.83	\N	13.1	0	0	0	0	0	0	0	2
7856	1	2017-02-23 13:43:02	0.0	0.0	0.0	\N	\N	\N	53.36	\N	13.1	0	0	0	0	0	0	0	2
7857	1	2017-02-23 14:14:02	0.0	0.0	0.0	\N	\N	\N	53.23	\N	13.1	0	0	0	0	0	0	0	2
7858	2	2017-02-23 14:18:48	0.0	0.0	0.0	0.0	0.0	0.0	0.00	0.0	0.0	0	0	0	0	0	0	1	2
7859	2	2017-02-23 14:19:18	217.8	217.2	218.1	0.0	0.0	0.0	52.10	0.0	0.0	1	1	1	0	0	0	0	2
7860	2	2017-02-23 14:23:02	219.6	219.0	219.9	0.0	0.0	0.0	54.71	0.0	0.0	1	1	1	0	0	0	0	2
7861	2	2017-02-23 14:26:44	0.0	0.0	0.0	0.0	0.0	0.0	52.96	0.0	0.0	0	0	0	0	0	0	0	2
7862	2	2017-02-23 14:29:02	0.0	0.0	0.0	0.0	0.0	0.0	52.87	0.0	0.0	0	0	0	0	0	0	0	2
7863	2	2017-02-23 14:35:02	0.0	0.0	0.0	0.0	0.0	0.0	52.43	0.0	0.0	0	0	0	0	0	0	0	2
7864	2	2017-02-23 14:37:02	214.8	214.2	215.1	0.0	0.0	0.0	52.32	0.0	0.0	1	1	1	0	0	0	0	2
7865	2	2017-02-23 14:41:02	220.3	219.7	220.6	0.0	0.0	0.0	54.59	0.0	0.0	1	1	1	0	0	0	0	2
7866	2	2017-02-23 14:44:31	0.0	0.0	0.0	0.0	0.0	0.0	52.89	0.0	0.0	0	0	0	0	0	0	0	2
7867	1	2017-02-23 14:45:02	0.0	0.0	0.0	\N	\N	\N	52.98	\N	13.1	0	0	0	0	0	0	0	2
7868	2	2017-02-23 14:47:02	0.0	0.0	0.0	0.0	0.0	0.0	52.79	0.0	0.0	0	0	0	0	0	0	0	2
7869	1	2017-02-23 14:56:57	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
7870	1	2017-02-23 15:26:02	0.0	0.0	0.0	\N	\N	\N	52.61	\N	13.0	0	0	0	0	0	0	0	2
7871	1	2017-02-23 15:44:46	221.4	220.8	221.7	\N	\N	\N	52.24	\N	13.2	1	1	1	0	0	0	0	2
7883	1	2017-02-23 16:46:26	0.0	0.0	0.0	\N	\N	\N	53.39	\N	14.6	0	0	0	0	0	0	0	2
7884	2	2017-02-23 16:54:02	220.2	219.6	220.5	0.0	0.0	0.0	56.33	0.0	14.6	1	1	1	0	0	0	0	2
7885	2	2017-02-23 17:06:11	0.0	0.0	0.0	0.0	0.0	0.0	55.39	0.0	14.5	0	0	0	0	0	0	0	2
7786	1	2017-02-22 18:20:01	225.2	224.6	225.5	\N	\N	\N	53.76	\N	14.7	1	1	1	0	0	0	0	2
7790	1	2017-02-22 18:35:02	0.0	0.0	0.0	\N	\N	\N	53.61	\N	13.6	0	0	0	0	0	0	0	2
7791	1	2017-02-22 18:40:02	0.0	0.0	0.0	\N	\N	\N	53.74	\N	13.5	0	0	0	0	0	0	0	2
7792	1	2017-02-22 18:45:02	0.0	0.0	0.0	\N	\N	\N	53.55	\N	13.4	0	0	0	0	0	0	0	2
7827	1	2017-02-23 03:44:02	0.0	0.0	0.0	\N	\N	\N	50.32	\N	13.0	0	0	0	0	0	0	0	2
7828	1	2017-02-23 04:15:02	0.0	0.0	0.0	\N	\N	\N	50.39	\N	13.0	0	0	0	0	0	0	0	2
7829	1	2017-02-23 04:46:02	0.0	0.0	0.0	\N	\N	\N	50.18	\N	13.0	0	0	0	0	0	0	0	2
7830	1	2017-02-23 05:17:02	0.0	0.0	0.0	\N	\N	\N	50.12	\N	13.0	0	0	0	0	0	0	0	2
7831	1	2017-02-23 05:48:02	0.0	0.0	0.0	\N	\N	\N	50.10	\N	13.0	0	0	0	0	0	0	0	2
7832	1	2017-02-23 06:19:02	0.0	0.0	0.0	\N	\N	\N	49.98	\N	13.0	0	0	0	0	0	0	0	2
7833	1	2017-02-23 06:43:03	220.0	219.4	220.3	\N	\N	\N	49.87	\N	12.3	1	1	1	0	0	0	0	2
7834	1	2017-02-23 06:50:02	222.5	221.9	222.8	\N	\N	\N	51.49	\N	14.6	1	1	1	0	0	0	0	2
7835	1	2017-02-23 07:21:02	223.4	222.8	223.7	\N	\N	\N	52.43	\N	14.7	1	1	1	0	0	0	0	2
7872	1	2017-02-23 15:51:02	223.9	223.3	224.2	\N	\N	\N	54.06	\N	14.5	1	1	1	0	0	0	0	2
7873	1	2017-02-23 15:56:02	222.4	221.8	222.7	\N	\N	\N	52.69	\N	14.3	1	1	1	0	0	0	0	2
7874	1	2017-02-23 16:01:02	226.0	225.4	226.3	\N	\N	\N	52.48	\N	14.7	1	1	1	0	0	0	0	2
7875	1	2017-02-23 16:06:02	226.5	225.9	226.8	\N	\N	\N	52.32	\N	14.8	1	1	1	0	0	0	0	2
7876	1	2017-02-23 16:11:02	221.8	221.2	222.1	\N	\N	\N	52.29	\N	14.8	1	1	1	0	0	0	0	2
7877	1	2017-02-23 16:14:16	0.0	0.0	0.0	\N	\N	\N	52.33	\N	14.4	0	0	0	0	0	0	0	2
7878	1	2017-02-23 16:17:37	221.0	220.4	221.3	\N	\N	\N	52.36	\N	12.8	1	1	1	0	0	0	0	2
7879	1	2017-02-23 16:22:02	224.3	223.7	224.6	\N	\N	\N	54.11	\N	14.5	1	1	1	0	0	0	0	2
7880	1	2017-02-23 16:33:02	223.8	223.2	224.1	\N	\N	\N	53.10	\N	14.8	1	1	1	0	0	0	0	2
7881	1	2017-02-23 16:36:36	219.7	219.1	220.0	\N	\N	\N	53.10	\N	13.3	1	1	1	0	0	0	0	2
7882	1	2017-02-23 16:44:02	223.7	223.1	224.0	\N	\N	\N	54.59	\N	14.8	1	1	1	0	0	0	0	2
7918	1	2017-02-23 17:15:02	0.0	0.0	0.0	\N	\N	\N	53.14	\N	13.3	0	0	0	0	0	0	0	2
7919	2	2017-02-23 17:20:02	0.0	0.0	0.0	0.0	0.0	0.0	54.74	0.0	14.1	0	0	0	0	0	0	0	2
7920	2	2017-02-23 17:31:02	0.0	0.0	0.0	0.0	0.0	0.0	55.22	0.0	14.0	0	0	0	0	0	0	0	2
7921	1	2017-02-23 17:46:02	0.0	0.0	0.0	\N	\N	\N	52.89	\N	13.1	0	0	0	0	0	0	0	2
7954	2	2017-02-23 17:53:02	221.9	221.3	222.2	0.0	0.0	0.0	55.85	0.0	14.6	1	1	1	0	0	0	0	2
7955	2	2017-02-23 18:04:02	218.9	218.3	219.2	0.0	0.0	0.0	55.68	0.0	14.5	1	1	1	0	0	0	0	2
7956	2	2017-02-23 18:15:02	0.0	0.0	0.0	0.0	0.0	0.0	55.16	0.0	14.2	0	0	0	0	0	0	0	2
7957	1	2017-02-23 18:17:02	0.0	0.0	0.0	\N	\N	\N	52.55	\N	13.1	0	0	0	0	0	0	0	2
7958	2	2017-02-23 18:26:02	0.0	0.0	0.0	0.0	0.0	0.0	54.85	0.0	14.2	0	0	0	0	0	0	0	2
7959	2	2017-02-23 18:35:03	204.1	203.5	204.4	0.0	0.0	0.0	54.85	0.0	13.9	1	1	1	0	0	0	0	2
7960	2	2017-02-23 18:37:01	222.5	221.9	222.8	0.0	0.0	0.0	55.90	0.0	14.5	1	1	1	0	0	0	0	2
7961	2	2017-02-23 18:48:02	220.2	219.6	220.5	0.0	0.0	0.0	56.53	0.0	14.6	1	1	1	0	0	0	0	2
7962	1	2017-02-23 18:48:02	0.0	0.0	0.0	\N	\N	\N	52.16	\N	13.0	0	0	0	0	0	0	0	2
7963	2	2017-02-23 18:57:36	0.0	0.0	0.0	0.0	0.0	0.0	55.39	0.0	14.5	0	0	0	0	0	0	0	2
7964	2	2017-02-23 18:59:02	0.0	0.0	0.0	0.0	0.0	0.0	55.61	0.0	14.4	0	0	0	0	0	0	0	2
7965	2	2017-02-23 19:10:02	0.0	0.0	0.0	0.0	0.0	0.0	55.41	0.0	14.3	0	0	0	0	0	0	0	2
7966	1	2017-02-23 19:19:02	0.0	0.0	0.0	\N	\N	\N	51.90	\N	13.1	0	0	0	0	0	0	0	2
7967	2	2017-02-23 19:21:02	0.0	0.0	0.0	0.0	0.0	0.0	54.90	0.0	14.1	0	0	0	0	0	0	0	2
7968	1	2017-02-23 19:50:02	0.0	0.0	0.0	\N	\N	\N	51.63	\N	13.0	0	0	0	0	0	0	0	2
7969	2	2017-02-23 19:52:02	0.0	0.0	0.0	0.0	0.0	0.0	54.47	0.0	13.9	0	0	0	0	0	0	0	2
7970	2	2017-02-23 19:53:57	199.2	198.6	199.5	0.0	0.0	0.0	54.30	0.0	13.9	1	1	1	0	0	0	0	2
7971	1	2017-02-23 20:21:02	0.0	0.0	0.0	\N	\N	\N	51.39	\N	13.0	0	0	0	0	0	0	0	2
7972	2	2017-02-23 20:23:01	222.3	221.7	222.6	0.0	0.0	0.0	56.07	0.0	14.7	1	1	1	0	0	0	0	2
7973	1	2017-02-23 20:24:50	222.5	221.9	222.8	\N	\N	\N	51.42	\N	13.4	1	1	1	0	0	0	0	2
7974	1	2017-02-23 20:52:02	223.6	223.0	223.9	\N	\N	\N	53.85	\N	14.8	1	1	1	0	0	0	0	2
7975	2	2017-02-23 20:54:02	221.2	220.6	221.5	0.0	0.0	0.0	55.90	0.0	14.6	1	1	1	0	0	0	0	2
7976	1	2017-02-23 21:23:02	223.5	222.9	223.8	\N	\N	\N	55.51	\N	15.0	1	1	1	0	0	0	0	2
7977	2	2017-02-23 21:25:02	219.9	219.3	220.2	0.0	0.0	0.0	56.56	0.0	14.6	1	1	1	0	0	0	0	2
7978	1	2017-02-23 21:54:02	223.4	222.8	223.7	\N	\N	\N	55.89	\N	14.9	1	1	1	0	0	0	0	2
7979	2	2017-02-23 21:56:02	221.0	220.4	221.3	0.0	0.0	0.0	55.61	0.0	14.7	1	1	1	0	0	0	0	2
7980	1	2017-02-23 22:25:02	228.7	228.1	229.0	\N	\N	\N	55.70	\N	14.9	1	1	1	0	0	0	0	2
7981	2	2017-02-23 22:27:02	221.1	220.5	221.4	0.0	0.0	0.0	55.71	0.0	14.8	1	1	1	0	0	0	0	2
7982	2	2017-02-23 22:31:42	0.0	0.0	0.0	0.0	0.0	0.0	55.72	0.0	14.5	0	0	0	0	0	0	0	2
7983	1	2017-02-23 22:42:29	0.0	0.0	0.0	\N	\N	\N	55.61	\N	14.7	0	0	0	0	0	0	0	2
7984	1	2017-02-23 22:42:29	0.0	0.0	0.0	\N	\N	\N	55.61	\N	14.7	0	0	0	0	0	0	0	2
7985	1	2017-02-23 22:56:02	0.0	0.0	0.0	\N	\N	\N	55.35	\N	13.7	0	0	0	0	0	0	0	2
7986	2	2017-02-23 22:58:02	0.0	0.0	0.0	0.0	0.0	0.0	54.95	0.0	14.1	0	0	0	0	0	0	0	2
7987	1	2017-02-23 23:27:02	0.0	0.0	0.0	\N	\N	\N	55.24	\N	13.3	0	0	0	0	0	0	0	2
7988	2	2017-02-23 23:29:02	0.0	0.0	0.0	0.0	0.0	0.0	55.13	0.0	14.1	0	0	0	0	0	0	0	2
7989	1	2017-02-23 23:58:02	0.0	0.0	0.0	\N	\N	\N	54.90	\N	13.2	0	0	0	0	0	0	0	2
7990	2	2017-02-24 00:00:07	0.0	0.0	0.0	0.0	0.0	0.0	54.29	0.0	13.8	0	0	0	0	0	0	0	2
7991	1	2017-02-24 00:29:02	0.0	0.0	0.0	\N	\N	\N	54.59	\N	13.1	0	0	0	0	0	0	0	2
7992	2	2017-02-24 00:31:02	0.0	0.0	0.0	0.0	0.0	0.0	53.09	0.0	13.7	0	0	0	0	0	0	0	2
7993	1	2017-02-24 01:00:07	0.0	0.0	0.0	\N	\N	\N	54.40	\N	13.1	0	0	0	0	0	0	0	2
7994	2	2017-02-24 01:02:02	0.0	0.0	0.0	0.0	0.0	0.0	53.06	0.0	13.6	0	0	0	0	0	0	0	2
7995	1	2017-02-24 01:31:02	0.0	0.0	0.0	\N	\N	\N	54.20	\N	13.1	0	0	0	0	0	0	0	2
7996	2	2017-02-24 01:33:02	0.0	0.0	0.0	0.0	0.0	0.0	52.75	0.0	13.5	0	0	0	0	0	0	0	2
7997	1	2017-02-24 02:02:02	0.0	0.0	0.0	\N	\N	\N	54.01	\N	13.0	0	0	0	0	0	0	0	2
7998	2	2017-02-24 02:04:02	0.0	0.0	0.0	0.0	0.0	0.0	51.68	0.0	13.4	0	0	0	0	0	0	0	2
7999	1	2017-02-24 02:33:02	0.0	0.0	0.0	\N	\N	\N	53.74	\N	13.0	0	0	0	0	0	0	0	2
8000	2	2017-02-24 02:35:02	0.0	0.0	0.0	0.0	0.0	0.0	51.54	0.0	13.4	0	0	0	0	0	0	0	2
8001	1	2017-02-24 03:04:02	0.0	0.0	0.0	\N	\N	\N	53.52	\N	13.0	0	0	0	0	0	0	0	2
8002	2	2017-02-24 03:06:02	0.0	0.0	0.0	0.0	0.0	0.0	51.71	0.0	13.3	0	0	0	0	0	0	0	2
8003	1	2017-02-24 03:35:02	0.0	0.0	0.0	\N	\N	\N	53.38	\N	13.0	0	0	0	0	0	0	0	2
8018	2	2017-02-24 07:14:02	0.0	0.0	0.0	0.0	0.0	0.0	49.44	0.0	15.3	0	0	0	0	0	0	0	2
8019	1	2017-02-24 07:43:02	0.0	0.0	0.0	\N	\N	\N	51.28	\N	13.0	0	0	0	0	0	0	0	2
8067	1	2017-02-24 12:04:02	219.3	218.7	219.6	\N	\N	\N	55.39	\N	14.9	1	1	1	0	0	0	0	2
8068	1	2017-02-24 12:04:02	219.3	218.7	219.6	\N	\N	\N	55.39	\N	14.9	1	1	1	0	0	0	0	2
8069	1	2017-02-24 12:05:27	0.0	0.0	0.0	\N	\N	\N	53.91	\N	14.4	0	0	0	0	0	0	0	2
8070	1	2017-02-24 12:09:02	0.0	0.0	0.0	\N	\N	\N	53.95	\N	13.8	0	0	0	0	0	0	0	2
8083	1	2017-02-24 12:49:02	0.0	0.0	0.0	\N	\N	\N	53.84	\N	13.7	0	0	0	0	0	0	0	2
8084	1	2017-02-24 12:51:05	206.8	206.2	207.1	\N	\N	\N	54.00	\N	12.9	1	1	1	0	0	0	0	2
8085	1	2017-02-24 12:54:02	219.8	219.2	220.1	\N	\N	\N	53.90	\N	14.8	1	1	1	0	0	0	0	2
8114	1	2017-02-24 15:02:18	0.0	0.0	0.0	\N	\N	\N	53.12	\N	13.8	0	0	0	0	0	0	0	2
8115	1	2017-02-24 15:04:57	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
8116	1	2017-02-24 15:07:15	177.1	176.5	177.4	\N	\N	\N	53.11	\N	12.6	1	1	1	0	0	0	0	2
8117	1	2017-02-24 15:10:09	0.0	0.0	0.0	\N	\N	\N	53.25	\N	14.1	0	0	0	0	0	0	0	2
8118	1	2017-02-24 15:13:55	210.6	210.0	210.9	\N	\N	\N	52.81	\N	12.8	1	1	1	0	0	0	0	2
8119	1	2017-02-24 15:21:25	0.0	0.0	0.0	\N	\N	\N	53.23	\N	14.5	0	0	0	0	0	0	0	2
8120	1	2017-02-24 15:26:38	207.5	206.9	207.8	\N	\N	\N	53.00	\N	12.8	1	1	1	0	0	0	0	2
8121	2	2017-02-24 15:30:02	0.0	0.0	0.0	0.0	0.0	0.0	49.79	0.0	12.8	0	0	0	0	0	0	0	2
8122	1	2017-02-24 15:34:02	221.4	220.8	221.7	\N	\N	\N	53.53	\N	14.8	1	1	1	0	0	0	0	2
8123	2	2017-02-24 16:01:02	0.0	0.0	0.0	0.0	0.0	0.0	49.37	0.0	12.9	0	0	0	0	0	0	0	2
8124	2	2017-02-24 16:32:02	0.0	0.0	0.0	0.0	0.0	0.0	49.26	0.0	12.7	0	0	0	0	0	0	0	2
8125	2	2017-02-24 17:03:02	0.0	0.0	0.0	0.0	0.0	0.0	48.78	0.0	12.7	0	0	0	0	0	0	0	2
8126	2	2017-02-24 17:34:02	0.0	0.0	0.0	0.0	0.0	0.0	48.78	0.0	12.5	0	0	0	0	0	0	0	2
8127	1	2017-02-24 17:39:41	0.0	0.0	0.0	\N	\N	\N	55.26	\N	14.1	0	0	0	0	0	0	0	2
8128	2	2017-02-24 18:05:02	0.0	0.0	0.0	0.0	0.0	0.0	48.50	0.0	12.6	0	0	0	0	0	0	0	2
8129	1	2017-02-24 18:10:02	0.0	0.0	0.0	\N	\N	\N	54.89	\N	13.4	0	0	0	0	0	0	0	2
8130	2	2017-02-24 18:36:02	0.0	0.0	0.0	0.0	0.0	0.0	47.79	0.0	12.5	0	0	0	0	0	0	0	2
8131	1	2017-02-24 18:41:02	0.0	0.0	0.0	\N	\N	\N	54.70	\N	13.2	0	0	0	0	0	0	0	2
8132	2	2017-02-24 18:57:02	198.4	197.8	198.7	0.0	0.0	0.0	47.22	0.0	12.2	1	1	1	0	0	0	0	2
8133	2	2017-02-24 19:07:02	222.6	222.0	222.9	0.0	0.0	0.0	50.32	0.0	13.3	1	1	1	0	0	0	0	2
8134	1	2017-02-24 19:12:02	0.0	0.0	0.0	\N	\N	\N	54.43	\N	13.1	0	0	0	0	0	0	0	2
8135	2	2017-02-24 19:38:01	220.3	219.7	220.6	0.0	0.0	0.0	51.37	0.0	13.6	1	1	1	0	0	0	0	2
8136	1	2017-02-24 19:43:02	0.0	0.0	0.0	\N	\N	\N	54.30	\N	13.1	0	0	0	0	0	0	0	2
8137	2	2017-02-24 20:09:02	217.9	217.3	218.2	0.0	0.0	0.0	52.47	0.0	13.8	1	1	1	0	0	0	0	2
8138	1	2017-02-24 20:14:02	0.0	0.0	0.0	\N	\N	\N	53.94	\N	13.1	0	0	0	0	0	0	0	2
8139	2	2017-02-24 20:40:02	217.0	216.4	217.3	0.0	0.0	0.0	53.91	0.0	14.2	1	1	1	0	0	0	0	2
8140	1	2017-02-24 20:45:02	0.0	0.0	0.0	\N	\N	\N	53.70	\N	13.1	0	0	0	0	0	0	0	2
8141	2	2017-02-24 21:11:02	220.4	219.8	220.7	0.0	0.0	0.0	55.59	0.0	14.4	1	1	1	0	0	0	0	2
8142	1	2017-02-24 21:16:02	0.0	0.0	0.0	\N	\N	\N	53.40	\N	13.0	0	0	0	0	0	0	0	2
8143	2	2017-02-24 21:42:02	220.8	220.2	221.1	0.0	0.0	0.0	55.00	0.0	14.4	1	1	1	0	0	0	0	2
8144	1	2017-02-24 21:47:02	0.0	0.0	0.0	\N	\N	\N	53.20	\N	13.1	0	0	0	0	0	0	0	2
8145	2	2017-02-24 22:13:02	222.5	221.9	222.8	0.0	0.0	0.0	55.39	0.0	14.4	1	1	1	0	0	0	0	2
8146	1	2017-02-24 22:18:02	0.0	0.0	0.0	\N	\N	\N	52.94	\N	13.0	0	0	0	0	0	0	0	2
8147	2	2017-02-24 22:29:49	0.0	0.0	0.0	0.0	0.0	0.0	54.53	0.0	14.2	0	0	0	0	0	0	0	2
8148	2	2017-02-24 22:44:02	0.0	0.0	0.0	0.0	0.0	0.0	54.15	0.0	13.9	0	0	0	0	0	0	0	2
8149	1	2017-02-24 22:49:02	0.0	0.0	0.0	\N	\N	\N	52.68	\N	13.0	0	0	0	0	0	0	0	2
8150	2	2017-02-24 23:15:02	0.0	0.0	0.0	0.0	0.0	0.0	53.47	0.0	13.7	0	0	0	0	0	0	0	2
8151	1	2017-02-24 23:20:02	0.0	0.0	0.0	\N	\N	\N	52.38	\N	13.0	0	0	0	0	0	0	0	2
8155	2	2017-02-25 00:17:02	0.0	0.0	0.0	0.0	0.0	0.0	52.64	0.0	13.4	0	0	0	0	0	0	0	2
8156	2	2017-02-25 00:17:02	0.0	0.0	0.0	\N	\N	\N	52.64	\N	13.4	0	0	0	0	0	0	0	2
8157	1	2017-02-25 00:22:02	0.0	0.0	0.0	\N	\N	\N	51.71	\N	13.0	0	0	0	0	0	0	0	2
8158	2	2017-02-25 00:48:02	0.0	0.0	0.0	0.0	0.0	0.0	51.99	0.0	13.2	0	0	0	0	0	0	0	2
8159	2	2017-02-25 00:48:02	0.0	0.0	0.0	\N	\N	\N	51.99	\N	13.2	0	0	0	0	0	0	0	2
8172	1	2017-02-25 03:28:02	0.0	0.0	0.0	\N	\N	\N	50.84	\N	13.0	0	0	0	0	0	0	0	2
8173	1	2017-02-25 03:40:07	209.7	209.1	210.0	\N	\N	\N	50.79	\N	12.3	1	1	1	0	0	0	0	2
8174	2	2017-02-25 03:54:02	0.0	0.0	0.0	0.0	0.0	0.0	50.14	0.0	12.9	0	0	0	0	0	0	0	2
8175	1	2017-02-25 03:59:02	221.6	221.0	221.9	\N	\N	\N	53.02	\N	14.9	1	1	1	0	0	0	0	2
8176	2	2017-02-25 04:25:02	0.0	0.0	0.0	0.0	0.0	0.0	49.46	0.0	12.8	0	0	0	0	0	0	0	2
8177	1	2017-02-25 04:30:02	221.0	220.4	221.3	\N	\N	\N	54.47	\N	15.0	1	1	1	0	0	0	0	2
8178	2	2017-02-25 04:56:02	0.0	0.0	0.0	0.0	0.0	0.0	49.65	0.0	12.7	0	0	0	0	0	0	0	2
8179	1	2017-02-25 05:01:02	222.0	221.4	222.3	\N	\N	\N	55.52	\N	15.0	1	1	1	0	0	0	0	2
8180	2	2017-02-25 05:27:02	0.0	0.0	0.0	0.0	0.0	0.0	48.86	0.0	12.7	0	0	0	0	0	0	0	2
8181	1	2017-02-25 05:32:02	219.9	219.3	220.2	\N	\N	\N	55.66	\N	15.0	1	1	1	0	0	0	0	2
8182	1	2017-02-25 05:42:47	0.0	0.0	0.0	\N	\N	\N	55.27	\N	14.3	0	0	0	0	0	0	0	2
8183	2	2017-02-25 05:58:02	0.0	0.0	0.0	0.0	0.0	0.0	48.78	0.0	12.6	0	0	0	0	0	0	0	2
8184	1	2017-02-25 06:03:02	0.0	0.0	0.0	\N	\N	\N	55.17	\N	13.6	0	0	0	0	0	0	0	2
8185	2	2017-02-25 06:29:02	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	12.7	0	0	0	0	0	0	0	2
8186	1	2017-02-25 06:34:02	0.0	0.0	0.0	\N	\N	\N	54.72	\N	13.3	0	0	0	0	0	0	0	2
8187	2	2017-02-25 07:00:07	0.0	0.0	0.0	0.0	0.0	0.0	48.18	0.0	12.5	0	0	0	0	0	0	0	2
8188	1	2017-02-25 07:05:02	0.0	0.0	0.0	\N	\N	\N	54.42	\N	13.1	0	0	0	0	0	0	0	2
8189	2	2017-02-25 07:30:47	211.9	211.3	212.2	0.0	0.0	0.0	47.64	0.0	12.2	1	1	1	0	0	0	0	2
8190	2	2017-02-25 07:31:47	219.1	218.5	219.4	0.0	0.0	0.0	47.39	0.0	12.7	1	1	1	0	0	0	0	2
8191	1	2017-02-25 07:36:02	0.0	0.0	0.0	\N	\N	\N	54.19	\N	13.1	0	0	0	0	0	0	0	2
8192	2	2017-02-25 08:02:02	224.4	223.8	224.7	0.0	0.0	0.0	51.56	0.0	13.6	1	1	1	0	0	0	0	2
8004	2	2017-02-24 03:37:02	0.0	0.0	0.0	0.0	0.0	0.0	50.74	0.0	13.1	0	0	0	0	0	0	0	2
8005	1	2017-02-24 04:06:02	0.0	0.0	0.0	\N	\N	\N	53.15	\N	13.0	0	0	0	0	0	0	0	2
8006	2	2017-02-24 04:08:02	0.0	0.0	0.0	0.0	0.0	0.0	50.61	0.0	13.2	0	0	0	0	0	0	0	2
8007	1	2017-02-24 04:37:02	0.0	0.0	0.0	\N	\N	\N	52.93	\N	13.0	0	0	0	0	0	0	0	2
8008	2	2017-02-24 04:39:02	0.0	0.0	0.0	0.0	0.0	0.0	50.32	0.0	13.2	0	0	0	0	0	0	0	2
8009	1	2017-02-24 05:08:02	0.0	0.0	0.0	\N	\N	\N	52.54	\N	12.9	0	0	0	0	0	0	0	2
8010	2	2017-02-24 05:10:02	0.0	0.0	0.0	0.0	0.0	0.0	50.81	0.0	13.1	0	0	0	0	0	0	0	2
8011	1	2017-02-24 05:39:02	0.0	0.0	0.0	\N	\N	\N	52.16	\N	13.0	0	0	0	0	0	0	0	2
8012	2	2017-02-24 05:41:02	0.0	0.0	0.0	0.0	0.0	0.0	50.49	0.0	13.1	0	0	0	0	0	0	0	2
8013	1	2017-02-24 06:10:02	0.0	0.0	0.0	\N	\N	\N	51.89	\N	13.0	0	0	0	0	0	0	0	2
8014	2	2017-02-24 06:12:02	0.0	0.0	0.0	0.0	0.0	0.0	50.10	0.0	13.2	0	0	0	0	0	0	0	2
8015	1	2017-02-24 06:41:02	0.0	0.0	0.0	\N	\N	\N	51.63	\N	13.0	0	0	0	0	0	0	0	2
8016	2	2017-02-24 06:43:02	0.0	0.0	0.0	0.0	0.0	0.0	50.12	0.0	13.0	0	0	0	0	0	0	0	2
8017	1	2017-02-24 07:12:02	0.0	0.0	0.0	\N	\N	\N	51.45	\N	13.0	0	0	0	0	0	0	0	2
8020	2	2017-02-24 07:45:02	0.0	0.0	0.0	0.0	0.0	0.0	49.02	0.0	15.4	0	0	0	0	0	0	0	2
8021	2	2017-02-24 08:02:42	217.8	217.2	218.1	0.0	0.0	0.0	48.78	0.0	15.5	1	1	1	0	0	0	0	2
8022	1	2017-02-24 08:14:02	0.0	0.0	0.0	\N	\N	\N	51.14	\N	13.0	0	0	0	0	0	0	0	2
8023	2	2017-02-24 08:16:02	220.8	220.2	221.1	0.0	0.0	0.0	50.49	0.0	16.1	1	1	1	0	0	0	0	2
8024	1	2017-02-24 08:45:02	0.0	0.0	0.0	\N	\N	\N	51.04	\N	13.0	0	0	0	0	0	0	0	2
8025	2	2017-02-24 08:47:02	222.4	221.8	222.7	0.0	0.0	0.0	51.85	0.0	16.2	1	1	1	0	0	0	0	2
8026	1	2017-02-24 09:14:46	217.8	217.2	218.1	\N	\N	\N	50.92	\N	12.0	1	1	1	0	0	0	0	2
8027	1	2017-02-24 09:16:02	222.6	222.0	222.9	\N	\N	\N	50.76	\N	14.4	1	1	1	0	0	0	0	2
8028	2	2017-02-24 09:18:02	221.9	221.3	222.2	0.0	0.0	0.0	52.74	0.0	13.8	1	1	1	0	0	0	0	2
8029	1	2017-02-24 09:47:02	224.2	223.6	224.5	\N	\N	\N	53.65	\N	14.9	1	1	1	0	0	0	0	2
8030	2	2017-02-24 09:49:02	222.8	222.2	223.1	0.0	0.0	0.0	54.78	0.0	14.2	1	1	1	0	0	0	0	2
8031	1	2017-02-24 10:15:58	0.0	0.0	0.0	\N	\N	\N	53.83	\N	14.4	0	0	0	0	0	0	0	2
8032	1	2017-02-24 10:19:48	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
8033	2	2017-02-24 10:20:02	222.1	221.5	222.4	0.0	0.0	0.0	55.26	0.0	14.2	1	1	1	0	0	0	0	2
8034	1	2017-02-24 10:26:05	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
8035	1	2017-02-24 10:29:44	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
8036	1	2017-02-24 10:32:17	223.3	222.7	223.6	\N	\N	\N	53.61	\N	13.1	1	1	1	0	0	0	0	2
8037	1	2017-02-24 10:34:02	224.6	224.0	224.9	\N	\N	\N	53.74	\N	14.8	1	1	1	0	0	0	0	2
8038	2	2017-02-24 10:35:18	0.0	0.0	0.0	0.0	0.0	0.0	54.80	0.0	14.2	0	0	0	0	0	0	0	2
8039	1	2017-02-24 10:39:46	0.0	0.0	0.0	\N	\N	\N	53.92	\N	14.6	0	0	0	0	0	0	0	2
8040	1	2017-02-24 10:41:01	0.0	0.0	0.0	\N	\N	\N	53.94	\N	14.0	0	0	0	0	0	0	0	2
8041	1	2017-02-24 10:42:36	220.0	219.4	220.3	\N	\N	\N	53.88	\N	13.9	1	1	1	0	0	0	0	2
8042	1	2017-02-24 10:46:28	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
8043	1	2017-02-24 10:49:14	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
8044	1	2017-02-24 10:50:53	0.0	0.0	0.0	\N	\N	\N	53.43	\N	13.4	0	0	0	0	0	0	0	2
8045	2	2017-02-24 10:51:02	0.0	0.0	0.0	0.0	0.0	0.0	54.09	0.0	13.9	0	0	0	0	0	0	0	2
8046	2	2017-02-24 10:51:02	0.0	0.0	0.0	\N	\N	\N	54.09	\N	13.9	0	0	0	0	0	0	0	2
8047	1	2017-02-24 11:04:05	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
8048	1	2017-02-24 11:04:43	217.4	216.8	217.7	\N	\N	\N	53.68	\N	13.6	1	1	1	0	0	0	0	2
8049	1	2017-02-24 11:09:02	217.2	216.6	217.5	\N	\N	\N	55.22	\N	14.9	1	1	1	0	0	0	0	2
8050	1	2017-02-24 11:12:13	0.0	0.0	0.0	\N	\N	\N	53.80	\N	14.5	0	0	0	0	0	0	0	2
8051	1	2017-02-24 11:14:02	0.0	0.0	0.0	\N	\N	\N	53.71	\N	14.0	0	0	0	0	0	0	0	2
8052	1	2017-02-24 11:19:02	0.0	0.0	0.0	\N	\N	\N	53.83	\N	13.7	0	0	0	0	0	0	0	2
8053	2	2017-02-24 11:22:02	0.0	0.0	0.0	0.0	0.0	0.0	53.53	0.0	13.7	0	0	0	0	0	0	0	2
8054	1	2017-02-24 11:22:26	220.4	219.8	220.7	\N	\N	\N	53.65	\N	13.1	1	1	1	0	0	0	0	2
8055	1	2017-02-24 11:24:02	219.0	218.4	219.3	\N	\N	\N	53.61	\N	14.8	1	1	1	0	0	0	0	2
8056	1	2017-02-24 11:29:02	219.9	219.3	220.2	\N	\N	\N	53.92	\N	14.9	1	1	1	0	0	0	0	2
8057	1	2017-02-24 11:34:02	0.0	0.0	0.0	\N	\N	\N	53.66	\N	13.8	0	0	0	0	0	0	0	2
8058	1	2017-02-24 11:39:02	0.0	0.0	0.0	\N	\N	\N	53.69	\N	13.7	0	0	0	0	0	0	0	2
8059	1	2017-02-24 11:40:09	208.0	207.4	208.3	\N	\N	\N	53.72	\N	12.8	1	1	1	0	0	0	0	2
8060	1	2017-02-24 11:44:02	221.7	221.1	222.0	\N	\N	\N	55.08	\N	14.9	1	1	1	0	0	0	0	2
8061	1	2017-02-24 11:47:40	0.0	0.0	0.0	\N	\N	\N	53.89	\N	14.3	0	0	0	0	0	0	0	2
8062	1	2017-02-24 11:49:02	0.0	0.0	0.0	\N	\N	\N	53.97	\N	14.0	0	0	0	0	0	0	0	2
8063	2	2017-02-24 11:53:02	0.0	0.0	0.0	0.0	0.0	0.0	53.16	0.0	13.9	0	0	0	0	0	0	0	2
8064	1	2017-02-24 11:54:02	0.0	0.0	0.0	\N	\N	\N	53.79	\N	13.8	0	0	0	0	0	0	0	2
8065	1	2017-02-24 11:57:53	217.6	217.0	217.9	\N	\N	\N	53.67	\N	13.6	1	1	1	0	0	0	0	2
8066	1	2017-02-24 11:59:02	220.6	220.0	220.9	\N	\N	\N	53.85	\N	14.8	1	1	1	0	0	0	0	2
8071	1	2017-02-24 12:14:02	0.0	0.0	0.0	\N	\N	\N	53.81	\N	13.7	0	0	0	0	0	0	0	2
8072	1	2017-02-24 12:15:39	207.0	206.4	207.3	\N	\N	\N	53.79	\N	12.9	1	1	1	0	0	0	0	2
8073	1	2017-02-24 12:19:02	217.4	216.8	217.7	\N	\N	\N	53.82	\N	14.8	1	1	1	0	0	0	0	2
8074	1	2017-02-24 12:23:11	0.0	0.0	0.0	\N	\N	\N	54.01	\N	14.4	0	0	0	0	0	0	0	2
8075	2	2017-02-24 12:24:02	0.0	0.0	0.0	0.0	0.0	0.0	52.64	0.0	13.3	0	0	0	0	0	0	0	2
8076	1	2017-02-24 12:24:11	0.0	0.0	0.0	\N	\N	\N	53.98	\N	14.0	0	0	0	0	0	0	0	2
8077	1	2017-02-24 12:29:02	0.0	0.0	0.0	\N	\N	\N	53.93	\N	13.8	0	0	0	0	0	0	0	2
8078	1	2017-02-24 12:33:20	221.2	220.6	221.5	\N	\N	\N	54.02	\N	13.0	1	1	1	0	0	0	0	2
8079	1	2017-02-24 12:34:19	215.9	215.3	216.2	\N	\N	\N	53.85	\N	14.7	1	1	1	0	0	0	0	2
8080	1	2017-02-24 12:39:02	212.5	211.9	212.8	\N	\N	\N	55.72	\N	14.9	1	1	1	0	0	0	0	2
8081	1	2017-02-24 12:40:56	0.0	0.0	0.0	\N	\N	\N	54.05	\N	14.1	0	0	0	0	0	0	0	2
8082	1	2017-02-24 12:44:02	0.0	0.0	0.0	\N	\N	\N	54.09	\N	13.8	0	0	0	0	0	0	0	2
8086	2	2017-02-24 12:55:02	0.0	0.0	0.0	0.0	0.0	0.0	52.01	0.0	13.3	0	0	0	0	0	0	0	2
8087	1	2017-02-24 12:58:36	0.0	0.0	0.0	\N	\N	\N	54.06	\N	14.3	0	0	0	0	0	0	0	2
8088	1	2017-02-24 12:59:36	0.0	0.0	0.0	\N	\N	\N	54.17	\N	14.0	0	0	0	0	0	0	0	2
8089	1	2017-02-24 13:04:02	0.0	0.0	0.0	\N	\N	\N	54.01	\N	13.8	0	0	0	0	0	0	0	2
8090	1	2017-02-24 13:06:07	0.0	0.0	0.0	\N	\N	\N	53.97	\N	13.7	0	0	0	0	0	0	0	2
8091	1	2017-02-24 13:07:15	0.0	0.0	0.0	\N	\N	\N	54.08	\N	13.7	0	0	0	0	0	0	0	2
8092	2	2017-02-24 13:26:02	0.0	0.0	0.0	0.0	0.0	0.0	51.04	0.0	13.1	0	0	0	0	0	0	0	2
8093	1	2017-02-24 13:35:02	0.0	0.0	0.0	\N	\N	\N	53.72	\N	13.3	0	0	0	0	0	0	0	2
8094	1	2017-02-24 13:41:36	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
8095	1	2017-02-24 13:46:17	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
8096	1	2017-02-24 13:50:25	217.0	216.4	217.3	\N	\N	\N	53.53	\N	13.0	1	1	1	0	0	0	0	2
8097	1	2017-02-24 13:51:32	218.4	217.8	218.7	\N	\N	\N	53.46	\N	14.4	1	1	1	0	0	0	0	2
8098	1	2017-02-24 13:55:02	220.9	220.3	221.2	\N	\N	\N	54.74	\N	14.7	1	1	1	0	0	0	0	2
8099	2	2017-02-24 13:57:02	0.0	0.0	0.0	0.0	0.0	0.0	50.57	0.0	13.1	0	0	0	0	0	0	0	2
8100	1	2017-02-24 13:59:02	218.1	217.5	218.4	\N	\N	\N	53.79	\N	14.9	1	1	1	0	0	0	0	2
8101	1	2017-02-24 14:17:51	0.0	0.0	0.0	\N	\N	\N	0.00	\N	0.0	0	0	0	0	0	0	1	2
8102	1	2017-02-24 14:20:59	195.3	194.7	195.6	\N	\N	\N	53.53	\N	12.5	1	1	1	0	0	0	0	2
8103	1	2017-02-24 14:25:48	0.0	0.0	0.0	\N	\N	\N	53.47	\N	13.7	0	0	0	0	0	0	0	2
8104	2	2017-02-24 14:28:02	0.0	0.0	0.0	0.0	0.0	0.0	50.17	0.0	12.8	0	0	0	0	0	0	0	2
8105	1	2017-02-24 14:28:02	217.4	216.8	217.7	\N	\N	\N	53.46	\N	12.8	1	1	1	0	0	0	0	2
8106	1	2017-02-24 14:35:04	0.0	0.0	0.0	\N	\N	\N	53.22	\N	13.8	0	0	0	0	0	0	0	2
8107	1	2017-02-24 14:36:59	210.7	210.1	211.0	\N	\N	\N	53.21	\N	12.5	1	1	1	0	0	0	0	2
8108	1	2017-02-24 14:45:25	0.0	0.0	0.0	\N	\N	\N	53.29	\N	13.7	0	0	0	0	0	0	0	2
8109	1	2017-02-24 14:47:02	0.0	0.0	0.0	\N	\N	\N	53.23	\N	13.3	0	0	0	0	0	0	0	2
8110	1	2017-02-24 14:49:52	216.8	216.2	217.1	\N	\N	\N	53.30	\N	12.8	1	1	1	0	0	0	0	2
8111	1	2017-02-24 14:55:15	0.0	0.0	0.0	\N	\N	\N	53.06	\N	14.2	0	0	0	0	0	0	0	2
8112	1	2017-02-24 14:56:17	214.7	214.1	215.0	\N	\N	\N	53.19	\N	12.7	1	1	1	0	0	0	0	2
8113	2	2017-02-24 14:59:02	0.0	0.0	0.0	0.0	0.0	0.0	50.02	0.0	12.8	0	0	0	0	0	0	0	2
8152	2	2017-02-24 23:46:02	0.0	0.0	0.0	0.0	0.0	0.0	53.00	0.0	13.6	0	0	0	0	0	0	0	2
8153	2	2017-02-24 23:46:02	0.0	0.0	0.0	\N	\N	\N	53.00	\N	13.6	0	0	0	0	0	0	0	2
8154	1	2017-02-24 23:51:02	0.0	0.0	0.0	\N	\N	\N	52.03	\N	13.0	0	0	0	0	0	0	0	2
8160	1	2017-02-25 00:53:02	0.0	0.0	0.0	\N	\N	\N	51.50	\N	13.0	0	0	0	0	0	0	0	2
8161	2	2017-02-25 01:19:02	0.0	0.0	0.0	0.0	0.0	0.0	51.16	0.0	13.2	0	0	0	0	0	0	0	2
8162	2	2017-02-25 01:19:02	0.0	0.0	0.0	\N	\N	\N	51.16	\N	13.2	0	0	0	0	0	0	0	2
8163	1	2017-02-25 01:24:02	0.0	0.0	0.0	\N	\N	\N	51.42	\N	13.0	0	0	0	0	0	0	0	2
8164	2	2017-02-25 01:50:02	0.0	0.0	0.0	0.0	0.0	0.0	50.90	0.0	13.1	0	0	0	0	0	0	0	2
8165	1	2017-02-25 01:55:02	0.0	0.0	0.0	\N	\N	\N	51.01	\N	13.0	0	0	0	0	0	0	0	2
8166	1	2017-02-25 01:55:02	0.0	0.0	0.0	\N	\N	\N	51.01	\N	13.0	0	0	0	0	0	0	0	2
8167	2	2017-02-25 02:21:02	0.0	0.0	0.0	0.0	0.0	0.0	50.21	0.0	13.1	0	0	0	0	0	0	0	2
8168	1	2017-02-25 02:26:02	0.0	0.0	0.0	\N	\N	\N	50.88	\N	13.0	0	0	0	0	0	0	0	2
8169	2	2017-02-25 02:52:02	0.0	0.0	0.0	0.0	0.0	0.0	50.43	0.0	12.9	0	0	0	0	0	0	0	2
8170	1	2017-02-25 02:57:02	0.0	0.0	0.0	\N	\N	\N	51.06	\N	13.0	0	0	0	0	0	0	0	2
8171	2	2017-02-25 03:23:02	0.0	0.0	0.0	0.0	0.0	0.0	49.75	0.0	12.9	0	0	0	0	0	0	0	2
8195	2	2017-02-25 09:04:02	220.0	219.4	220.3	0.0	0.0	0.0	53.27	0.0	13.9	1	1	1	0	0	0	0	2
8196	2	2017-02-25 09:04:02	220.0	219.4	220.3	\N	\N	\N	53.27	\N	13.9	1	1	1	0	0	0	0	2
8197	1	2017-02-25 09:09:02	0.0	0.0	0.0	\N	\N	\N	53.52	\N	13.1	0	0	0	0	0	0	0	2
8205	1	2017-02-25 11:13:02	0.0	0.0	0.0	\N	\N	\N	52.43	\N	13.0	0	0	0	0	0	0	0	2
8206	2	2017-02-25 11:15:27	0.0	0.0	0.0	0.0	0.0	0.0	53.06	0.0	13.8	0	0	0	0	0	0	0	2
8207	2	2017-02-25 11:39:02	0.0	0.0	0.0	0.0	0.0	0.0	52.75	0.0	13.6	0	0	0	0	0	0	0	2
8208	1	2017-02-25 11:44:02	0.0	0.0	0.0	\N	\N	\N	51.98	\N	13.0	0	0	0	0	0	0	0	2
8209	2	2017-02-25 12:10:02	0.0	0.0	0.0	0.0	0.0	0.0	51.97	0.0	13.4	0	0	0	0	0	0	0	2
8210	1	2017-02-25 12:15:02	0.0	0.0	0.0	\N	\N	\N	51.55	\N	13.0	0	0	0	0	0	0	0	2
8211	2	2017-02-25 12:41:02	0.0	0.0	0.0	0.0	0.0	0.0	51.60	0.0	13.3	0	0	0	0	0	0	0	2
8212	1	2017-02-25 12:46:02	0.0	0.0	0.0	\N	\N	\N	51.45	\N	13.0	0	0	0	0	0	0	0	2
8213	2	2017-02-25 13:12:02	0.0	0.0	0.0	0.0	0.0	0.0	50.85	0.0	13.1	0	0	0	0	0	0	0	2
8233	2	2017-02-25 17:51:01	0.0	0.0	0.0	0.0	0.0	0.0	48.22	0.0	12.6	0	0	0	0	0	0	0	2
8234	1	2017-02-25 17:56:02	0.0	0.0	0.0	\N	\N	\N	55.04	\N	13.6	0	0	0	0	0	0	0	2
8235	2	2017-02-25 17:56:55	204.4	203.8	204.7	0.0	0.0	0.0	48.03	0.0	12.4	1	1	1	0	0	0	0	2
8236	2	2017-02-25 18:22:02	219.9	219.3	220.2	0.0	0.0	0.0	51.26	0.0	13.5	1	1	1	0	0	0	0	2
8237	1	2017-02-25 18:27:02	0.0	0.0	0.0	\N	\N	\N	54.71	\N	13.3	0	0	0	0	0	0	0	2
8238	2	2017-02-25 18:53:02	221.0	220.4	221.3	0.0	0.0	0.0	52.40	0.0	13.8	1	1	1	0	0	0	0	2
8239	1	2017-02-25 18:58:02	0.0	0.0	0.0	\N	\N	\N	54.46	\N	13.1	0	0	0	0	0	0	0	2
8240	2	2017-02-25 19:24:02	220.6	220.0	220.9	0.0	0.0	0.0	53.73	0.0	14.1	1	1	1	0	0	0	0	2
8241	1	2017-02-25 19:29:02	0.0	0.0	0.0	\N	\N	\N	54.10	\N	13.1	0	0	0	0	0	0	0	2
8242	2	2017-02-25 19:55:02	220.5	219.9	220.8	0.0	0.0	0.0	55.17	0.0	14.4	1	1	1	0	0	0	0	2
8243	1	2017-02-25 20:00:07	0.0	0.0	0.0	\N	\N	\N	53.94	\N	13.1	0	0	0	0	0	0	0	2
8249	2	2017-02-25 21:28:02	0.0	0.0	0.0	0.0	0.0	0.0	54.31	0.0	13.8	0	0	0	0	0	0	0	2
8250	1	2017-02-25 21:33:02	0.0	0.0	0.0	\N	\N	\N	53.10	\N	13.0	0	0	0	0	0	0	0	2
8251	2	2017-02-25 21:59:02	0.0	0.0	0.0	0.0	0.0	0.0	53.41	0.0	13.6	0	0	0	0	0	0	0	2
8252	1	2017-02-25 22:04:02	0.0	0.0	0.0	\N	\N	\N	52.81	\N	13.0	0	0	0	0	0	0	0	2
8253	2	2017-02-25 22:30:02	0.0	0.0	0.0	0.0	0.0	0.0	52.76	0.0	13.5	0	0	0	0	0	0	0	2
8254	1	2017-02-25 22:35:02	0.0	0.0	0.0	\N	\N	\N	52.54	\N	13.0	0	0	0	0	0	0	0	2
8255	2	2017-02-25 23:01:02	0.0	0.0	0.0	0.0	0.0	0.0	51.99	0.0	13.4	0	0	0	0	0	0	0	2
8256	1	2017-02-25 23:06:02	0.0	0.0	0.0	\N	\N	\N	52.31	\N	13.0	0	0	0	0	0	0	0	2
8257	2	2017-02-25 23:32:02	0.0	0.0	0.0	0.0	0.0	0.0	51.79	0.0	13.1	0	0	0	0	0	0	0	2
8258	1	2017-02-25 23:37:02	0.0	0.0	0.0	\N	\N	\N	52.00	\N	13.0	0	0	0	0	0	0	0	2
8259	2	2017-02-26 00:03:02	0.0	0.0	0.0	0.0	0.0	0.0	51.04	0.0	13.0	0	0	0	0	0	0	0	2
8260	1	2017-02-26 00:08:02	0.0	0.0	0.0	\N	\N	\N	51.73	\N	13.0	0	0	0	0	0	0	0	2
8261	2	2017-02-26 00:34:02	0.0	0.0	0.0	0.0	0.0	0.0	50.57	0.0	13.0	0	0	0	0	0	0	0	2
8262	1	2017-02-26 00:39:02	0.0	0.0	0.0	\N	\N	\N	51.38	\N	13.0	0	0	0	0	0	0	0	2
8193	1	2017-02-25 08:07:02	0.0	0.0	0.0	\N	\N	\N	54.05	\N	13.1	0	0	0	0	0	0	0	2
8194	2	2017-02-25 08:33:02	224.0	223.4	224.3	0.0	0.0	0.0	52.19	0.0	13.7	1	1	1	0	0	0	0	2
8198	2	2017-02-25 09:35:02	219.6	219.0	219.9	0.0	0.0	0.0	55.13	0.0	14.3	1	1	1	0	0	0	0	2
8199	1	2017-02-25 09:40:02	0.0	0.0	0.0	\N	\N	\N	53.31	\N	13.0	0	0	0	0	0	0	0	2
8200	2	2017-02-25 10:06:02	218.0	217.4	218.3	0.0	0.0	0.0	54.99	0.0	14.3	1	1	1	0	0	0	0	2
8201	1	2017-02-25 10:11:02	0.0	0.0	0.0	\N	\N	\N	53.06	\N	13.1	0	0	0	0	0	0	0	2
8202	2	2017-02-25 10:37:02	218.2	217.6	218.5	0.0	0.0	0.0	53.86	0.0	14.2	1	1	1	0	0	0	0	2
8203	1	2017-02-25 10:42:02	0.0	0.0	0.0	\N	\N	\N	52.70	\N	13.0	0	0	0	0	0	0	0	2
8204	2	2017-02-25 11:08:02	216.8	216.2	217.1	0.0	0.0	0.0	53.38	0.0	13.9	1	1	1	0	0	0	0	2
8214	1	2017-02-25 13:17:02	0.0	0.0	0.0	\N	\N	\N	51.19	\N	13.0	0	0	0	0	0	0	0	2
8215	2	2017-02-25 13:43:02	0.0	0.0	0.0	0.0	0.0	0.0	50.32	0.0	13.0	0	0	0	0	0	0	0	2
8216	1	2017-02-25 13:48:02	0.0	0.0	0.0	\N	\N	\N	51.11	\N	13.0	0	0	0	0	0	0	0	2
8217	2	2017-02-25 14:14:02	0.0	0.0	0.0	0.0	0.0	0.0	50.50	0.0	12.9	0	0	0	0	0	0	0	2
8218	1	2017-02-25 14:19:02	0.0	0.0	0.0	\N	\N	\N	50.94	\N	13.0	0	0	0	0	0	0	0	2
8219	2	2017-02-25 14:45:02	0.0	0.0	0.0	0.0	0.0	0.0	49.97	0.0	12.9	0	0	0	0	0	0	0	2
8220	1	2017-02-25 14:50:02	0.0	0.0	0.0	\N	\N	\N	51.08	\N	13.0	0	0	0	0	0	0	0	2
8221	2	2017-02-25 15:16:02	0.0	0.0	0.0	0.0	0.0	0.0	49.89	0.0	12.8	0	0	0	0	0	0	0	2
8222	1	2017-02-25 15:21:02	0.0	0.0	0.0	\N	\N	\N	50.55	\N	13.0	0	0	0	0	0	0	0	2
8223	1	2017-02-25 15:43:41	219.1	218.5	219.4	\N	\N	\N	50.60	\N	13.2	1	1	1	0	0	0	0	2
8224	2	2017-02-25 15:47:02	0.0	0.0	0.0	0.0	0.0	0.0	49.32	0.0	12.8	0	0	0	0	0	0	0	2
8225	1	2017-02-25 15:52:02	218.7	218.1	219.0	\N	\N	\N	52.02	\N	14.5	1	1	1	0	0	0	0	2
8226	2	2017-02-25 16:18:02	0.0	0.0	0.0	0.0	0.0	0.0	49.07	0.0	12.7	0	0	0	0	0	0	0	2
8227	1	2017-02-25 16:23:02	229.9	229.3	230.2	\N	\N	\N	53.18	\N	14.8	1	1	1	0	0	0	0	2
8228	2	2017-02-25 16:49:02	0.0	0.0	0.0	0.0	0.0	0.0	48.82	0.0	12.5	0	0	0	0	0	0	0	2
8229	1	2017-02-25 16:54:02	224.3	223.7	224.6	\N	\N	\N	54.54	\N	14.9	1	1	1	0	0	0	0	2
8230	2	2017-02-25 17:20:02	0.0	0.0	0.0	0.0	0.0	0.0	48.49	0.0	12.5	0	0	0	0	0	0	0	2
8231	1	2017-02-25 17:25:02	220.3	219.7	220.6	\N	\N	\N	55.59	\N	14.9	1	1	1	0	0	0	0	2
8232	1	2017-02-25 17:46:17	0.0	0.0	0.0	\N	\N	\N	55.26	\N	14.3	0	0	0	0	0	0	0	2
8244	2	2017-02-25 20:26:02	221.3	220.7	221.6	0.0	0.0	0.0	55.17	0.0	14.4	1	1	1	0	0	0	0	2
8245	1	2017-02-25 20:31:02	0.0	0.0	0.0	\N	\N	\N	53.84	\N	13.1	0	0	0	0	0	0	0	2
8246	2	2017-02-25 20:57:02	221.5	220.9	221.8	0.0	0.0	0.0	55.10	0.0	14.4	1	1	1	0	0	0	0	2
8247	2	2017-02-25 21:00:30	0.0	0.0	0.0	0.0	0.0	0.0	54.46	0.0	14.3	0	0	0	0	0	0	0	2
8248	1	2017-02-25 21:02:02	0.0	0.0	0.0	\N	\N	\N	53.47	\N	13.1	0	0	0	0	0	0	0	2
8264	1	2017-02-26 01:10:02	0.0	0.0	0.0	\N	\N	\N	51.36	\N	13.1	0	0	0	0	0	0	0	2
8265	2	2017-02-26 01:36:02	0.0	0.0	0.0	0.0	0.0	0.0	49.96	0.0	12.7	0	0	0	0	0	0	0	2
8266	1	2017-02-26 01:41:02	0.0	0.0	0.0	\N	\N	\N	51.12	\N	13.0	0	0	0	0	0	0	0	2
8267	2	2017-02-26 02:07:02	0.0	0.0	0.0	0.0	0.0	0.0	49.74	0.0	12.8	0	0	0	0	0	0	0	2
8268	1	2017-02-26 02:12:02	0.0	0.0	0.0	\N	\N	\N	51.07	\N	13.0	0	0	0	0	0	0	0	2
8269	2	2017-02-26 02:38:02	0.0	0.0	0.0	0.0	0.0	0.0	49.78	0.0	12.8	0	0	0	0	0	0	0	2
8270	1	2017-02-26 02:43:02	0.0	0.0	0.0	\N	\N	\N	50.92	\N	13.0	0	0	0	0	0	0	0	2
8271	2	2017-02-26 03:09:02	0.0	0.0	0.0	0.0	0.0	0.0	49.39	0.0	12.8	0	0	0	0	0	0	0	2
8272	1	2017-02-26 03:14:02	0.0	0.0	0.0	\N	\N	\N	50.93	\N	13.0	0	0	0	0	0	0	0	2
8273	2	2017-02-26 03:40:02	0.0	0.0	0.0	0.0	0.0	0.0	49.46	0.0	12.7	0	0	0	0	0	0	0	2
8274	1	2017-02-26 03:45:02	0.0	0.0	0.0	\N	\N	\N	50.79	\N	13.0	0	0	0	0	0	0	0	2
8275	1	2017-02-26 03:47:07	212.4	211.8	212.7	\N	\N	\N	50.87	\N	12.3	1	1	1	0	0	0	0	2
8276	2	2017-02-26 04:11:02	0.0	0.0	0.0	0.0	0.0	0.0	49.32	0.0	12.6	0	0	0	0	0	0	0	2
8277	1	2017-02-26 04:16:02	220.8	220.2	221.1	\N	\N	\N	53.28	\N	14.7	1	1	1	0	0	0	0	2
8278	2	2017-02-26 04:42:02	0.0	0.0	0.0	0.0	0.0	0.0	48.59	0.0	12.6	0	0	0	0	0	0	0	2
8279	1	2017-02-26 04:47:02	213.2	212.6	213.5	\N	\N	\N	55.55	\N	14.7	1	1	1	0	0	0	0	2
8280	2	2017-02-26 05:13:02	0.0	0.0	0.0	0.0	0.0	0.0	48.58	0.0	12.5	0	0	0	0	0	0	0	2
8281	1	2017-02-26 05:18:01	220.2	219.6	220.5	\N	\N	\N	55.50	\N	14.9	1	1	1	0	0	0	0	2
8282	2	2017-02-26 05:18:24	215.9	215.3	216.2	0.0	0.0	0.0	48.47	0.0	12.8	1	1	1	0	0	0	0	2
8283	2	2017-02-26 05:28:25	0.0	0.0	0.0	0.0	0.0	0.0	48.81	0.0	12.9	0	0	0	0	0	0	0	2
8284	2	2017-02-26 05:29:43	213.6	213.0	213.9	0.0	0.0	0.0	49.09	0.0	12.7	1	1	1	0	0	0	0	2
8285	2	2017-02-26 05:42:27	0.0	0.0	0.0	0.0	0.0	0.0	49.37	0.0	13.1	0	0	0	0	0	0	0	2
8286	1	2017-02-26 05:49:02	219.9	219.3	220.2	\N	\N	\N	55.27	\N	14.9	1	1	1	0	0	0	0	2
8287	1	2017-02-26 06:20:02	0.0	0.0	0.0	\N	\N	\N	54.88	\N	13.5	0	0	0	0	0	0	0	2
8288	2	2017-02-26 06:46:02	221.5	220.9	221.8	0.0	0.0	0.0	53.03	0.0	13.9	1	1	1	0	0	0	0	2
8289	1	2017-02-26 06:51:02	0.0	0.0	0.0	\N	\N	\N	54.65	\N	13.2	0	0	0	0	0	0	0	2
8290	2	2017-02-26 07:17:02	220.6	220.0	220.9	0.0	0.0	0.0	54.93	0.0	14.3	1	1	1	0	0	0	0	2
8291	1	2017-02-26 07:22:02	0.0	0.0	0.0	\N	\N	\N	54.37	\N	13.2	0	0	0	0	0	0	0	2
8292	2	2017-02-26 07:48:02	220.9	220.3	221.2	0.0	0.0	0.0	55.17	0.0	14.4	1	1	1	0	0	0	0	2
8293	1	2017-02-26 07:53:02	0.0	0.0	0.0	\N	\N	\N	54.17	\N	13.2	0	0	0	0	0	0	0	2
8294	2	2017-02-26 08:19:01	220.0	219.4	220.3	0.0	0.0	0.0	55.35	0.0	14.4	1	1	1	0	0	0	0	2
8313	2	2017-02-26 11:23:02	0.0	0.0	0.0	0.0	0.0	0.0	53.27	0.0	13.9	0	0	0	0	0	0	0	2
8314	1	2017-02-26 11:30:02	0.0	0.0	0.0	\N	\N	\N	52.30	\N	13.0	0	0	0	0	0	0	0	2
8315	2	2017-02-26 11:54:02	0.0	0.0	0.0	0.0	0.0	0.0	52.74	0.0	13.6	0	0	0	0	0	0	0	2
8316	1	2017-02-26 12:01:02	0.0	0.0	0.0	\N	\N	\N	51.97	\N	13.0	0	0	0	0	0	0	0	2
8318	1	2017-02-26 12:32:02	0.0	0.0	0.0	\N	\N	\N	51.69	\N	13.0	0	0	0	0	0	0	0	2
8319	2	2017-02-26 12:56:02	0.0	0.0	0.0	0.0	0.0	0.0	51.98	0.0	13.1	0	0	0	0	0	0	0	2
8320	1	2017-02-26 13:03:02	0.0	0.0	0.0	\N	\N	\N	51.40	\N	13.0	0	0	0	0	0	0	0	2
8321	2	2017-02-26 13:27:02	0.0	0.0	0.0	0.0	0.0	0.0	50.40	0.0	13.1	0	0	0	0	0	0	0	2
8322	1	2017-02-26 13:34:02	0.0	0.0	0.0	\N	\N	\N	51.24	\N	13.0	0	0	0	0	0	0	0	2
8323	2	2017-02-26 13:58:02	0.0	0.0	0.0	0.0	0.0	0.0	50.26	0.0	13.1	0	0	0	0	0	0	0	2
8324	1	2017-02-26 14:05:02	0.0	0.0	0.0	\N	\N	\N	51.14	\N	13.0	0	0	0	0	0	0	0	2
8325	2	2017-02-26 14:29:02	0.0	0.0	0.0	0.0	0.0	0.0	49.74	0.0	12.9	0	0	0	0	0	0	0	2
8263	2	2017-02-26 01:05:02	0.0	0.0	0.0	0.0	0.0	0.0	50.14	0.0	12.8	0	0	0	0	0	0	0	2
8295	1	2017-02-26 08:24:02	0.0	0.0	0.0	\N	\N	\N	53.98	\N	13.1	0	0	0	0	0	0	0	2
8296	2	2017-02-26 08:50:02	220.7	220.1	221.0	0.0	0.0	0.0	54.97	0.0	14.4	1	1	1	0	0	0	0	2
8297	1	2017-02-26 08:55:02	0.0	0.0	0.0	\N	\N	\N	53.74	\N	13.1	0	0	0	0	0	0	0	2
8298	2	2017-02-26 08:55:21	0.0	0.0	0.0	0.0	0.0	0.0	54.68	0.0	14.0	0	0	0	0	0	0	0	2
8299	2	2017-02-26 09:21:02	0.0	0.0	0.0	0.0	0.0	0.0	53.87	0.0	13.8	0	0	0	0	0	0	0	2
8300	1	2017-02-26 09:26:02	0.0	0.0	0.0	\N	\N	\N	53.46	\N	13.1	0	0	0	0	0	0	0	2
8301	2	2017-02-26 09:52:02	0.0	0.0	0.0	0.0	0.0	0.0	53.57	0.0	13.8	0	0	0	0	0	0	0	2
8302	1	2017-02-26 09:57:02	0.0	0.0	0.0	\N	\N	\N	53.26	\N	13.1	0	0	0	0	0	0	0	2
8303	2	2017-02-26 10:21:51	207.7	207.1	208.0	0.0	0.0	0.0	53.24	0.0	13.4	1	1	1	0	0	0	0	2
8304	2	2017-02-26 10:23:02	217.6	217.0	217.9	0.0	0.0	0.0	52.88	0.0	14.0	1	1	1	0	0	0	0	2
8305	1	2017-02-26 10:28:02	0.0	0.0	0.0	\N	\N	\N	52.83	\N	13.0	0	0	0	0	0	0	0	2
8306	2	2017-02-26 10:40:30	0.0	0.0	0.0	0.0	0.0	0.0	53.68	0.0	14.0	0	0	0	0	0	0	0	2
8307	2	2017-02-26 10:42:40	189.0	188.4	189.3	0.0	0.0	0.0	53.72	0.0	13.7	1	1	1	0	0	0	0	2
8308	2	2017-02-26 10:47:22	0.0	0.0	0.0	0.0	0.0	0.0	53.54	0.0	13.9	0	0	0	0	0	0	0	2
8309	2	2017-02-26 10:51:37	210.1	209.5	210.4	0.0	0.0	0.0	53.36	0.0	13.8	1	1	1	0	0	0	0	2
8310	2	2017-02-26 10:53:02	217.9	217.3	218.2	0.0	0.0	0.0	53.42	0.0	13.9	1	1	1	0	0	0	0	2
8311	1	2017-02-26 10:59:02	0.0	0.0	0.0	\N	\N	\N	52.61	\N	13.1	0	0	0	0	0	0	0	2
8312	2	2017-02-26 11:02:25	0.0	0.0	0.0	0.0	0.0	0.0	54.04	0.0	14.1	0	0	0	0	0	0	0	2
8317	2	2017-02-26 12:25:02	0.0	0.0	0.0	0.0	0.0	0.0	52.01	0.0	13.5	0	0	0	0	0	0	0	2
8337	1	2017-02-26 17:11:02	216.5	215.9	216.8	\N	\N	\N	55.64	\N	14.7	1	1	1	0	0	0	0	2
8401	1	2017-02-27 08:10:02	0.0	0.0	0.0	\N	\N	\N	54.16	\N	13.1	0	0	0	0	0	0	0	2
8402	2	2017-02-27 08:34:02	219.9	219.3	220.2	0.0	0.0	0.0	54.93	0.0	14.4	1	1	1	0	0	0	0	2
8403	1	2017-02-27 08:41:02	0.0	0.0	0.0	\N	\N	\N	53.80	\N	13.1	0	0	0	0	0	0	0	2
8404	2	2017-02-27 09:05:02	224.2	223.6	224.5	0.0	0.0	0.0	55.96	0.0	14.6	1	1	1	0	0	0	0	2
8405	1	2017-02-27 09:12:02	0.0	0.0	0.0	\N	\N	\N	53.53	\N	13.1	0	0	0	0	0	0	0	2
8406	2	2017-02-27 09:28:32	0.0	0.0	0.0	0.0	0.0	0.0	55.62	0.0	14.5	0	0	0	0	0	0	0	2
8407	2	2017-02-27 09:36:02	0.0	0.0	0.0	0.0	0.0	0.0	55.06	0.0	14.2	0	0	0	0	0	0	0	2
8408	1	2017-02-27 09:43:02	0.0	0.0	0.0	\N	\N	\N	53.18	\N	13.1	0	0	0	0	0	0	0	2
8409	2	2017-02-27 10:07:02	0.0	0.0	0.0	0.0	0.0	0.0	54.72	0.0	14.0	0	0	0	0	0	0	0	2
8410	1	2017-02-27 10:14:02	0.0	0.0	0.0	\N	\N	\N	53.03	\N	13.1	0	0	0	0	0	0	0	2
8411	2	2017-02-27 10:38:01	0.0	0.0	0.0	0.0	0.0	0.0	53.74	0.0	13.9	0	0	0	0	0	0	0	2
8412	1	2017-02-27 10:45:02	0.0	0.0	0.0	\N	\N	\N	52.74	\N	13.0	0	0	0	0	0	0	0	2
8413	2	2017-02-27 11:09:02	0.0	0.0	0.0	0.0	0.0	0.0	53.53	0.0	13.8	0	0	0	0	0	0	0	2
8440	1	2017-02-27 17:28:02	221.8	221.2	222.1	\N	\N	\N	55.48	\N	14.9	1	1	1	0	0	0	0	2
8441	2	2017-02-27 17:52:02	0.0	0.0	0.0	0.0	0.0	0.0	47.92	0.0	12.6	0	0	0	0	0	0	0	2
8448	1	2017-02-27 19:01:02	0.0	0.0	0.0	\N	\N	\N	54.64	\N	13.3	0	0	0	0	0	0	0	2
8449	2	2017-02-27 19:25:02	221.6	221.0	221.9	0.0	0.0	0.0	52.24	0.0	13.8	1	1	1	0	0	0	0	2
8450	1	2017-02-27 19:32:02	0.0	0.0	0.0	\N	\N	\N	54.29	\N	13.1	0	0	0	0	0	0	0	2
8451	2	2017-02-27 19:56:02	221.6	221.0	221.9	0.0	0.0	0.0	53.08	0.0	14.0	1	1	1	0	0	0	0	2
8452	1	2017-02-27 20:03:02	0.0	0.0	0.0	\N	\N	\N	54.08	\N	13.1	0	0	0	0	0	0	0	2
8453	2	2017-02-27 20:27:02	222.5	221.9	222.8	0.0	0.0	0.0	53.91	0.0	14.2	1	1	1	0	0	0	0	2
8454	2	2017-02-27 20:27:02	222.5	221.9	222.8	\N	\N	\N	53.91	\N	14.2	1	1	1	0	0	0	0	2
8455	1	2017-02-27 20:34:02	0.0	0.0	0.0	\N	\N	\N	53.80	\N	13.1	0	0	0	0	0	0	0	2
8463	2	2017-02-27 22:31:02	0.0	0.0	0.0	0.0	0.0	0.0	53.68	0.0	13.9	0	0	0	0	0	0	0	2
8464	1	2017-02-27 22:38:02	0.0	0.0	0.0	\N	\N	\N	52.74	\N	13.1	0	0	0	0	0	0	0	2
8465	2	2017-02-27 23:02:01	0.0	0.0	0.0	0.0	0.0	0.0	52.92	0.0	13.6	0	0	0	0	0	0	0	2
8466	1	2017-02-27 23:09:02	0.0	0.0	0.0	\N	\N	\N	52.52	\N	13.1	0	0	0	0	0	0	0	2
8467	2	2017-02-27 23:33:02	0.0	0.0	0.0	0.0	0.0	0.0	52.02	0.0	13.7	0	0	0	0	0	0	0	2
8468	1	2017-02-27 23:40:02	0.0	0.0	0.0	\N	\N	\N	52.21	\N	13.0	0	0	0	0	0	0	0	2
8469	2	2017-02-28 00:04:01	0.0	0.0	0.0	0.0	0.0	0.0	51.78	0.0	13.3	0	0	0	0	0	0	0	2
8470	1	2017-02-28 00:11:02	0.0	0.0	0.0	\N	\N	\N	51.84	\N	13.0	0	0	0	0	0	0	0	2
8471	2	2017-02-28 00:35:02	0.0	0.0	0.0	0.0	0.0	0.0	51.25	0.0	13.3	0	0	0	0	0	0	0	2
8485	1	2017-02-28 03:48:02	0.0	0.0	0.0	\N	\N	\N	50.75	\N	13.0	0	0	0	0	0	0	0	2
8486	1	2017-02-28 04:01:17	180.2	179.6	180.5	\N	\N	\N	50.70	\N	12.2	1	1	1	0	0	0	0	2
8487	2	2017-02-28 04:12:02	0.0	0.0	0.0	0.0	0.0	0.0	49.72	0.0	12.9	0	0	0	0	0	0	0	2
8488	1	2017-02-28 04:19:02	221.8	221.2	222.1	\N	\N	\N	51.67	\N	14.5	1	1	1	0	0	0	0	2
8489	2	2017-02-28 04:43:02	0.0	0.0	0.0	0.0	0.0	0.0	49.83	0.0	12.8	0	0	0	0	0	0	0	2
8490	1	2017-02-28 04:50:02	221.7	221.1	222.0	\N	\N	\N	53.95	\N	14.4	1	1	1	0	0	0	0	2
8491	2	2017-02-28 05:14:02	0.0	0.0	0.0	0.0	0.0	0.0	49.31	0.0	12.8	0	0	0	0	0	0	0	2
8492	1	2017-02-28 05:21:02	221.1	220.5	221.4	\N	\N	\N	54.68	\N	14.5	1	1	1	0	0	0	0	2
8493	2	2017-02-28 05:45:02	0.0	0.0	0.0	0.0	0.0	0.0	48.82	0.0	12.8	0	0	0	0	0	0	0	2
8494	1	2017-02-28 05:52:02	220.3	219.7	220.6	\N	\N	\N	54.64	\N	14.6	1	1	1	0	0	0	0	2
8495	1	2017-02-28 06:04:00	0.0	0.0	0.0	\N	\N	\N	54.05	\N	13.8	0	0	0	0	0	0	0	2
8496	2	2017-02-28 06:16:02	0.0	0.0	0.0	0.0	0.0	0.0	48.37	0.0	12.6	0	0	0	0	0	0	0	2
8497	1	2017-02-28 06:23:02	0.0	0.0	0.0	\N	\N	\N	53.85	\N	13.3	0	0	0	0	0	0	0	2
8498	2	2017-02-28 06:47:02	0.0	0.0	0.0	0.0	0.0	0.0	47.84	0.0	12.6	0	0	0	0	0	0	0	2
8499	2	2017-02-28 06:48:13	180.0	179.4	180.3	0.0	0.0	0.0	47.97	0.0	12.5	1	1	1	0	0	0	0	2
8500	1	2017-02-28 06:54:02	0.0	0.0	0.0	\N	\N	\N	53.67	\N	13.0	0	0	0	0	0	0	0	2
8501	2	2017-02-28 07:18:02	225.0	224.4	225.3	0.0	0.0	0.0	51.77	0.0	13.8	1	1	1	0	0	0	0	2
8502	1	2017-02-28 07:25:02	0.0	0.0	0.0	\N	\N	\N	53.45	\N	12.9	0	0	0	0	0	0	0	2
8503	2	2017-02-28 07:49:02	223.5	222.9	223.8	0.0	0.0	0.0	52.87	0.0	13.9	1	1	1	0	0	0	0	2
8504	1	2017-02-28 07:56:02	0.0	0.0	0.0	\N	\N	\N	53.06	\N	12.8	0	0	0	0	0	0	0	2
8505	2	2017-02-28 08:20:02	223.4	222.8	223.7	0.0	0.0	0.0	53.71	0.0	14.1	1	1	1	0	0	0	0	2
8506	1	2017-02-28 08:27:02	0.0	0.0	0.0	\N	\N	\N	52.87	\N	12.8	0	0	0	0	0	0	0	2
8609	1	2017-03-01 08:44:02	0.0	0.0	0.0	\N	\N	\N	49.36	\N	12.7	0	0	0	0	0	0	0	2
8326	1	2017-02-26 14:36:02	0.0	0.0	0.0	\N	\N	\N	50.92	\N	13.0	0	0	0	0	0	0	0	2
8327	2	2017-02-26 15:00:07	0.0	0.0	0.0	0.0	0.0	0.0	49.24	0.0	12.8	0	0	0	0	0	0	0	2
8328	1	2017-02-26 15:07:02	0.0	0.0	0.0	\N	\N	\N	50.88	\N	13.0	0	0	0	0	0	0	0	2
8329	2	2017-02-26 15:31:02	0.0	0.0	0.0	0.0	0.0	0.0	49.77	0.0	12.8	0	0	0	0	0	0	0	2
8330	1	2017-02-26 15:38:02	0.0	0.0	0.0	\N	\N	\N	50.68	\N	13.0	0	0	0	0	0	0	0	2
8331	1	2017-02-26 15:50:40	178.9	178.3	179.2	\N	\N	\N	50.75	\N	12.3	1	1	1	0	0	0	0	2
8332	2	2017-02-26 16:02:02	0.0	0.0	0.0	0.0	0.0	0.0	49.31	0.0	12.7	0	0	0	0	0	0	0	2
8333	1	2017-02-26 16:09:02	220.4	219.8	220.7	\N	\N	\N	52.79	\N	14.7	1	1	1	0	0	0	0	2
8334	2	2017-02-26 16:33:02	0.0	0.0	0.0	0.0	0.0	0.0	49.23	0.0	12.7	0	0	0	0	0	0	0	2
8335	1	2017-02-26 16:40:02	230.2	229.6	230.5	\N	\N	\N	54.76	\N	14.9	1	1	1	0	0	0	0	2
8336	2	2017-02-26 17:04:02	0.0	0.0	0.0	0.0	0.0	0.0	48.91	0.0	12.7	0	0	0	0	0	0	0	2
8338	2	2017-02-26 17:35:02	0.0	0.0	0.0	0.0	0.0	0.0	48.98	0.0	12.7	0	0	0	0	0	0	0	2
8339	1	2017-02-26 17:42:02	223.5	222.9	223.8	\N	\N	\N	55.52	\N	14.8	1	1	1	0	0	0	0	2
8340	1	2017-02-26 17:53:18	0.0	0.0	0.0	\N	\N	\N	55.32	\N	14.7	0	0	0	0	0	0	0	2
8341	2	2017-02-26 18:06:02	0.0	0.0	0.0	0.0	0.0	0.0	48.26	0.0	12.6	0	0	0	0	0	0	0	2
8342	1	2017-02-26 18:13:02	0.0	0.0	0.0	\N	\N	\N	55.01	\N	13.5	0	0	0	0	0	0	0	2
8343	2	2017-02-26 18:37:02	0.0	0.0	0.0	0.0	0.0	0.0	47.94	0.0	12.3	0	0	0	0	0	0	0	2
8344	1	2017-02-26 18:44:02	0.0	0.0	0.0	\N	\N	\N	54.61	\N	13.3	0	0	0	0	0	0	0	2
8345	2	2017-02-26 18:46:16	218.0	217.4	218.3	0.0	0.0	0.0	48.07	0.0	12.6	1	1	1	0	0	0	0	2
8346	2	2017-02-26 19:08:02	220.2	219.6	220.5	0.0	0.0	0.0	51.16	0.0	13.4	1	1	1	0	0	0	0	2
8347	1	2017-02-26 19:15:02	0.0	0.0	0.0	\N	\N	\N	54.37	\N	13.1	0	0	0	0	0	0	0	2
8348	2	2017-02-26 19:39:02	223.1	222.5	223.4	0.0	0.0	0.0	51.46	0.0	13.6	1	1	1	0	0	0	0	2
8349	1	2017-02-26 19:46:02	0.0	0.0	0.0	\N	\N	\N	54.16	\N	13.1	0	0	0	0	0	0	0	2
8350	2	2017-02-26 20:10:02	221.4	220.8	221.7	0.0	0.0	0.0	53.16	0.0	14.0	1	1	1	0	0	0	0	2
8351	1	2017-02-26 20:17:02	0.0	0.0	0.0	\N	\N	\N	53.96	\N	13.1	0	0	0	0	0	0	0	2
8352	2	2017-02-26 20:41:02	222.1	221.5	222.4	0.0	0.0	0.0	54.80	0.0	14.4	1	1	1	0	0	0	0	2
8353	1	2017-02-26 20:48:02	0.0	0.0	0.0	\N	\N	\N	53.76	\N	13.1	0	0	0	0	0	0	0	2
8354	2	2017-02-26 21:12:02	222.7	222.1	223.0	0.0	0.0	0.0	55.26	0.0	14.3	1	1	1	0	0	0	0	2
8355	1	2017-02-26 21:19:02	0.0	0.0	0.0	\N	\N	\N	53.46	\N	13.0	0	0	0	0	0	0	0	2
8356	2	2017-02-26 21:21:59	0.0	0.0	0.0	0.0	0.0	0.0	54.00	0.0	14.2	0	0	0	0	0	0	0	2
8357	2	2017-02-26 21:43:02	0.0	0.0	0.0	0.0	0.0	0.0	55.18	0.0	14.2	0	0	0	0	0	0	0	2
8358	1	2017-02-26 21:50:02	0.0	0.0	0.0	\N	\N	\N	53.17	\N	13.1	0	0	0	0	0	0	0	2
8359	2	2017-02-26 22:14:02	0.0	0.0	0.0	0.0	0.0	0.0	54.50	0.0	14.1	0	0	0	0	0	0	0	2
8360	1	2017-02-26 22:21:02	0.0	0.0	0.0	\N	\N	\N	53.01	\N	13.1	0	0	0	0	0	0	0	2
8361	2	2017-02-26 22:45:02	0.0	0.0	0.0	0.0	0.0	0.0	53.60	0.0	13.8	0	0	0	0	0	0	0	2
8362	1	2017-02-26 22:52:02	0.0	0.0	0.0	\N	\N	\N	52.66	\N	13.0	0	0	0	0	0	0	0	2
8363	2	2017-02-26 23:16:02	0.0	0.0	0.0	0.0	0.0	0.0	53.54	0.0	13.7	0	0	0	0	0	0	0	2
8364	1	2017-02-26 23:23:02	0.0	0.0	0.0	\N	\N	\N	52.44	\N	13.0	0	0	0	0	0	0	0	2
8365	2	2017-02-26 23:47:02	0.0	0.0	0.0	0.0	0.0	0.0	52.42	0.0	13.5	0	0	0	0	0	0	0	2
8366	1	2017-02-26 23:54:02	0.0	0.0	0.0	\N	\N	\N	52.05	\N	13.0	0	0	0	0	0	0	0	2
8367	2	2017-02-27 00:18:02	0.0	0.0	0.0	0.0	0.0	0.0	52.04	0.0	13.4	0	0	0	0	0	0	0	2
8368	1	2017-02-27 00:25:02	0.0	0.0	0.0	\N	\N	\N	51.83	\N	13.0	0	0	0	0	0	0	0	2
8369	2	2017-02-27 00:49:02	0.0	0.0	0.0	0.0	0.0	0.0	51.60	0.0	13.3	0	0	0	0	0	0	0	2
8370	1	2017-02-27 00:56:02	0.0	0.0	0.0	\N	\N	\N	51.47	\N	13.0	0	0	0	0	0	0	0	2
8371	2	2017-02-27 01:20:02	0.0	0.0	0.0	0.0	0.0	0.0	51.37	0.0	13.3	0	0	0	0	0	0	0	2
8372	1	2017-02-27 01:27:02	0.0	0.0	0.0	\N	\N	\N	51.26	\N	13.0	0	0	0	0	0	0	0	2
8373	2	2017-02-27 01:51:02	0.0	0.0	0.0	0.0	0.0	0.0	50.70	0.0	13.1	0	0	0	0	0	0	0	2
8374	1	2017-02-27 01:58:02	0.0	0.0	0.0	\N	\N	\N	51.16	\N	13.0	0	0	0	0	0	0	0	2
8375	2	2017-02-27 02:22:02	0.0	0.0	0.0	0.0	0.0	0.0	51.12	0.0	13.2	0	0	0	0	0	0	0	2
8376	1	2017-02-27 02:29:02	0.0	0.0	0.0	\N	\N	\N	51.07	\N	13.0	0	0	0	0	0	0	0	2
8377	2	2017-02-27 02:53:02	0.0	0.0	0.0	0.0	0.0	0.0	50.57	0.0	13.1	0	0	0	0	0	0	0	2
8378	1	2017-02-27 03:00:07	0.0	0.0	0.0	\N	\N	\N	50.94	\N	13.0	0	0	0	0	0	0	0	2
8379	2	2017-02-27 03:24:01	0.0	0.0	0.0	0.0	0.0	0.0	50.86	0.0	13.0	0	0	0	0	0	0	0	2
8380	1	2017-02-27 03:31:02	0.0	0.0	0.0	\N	\N	\N	50.89	\N	13.0	0	0	0	0	0	0	0	2
8381	1	2017-02-27 03:54:16	218.6	218.0	218.9	\N	\N	\N	50.72	\N	13.1	1	1	1	0	0	0	0	2
8382	2	2017-02-27 03:55:02	0.0	0.0	0.0	0.0	0.0	0.0	50.27	0.0	13.2	0	0	0	0	0	0	0	2
8383	1	2017-02-27 04:02:02	221.5	220.9	221.8	\N	\N	\N	52.78	\N	14.6	1	1	1	0	0	0	0	2
8384	2	2017-02-27 04:26:02	0.0	0.0	0.0	0.0	0.0	0.0	50.12	0.0	13.0	0	0	0	0	0	0	0	2
8385	1	2017-02-27 04:33:02	218.0	217.4	218.3	\N	\N	\N	54.00	\N	15.0	1	1	1	0	0	0	0	2
8386	2	2017-02-27 04:57:02	0.0	0.0	0.0	0.0	0.0	0.0	49.70	0.0	12.9	0	0	0	0	0	0	0	2
8387	1	2017-02-27 05:04:02	222.2	221.6	222.5	\N	\N	\N	55.12	\N	15.0	1	1	1	0	0	0	0	2
8388	2	2017-02-27 05:28:02	0.0	0.0	0.0	0.0	0.0	0.0	49.42	0.0	12.8	0	0	0	0	0	0	0	2
8389	1	2017-02-27 05:35:01	216.3	215.7	216.6	\N	\N	\N	55.47	\N	14.9	1	1	1	0	0	0	0	2
8390	1	2017-02-27 05:56:54	0.0	0.0	0.0	\N	\N	\N	55.32	\N	14.3	0	0	0	0	0	0	0	2
8391	2	2017-02-27 05:59:02	0.0	0.0	0.0	0.0	0.0	0.0	49.22	0.0	12.8	0	0	0	0	0	0	0	2
8392	1	2017-02-27 06:06:02	0.0	0.0	0.0	\N	\N	\N	55.08	\N	13.8	0	0	0	0	0	0	0	2
8393	2	2017-02-27 06:30:02	0.0	0.0	0.0	0.0	0.0	0.0	48.89	0.0	12.6	0	0	0	0	0	0	0	2
8394	1	2017-02-27 06:37:02	0.0	0.0	0.0	\N	\N	\N	54.72	\N	13.3	0	0	0	0	0	0	0	2
8395	2	2017-02-27 06:52:51	214.2	213.6	214.5	0.0	0.0	0.0	47.82	0.0	12.7	1	1	1	0	0	0	0	2
8396	2	2017-02-27 07:01:01	224.5	223.9	224.8	0.0	0.0	0.0	50.82	0.0	13.4	1	1	1	0	0	0	0	2
8397	1	2017-02-27 07:08:02	0.0	0.0	0.0	\N	\N	\N	54.54	\N	13.2	0	0	0	0	0	0	0	2
8398	2	2017-02-27 07:32:02	224.1	223.5	224.4	0.0	0.0	0.0	52.22	0.0	13.8	1	1	1	0	0	0	0	2
8399	1	2017-02-27 07:39:02	0.0	0.0	0.0	\N	\N	\N	54.34	\N	13.1	0	0	0	0	0	0	0	2
8400	2	2017-02-27 08:03:02	221.4	220.8	221.7	0.0	0.0	0.0	53.30	0.0	14.2	1	1	1	0	0	0	0	2
8414	1	2017-02-27 11:16:02	0.0	0.0	0.0	\N	\N	\N	52.44	\N	13.1	0	0	0	0	0	0	0	2
8415	2	2017-02-27 11:40:02	0.0	0.0	0.0	0.0	0.0	0.0	52.78	0.0	13.6	0	0	0	0	0	0	0	2
8416	1	2017-02-27 11:47:02	0.0	0.0	0.0	\N	\N	\N	52.03	\N	13.1	0	0	0	0	0	0	0	2
8417	2	2017-02-27 12:11:02	0.0	0.0	0.0	0.0	0.0	0.0	52.05	0.0	13.4	0	0	0	0	0	0	0	2
8418	1	2017-02-27 12:18:02	0.0	0.0	0.0	\N	\N	\N	51.74	\N	13.0	0	0	0	0	0	0	0	2
8419	1	2017-02-27 12:18:02	0.0	0.0	0.0	\N	\N	\N	51.74	\N	13.0	0	0	0	0	0	0	0	2
8420	2	2017-02-27 12:42:02	0.0	0.0	0.0	0.0	0.0	0.0	51.59	0.0	13.4	0	0	0	0	0	0	0	2
8421	1	2017-02-27 12:49:02	0.0	0.0	0.0	\N	\N	\N	51.53	\N	13.0	0	0	0	0	0	0	0	2
8422	2	2017-02-27 13:13:02	0.0	0.0	0.0	0.0	0.0	0.0	51.50	0.0	13.3	0	0	0	0	0	0	0	2
8423	1	2017-02-27 13:20:02	0.0	0.0	0.0	\N	\N	\N	51.41	\N	13.1	0	0	0	0	0	0	0	2
8424	2	2017-02-27 13:44:02	0.0	0.0	0.0	0.0	0.0	0.0	50.90	0.0	13.2	0	0	0	0	0	0	0	2
8425	1	2017-02-27 13:51:02	0.0	0.0	0.0	\N	\N	\N	51.20	\N	13.0	0	0	0	0	0	0	0	2
8426	2	2017-02-27 14:15:02	0.0	0.0	0.0	0.0	0.0	0.0	50.69	0.0	13.4	0	0	0	0	0	0	0	2
8427	1	2017-02-27 14:22:02	0.0	0.0	0.0	\N	\N	\N	51.06	\N	13.0	0	0	0	0	0	0	0	2
8428	2	2017-02-27 14:46:02	0.0	0.0	0.0	0.0	0.0	0.0	50.47	0.0	13.3	0	0	0	0	0	0	0	2
8429	1	2017-02-27 14:53:02	0.0	0.0	0.0	\N	\N	\N	50.88	\N	13.0	0	0	0	0	0	0	0	2
8430	2	2017-02-27 15:17:02	0.0	0.0	0.0	0.0	0.0	0.0	50.52	0.0	13.1	0	0	0	0	0	0	0	2
8431	1	2017-02-27 15:24:02	0.0	0.0	0.0	\N	\N	\N	50.67	\N	13.0	0	0	0	0	0	0	0	2
8432	2	2017-02-27 15:48:02	0.0	0.0	0.0	0.0	0.0	0.0	50.06	0.0	12.9	0	0	0	0	0	0	0	2
8433	1	2017-02-27 15:55:02	0.0	0.0	0.0	\N	\N	\N	50.67	\N	13.0	0	0	0	0	0	0	0	2
8434	1	2017-02-27 15:57:48	219.4	218.8	219.7	\N	\N	\N	50.70	\N	13.2	1	1	1	0	0	0	0	2
8435	2	2017-02-27 16:19:02	0.0	0.0	0.0	0.0	0.0	0.0	49.48	0.0	13.0	0	0	0	0	0	0	0	2
8436	1	2017-02-27 16:26:02	221.9	221.3	222.2	\N	\N	\N	52.59	\N	14.9	1	1	1	0	0	0	0	2
8437	2	2017-02-27 16:50:02	0.0	0.0	0.0	0.0	0.0	0.0	49.12	0.0	12.8	0	0	0	0	0	0	0	2
8438	1	2017-02-27 16:57:02	215.5	214.9	215.8	\N	\N	\N	55.01	\N	15.1	1	1	1	0	0	0	0	2
8439	2	2017-02-27 17:21:02	0.0	0.0	0.0	0.0	0.0	0.0	49.35	0.0	12.6	0	0	0	0	0	0	0	2
8442	1	2017-02-27 17:59:02	216.9	216.3	217.2	\N	\N	\N	55.57	\N	14.9	1	1	1	0	0	0	0	2
8443	1	2017-02-27 18:00:28	0.0	0.0	0.0	\N	\N	\N	55.22	\N	14.6	0	0	0	0	0	0	0	2
8444	2	2017-02-27 18:23:02	0.0	0.0	0.0	0.0	0.0	0.0	48.15	0.0	12.6	0	0	0	0	0	0	0	2
8445	1	2017-02-27 18:30:02	0.0	0.0	0.0	\N	\N	\N	54.94	\N	13.4	0	0	0	0	0	0	0	2
8446	2	2017-02-27 18:41:34	189.3	188.7	189.6	0.0	0.0	0.0	47.15	0.0	12.3	1	1	1	0	0	0	0	2
8447	2	2017-02-27 18:54:02	223.1	222.5	223.4	0.0	0.0	0.0	50.75	0.0	13.5	1	1	1	0	0	0	0	2
8456	2	2017-02-27 20:58:02	221.9	221.3	222.2	0.0	0.0	0.0	56.02	0.0	14.7	1	1	1	0	0	0	0	2
8457	1	2017-02-27 21:05:02	0.0	0.0	0.0	\N	\N	\N	53.63	\N	13.1	0	0	0	0	0	0	0	2
8458	2	2017-02-27 21:17:20	0.0	0.0	0.0	0.0	0.0	0.0	54.67	0.0	14.2	0	0	0	0	0	0	0	2
8459	2	2017-02-27 21:29:02	0.0	0.0	0.0	0.0	0.0	0.0	54.88	0.0	14.1	0	0	0	0	0	0	0	2
8460	1	2017-02-27 21:36:02	0.0	0.0	0.0	\N	\N	\N	53.44	\N	13.1	0	0	0	0	0	0	0	2
8461	2	2017-02-27 22:00:07	0.0	0.0	0.0	0.0	0.0	0.0	53.43	0.0	13.9	0	0	0	0	0	0	0	2
8462	1	2017-02-27 22:07:02	0.0	0.0	0.0	\N	\N	\N	53.09	\N	13.1	0	0	0	0	0	0	0	2
8472	1	2017-02-28 00:42:02	0.0	0.0	0.0	\N	\N	\N	51.60	\N	13.0	0	0	0	0	0	0	0	2
8473	2	2017-02-28 01:06:02	0.0	0.0	0.0	0.0	0.0	0.0	51.07	0.0	13.2	0	0	0	0	0	0	0	2
8474	1	2017-02-28 01:13:02	0.0	0.0	0.0	\N	\N	\N	51.34	\N	13.0	0	0	0	0	0	0	0	2
8475	2	2017-02-28 01:37:02	0.0	0.0	0.0	0.0	0.0	0.0	50.85	0.0	13.3	0	0	0	0	0	0	0	2
8476	1	2017-02-28 01:44:02	0.0	0.0	0.0	\N	\N	\N	51.27	\N	13.0	0	0	0	0	0	0	0	2
8477	1	2017-02-28 01:44:02	0.0	0.0	0.0	\N	\N	\N	51.27	\N	13.0	0	0	0	0	0	0	0	2
8478	2	2017-02-28 02:08:02	0.0	0.0	0.0	0.0	0.0	0.0	50.57	0.0	13.2	0	0	0	0	0	0	0	2
8479	1	2017-02-28 02:15:02	0.0	0.0	0.0	\N	\N	\N	51.01	\N	13.0	0	0	0	0	0	0	0	2
8480	2	2017-02-28 02:39:02	0.0	0.0	0.0	0.0	0.0	0.0	50.88	0.0	13.1	0	0	0	0	0	0	0	2
8481	1	2017-02-28 02:46:02	0.0	0.0	0.0	\N	\N	\N	50.93	\N	13.0	0	0	0	0	0	0	0	2
8482	2	2017-02-28 03:10:02	0.0	0.0	0.0	0.0	0.0	0.0	50.29	0.0	13.1	0	0	0	0	0	0	0	2
8483	1	2017-02-28 03:17:02	0.0	0.0	0.0	\N	\N	\N	50.94	\N	13.0	0	0	0	0	0	0	0	2
8484	2	2017-02-28 03:41:02	0.0	0.0	0.0	0.0	0.0	0.0	50.45	0.0	13.0	0	0	0	0	0	0	0	2
8568	2	2017-02-28 22:48:02	0.0	0.0	0.0	0.0	0.0	0.0	53.05	0.0	13.6	0	0	0	0	0	0	0	2
8569	1	2017-02-28 22:55:02	0.0	0.0	0.0	\N	\N	\N	53.01	\N	12.8	0	0	0	0	0	0	0	2
8570	2	2017-02-28 23:19:02	0.0	0.0	0.0	0.0	0.0	0.0	52.23	0.0	13.5	0	0	0	0	0	0	0	2
8571	1	2017-02-28 23:26:02	0.0	0.0	0.0	\N	\N	\N	52.74	\N	12.8	0	0	0	0	0	0	0	2
8572	2	2017-02-28 23:50:02	0.0	0.0	0.0	0.0	0.0	0.0	51.66	0.0	13.3	0	0	0	0	0	0	0	2
8573	2	2017-02-28 23:50:02	0.0	0.0	0.0	\N	\N	\N	51.66	\N	13.3	0	0	0	0	0	0	0	2
8574	1	2017-02-28 23:57:02	0.0	0.0	0.0	\N	\N	\N	52.55	\N	12.8	0	0	0	0	0	0	0	2
8575	2	2017-03-01 00:21:02	0.0	0.0	0.0	0.0	0.0	0.0	51.19	0.0	13.2	0	0	0	0	0	0	0	2
8576	1	2017-03-01 00:28:02	0.0	0.0	0.0	\N	\N	\N	52.20	\N	12.8	0	0	0	0	0	0	0	2
8577	2	2017-03-01 00:52:02	0.0	0.0	0.0	0.0	0.0	0.0	51.17	0.0	13.3	0	0	0	0	0	0	0	2
8578	1	2017-03-01 00:59:02	0.0	0.0	0.0	\N	\N	\N	52.15	\N	12.8	0	0	0	0	0	0	0	2
8585	2	2017-03-01 02:56:02	0.0	0.0	0.0	0.0	0.0	0.0	50.47	0.0	13.0	0	0	0	0	0	0	0	2
8586	1	2017-03-01 03:03:02	0.0	0.0	0.0	\N	\N	\N	51.05	\N	12.8	0	0	0	0	0	0	0	2
8587	2	2017-03-01 03:27:02	0.0	0.0	0.0	0.0	0.0	0.0	50.12	0.0	12.9	0	0	0	0	0	0	0	2
8588	1	2017-03-01 03:34:02	0.0	0.0	0.0	\N	\N	\N	50.76	\N	12.7	0	0	0	0	0	0	0	2
8589	2	2017-03-01 03:58:02	0.0	0.0	0.0	0.0	0.0	0.0	49.85	0.0	12.9	0	0	0	0	0	0	0	2
8590	1	2017-03-01 04:05:02	0.0	0.0	0.0	\N	\N	\N	50.46	\N	12.7	0	0	0	0	0	0	0	2
8591	2	2017-03-01 04:29:02	0.0	0.0	0.0	0.0	0.0	0.0	49.13	0.0	12.8	0	0	0	0	0	0	0	2
8592	1	2017-03-01 04:36:02	0.0	0.0	0.0	\N	\N	\N	50.30	\N	12.7	0	0	0	0	0	0	0	2
8601	1	2017-03-01 06:40:02	0.0	0.0	0.0	\N	\N	\N	49.74	\N	12.7	0	0	0	0	0	0	0	2
8602	2	2017-03-01 07:04:02	222.3	221.7	222.6	0.0	0.0	0.0	51.38	0.0	13.8	1	1	1	0	0	0	0	2
8603	1	2017-03-01 07:11:02	0.0	0.0	0.0	\N	\N	\N	49.63	\N	12.7	0	0	0	0	0	0	0	2
8604	2	2017-03-01 07:35:02	220.3	219.7	220.6	0.0	0.0	0.0	52.72	0.0	14.0	1	1	1	0	0	0	0	2
8605	1	2017-03-01 07:42:02	0.0	0.0	0.0	\N	\N	\N	49.52	\N	12.7	0	0	0	0	0	0	0	2
8606	2	2017-03-01 08:06:02	221.2	220.6	221.5	0.0	0.0	0.0	53.78	0.0	14.1	1	1	1	0	0	0	0	2
8607	1	2017-03-01 08:13:02	0.0	0.0	0.0	\N	\N	\N	49.43	\N	12.7	0	0	0	0	0	0	0	2
8608	2	2017-03-01 08:37:02	222.6	222.0	222.9	0.0	0.0	0.0	56.16	0.0	14.5	1	1	1	0	0	0	0	2
8507	2	2017-02-28 08:51:02	222.3	221.7	222.6	0.0	0.0	0.0	55.35	0.0	14.5	1	1	1	0	0	0	0	2
8508	1	2017-02-28 08:58:02	0.0	0.0	0.0	\N	\N	\N	52.63	\N	12.8	0	0	0	0	0	0	0	2
8509	2	2017-02-28 09:22:02	221.4	220.8	221.7	0.0	0.0	0.0	55.70	0.0	14.4	1	1	1	0	0	0	0	2
8510	2	2017-02-28 09:23:56	0.0	0.0	0.0	0.0	0.0	0.0	55.22	0.0	14.5	0	0	0	0	0	0	0	2
8511	1	2017-02-28 09:29:02	0.0	0.0	0.0	\N	\N	\N	52.37	\N	12.8	0	0	0	0	0	0	0	2
8512	2	2017-02-28 09:53:02	0.0	0.0	0.0	0.0	0.0	0.0	54.84	0.0	14.1	0	0	0	0	0	0	0	2
8513	1	2017-02-28 10:00:07	0.0	0.0	0.0	\N	\N	\N	52.12	\N	12.8	0	0	0	0	0	0	0	2
8514	2	2017-02-28 10:24:02	0.0	0.0	0.0	0.0	0.0	0.0	53.87	0.0	13.9	0	0	0	0	0	0	0	2
8515	1	2017-02-28 10:31:02	0.0	0.0	0.0	\N	\N	\N	51.86	\N	12.8	0	0	0	0	0	0	0	2
8516	2	2017-02-28 10:55:02	0.0	0.0	0.0	0.0	0.0	0.0	53.34	0.0	13.7	0	0	0	0	0	0	0	2
8517	1	2017-02-28 11:02:02	0.0	0.0	0.0	\N	\N	\N	51.45	\N	12.7	0	0	0	0	0	0	0	2
8518	2	2017-02-28 11:26:02	0.0	0.0	0.0	0.0	0.0	0.0	52.94	0.0	13.5	0	0	0	0	0	0	0	2
8519	1	2017-02-28 11:33:02	0.0	0.0	0.0	\N	\N	\N	51.13	\N	12.7	0	0	0	0	0	0	0	2
8520	2	2017-02-28 11:57:02	0.0	0.0	0.0	0.0	0.0	0.0	51.93	0.0	13.4	0	0	0	0	0	0	0	2
8521	1	2017-02-28 12:04:02	0.0	0.0	0.0	\N	\N	\N	50.78	\N	12.7	0	0	0	0	0	0	0	2
8522	2	2017-02-28 12:28:02	0.0	0.0	0.0	0.0	0.0	0.0	51.41	0.0	13.3	0	0	0	0	0	0	0	2
8523	1	2017-02-28 12:35:02	0.0	0.0	0.0	\N	\N	\N	50.37	\N	12.8	0	0	0	0	0	0	0	2
8524	2	2017-02-28 12:59:02	0.0	0.0	0.0	0.0	0.0	0.0	51.11	0.0	13.2	0	0	0	0	0	0	0	2
8525	1	2017-02-28 13:06:02	0.0	0.0	0.0	\N	\N	\N	50.34	\N	12.7	0	0	0	0	0	0	0	2
8526	2	2017-02-28 13:30:02	0.0	0.0	0.0	0.0	0.0	0.0	50.79	0.0	13.2	0	0	0	0	0	0	0	2
8527	1	2017-02-28 13:37:02	0.0	0.0	0.0	\N	\N	\N	50.07	\N	12.7	0	0	0	0	0	0	0	2
8528	2	2017-02-28 14:01:02	0.0	0.0	0.0	0.0	0.0	0.0	50.44	0.0	13.2	0	0	0	0	0	0	0	2
8529	1	2017-02-28 14:08:02	0.0	0.0	0.0	\N	\N	\N	49.96	\N	12.7	0	0	0	0	0	0	0	2
8530	2	2017-02-28 14:32:02	0.0	0.0	0.0	0.0	0.0	0.0	50.18	0.0	13.1	0	0	0	0	0	0	0	2
8531	1	2017-02-28 14:39:02	0.0	0.0	0.0	\N	\N	\N	49.97	\N	12.7	0	0	0	0	0	0	0	2
8532	1	2017-02-28 14:39:02	0.0	0.0	0.0	\N	\N	\N	49.97	\N	12.7	0	0	0	0	0	0	0	2
8533	2	2017-02-28 15:03:01	0.0	0.0	0.0	0.0	0.0	0.0	50.09	0.0	13.0	0	0	0	0	0	0	0	2
8534	2	2017-02-28 15:03:01	0.0	0.0	0.0	\N	\N	\N	50.09	\N	13.0	0	0	0	0	0	0	0	2
8535	1	2017-02-28 15:10:02	0.0	0.0	0.0	\N	\N	\N	49.63	\N	12.7	0	0	0	0	0	0	0	2
8536	2	2017-02-28 15:34:02	0.0	0.0	0.0	0.0	0.0	0.0	49.95	0.0	13.1	0	0	0	0	0	0	0	2
8537	1	2017-02-28 15:41:02	0.0	0.0	0.0	\N	\N	\N	49.63	\N	12.7	0	0	0	0	0	0	0	2
8538	2	2017-02-28 16:05:02	0.0	0.0	0.0	0.0	0.0	0.0	50.21	0.0	13.0	0	0	0	0	0	0	0	2
8539	1	2017-02-28 16:12:02	0.0	0.0	0.0	\N	\N	\N	49.51	\N	12.7	0	0	0	0	0	0	0	2
8540	2	2017-02-28 16:36:02	0.0	0.0	0.0	0.0	0.0	0.0	49.08	0.0	12.7	0	0	0	0	0	0	0	2
8541	1	2017-02-28 16:43:02	0.0	0.0	0.0	\N	\N	\N	49.39	\N	12.7	0	0	0	0	0	0	0	2
8542	2	2017-02-28 17:07:02	0.0	0.0	0.0	0.0	0.0	0.0	48.47	0.0	12.7	0	0	0	0	0	0	0	2
8543	1	2017-02-28 17:14:02	0.0	0.0	0.0	\N	\N	\N	49.41	\N	12.7	0	0	0	0	0	0	0	2
8544	2	2017-02-28 17:38:02	0.0	0.0	0.0	0.0	0.0	0.0	48.50	0.0	12.7	0	0	0	0	0	0	0	2
8545	1	2017-02-28 17:45:02	0.0	0.0	0.0	\N	\N	\N	49.30	\N	12.7	0	0	0	0	0	0	0	2
8546	2	2017-02-28 18:09:02	0.0	0.0	0.0	0.0	0.0	0.0	48.22	0.0	12.6	0	0	0	0	0	0	0	2
8547	1	2017-02-28 18:16:02	0.0	0.0	0.0	\N	\N	\N	49.16	\N	12.6	0	0	0	0	0	0	0	2
8548	2	2017-02-28 18:23:56	217.1	216.5	217.4	0.0	0.0	0.0	47.25	0.0	12.6	1	1	1	0	0	0	0	2
8549	2	2017-02-28 18:40:02	222.7	222.1	223.0	0.0	0.0	0.0	50.84	0.0	13.5	1	1	1	0	0	0	0	2
8550	1	2017-02-28 18:47:02	0.0	0.0	0.0	\N	\N	\N	49.18	\N	12.7	0	0	0	0	0	0	0	2
8551	2	2017-02-28 19:11:01	221.5	220.9	221.8	0.0	0.0	0.0	52.41	0.0	13.9	1	1	1	0	0	0	0	2
8552	1	2017-02-28 19:18:02	0.0	0.0	0.0	\N	\N	\N	48.94	\N	12.7	0	0	0	0	0	0	0	2
8553	1	2017-02-28 19:25:01	214.5	213.9	214.8	\N	\N	\N	49.06	\N	12.0	1	1	1	0	0	0	0	2
8554	2	2017-02-28 19:42:02	221.6	221.0	221.9	0.0	0.0	0.0	53.50	0.0	14.0	1	1	1	0	0	0	0	2
8555	1	2017-02-28 19:49:02	216.4	215.8	216.7	\N	\N	\N	50.81	\N	14.3	1	1	1	0	0	0	0	2
8556	2	2017-02-28 20:13:02	221.8	221.2	222.1	0.0	0.0	0.0	54.76	0.0	14.3	1	1	1	0	0	0	0	2
8557	1	2017-02-28 20:20:02	217.9	217.3	218.2	\N	\N	\N	51.68	\N	14.4	1	1	1	0	0	0	0	2
8558	2	2017-02-28 20:44:02	222.3	221.7	222.6	0.0	0.0	0.0	56.25	0.0	14.7	1	1	1	0	0	0	0	2
8559	1	2017-02-28 20:51:02	219.0	218.4	219.3	\N	\N	\N	52.86	\N	14.6	1	1	1	0	0	0	0	2
8560	2	2017-02-28 20:59:34	0.0	0.0	0.0	0.0	0.0	0.0	54.91	0.0	14.3	0	0	0	0	0	0	0	2
8561	2	2017-02-28 21:15:02	0.0	0.0	0.0	0.0	0.0	0.0	54.48	0.0	14.1	0	0	0	0	0	0	0	2
8562	1	2017-02-28 21:22:02	230.7	230.1	231.0	\N	\N	\N	54.63	\N	14.5	1	1	1	0	0	0	0	2
8563	1	2017-02-28 21:27:39	0.0	0.0	0.0	\N	\N	\N	53.82	\N	14.1	0	0	0	0	0	0	0	2
8564	2	2017-02-28 21:46:02	0.0	0.0	0.0	0.0	0.0	0.0	53.95	0.0	14.0	0	0	0	0	0	0	0	2
8565	1	2017-02-28 21:53:02	0.0	0.0	0.0	\N	\N	\N	53.56	\N	13.2	0	0	0	0	0	0	0	2
8566	2	2017-02-28 22:17:02	0.0	0.0	0.0	0.0	0.0	0.0	52.97	0.0	13.8	0	0	0	0	0	0	0	2
8567	1	2017-02-28 22:24:02	0.0	0.0	0.0	\N	\N	\N	53.18	\N	12.9	0	0	0	0	0	0	0	2
8579	2	2017-03-01 01:23:02	0.0	0.0	0.0	0.0	0.0	0.0	50.71	0.0	13.1	0	0	0	0	0	0	0	2
8580	1	2017-03-01 01:30:02	0.0	0.0	0.0	\N	\N	\N	51.90	\N	12.8	0	0	0	0	0	0	0	2
8581	2	2017-03-01 01:54:02	0.0	0.0	0.0	0.0	0.0	0.0	50.39	0.0	13.2	0	0	0	0	0	0	0	2
8582	1	2017-03-01 02:01:02	0.0	0.0	0.0	\N	\N	\N	51.76	\N	12.8	0	0	0	0	0	0	0	2
8583	2	2017-03-01 02:25:02	0.0	0.0	0.0	0.0	0.0	0.0	50.14	0.0	13.1	0	0	0	0	0	0	0	2
8584	1	2017-03-01 02:32:02	0.0	0.0	0.0	\N	\N	\N	51.47	\N	12.7	0	0	0	0	0	0	0	2
8593	2	2017-03-01 05:00:07	0.0	0.0	0.0	0.0	0.0	0.0	48.85	0.0	12.8	0	0	0	0	0	0	0	2
8594	1	2017-03-01 05:07:02	0.0	0.0	0.0	\N	\N	\N	50.08	\N	12.7	0	0	0	0	0	0	0	2
8595	2	2017-03-01 05:31:02	0.0	0.0	0.0	0.0	0.0	0.0	48.80	0.0	12.7	0	0	0	0	0	0	0	2
8596	1	2017-03-01 05:38:02	0.0	0.0	0.0	\N	\N	\N	50.18	\N	12.7	0	0	0	0	0	0	0	2
8597	2	2017-03-01 06:02:02	0.0	0.0	0.0	0.0	0.0	0.0	48.40	0.0	12.6	0	0	0	0	0	0	0	2
8598	1	2017-03-01 06:09:02	0.0	0.0	0.0	\N	\N	\N	49.92	\N	12.7	0	0	0	0	0	0	0	2
8599	2	2017-03-01 06:30:25	197.7	197.1	198.0	0.0	0.0	0.0	47.13	0.0	12.2	1	1	1	0	0	0	0	2
8600	2	2017-03-01 06:33:02	221.9	221.3	222.2	0.0	0.0	0.0	49.77	0.0	13.3	1	1	1	0	0	0	0	2
8617	2	2017-03-01 10:41:02	0.0	0.0	0.0	0.0	0.0	0.0	53.36	0.0	13.8	0	0	0	0	0	0	0	2
8610	2	2017-03-01 09:06:09	0.0	0.0	0.0	0.0	0.0	0.0	54.94	0.0	14.2	0	0	0	0	0	0	0	2
8611	2	2017-03-01 09:08:02	0.0	0.0	0.0	0.0	0.0	0.0	54.88	0.0	14.4	0	0	0	0	0	0	0	2
8612	1	2017-03-01 09:15:02	0.0	0.0	0.0	\N	\N	\N	49.20	\N	12.7	0	0	0	0	0	0	0	2
8613	2	2017-03-01 09:39:02	0.0	0.0	0.0	0.0	0.0	0.0	53.94	0.0	14.0	0	0	0	0	0	0	0	2
8614	1	2017-03-01 09:46:02	0.0	0.0	0.0	\N	\N	\N	49.20	\N	12.7	0	0	0	0	0	0	0	2
8615	2	2017-03-01 10:10:02	0.0	0.0	0.0	0.0	0.0	0.0	53.83	0.0	13.8	0	0	0	0	0	0	0	2
8616	1	2017-03-01 10:17:02	0.0	0.0	0.0	\N	\N	\N	49.13	\N	12.6	0	0	0	0	0	0	0	2
8626	2	2017-03-01 12:45:02	0.0	0.0	0.0	0.0	0.0	0.0	50.99	0.0	13.3	0	0	0	0	0	0	0	2
8627	1	2017-03-01 12:51:23	0.0	0.0	0.0	\N	\N	\N	53.91	\N	13.9	0	0	0	0	0	0	0	2
8632	2	2017-03-01 13:47:02	0.0	0.0	0.0	0.0	0.0	0.0	50.87	0.0	13.2	0	0	0	0	0	0	0	2
8633	1	2017-03-01 13:54:02	0.0	0.0	0.0	\N	\N	\N	53.11	\N	12.9	0	0	0	0	0	0	0	2
8634	2	2017-03-01 14:18:02	0.0	0.0	0.0	0.0	0.0	0.0	50.32	0.0	13.1	0	0	0	0	0	0	0	2
8635	1	2017-03-01 14:25:02	0.0	0.0	0.0	\N	\N	\N	53.05	\N	12.9	0	0	0	0	0	0	0	2
8636	2	2017-03-01 14:49:02	0.0	0.0	0.0	0.0	0.0	0.0	50.34	0.0	13.0	0	0	0	0	0	0	0	2
8637	1	2017-03-01 14:56:02	0.0	0.0	0.0	\N	\N	\N	52.87	\N	12.8	0	0	0	0	0	0	0	2
8638	2	2017-03-01 15:20:02	0.0	0.0	0.0	0.0	0.0	0.0	49.91	0.0	13.0	0	0	0	0	0	0	0	2
8639	2	2017-03-01 15:20:02	0.0	0.0	0.0	\N	\N	\N	49.91	\N	13.0	0	0	0	0	0	0	0	2
8640	1	2017-03-01 15:27:02	0.0	0.0	0.0	\N	\N	\N	52.51	\N	12.8	0	0	0	0	0	0	0	2
8648	1	2017-03-01 17:31:02	0.0	0.0	0.0	\N	\N	\N	51.55	\N	12.8	0	0	0	0	0	0	0	2
8649	2	2017-03-01 17:55:02	0.0	0.0	0.0	0.0	0.0	0.0	47.95	0.0	12.6	0	0	0	0	0	0	0	2
8650	1	2017-03-01 18:02:02	0.0	0.0	0.0	\N	\N	\N	51.34	\N	12.7	0	0	0	0	0	0	0	2
8651	2	2017-03-01 18:19:34	201.1	200.5	201.4	0.0	0.0	0.0	47.34	0.0	12.3	1	1	1	0	0	0	0	2
8652	2	2017-03-01 18:26:01	224.0	223.4	224.3	0.0	0.0	0.0	50.41	0.0	13.4	1	1	1	0	0	0	0	2
8653	1	2017-03-01 18:33:02	0.0	0.0	0.0	\N	\N	\N	50.73	\N	12.8	0	0	0	0	0	0	0	2
8654	2	2017-03-01 18:57:01	223.5	222.9	223.8	0.0	0.0	0.0	52.20	0.0	13.7	1	1	1	0	0	0	0	2
8655	1	2017-03-01 19:04:02	0.0	0.0	0.0	\N	\N	\N	50.61	\N	12.7	0	0	0	0	0	0	0	2
8656	2	2017-03-01 19:28:02	220.2	219.6	220.5	0.0	0.0	0.0	52.99	0.0	13.9	1	1	1	0	0	0	0	2
8657	1	2017-03-01 19:35:02	0.0	0.0	0.0	\N	\N	\N	50.37	\N	12.7	0	0	0	0	0	0	0	2
8658	2	2017-03-01 19:59:02	222.1	221.5	222.4	0.0	0.0	0.0	54.29	0.0	14.1	1	1	1	0	0	0	0	2
8659	1	2017-03-01 20:06:02	0.0	0.0	0.0	\N	\N	\N	50.05	\N	12.7	0	0	0	0	0	0	0	2
8660	2	2017-03-01 20:30:02	221.4	220.8	221.7	0.0	0.0	0.0	55.54	0.0	14.6	1	1	1	0	0	0	0	2
8661	1	2017-03-01 20:37:02	0.0	0.0	0.0	\N	\N	\N	49.98	\N	12.7	0	0	0	0	0	0	0	2
8662	2	2017-03-01 20:55:16	0.0	0.0	0.0	0.0	0.0	0.0	54.89	0.0	14.4	0	0	0	0	0	0	0	2
8674	1	2017-03-01 23:43:02	0.0	0.0	0.0	\N	\N	\N	49.41	\N	12.7	0	0	0	0	0	0	0	2
8675	2	2017-03-02 00:07:02	0.0	0.0	0.0	0.0	0.0	0.0	51.25	0.0	13.3	0	0	0	0	0	0	0	2
8676	1	2017-03-02 00:14:02	0.0	0.0	0.0	\N	\N	\N	49.27	\N	12.7	0	0	0	0	0	0	0	2
8677	2	2017-03-02 00:38:02	0.0	0.0	0.0	0.0	0.0	0.0	51.29	0.0	13.3	0	0	0	0	0	0	0	2
8678	1	2017-03-02 00:45:02	0.0	0.0	0.0	\N	\N	\N	49.30	\N	12.7	0	0	0	0	0	0	0	2
8679	2	2017-03-02 01:09:02	0.0	0.0	0.0	0.0	0.0	0.0	51.20	0.0	13.2	0	0	0	0	0	0	0	2
8680	1	2017-03-02 01:16:02	0.0	0.0	0.0	\N	\N	\N	49.15	\N	12.7	0	0	0	0	0	0	0	2
8681	2	2017-03-02 01:40:02	0.0	0.0	0.0	0.0	0.0	0.0	50.85	0.0	9.9	0	0	0	0	0	0	0	2
8682	1	2017-03-02 01:47:02	0.0	0.0	0.0	\N	\N	\N	49.04	\N	12.7	0	0	0	0	0	0	0	2
8683	2	2017-03-02 02:11:02	0.0	0.0	0.0	0.0	0.0	0.0	50.30	0.0	10.2	0	0	0	0	0	0	0	2
8684	1	2017-03-02 02:12:36	216.7	216.1	217.0	\N	\N	\N	49.00	\N	12.5	1	1	1	0	0	0	0	2
8685	1	2017-03-02 02:18:02	221.4	220.8	221.7	\N	\N	\N	50.61	\N	14.3	1	1	1	0	0	0	0	2
8686	2	2017-03-02 02:42:02	0.0	0.0	0.0	0.0	0.0	0.0	50.32	0.0	12.7	0	0	0	0	0	0	0	2
8687	1	2017-03-02 02:49:01	220.2	219.6	220.5	\N	\N	\N	51.63	\N	14.4	1	1	1	0	0	0	0	2
8688	2	2017-03-02 03:13:02	0.0	0.0	0.0	0.0	0.0	0.0	50.24	0.0	13.1	0	0	0	0	0	0	0	2
8689	1	2017-03-02 03:20:02	222.3	221.7	222.6	\N	\N	\N	52.66	\N	14.7	1	1	1	0	0	0	0	2
8690	2	2017-03-02 03:44:02	0.0	0.0	0.0	0.0	0.0	0.0	49.82	0.0	13.0	0	0	0	0	0	0	0	2
8691	1	2017-03-02 03:51:02	226.3	225.7	226.6	\N	\N	\N	54.17	\N	14.6	1	1	1	0	0	0	0	2
8692	2	2017-03-02 04:15:02	0.0	0.0	0.0	0.0	0.0	0.0	49.37	0.0	12.9	0	0	0	0	0	0	0	2
8693	1	2017-03-02 04:15:14	0.0	0.0	0.0	\N	\N	\N	53.73	\N	14.1	0	0	0	0	0	0	0	2
8702	2	2017-03-02 06:25:48	200.0	199.4	200.3	0.0	0.0	0.0	47.21	0.0	12.3	1	1	1	0	0	0	0	2
8718	1	2017-03-02 10:03:02	0.0	0.0	0.0	\N	\N	\N	51.62	\N	13.0	0	0	0	0	0	0	0	2
8719	2	2017-03-02 10:27:02	0.0	0.0	0.0	0.0	0.0	0.0	53.31	0.0	13.7	0	0	0	0	0	0	0	2
8720	1	2017-03-02 10:34:02	0.0	0.0	0.0	\N	\N	\N	51.47	\N	13.1	0	0	0	0	0	0	0	2
8618	1	2017-03-01 10:48:02	0.0	0.0	0.0	\N	\N	\N	49.10	\N	12.7	0	0	0	0	0	0	0	2
8619	2	2017-03-01 11:12:02	0.0	0.0	0.0	0.0	0.0	0.0	52.27	0.0	13.5	0	0	0	0	0	0	0	2
8620	1	2017-03-01 11:19:02	219.4	218.8	219.7	\N	\N	\N	51.08	\N	14.5	1	1	1	0	0	0	0	2
8621	2	2017-03-01 11:43:02	0.0	0.0	0.0	0.0	0.0	0.0	51.80	0.0	13.4	0	0	0	0	0	0	0	2
8622	2	2017-03-01 11:43:02	0.0	0.0	0.0	\N	\N	\N	51.80	\N	13.4	0	0	0	0	0	0	0	2
8623	1	2017-03-01 11:50:02	225.0	224.4	225.3	\N	\N	\N	51.51	\N	14.8	1	1	1	0	0	0	0	2
8624	2	2017-03-01 12:14:02	0.0	0.0	0.0	0.0	0.0	0.0	51.64	0.0	13.2	0	0	0	0	0	0	0	2
8625	1	2017-03-01 12:21:02	217.9	217.3	218.2	\N	\N	\N	53.96	\N	14.5	1	1	1	0	0	0	0	2
8628	1	2017-03-01 12:51:23	0.0	0.0	0.0	\N	\N	\N	53.91	\N	13.9	0	0	0	0	0	0	0	2
8629	1	2017-03-01 12:52:23	0.0	0.0	0.0	\N	\N	\N	54.03	\N	13.7	0	0	0	0	0	0	0	2
8630	2	2017-03-01 13:16:02	0.0	0.0	0.0	0.0	0.0	0.0	51.01	0.0	13.4	0	0	0	0	0	0	0	2
8631	1	2017-03-01 13:23:02	0.0	0.0	0.0	\N	\N	\N	53.59	\N	13.1	0	0	0	0	0	0	0	2
8641	2	2017-03-01 15:51:02	0.0	0.0	0.0	0.0	0.0	0.0	49.78	0.0	13.0	0	0	0	0	0	0	0	2
8642	1	2017-03-01 15:58:02	0.0	0.0	0.0	\N	\N	\N	52.25	\N	12.8	0	0	0	0	0	0	0	2
8643	2	2017-03-01 16:22:02	0.0	0.0	0.0	0.0	0.0	0.0	49.16	0.0	12.8	0	0	0	0	0	0	0	2
8644	1	2017-03-01 16:29:02	0.0	0.0	0.0	\N	\N	\N	51.91	\N	12.8	0	0	0	0	0	0	0	2
8645	2	2017-03-01 16:53:02	0.0	0.0	0.0	0.0	0.0	0.0	48.78	0.0	12.6	0	0	0	0	0	0	0	2
8646	1	2017-03-01 17:00:07	0.0	0.0	0.0	\N	\N	\N	51.88	\N	12.8	0	0	0	0	0	0	0	2
8647	2	2017-03-01 17:24:02	0.0	0.0	0.0	0.0	0.0	0.0	48.53	0.0	12.6	0	0	0	0	0	0	0	2
8663	2	2017-03-01 21:01:02	0.0	0.0	0.0	0.0	0.0	0.0	55.20	0.0	14.4	0	0	0	0	0	0	0	2
8664	1	2017-03-01 21:08:02	0.0	0.0	0.0	\N	\N	\N	49.89	\N	12.7	0	0	0	0	0	0	0	2
8665	2	2017-03-01 21:32:02	0.0	0.0	0.0	0.0	0.0	0.0	54.52	0.0	13.9	0	0	0	0	0	0	0	2
8666	1	2017-03-01 21:39:02	0.0	0.0	0.0	\N	\N	\N	49.93	\N	12.7	0	0	0	0	0	0	0	2
8667	2	2017-03-01 22:03:02	0.0	0.0	0.0	0.0	0.0	0.0	53.55	0.0	13.7	0	0	0	0	0	0	0	2
8668	1	2017-03-01 22:10:02	0.0	0.0	0.0	\N	\N	\N	49.70	\N	12.7	0	0	0	0	0	0	0	2
8669	2	2017-03-01 22:34:02	0.0	0.0	0.0	0.0	0.0	0.0	52.86	0.0	13.7	0	0	0	0	0	0	0	2
8670	1	2017-03-01 22:41:02	0.0	0.0	0.0	\N	\N	\N	49.60	\N	12.7	0	0	0	0	0	0	0	2
8671	2	2017-03-01 23:05:02	0.0	0.0	0.0	0.0	0.0	0.0	51.93	0.0	13.3	0	0	0	0	0	0	0	2
8672	1	2017-03-01 23:12:02	0.0	0.0	0.0	\N	\N	\N	49.55	\N	12.7	0	0	0	0	0	0	0	2
8673	2	2017-03-01 23:36:02	0.0	0.0	0.0	0.0	0.0	0.0	51.63	0.0	13.4	0	0	0	0	0	0	0	2
8694	1	2017-03-02 04:22:02	0.0	0.0	0.0	\N	\N	\N	54.82	\N	13.8	0	0	0	0	0	0	0	2
8695	2	2017-03-02 04:46:02	0.0	0.0	0.0	0.0	0.0	0.0	49.06	0.0	12.7	0	0	0	0	0	0	0	2
8696	1	2017-03-02 04:53:02	0.0	0.0	0.0	\N	\N	\N	54.41	\N	13.3	0	0	0	0	0	0	0	2
8697	2	2017-03-02 05:17:02	0.0	0.0	0.0	0.0	0.0	0.0	48.60	0.0	12.7	0	0	0	0	0	0	0	2
8698	1	2017-03-02 05:24:02	0.0	0.0	0.0	\N	\N	\N	54.24	\N	13.2	0	0	0	0	0	0	0	2
8699	2	2017-03-02 05:48:02	0.0	0.0	0.0	0.0	0.0	0.0	48.24	0.0	12.7	0	0	0	0	0	0	0	2
8700	1	2017-03-02 05:55:02	0.0	0.0	0.0	\N	\N	\N	54.14	\N	13.2	0	0	0	0	0	0	0	2
8701	2	2017-03-02 06:19:02	0.0	0.0	0.0	0.0	0.0	0.0	47.79	0.0	12.5	0	0	0	0	0	0	0	2
8703	1	2017-03-02 06:26:02	0.0	0.0	0.0	\N	\N	\N	53.54	\N	13.1	0	0	0	0	0	0	0	2
8704	2	2017-03-02 06:50:02	221.5	220.9	221.8	0.0	0.0	0.0	51.52	0.0	13.6	1	1	1	0	0	0	0	2
8705	1	2017-03-02 06:57:02	0.0	0.0	0.0	\N	\N	\N	53.40	\N	13.1	0	0	0	0	0	0	0	2
8706	2	2017-03-02 07:21:02	220.6	220.0	220.9	0.0	0.0	0.0	52.65	0.0	13.8	1	1	1	0	0	0	0	2
8707	1	2017-03-02 07:28:02	0.0	0.0	0.0	\N	\N	\N	53.18	\N	13.1	0	0	0	0	0	0	0	2
8708	2	2017-03-02 07:52:02	219.5	218.9	219.8	0.0	0.0	0.0	53.46	0.0	14.1	1	1	1	0	0	0	0	2
8709	1	2017-03-02 07:59:02	0.0	0.0	0.0	\N	\N	\N	53.06	\N	13.1	0	0	0	0	0	0	0	2
8710	2	2017-03-02 08:23:02	218.2	217.6	218.5	0.0	0.0	0.0	55.34	0.0	14.4	1	1	1	0	0	0	0	2
8711	1	2017-03-02 08:30:02	0.0	0.0	0.0	\N	\N	\N	52.87	\N	13.1	0	0	0	0	0	0	0	2
8712	2	2017-03-02 08:54:02	221.2	220.6	221.5	0.0	0.0	0.0	56.63	0.0	14.6	1	1	1	0	0	0	0	2
8713	1	2017-03-02 09:01:02	0.0	0.0	0.0	\N	\N	\N	52.51	\N	13.1	0	0	0	0	0	0	0	2
8714	2	2017-03-02 09:01:35	0.0	0.0	0.0	0.0	0.0	0.0	55.04	0.0	14.5	0	0	0	0	0	0	0	2
8715	2	2017-03-02 09:25:02	0.0	0.0	0.0	0.0	0.0	0.0	54.51	0.0	14.0	0	0	0	0	0	0	0	2
8716	1	2017-03-02 09:32:02	0.0	0.0	0.0	\N	\N	\N	52.01	\N	13.1	0	0	0	0	0	0	0	2
8717	2	2017-03-02 09:56:02	0.0	0.0	0.0	0.0	0.0	0.0	54.10	0.0	14.1	0	0	0	0	0	0	0	2
8721	2	2017-03-02 10:58:02	0.0	0.0	0.0	0.0	0.0	0.0	53.21	0.0	13.7	0	0	0	0	0	0	0	2
8722	1	2017-03-02 11:05:02	0.0	0.0	0.0	\N	\N	\N	51.25	\N	13.0	0	0	0	0	0	0	0	2
8723	2	2017-03-02 11:29:02	0.0	0.0	0.0	0.0	0.0	0.0	52.11	0.0	13.4	0	0	0	0	0	0	0	2
8724	1	2017-03-02 11:36:02	0.0	0.0	0.0	\N	\N	\N	50.91	\N	13.1	0	0	0	0	0	0	0	2
8725	2	2017-03-02 12:00:07	0.0	0.0	0.0	0.0	0.0	0.0	51.20	0.0	13.4	0	0	0	0	0	0	0	2
8726	1	2017-03-02 12:07:02	0.0	0.0	0.0	\N	\N	\N	50.97	\N	13.0	0	0	0	0	0	0	0	2
8727	2	2017-03-02 12:31:02	0.0	0.0	0.0	0.0	0.0	0.0	51.45	0.0	13.2	0	0	0	0	0	0	0	2
8728	1	2017-03-02 12:38:02	0.0	0.0	0.0	\N	\N	\N	50.92	\N	13.1	0	0	0	0	0	0	0	2
8729	2	2017-03-02 13:02:02	0.0	0.0	0.0	0.0	0.0	0.0	50.68	0.0	13.2	0	0	0	0	0	0	0	2
8730	1	2017-03-02 13:09:02	0.0	0.0	0.0	\N	\N	\N	50.77	\N	13.0	0	0	0	0	0	0	0	2
8731	2	2017-03-02 13:33:02	0.0	0.0	0.0	0.0	0.0	0.0	50.84	0.0	13.3	0	0	0	0	0	0	0	2
8732	1	2017-03-02 13:40:02	0.0	0.0	0.0	\N	\N	\N	50.67	\N	13.0	0	0	0	0	0	0	0	2
8733	2	2017-03-02 14:04:02	0.0	0.0	0.0	0.0	0.0	0.0	50.40	0.0	13.1	0	0	0	0	0	0	0	2
8734	1	2017-03-02 14:11:02	0.0	0.0	0.0	\N	\N	\N	50.61	\N	13.0	0	0	0	0	0	0	0	2
8735	2	2017-03-02 14:35:02	0.0	0.0	0.0	0.0	0.0	0.0	50.24	0.0	13.1	0	0	0	0	0	0	0	2
8736	1	2017-03-02 14:42:02	0.0	0.0	0.0	\N	\N	\N	50.50	\N	13.0	0	0	0	0	0	0	0	2
8737	2	2017-03-02 15:06:02	0.0	0.0	0.0	0.0	0.0	0.0	49.97	0.0	13.1	0	0	0	0	0	0	0	2
8738	1	2017-03-02 15:13:02	0.0	0.0	0.0	\N	\N	\N	50.40	\N	13.0	0	0	0	0	0	0	0	2
8739	2	2017-03-02 15:37:02	0.0	0.0	0.0	0.0	0.0	0.0	49.81	0.0	13.0	0	0	0	0	0	0	0	2
8740	1	2017-03-02 15:44:02	0.0	0.0	0.0	\N	\N	\N	50.16	\N	13.0	0	0	0	0	0	0	0	2
8741	2	2017-03-02 16:08:02	0.0	0.0	0.0	0.0	0.0	0.0	49.36	0.0	12.9	0	0	0	0	0	0	0	2
8742	1	2017-03-02 16:15:02	0.0	0.0	0.0	\N	\N	\N	50.27	\N	13.0	0	0	0	0	0	0	0	2
8743	2	2017-03-02 16:39:02	0.0	0.0	0.0	0.0	0.0	0.0	49.02	0.0	12.8	0	0	0	0	0	0	0	2
8744	1	2017-03-02 16:46:02	0.0	0.0	0.0	\N	\N	\N	50.03	\N	13.0	0	0	0	0	0	0	0	2
8745	2	2017-03-02 17:10:02	0.0	0.0	0.0	0.0	0.0	0.0	48.50	0.0	12.8	0	0	0	0	0	0	0	2
8746	1	2017-03-02 17:17:02	0.0	0.0	0.0	\N	\N	\N	50.12	\N	13.0	0	0	0	0	0	0	0	2
8747	2	2017-03-02 17:41:02	0.0	0.0	0.0	0.0	0.0	0.0	47.79	0.0	12.5	0	0	0	0	0	0	0	2
8748	1	2017-03-02 17:48:02	224.1	223.5	224.4	\N	\N	\N	51.60	\N	14.6	1	1	1	0	0	0	0	2
8749	2	2017-03-02 18:03:39	215.1	214.5	215.4	0.0	0.0	0.0	47.23	0.0	12.7	1	1	1	0	0	0	0	2
8750	2	2017-03-02 18:12:02	222.6	222.0	222.9	0.0	0.0	0.0	50.59	0.0	13.5	1	1	1	0	0	0	0	2
8751	1	2017-03-02 18:19:02	219.6	219.0	219.9	\N	\N	\N	53.51	\N	14.9	1	1	1	0	0	0	0	2
8752	2	2017-03-02 18:43:02	218.7	218.1	219.0	0.0	0.0	0.0	52.19	0.0	13.8	1	1	1	0	0	0	0	2
8753	1	2017-03-02 18:50:02	226.6	226.0	226.9	\N	\N	\N	54.08	\N	14.8	1	1	1	0	0	0	0	2
8754	2	2017-03-02 19:14:02	223.2	222.6	223.5	0.0	0.0	0.0	53.11	0.0	13.9	1	1	1	0	0	0	0	2
8755	1	2017-03-02 19:21:02	220.3	219.7	220.6	\N	\N	\N	54.83	\N	14.8	1	1	1	0	0	0	0	2
8756	2	2017-03-02 19:45:02	223.9	223.3	224.2	0.0	0.0	0.0	54.44	0.0	14.2	1	1	1	0	0	0	0	2
8757	1	2017-03-02 19:52:02	0.0	0.0	0.0	\N	\N	\N	54.46	\N	13.6	0	0	0	0	0	0	0	2
8758	2	2017-03-02 20:16:02	220.1	219.5	220.4	0.0	0.0	0.0	56.08	0.0	14.7	1	1	1	0	0	0	0	2
8759	1	2017-03-02 20:23:02	0.0	0.0	0.0	\N	\N	\N	54.23	\N	13.3	0	0	0	0	0	0	0	2
8760	2	2017-03-02 20:39:17	0.0	0.0	0.0	0.0	0.0	0.0	55.19	0.0	14.3	0	0	0	0	0	0	0	2
8761	2	2017-03-02 20:47:02	0.0	0.0	0.0	0.0	0.0	0.0	55.03	0.0	14.1	0	0	0	0	0	0	0	2
8762	1	2017-03-02 20:54:02	0.0	0.0	0.0	\N	\N	\N	54.00	\N	13.2	0	0	0	0	0	0	0	2
8763	2	2017-03-02 21:18:02	0.0	0.0	0.0	0.0	0.0	0.0	54.33	0.0	13.9	0	0	0	0	0	0	0	2
8764	1	2017-03-02 21:25:02	0.0	0.0	0.0	\N	\N	\N	53.82	\N	13.1	0	0	0	0	0	0	0	2
8765	2	2017-03-02 21:49:02	0.0	0.0	0.0	0.0	0.0	0.0	53.58	0.0	13.8	0	0	0	0	0	0	0	2
8766	1	2017-03-02 21:56:02	0.0	0.0	0.0	\N	\N	\N	53.49	\N	13.1	0	0	0	0	0	0	0	2
8767	2	2017-03-02 22:20:02	0.0	0.0	0.0	0.0	0.0	0.0	53.11	0.0	13.7	0	0	0	0	0	0	0	2
8768	1	2017-03-02 22:27:02	0.0	0.0	0.0	\N	\N	\N	53.23	\N	13.1	0	0	0	0	0	0	0	2
8769	2	2017-03-02 22:51:02	0.0	0.0	0.0	0.0	0.0	0.0	52.18	0.0	13.2	0	0	0	0	0	0	0	2
8770	1	2017-03-02 22:58:02	0.0	0.0	0.0	\N	\N	\N	52.91	\N	13.1	0	0	0	0	0	0	0	2
8771	2	2017-03-02 23:22:02	0.0	0.0	0.0	0.0	0.0	0.0	51.65	0.0	13.4	0	0	0	0	0	0	0	2
8772	1	2017-03-02 23:29:02	0.0	0.0	0.0	\N	\N	\N	52.74	\N	13.1	0	0	0	0	0	0	0	2
8773	2	2017-03-02 23:53:02	0.0	0.0	0.0	0.0	0.0	0.0	50.88	0.0	13.3	0	0	0	0	0	0	0	2
8774	1	2017-03-03 00:00:07	0.0	0.0	0.0	\N	\N	\N	52.42	\N	13.1	0	0	0	0	0	0	0	2
8775	2	2017-03-03 00:24:02	0.0	0.0	0.0	0.0	0.0	0.0	50.70	0.0	13.2	0	0	0	0	0	0	0	2
8776	1	2017-03-03 00:31:02	0.0	0.0	0.0	\N	\N	\N	52.13	\N	13.1	0	0	0	0	0	0	0	2
8777	2	2017-03-03 00:55:02	0.0	0.0	0.0	0.0	0.0	0.0	50.12	0.0	13.2	0	0	0	0	0	0	0	2
8778	1	2017-03-03 01:02:02	0.0	0.0	0.0	\N	\N	\N	51.68	\N	13.1	0	0	0	0	0	0	0	2
8779	2	2017-03-03 01:26:02	0.0	0.0	0.0	0.0	0.0	0.0	50.83	0.0	13.3	0	0	0	0	0	0	0	2
8780	1	2017-03-03 01:33:02	0.0	0.0	0.0	\N	\N	\N	51.53	\N	13.1	0	0	0	0	0	0	0	2
8781	2	2017-03-03 01:57:02	0.0	0.0	0.0	0.0	0.0	0.0	50.41	0.0	13.0	0	0	0	0	0	0	0	2
8782	1	2017-03-03 02:04:02	0.0	0.0	0.0	\N	\N	\N	51.29	\N	13.0	0	0	0	0	0	0	0	2
8783	2	2017-03-03 02:28:02	0.0	0.0	0.0	0.0	0.0	0.0	50.25	0.0	13.1	0	0	0	0	0	0	0	2
8784	1	2017-03-03 02:35:02	0.0	0.0	0.0	\N	\N	\N	51.36	\N	13.0	0	0	0	0	0	0	0	2
8785	2	2017-03-03 02:59:02	0.0	0.0	0.0	0.0	0.0	0.0	49.88	0.0	13.0	0	0	0	0	0	0	0	2
8786	1	2017-03-03 03:06:02	0.0	0.0	0.0	\N	\N	\N	51.08	\N	13.0	0	0	0	0	0	0	0	2
8787	2	2017-03-03 03:30:02	0.0	0.0	0.0	0.0	0.0	0.0	49.91	0.0	12.9	0	0	0	0	0	0	0	2
8788	1	2017-03-03 03:37:02	0.0	0.0	0.0	\N	\N	\N	50.93	\N	13.0	0	0	0	0	0	0	0	2
8789	2	2017-03-03 04:01:02	0.0	0.0	0.0	0.0	0.0	0.0	49.43	0.0	12.6	0	0	0	0	0	0	0	2
8790	1	2017-03-03 04:08:02	0.0	0.0	0.0	\N	\N	\N	50.93	\N	13.0	0	0	0	0	0	0	0	2
8791	2	2017-03-03 04:32:02	0.0	0.0	0.0	0.0	0.0	0.0	49.22	0.0	12.1	0	0	0	0	0	0	0	2
8792	1	2017-03-03 04:39:02	0.0	0.0	0.0	\N	\N	\N	50.77	\N	13.0	0	0	0	0	0	0	0	2
8793	2	2017-03-03 05:03:02	0.0	0.0	0.0	0.0	0.0	0.0	48.27	0.0	12.5	0	0	0	0	0	0	0	2
8794	1	2017-03-03 05:10:02	0.0	0.0	0.0	\N	\N	\N	50.71	\N	13.0	0	0	0	0	0	0	0	2
8795	2	2017-03-03 05:34:02	0.0	0.0	0.0	0.0	0.0	0.0	48.37	0.0	12.6	0	0	0	0	0	0	0	2
8796	1	2017-03-03 05:41:02	0.0	0.0	0.0	\N	\N	\N	50.66	\N	13.0	0	0	0	0	0	0	0	2
8797	2	2017-03-03 06:05:02	0.0	0.0	0.0	0.0	0.0	0.0	47.75	0.0	12.6	0	0	0	0	0	0	0	2
8798	2	2017-03-03 06:09:55	217.1	216.5	217.4	0.0	0.0	0.0	47.93	0.0	12.7	1	1	1	0	0	0	0	2
8799	1	2017-03-03 06:12:02	0.0	0.0	0.0	\N	\N	\N	50.59	\N	13.0	0	0	0	0	0	0	0	2
8800	2	2017-03-03 06:36:02	222.7	222.1	223.0	0.0	0.0	0.0	50.59	0.0	13.2	1	1	1	0	0	0	0	2
8801	1	2017-03-03 06:43:02	0.0	0.0	0.0	\N	\N	\N	50.40	\N	13.0	0	0	0	0	0	0	0	2
8802	2	2017-03-03 07:07:02	220.5	219.9	220.8	0.0	0.0	0.0	51.69	0.0	13.6	1	1	1	0	0	0	0	2
8803	1	2017-03-03 07:14:02	0.0	0.0	0.0	\N	\N	\N	50.43	\N	13.0	0	0	0	0	0	0	0	2
8804	2	2017-03-03 07:38:02	218.9	218.3	219.2	0.0	0.0	0.0	52.45	0.0	13.9	1	1	1	0	0	0	0	2
8805	1	2017-03-03 07:45:02	0.0	0.0	0.0	\N	\N	\N	50.31	\N	13.0	0	0	0	0	0	0	0	2
8806	2	2017-03-03 08:09:02	223.7	223.1	224.0	0.0	0.0	0.0	54.26	0.0	14.2	1	1	1	0	0	0	0	2
8807	1	2017-03-03 08:16:02	0.0	0.0	0.0	\N	\N	\N	50.13	\N	13.0	0	0	0	0	0	0	0	2
8808	2	2017-03-03 08:40:02	221.8	221.2	222.1	0.0	0.0	0.0	55.26	0.0	14.4	1	1	1	0	0	0	0	2
8809	2	2017-03-03 08:45:33	0.0	0.0	0.0	0.0	0.0	0.0	54.27	0.0	14.1	0	0	0	0	0	0	0	2
8810	1	2017-03-03 08:47:02	0.0	0.0	0.0	\N	\N	\N	50.03	\N	13.0	0	0	0	0	0	0	0	2
8811	2	2017-03-03 09:11:02	0.0	0.0	0.0	0.0	0.0	0.0	53.79	0.0	13.7	0	0	0	0	0	0	0	2
8812	1	2017-03-03 09:18:02	220.0	219.4	220.3	\N	\N	\N	52.56	\N	14.7	1	1	1	0	0	0	0	2
8813	2	2017-03-03 09:42:02	0.0	0.0	0.0	0.0	0.0	0.0	53.11	0.0	13.7	0	0	0	0	0	0	0	2
8814	1	2017-03-03 09:49:02	228.4	227.8	228.7	\N	\N	\N	52.71	\N	14.8	1	1	1	0	0	0	0	2
8815	2	2017-03-03 10:13:02	0.0	0.0	0.0	0.0	0.0	0.0	52.25	0.0	13.4	0	0	0	0	0	0	0	2
8816	1	2017-03-03 10:20:02	223.8	223.2	224.1	\N	\N	\N	54.75	\N	14.9	1	1	1	0	0	0	0	2
8817	2	2017-03-03 10:44:02	0.0	0.0	0.0	0.0	0.0	0.0	52.36	0.0	13.4	0	0	0	0	0	0	0	2
8818	1	2017-03-03 10:51:02	220.4	219.8	220.7	\N	\N	\N	55.37	\N	14.7	1	1	1	0	0	0	0	2
8819	2	2017-03-03 11:15:02	0.0	0.0	0.0	0.0	0.0	0.0	50.79	0.0	13.2	0	0	0	0	0	0	0	2
8820	1	2017-03-03 11:22:02	0.0	0.0	0.0	\N	\N	\N	54.63	\N	13.5	0	0	0	0	0	0	0	2
8821	2	2017-03-03 11:46:02	0.0	0.0	0.0	0.0	0.0	0.0	50.69	0.0	13.1	0	0	0	0	0	0	0	2
8822	1	2017-03-03 11:53:02	0.0	0.0	0.0	\N	\N	\N	54.11	\N	13.3	0	0	0	0	0	0	0	2
8823	2	2017-03-03 12:17:02	0.0	0.0	0.0	0.0	0.0	0.0	50.33	0.0	13.0	0	0	0	0	0	0	0	2
8824	1	2017-03-03 12:24:02	0.0	0.0	0.0	\N	\N	\N	54.01	\N	13.2	0	0	0	0	0	0	0	2
8825	2	2017-03-03 12:48:02	0.0	0.0	0.0	0.0	0.0	0.0	50.20	0.0	12.9	0	0	0	0	0	0	0	2
8826	1	2017-03-03 12:55:02	0.0	0.0	0.0	\N	\N	\N	53.73	\N	13.1	0	0	0	0	0	0	0	2
8827	2	2017-03-03 13:19:02	0.0	0.0	0.0	0.0	0.0	0.0	49.96	0.0	12.8	0	0	0	0	0	0	0	2
8828	1	2017-03-03 13:26:02	0.0	0.0	0.0	\N	\N	\N	53.53	\N	13.1	0	0	0	0	0	0	0	2
8829	2	2017-03-03 13:50:02	0.0	0.0	0.0	0.0	0.0	0.0	49.74	0.0	12.9	0	0	0	0	0	0	0	2
8830	1	2017-03-03 13:57:02	0.0	0.0	0.0	\N	\N	\N	53.24	\N	13.1	0	0	0	0	0	0	0	2
8831	2	2017-03-03 14:21:02	0.0	0.0	0.0	0.0	0.0	0.0	49.23	0.0	12.7	0	0	0	0	0	0	0	2
8832	1	2017-03-03 14:28:02	0.0	0.0	0.0	\N	\N	\N	53.01	\N	13.1	0	0	0	0	0	0	0	2
8833	2	2017-03-03 14:52:02	0.0	0.0	0.0	0.0	0.0	0.0	49.19	0.0	12.7	0	0	0	0	0	0	0	2
8834	1	2017-03-03 14:59:02	0.0	0.0	0.0	\N	\N	\N	52.81	\N	13.1	0	0	0	0	0	0	0	2
8835	2	2017-03-03 15:23:02	0.0	0.0	0.0	0.0	0.0	0.0	48.79	0.0	12.7	0	0	0	0	0	0	0	2
8836	1	2017-03-03 15:30:02	0.0	0.0	0.0	\N	\N	\N	52.39	\N	13.1	0	0	0	0	0	0	0	2
8837	2	2017-03-03 15:54:02	0.0	0.0	0.0	0.0	0.0	0.0	47.93	0.0	12.5	0	0	0	0	0	0	0	2
8838	1	2017-03-03 16:01:02	0.0	0.0	0.0	\N	\N	\N	52.02	\N	13.1	0	0	0	0	0	0	0	2
8839	2	2017-03-03 16:25:02	0.0	0.0	0.0	0.0	0.0	0.0	47.77	0.0	12.4	0	0	0	0	0	0	0	2
8840	1	2017-03-03 16:32:02	0.0	0.0	0.0	\N	\N	\N	51.63	\N	13.1	0	0	0	0	0	0	0	2
8841	2	2017-03-03 16:44:30	182.7	182.1	183.0	0.0	0.0	0.0	47.70	0.0	12.2	1	1	1	0	0	0	0	2
8842	2	2017-03-03 16:56:02	225.7	225.1	226.0	0.0	0.0	0.0	50.25	0.0	13.3	1	1	1	0	0	0	0	2
8843	1	2017-03-03 17:03:02	0.0	0.0	0.0	\N	\N	\N	51.43	\N	13.1	0	0	0	0	0	0	0	2
8844	2	2017-03-03 17:27:02	223.1	222.5	223.4	0.0	0.0	0.0	51.59	0.0	13.7	1	1	1	0	0	0	0	2
8845	1	2017-03-03 17:34:02	0.0	0.0	0.0	\N	\N	\N	51.34	\N	13.1	0	0	0	0	0	0	0	2
8846	2	2017-03-03 17:58:02	221.5	220.9	221.8	0.0	0.0	0.0	52.35	0.0	13.8	1	1	1	0	0	0	0	2
8847	1	2017-03-03 18:05:02	0.0	0.0	0.0	\N	\N	\N	51.09	\N	13.0	0	0	0	0	0	0	0	2
8848	2	2017-03-03 18:29:02	218.7	218.1	219.0	0.0	0.0	0.0	54.11	0.0	14.2	1	1	1	0	0	0	0	2
8849	1	2017-03-03 18:36:02	0.0	0.0	0.0	\N	\N	\N	50.99	\N	13.0	0	0	0	0	0	0	0	2
8850	2	2017-03-03 19:00:07	222.6	222.0	222.9	0.0	0.0	0.0	55.16	0.0	14.4	1	1	1	0	0	0	0	2
8851	1	2017-03-03 19:07:02	0.0	0.0	0.0	\N	\N	\N	50.81	\N	13.0	0	0	0	0	0	0	0	2
8852	2	2017-03-03 19:20:19	0.0	0.0	0.0	0.0	0.0	0.0	54.59	0.0	14.2	0	0	0	0	0	0	0	2
8853	2	2017-03-03 19:31:02	0.0	0.0	0.0	0.0	0.0	0.0	54.36	0.0	13.9	0	0	0	0	0	0	0	2
8854	1	2017-03-03 19:38:02	0.0	0.0	0.0	\N	\N	\N	50.79	\N	13.0	0	0	0	0	0	0	0	2
8855	1	2017-03-03 19:38:02	0.0	0.0	0.0	\N	\N	\N	50.79	\N	13.0	0	0	0	0	0	0	0	2
8856	2	2017-03-03 20:02:02	0.0	0.0	0.0	0.0	0.0	0.0	53.47	0.0	13.7	0	0	0	0	0	0	0	2
8857	2	2017-03-03 20:02:02	0.0	0.0	0.0	\N	\N	\N	53.47	\N	13.7	0	0	0	0	0	0	0	2
8858	1	2017-03-03 20:09:02	0.0	0.0	0.0	\N	\N	\N	50.68	\N	13.0	0	0	0	0	0	0	0	2
8859	2	2017-03-03 20:33:02	0.0	0.0	0.0	0.0	0.0	0.0	52.79	0.0	13.5	0	0	0	0	0	0	0	2
8860	1	2017-03-03 20:40:02	0.0	0.0	0.0	\N	\N	\N	50.55	\N	13.0	0	0	0	0	0	0	0	2
8861	2	2017-03-03 21:04:02	0.0	0.0	0.0	0.0	0.0	0.0	52.45	0.0	13.5	0	0	0	0	0	0	0	2
8862	1	2017-03-03 21:11:02	0.0	0.0	0.0	\N	\N	\N	50.45	\N	13.0	0	0	0	0	0	0	0	2
8863	2	2017-03-03 21:35:02	0.0	0.0	0.0	0.0	0.0	0.0	52.03	0.0	13.3	0	0	0	0	0	0	0	2
8864	1	2017-03-03 21:42:02	0.0	0.0	0.0	\N	\N	\N	50.38	\N	13.0	0	0	0	0	0	0	0	2
8865	2	2017-03-03 22:06:02	0.0	0.0	0.0	0.0	0.0	0.0	51.44	0.0	13.1	0	0	0	0	0	0	0	2
8866	1	2017-03-03 22:13:02	0.0	0.0	0.0	\N	\N	\N	50.39	\N	13.0	0	0	0	0	0	0	0	2
8867	2	2017-03-03 22:37:02	0.0	0.0	0.0	0.0	0.0	0.0	50.40	0.0	13.0	0	0	0	0	0	0	0	2
8868	1	2017-03-03 22:44:02	0.0	0.0	0.0	\N	\N	\N	50.22	\N	13.0	0	0	0	0	0	0	0	2
8869	2	2017-03-03 23:08:01	0.0	0.0	0.0	0.0	0.0	0.0	50.37	0.0	13.1	0	0	0	0	0	0	0	2
8870	1	2017-03-03 23:15:02	0.0	0.0	0.0	\N	\N	\N	50.08	\N	13.0	0	0	0	0	0	0	0	2
8871	2	2017-03-03 23:39:02	0.0	0.0	0.0	0.0	0.0	0.0	50.36	0.0	13.0	0	0	0	0	0	0	0	2
8872	1	2017-03-03 23:46:02	0.0	0.0	0.0	\N	\N	\N	50.12	\N	13.1	0	0	0	0	0	0	0	2
8873	2	2017-03-04 00:10:02	0.0	0.0	0.0	0.0	0.0	0.0	50.05	0.0	12.9	0	0	0	0	0	0	0	2
8874	1	2017-03-04 00:17:02	0.0	0.0	0.0	\N	\N	\N	50.02	\N	13.0	0	0	0	0	0	0	0	2
8875	2	2017-03-04 00:41:02	0.0	0.0	0.0	0.0	0.0	0.0	49.54	0.0	12.8	0	0	0	0	0	0	0	2
8876	1	2017-03-04 00:48:02	214.9	214.3	215.2	\N	\N	\N	52.18	\N	14.6	1	1	1	0	0	0	0	2
8877	2	2017-03-04 01:14:02	0.0	0.0	0.0	0.0	0.0	0.0	49.25	0.0	12.7	0	0	0	0	0	0	0	2
8878	1	2017-03-04 01:19:02	223.3	222.7	223.6	\N	\N	\N	52.54	\N	14.9	1	1	1	0	0	0	0	2
8879	2	2017-03-04 01:45:02	0.0	0.0	0.0	0.0	0.0	0.0	49.77	0.0	12.8	0	0	0	0	0	0	0	2
8880	1	2017-03-04 01:50:02	221.6	221.0	221.9	\N	\N	\N	54.07	\N	14.9	1	1	1	0	0	0	0	2
8881	2	2017-03-04 02:16:02	0.0	0.0	0.0	0.0	0.0	0.0	49.00	0.0	12.6	0	0	0	0	0	0	0	2
8882	1	2017-03-04 02:21:02	221.9	221.3	222.2	\N	\N	\N	56.01	\N	14.8	1	1	1	0	0	0	0	2
8883	2	2017-03-04 02:47:02	0.0	0.0	0.0	0.0	0.0	0.0	48.48	0.0	12.6	0	0	0	0	0	0	0	2
8884	1	2017-03-04 02:52:02	0.0	0.0	0.0	\N	\N	\N	54.44	\N	13.5	0	0	0	0	0	0	0	2
8885	2	2017-03-04 03:18:02	0.0	0.0	0.0	0.0	0.0	0.0	48.33	0.0	12.5	0	0	0	0	0	0	0	2
8886	1	2017-03-04 03:23:02	0.0	0.0	0.0	\N	\N	\N	54.18	\N	13.3	0	0	0	0	0	0	0	2
8887	2	2017-03-04 03:49:02	0.0	0.0	0.0	0.0	0.0	0.0	47.80	0.0	12.5	0	0	0	0	0	0	0	2
8888	1	2017-03-04 03:54:02	0.0	0.0	0.0	\N	\N	\N	53.97	\N	13.2	0	0	0	0	0	0	0	2
8889	2	2017-03-04 04:20:02	0.0	0.0	0.0	0.0	0.0	0.0	47.61	0.0	12.5	0	0	0	0	0	0	0	2
8890	2	2017-03-04 04:27:09	197.5	196.9	197.8	0.0	0.0	0.0	47.70	0.0	12.2	1	1	1	0	0	0	0	2
8891	1	2017-03-04 04:25:02	0.0	0.0	0.0	\N	\N	\N	53.69	\N	13.1	0	0	0	0	0	0	0	2
8892	2	2017-03-04 04:51:02	223.2	222.6	223.5	0.0	0.0	0.0	51.00	0.0	13.5	1	1	1	0	0	0	0	2
8893	1	2017-03-04 04:56:02	0.0	0.0	0.0	\N	\N	\N	53.41	\N	13.1	0	0	0	0	0	0	0	2
8894	2	2017-03-04 05:19:02	223.2	222.6	223.5	0.0	0.0	0.0	51.72	0.0	13.7	1	1	1	0	0	0	0	2
8895	1	2017-03-04 05:27:02	0.0	0.0	0.0	\N	\N	\N	53.34	\N	13.1	0	0	0	0	0	0	0	2
8896	2	2017-03-04 05:50:02	223.1	222.5	223.4	0.0	0.0	0.0	53.06	0.0	13.9	1	1	1	0	0	0	0	2
8897	1	2017-03-04 05:58:02	0.0	0.0	0.0	\N	\N	\N	53.07	\N	13.1	0	0	0	0	0	0	0	2
8898	2	2017-03-04 06:10:06	223.2	222.6	223.5	0.0	0.0	0.0	54.09	0.0	3777882719232.0	1	1	1	0	0	0	0	2
8899	2	2017-03-04 06:21:02	222.4	221.8	222.7	0.0	0.0	0.0	54.67	0.0	14.2	1	1	1	0	0	0	0	2
8900	1	2017-03-04 06:29:02	0.0	0.0	0.0	\N	\N	\N	52.80	\N	13.1	0	0	0	0	0	0	0	2
8901	2	2017-03-04 06:52:02	222.4	221.8	222.7	0.0	0.0	0.0	55.50	0.0	14.4	1	1	1	0	0	0	0	2
8902	1	2017-03-04 07:00:06	0.0	0.0	0.0	\N	\N	\N	52.49	\N	13.1	0	0	0	0	0	0	0	2
8903	2	2017-03-04 07:23:02	0.0	0.0	0.0	0.0	0.0	0.0	54.12	0.0	13.9	0	0	0	0	0	0	0	2
8904	1	2017-03-04 07:31:02	0.0	0.0	0.0	\N	\N	\N	52.07	\N	13.1	0	0	0	0	0	0	0	2
8905	2	2017-03-04 07:54:02	0.0	0.0	0.0	0.0	0.0	0.0	53.31	0.0	13.7	0	0	0	0	0	0	0	2
8906	1	2017-03-04 08:02:02	0.0	0.0	0.0	\N	\N	\N	51.85	\N	13.1	0	0	0	0	0	0	0	2
8907	2	2017-03-04 08:27:02	0.0	0.0	0.0	0.0	0.0	0.0	52.88	0.0	13.6	0	0	0	0	0	0	0	2
8908	2	2017-03-04 08:27:02	0.0	0.0	0.0	\N	\N	\N	52.88	\N	13.6	0	0	0	0	0	0	0	2
8909	1	2017-03-04 08:33:02	0.0	0.0	0.0	\N	\N	\N	51.42	\N	13.0	0	0	0	0	0	0	0	2
8910	2	2017-03-04 08:58:02	0.0	0.0	0.0	0.0	0.0	0.0	52.69	0.0	13.5	0	0	0	0	0	0	0	2
8918	2	2017-03-04 11:02:02	0.0	0.0	0.0	0.0	0.0	0.0	50.27	0.0	13.1	0	0	0	0	0	0	0	2
8919	1	2017-03-04 11:08:02	0.0	0.0	0.0	\N	\N	\N	50.65	\N	13.0	0	0	0	0	0	0	0	2
8920	2	2017-03-04 11:33:02	0.0	0.0	0.0	0.0	0.0	0.0	49.80	0.0	12.9	0	0	0	0	0	0	0	2
8939	1	2017-03-04 15:46:02	0.0	0.0	0.0	\N	\N	\N	54.51	\N	13.2	0	0	0	0	0	0	0	2
8940	2	2017-03-04 16:09:02	220.3	219.7	220.6	0.0	0.0	0.0	52.11	0.0	13.7	1	1	1	0	0	0	0	2
8941	1	2017-03-04 16:17:02	0.0	0.0	0.0	\N	\N	\N	54.11	\N	13.2	0	0	0	0	0	0	0	2
8942	2	2017-03-04 16:40:02	224.2	223.6	224.5	0.0	0.0	0.0	53.72	0.0	13.9	1	1	1	0	0	0	0	2
8943	1	2017-03-04 16:48:02	0.0	0.0	0.0	\N	\N	\N	53.94	\N	13.1	0	0	0	0	0	0	0	2
8944	2	2017-03-04 17:11:02	220.6	220.0	220.9	0.0	0.0	0.0	55.31	0.0	14.4	1	1	1	0	0	0	0	2
8945	1	2017-03-04 17:19:02	0.0	0.0	0.0	\N	\N	\N	53.69	\N	13.1	0	0	0	0	0	0	0	2
8946	2	2017-03-04 17:42:02	221.5	220.9	221.8	0.0	0.0	0.0	55.28	0.0	14.4	1	1	1	0	0	0	0	2
8947	1	2017-03-04 17:50:02	0.0	0.0	0.0	\N	\N	\N	53.33	\N	13.1	0	0	0	0	0	0	0	2
8948	2	2017-03-04 18:15:02	0.0	0.0	0.0	0.0	0.0	0.0	53.90	0.0	13.9	0	0	0	0	0	0	0	2
8949	1	2017-03-04 18:21:02	0.0	0.0	0.0	\N	\N	\N	53.12	\N	13.1	0	0	0	0	0	0	0	2
8950	2	2017-03-04 18:46:02	0.0	0.0	0.0	0.0	0.0	0.0	53.30	0.0	13.8	0	0	0	0	0	0	0	2
8951	1	2017-03-04 18:52:02	0.0	0.0	0.0	\N	\N	\N	52.90	\N	13.2	0	0	0	0	0	0	0	2
8952	2	2017-03-04 19:17:02	0.0	0.0	0.0	0.0	0.0	0.0	53.21	0.0	13.5	0	0	0	0	0	0	0	2
8953	1	2017-03-04 19:23:02	0.0	0.0	0.0	\N	\N	\N	52.66	\N	13.1	0	0	0	0	0	0	0	2
8978	1	2017-03-05 01:35:02	0.0	0.0	0.0	\N	\N	\N	50.46	\N	13.0	0	0	0	0	0	0	0	2
8979	1	2017-03-05 01:35:02	0.0	0.0	0.0	\N	\N	\N	50.46	\N	13.0	0	0	0	0	0	0	0	2
8980	2	2017-03-05 01:57:02	0.0	0.0	0.0	0.0	0.0	0.0	47.71	0.0	12.5	0	0	0	0	0	0	0	2
8981	1	2017-03-05 02:06:02	0.0	0.0	0.0	\N	\N	\N	50.48	\N	13.0	0	0	0	0	0	0	0	2
8982	2	2017-03-05 02:28:02	220.5	219.9	220.8	0.0	0.0	0.0	49.79	0.0	13.2	1	1	1	0	0	0	0	2
8983	1	2017-03-05 02:37:02	0.0	0.0	0.0	\N	\N	\N	50.33	\N	13.0	0	0	0	0	0	0	0	2
8984	2	2017-03-05 02:59:02	224.3	223.7	224.6	0.0	0.0	0.0	51.36	0.0	13.6	1	1	1	0	0	0	0	2
8985	1	2017-03-05 03:08:02	0.0	0.0	0.0	\N	\N	\N	50.19	\N	13.0	0	0	0	0	0	0	0	2
8986	2	2017-03-05 03:30:02	224.4	223.8	224.7	0.0	0.0	0.0	52.33	0.0	13.6	1	1	1	0	0	0	0	2
8987	1	2017-03-05 03:39:02	0.0	0.0	0.0	\N	\N	\N	50.20	\N	13.0	0	0	0	0	0	0	0	2
8988	1	2017-03-05 03:42:57	184.4	183.8	184.7	\N	\N	\N	50.09	\N	12.3	1	1	1	0	0	0	0	2
8989	2	2017-03-05 04:01:02	216.7	216.1	217.0	0.0	0.0	0.0	53.42	0.0	13.9	1	1	1	0	0	0	0	2
8990	1	2017-03-05 04:10:01	226.5	225.9	226.8	\N	\N	\N	52.04	\N	14.6	1	1	1	0	0	0	0	2
8991	2	2017-03-05 04:32:02	223.3	222.7	223.6	0.0	0.0	0.0	55.32	0.0	14.4	1	1	1	0	0	0	0	2
8992	1	2017-03-05 04:41:02	227.0	226.4	227.3	\N	\N	\N	53.27	\N	14.7	1	1	1	0	0	0	0	2
8993	2	2017-03-05 05:03:02	0.0	0.0	0.0	0.0	0.0	0.0	54.89	0.0	14.1	0	0	0	0	0	0	0	2
8994	1	2017-03-05 05:12:02	220.6	220.0	220.9	\N	\N	\N	55.14	\N	15.0	1	1	1	0	0	0	0	2
8995	2	2017-03-05 05:34:02	0.0	0.0	0.0	0.0	0.0	0.0	54.17	0.0	13.9	0	0	0	0	0	0	0	2
9019	2	2017-03-05 11:15:02	0.0	0.0	0.0	0.0	0.0	0.0	49.21	0.0	12.8	0	0	0	0	0	0	0	2
9020	1	2017-03-05 11:24:02	0.0	0.0	0.0	\N	\N	\N	51.65	\N	13.1	0	0	0	0	0	0	0	2
9021	2	2017-03-05 11:46:02	0.0	0.0	0.0	0.0	0.0	0.0	49.42	0.0	12.8	0	0	0	0	0	0	0	2
9022	1	2017-03-05 11:55:02	0.0	0.0	0.0	\N	\N	\N	51.39	\N	13.1	0	0	0	0	0	0	0	2
9023	2	2017-03-05 12:17:02	0.0	0.0	0.0	0.0	0.0	0.0	48.52	0.0	12.6	0	0	0	0	0	0	0	2
9024	1	2017-03-05 12:26:02	0.0	0.0	0.0	\N	\N	\N	51.34	\N	13.1	0	0	0	0	0	0	0	2
9025	2	2017-03-05 12:48:02	0.0	0.0	0.0	0.0	0.0	0.0	48.27	0.0	12.5	0	0	0	0	0	0	0	2
9026	2	2017-03-05 12:48:02	0.0	0.0	0.0	\N	\N	\N	48.27	\N	12.5	0	0	0	0	0	0	0	2
9027	1	2017-03-05 12:57:02	0.0	0.0	0.0	\N	\N	\N	51.22	\N	13.1	0	0	0	0	0	0	0	2
9028	2	2017-03-05 13:19:02	0.0	0.0	0.0	0.0	0.0	0.0	47.61	0.0	12.4	0	0	0	0	0	0	0	2
9029	1	2017-03-05 13:28:02	0.0	0.0	0.0	\N	\N	\N	51.01	\N	13.1	0	0	0	0	0	0	0	2
9030	2	2017-03-05 13:50:02	0.0	0.0	0.0	0.0	0.0	0.0	47.27	0.0	12.4	0	0	0	0	0	0	0	2
9031	1	2017-03-05 13:59:02	0.0	0.0	0.0	\N	\N	\N	50.83	\N	13.0	0	0	0	0	0	0	0	2
9032	2	2017-03-05 14:21:02	222.0	221.4	222.3	0.0	0.0	0.0	51.00	0.0	13.4	1	1	1	0	0	0	0	2
9033	1	2017-03-05 14:30:02	0.0	0.0	0.0	\N	\N	\N	50.66	\N	13.1	0	0	0	0	0	0	0	2
9034	2	2017-03-05 14:52:02	222.6	222.0	222.9	0.0	0.0	0.0	51.58	0.0	13.6	1	1	1	0	0	0	0	2
9035	1	2017-03-05 15:01:02	0.0	0.0	0.0	\N	\N	\N	50.62	\N	13.0	0	0	0	0	0	0	0	2
9048	2	2017-03-05 18:29:02	0.0	0.0	0.0	0.0	0.0	0.0	51.84	0.0	13.3	0	0	0	0	0	0	0	2
8911	1	2017-03-04 09:04:02	0.0	0.0	0.0	\N	\N	\N	51.42	\N	13.1	0	0	0	0	0	0	0	2
8912	2	2017-03-04 09:29:02	0.0	0.0	0.0	0.0	0.0	0.0	51.83	0.0	13.3	0	0	0	0	0	0	0	2
8913	1	2017-03-04 09:35:02	0.0	0.0	0.0	\N	\N	\N	51.07	\N	13.1	0	0	0	0	0	0	0	2
8914	2	2017-03-04 10:00:07	0.0	0.0	0.0	0.0	0.0	0.0	51.00	0.0	13.1	0	0	0	0	0	0	0	2
8915	1	2017-03-04 10:06:02	0.0	0.0	0.0	\N	\N	\N	51.06	\N	13.0	0	0	0	0	0	0	0	2
8916	2	2017-03-04 10:31:02	0.0	0.0	0.0	0.0	0.0	0.0	50.47	0.0	13.0	0	0	0	0	0	0	0	2
8917	1	2017-03-04 10:37:02	0.0	0.0	0.0	\N	\N	\N	50.87	\N	13.1	0	0	0	0	0	0	0	2
8921	1	2017-03-04 11:39:02	0.0	0.0	0.0	\N	\N	\N	50.69	\N	13.0	0	0	0	0	0	0	0	2
8922	2	2017-03-04 12:01:02	0.0	0.0	0.0	0.0	0.0	0.0	49.57	0.0	12.7	0	0	0	0	0	0	0	2
8923	1	2017-03-04 12:10:02	0.0	0.0	0.0	\N	\N	\N	50.60	\N	13.0	0	0	0	0	0	0	0	2
8924	1	2017-03-04 12:19:08	0.0	0.0	0.0	\N	\N	\N	50.65	\N	68433857923549525834754774180.0	0	0	0	0	0	0	0	2
8925	2	2017-03-04 12:32:02	0.0	0.0	0.0	0.0	0.0	0.0	49.47	0.0	12.9	0	0	0	0	0	0	0	2
8926	2	2017-03-04 12:32:02	0.0	0.0	0.0	\N	\N	\N	49.47	\N	12.9	0	0	0	0	0	0	0	2
8927	2	2017-03-04 13:03:02	0.0	0.0	0.0	0.0	0.0	0.0	49.41	0.0	12.8	0	0	0	0	0	0	0	2
8928	1	2017-03-04 13:11:02	224.3	223.7	224.6	\N	\N	\N	54.26	\N	15.0	1	1	1	0	0	0	0	2
8929	2	2017-03-04 13:34:02	0.0	0.0	0.0	0.0	0.0	0.0	48.90	0.0	12.7	0	0	0	0	0	0	0	2
8930	1	2017-03-04 13:42:02	222.9	222.3	223.2	\N	\N	\N	55.69	\N	15.0	1	1	1	0	0	0	0	2
8931	2	2017-03-04 14:05:02	0.0	0.0	0.0	0.0	0.0	0.0	48.84	0.0	12.6	0	0	0	0	0	0	0	2
8932	1	2017-03-04 14:13:02	217.8	217.2	218.1	\N	\N	\N	55.67	\N	14.8	1	1	1	0	0	0	0	2
8933	1	2017-03-04 14:21:58	0.0	0.0	0.0	\N	\N	\N	55.28	\N	14.3	0	0	0	0	0	0	0	2
8934	2	2017-03-04 14:36:02	0.0	0.0	0.0	0.0	0.0	0.0	48.37	0.0	12.6	0	0	0	0	0	0	0	2
8935	1	2017-03-04 14:44:02	0.0	0.0	0.0	\N	\N	\N	54.91	\N	13.4	0	0	0	0	0	0	0	2
8936	2	2017-03-04 15:07:02	0.0	0.0	0.0	0.0	0.0	0.0	47.65	0.0	12.4	0	0	0	0	0	0	0	2
8937	1	2017-03-04 15:15:02	0.0	0.0	0.0	\N	\N	\N	54.60	\N	13.2	0	0	0	0	0	0	0	2
8938	2	2017-03-04 15:38:02	222.9	222.3	223.2	0.0	0.0	0.0	51.25	0.0	13.4	1	1	1	0	0	0	0	2
8954	2	2017-03-04 19:48:02	0.0	0.0	0.0	0.0	0.0	0.0	52.06	0.0	13.5	0	0	0	0	0	0	0	2
8955	1	2017-03-04 19:54:02	0.0	0.0	0.0	\N	\N	\N	52.25	\N	13.1	0	0	0	0	0	0	0	2
8956	2	2017-03-04 20:19:02	0.0	0.0	0.0	0.0	0.0	0.0	51.52	0.0	13.2	0	0	0	0	0	0	0	2
8957	1	2017-03-04 20:25:02	0.0	0.0	0.0	\N	\N	\N	51.90	\N	13.0	0	0	0	0	0	0	0	2
8958	2	2017-03-04 20:50:02	0.0	0.0	0.0	0.0	0.0	0.0	50.57	0.0	13.1	0	0	0	0	0	0	0	2
8959	1	2017-03-04 20:56:02	0.0	0.0	0.0	\N	\N	\N	51.60	\N	13.1	0	0	0	0	0	0	0	2
8960	2	2017-03-04 21:21:02	0.0	0.0	0.0	0.0	0.0	0.0	50.50	0.0	13.0	0	0	0	0	0	0	0	2
8961	1	2017-03-04 21:27:02	0.0	0.0	0.0	\N	\N	\N	51.38	\N	13.0	0	0	0	0	0	0	0	2
8962	2	2017-03-04 21:52:02	0.0	0.0	0.0	0.0	0.0	0.0	50.33	0.0	13.0	0	0	0	0	0	0	0	2
8963	1	2017-03-04 21:58:02	0.0	0.0	0.0	\N	\N	\N	51.20	\N	13.0	0	0	0	0	0	0	0	2
8964	2	2017-03-04 22:20:02	0.0	0.0	0.0	0.0	0.0	0.0	50.10	0.0	12.9	0	0	0	0	0	0	0	2
8965	1	2017-03-04 22:29:02	0.0	0.0	0.0	\N	\N	\N	51.03	\N	13.0	0	0	0	0	0	0	0	2
8966	2	2017-03-04 22:51:02	0.0	0.0	0.0	0.0	0.0	0.0	49.73	0.0	12.8	0	0	0	0	0	0	0	2
8967	1	2017-03-04 23:00:07	0.0	0.0	0.0	\N	\N	\N	50.90	\N	13.0	0	0	0	0	0	0	0	2
8968	1	2017-03-04 23:00:07	0.0	0.0	0.0	\N	\N	\N	50.90	\N	13.0	0	0	0	0	0	0	0	2
8969	2	2017-03-04 23:22:02	0.0	0.0	0.0	0.0	0.0	0.0	49.44	0.0	12.8	0	0	0	0	0	0	0	2
8970	1	2017-03-04 23:31:02	0.0	0.0	0.0	\N	\N	\N	50.84	\N	13.0	0	0	0	0	0	0	0	2
8971	2	2017-03-04 23:53:02	0.0	0.0	0.0	0.0	0.0	0.0	48.98	0.0	12.7	0	0	0	0	0	0	0	2
8972	1	2017-03-05 00:02:02	0.0	0.0	0.0	\N	\N	\N	50.70	\N	13.0	0	0	0	0	0	0	0	2
8973	2	2017-03-05 00:24:02	0.0	0.0	0.0	0.0	0.0	0.0	48.89	0.0	12.6	0	0	0	0	0	0	0	2
8974	1	2017-03-05 00:33:02	0.0	0.0	0.0	\N	\N	\N	50.56	\N	13.0	0	0	0	0	0	0	0	2
8975	2	2017-03-05 00:55:02	0.0	0.0	0.0	0.0	0.0	0.0	48.57	0.0	12.6	0	0	0	0	0	0	0	2
8976	1	2017-03-05 01:04:02	0.0	0.0	0.0	\N	\N	\N	50.49	\N	13.0	0	0	0	0	0	0	0	2
8977	2	2017-03-05 01:26:02	0.0	0.0	0.0	0.0	0.0	0.0	48.02	0.0	12.5	0	0	0	0	0	0	0	2
8996	1	2017-03-05 05:43:02	220.8	220.2	221.1	\N	\N	\N	55.50	\N	14.8	1	1	1	0	0	0	0	2
8997	1	2017-03-05 05:45:39	0.0	0.0	0.0	\N	\N	\N	54.77	\N	14.2	0	0	0	0	0	0	0	2
8998	2	2017-03-05 06:05:02	0.0	0.0	0.0	0.0	0.0	0.0	53.33	0.0	13.6	0	0	0	0	0	0	0	2
8999	1	2017-03-05 06:14:02	0.0	0.0	0.0	\N	\N	\N	54.51	\N	13.5	0	0	0	0	0	0	0	2
9000	2	2017-03-05 06:36:02	0.0	0.0	0.0	0.0	0.0	0.0	53.20	0.0	13.6	0	0	0	0	0	0	0	2
9001	1	2017-03-05 06:45:02	0.0	0.0	0.0	\N	\N	\N	54.30	\N	13.3	0	0	0	0	0	0	0	2
9002	2	2017-03-05 07:07:02	0.0	0.0	0.0	0.0	0.0	0.0	52.37	0.0	13.4	0	0	0	0	0	0	0	2
9003	1	2017-03-05 07:16:02	0.0	0.0	0.0	\N	\N	\N	54.04	\N	13.2	0	0	0	0	0	0	0	2
9004	2	2017-03-05 07:38:02	0.0	0.0	0.0	0.0	0.0	0.0	51.51	0.0	13.3	0	0	0	0	0	0	0	2
9005	1	2017-03-05 07:47:02	0.0	0.0	0.0	\N	\N	\N	53.72	\N	13.2	0	0	0	0	0	0	0	2
9006	2	2017-03-05 08:09:02	0.0	0.0	0.0	0.0	0.0	0.0	50.90	0.0	13.1	0	0	0	0	0	0	0	2
9007	1	2017-03-05 08:18:02	0.0	0.0	0.0	\N	\N	\N	53.46	\N	13.1	0	0	0	0	0	0	0	2
9008	1	2017-03-05 08:18:02	0.0	0.0	0.0	\N	\N	\N	53.46	\N	13.1	0	0	0	0	0	0	0	2
9009	2	2017-03-05 08:40:02	0.0	0.0	0.0	0.0	0.0	0.0	50.47	0.0	13.1	0	0	0	0	0	0	0	2
9010	1	2017-03-05 08:49:02	0.0	0.0	0.0	\N	\N	\N	53.36	\N	13.1	0	0	0	0	0	0	0	2
9011	2	2017-03-05 09:11:02	0.0	0.0	0.0	0.0	0.0	0.0	50.39	0.0	13.0	0	0	0	0	0	0	0	2
9012	1	2017-03-05 09:20:02	0.0	0.0	0.0	\N	\N	\N	53.01	\N	13.1	0	0	0	0	0	0	0	2
9013	2	2017-03-05 09:42:02	0.0	0.0	0.0	0.0	0.0	0.0	50.50	0.0	12.9	0	0	0	0	0	0	0	2
9014	1	2017-03-05 09:51:02	0.0	0.0	0.0	\N	\N	\N	52.72	\N	13.1	0	0	0	0	0	0	0	2
9015	2	2017-03-05 10:13:02	0.0	0.0	0.0	0.0	0.0	0.0	49.87	0.0	13.0	0	0	0	0	0	0	0	2
9016	1	2017-03-05 10:22:02	0.0	0.0	0.0	\N	\N	\N	52.55	\N	13.1	0	0	0	0	0	0	0	2
9017	2	2017-03-05 10:44:02	0.0	0.0	0.0	0.0	0.0	0.0	49.17	0.0	12.9	0	0	0	0	0	0	0	2
9018	1	2017-03-05 10:53:02	0.0	0.0	0.0	\N	\N	\N	52.11	\N	13.1	0	0	0	0	0	0	0	2
9036	2	2017-03-05 15:23:02	219.7	219.1	220.0	0.0	0.0	0.0	53.19	0.0	14.0	1	1	1	0	0	0	0	2
9037	1	2017-03-05 15:32:02	0.0	0.0	0.0	\N	\N	\N	50.55	\N	13.0	0	0	0	0	0	0	0	2
9038	2	2017-03-05 15:54:02	218.7	218.1	219.0	0.0	0.0	0.0	54.73	0.0	14.2	1	1	1	0	0	0	0	2
9039	1	2017-03-05 16:03:02	0.0	0.0	0.0	\N	\N	\N	50.38	\N	13.0	0	0	0	0	0	0	0	2
9040	2	2017-03-05 16:25:02	222.0	221.4	222.3	0.0	0.0	0.0	55.39	0.0	14.4	1	1	1	0	0	0	0	2
9041	1	2017-03-05 16:34:02	0.0	0.0	0.0	\N	\N	\N	50.43	\N	13.0	0	0	0	0	0	0	0	2
9042	2	2017-03-05 16:56:02	0.0	0.0	0.0	0.0	0.0	0.0	53.73	0.0	13.9	0	0	0	0	0	0	0	2
9043	1	2017-03-05 17:05:02	0.0	0.0	0.0	\N	\N	\N	50.34	\N	13.0	0	0	0	0	0	0	0	2
9044	2	2017-03-05 17:27:02	0.0	0.0	0.0	0.0	0.0	0.0	53.39	0.0	13.6	0	0	0	0	0	0	0	2
9045	1	2017-03-05 17:36:02	0.0	0.0	0.0	\N	\N	\N	50.20	\N	13.0	0	0	0	0	0	0	0	2
9046	2	2017-03-05 17:58:02	0.0	0.0	0.0	0.0	0.0	0.0	52.84	0.0	13.5	0	0	0	0	0	0	0	2
9047	1	2017-03-05 18:07:02	0.0	0.0	0.0	\N	\N	\N	50.12	\N	13.0	0	0	0	0	0	0	0	2
9049	1	2017-03-05 18:38:02	0.0	0.0	0.0	\N	\N	\N	49.95	\N	13.0	0	0	0	0	0	0	0	2
9050	2	2017-03-05 19:00:07	0.0	0.0	0.0	0.0	0.0	0.0	51.29	0.0	13.3	0	0	0	0	0	0	0	2
9051	1	2017-03-05 19:09:02	0.0	0.0	0.0	\N	\N	\N	49.97	\N	13.0	0	0	0	0	0	0	0	2
9052	2	2017-03-05 19:31:02	0.0	0.0	0.0	0.0	0.0	0.0	50.53	0.0	13.1	0	0	0	0	0	0	0	2
9053	1	2017-03-05 19:40:02	0.0	0.0	0.0	\N	\N	\N	49.82	\N	13.0	0	0	0	0	0	0	0	2
9054	1	2017-03-05 19:46:45	193.5	192.9	193.8	\N	\N	\N	49.67	\N	12.3	1	1	1	0	0	0	0	2
9055	2	2017-03-05 20:02:02	0.0	0.0	0.0	0.0	0.0	0.0	50.42	0.0	12.9	0	0	0	0	0	0	0	2
9056	1	2017-03-05 20:11:02	222.7	222.1	223.0	\N	\N	\N	51.92	\N	14.8	1	1	1	0	0	0	0	2
9057	2	2017-03-05 20:33:02	0.0	0.0	0.0	0.0	0.0	0.0	50.11	0.0	13.0	0	0	0	0	0	0	0	2
9058	1	2017-03-05 20:42:02	221.0	220.4	221.3	\N	\N	\N	51.74	\N	14.8	1	1	1	0	0	0	0	2
9059	2	2017-03-05 21:04:02	0.0	0.0	0.0	0.0	0.0	0.0	49.90	0.0	13.0	0	0	0	0	0	0	0	2
9060	1	2017-03-05 21:13:02	218.3	217.7	218.6	\N	\N	\N	54.22	\N	14.9	1	1	1	0	0	0	0	2
9061	2	2017-03-05 21:35:01	0.0	0.0	0.0	0.0	0.0	0.0	49.69	0.0	12.8	0	0	0	0	0	0	0	2
9062	1	2017-03-05 21:44:02	221.4	220.8	221.7	\N	\N	\N	56.29	\N	15.0	1	1	1	0	0	0	0	2
9063	1	2017-03-05 21:49:24	0.0	0.0	0.0	\N	\N	\N	54.67	\N	14.4	0	0	0	0	0	0	0	2
9064	2	2017-03-05 22:06:02	0.0	0.0	0.0	0.0	0.0	0.0	49.69	0.0	12.9	0	0	0	0	0	0	0	2
9065	1	2017-03-05 22:15:02	0.0	0.0	0.0	\N	\N	\N	54.25	\N	13.5	0	0	0	0	0	0	0	2
9066	2	2017-03-05 22:37:02	0.0	0.0	0.0	0.0	0.0	0.0	49.03	0.0	12.8	0	0	0	0	0	0	0	2
9067	1	2017-03-05 22:46:02	0.0	0.0	0.0	\N	\N	\N	54.04	\N	13.3	0	0	0	0	0	0	0	2
9068	2	2017-03-05 23:08:02	0.0	0.0	0.0	0.0	0.0	0.0	48.68	0.0	12.8	0	0	0	0	0	0	0	2
9069	1	2017-03-05 23:17:02	0.0	0.0	0.0	\N	\N	\N	53.70	\N	13.2	0	0	0	0	0	0	0	2
9070	2	2017-03-05 23:39:02	0.0	0.0	0.0	0.0	0.0	0.0	48.42	0.0	12.7	0	0	0	0	0	0	0	2
9071	1	2017-03-05 23:48:02	0.0	0.0	0.0	\N	\N	\N	53.67	\N	13.1	0	0	0	0	0	0	0	2
9072	2	2017-03-06 00:10:02	0.0	0.0	0.0	0.0	0.0	0.0	48.01	0.0	12.4	0	0	0	0	0	0	0	2
9073	1	2017-03-06 00:19:02	0.0	0.0	0.0	\N	\N	\N	53.21	\N	13.1	0	0	0	0	0	0	0	2
9074	2	2017-03-06 00:41:02	223.2	222.6	223.5	0.0	0.0	0.0	50.43	0.0	13.2	1	1	1	0	0	0	0	2
9075	1	2017-03-06 00:50:02	0.0	0.0	0.0	\N	\N	\N	53.00	\N	13.1	0	0	0	0	0	0	0	2
9076	2	2017-03-06 01:12:02	223.0	222.4	223.3	0.0	0.0	0.0	51.55	0.0	13.7	1	1	1	0	0	0	0	2
9077	1	2017-03-06 01:21:02	0.0	0.0	0.0	\N	\N	\N	52.62	\N	13.1	0	0	0	0	0	0	0	2
9078	2	2017-03-06 01:43:02	223.8	223.2	224.1	0.0	0.0	0.0	52.72	0.0	13.8	1	1	1	0	0	0	0	2
9079	1	2017-03-06 01:52:02	0.0	0.0	0.0	\N	\N	\N	52.61	\N	13.1	0	0	0	0	0	0	0	2
9080	2	2017-03-06 02:14:02	223.6	223.0	223.9	0.0	0.0	0.0	54.10	0.0	14.2	1	1	1	0	0	0	0	2
9081	1	2017-03-06 02:23:02	0.0	0.0	0.0	\N	\N	\N	52.23	\N	13.1	0	0	0	0	0	0	0	2
9082	2	2017-03-06 02:45:02	222.3	221.7	222.6	0.0	0.0	0.0	55.21	0.0	14.3	1	1	1	0	0	0	0	2
9083	1	2017-03-06 02:54:02	0.0	0.0	0.0	\N	\N	\N	51.82	\N	13.1	0	0	0	0	0	0	0	2
9084	2	2017-03-06 03:16:02	0.0	0.0	0.0	0.0	0.0	0.0	54.71	0.0	13.9	0	0	0	0	0	0	0	2
9085	1	2017-03-06 03:25:02	0.0	0.0	0.0	\N	\N	\N	51.53	\N	13.1	0	0	0	0	0	0	0	2
9086	2	2017-03-06 03:47:02	0.0	0.0	0.0	0.0	0.0	0.0	54.34	0.0	13.8	0	0	0	0	0	0	0	2
9087	1	2017-03-06 03:56:02	0.0	0.0	0.0	\N	\N	\N	51.41	\N	13.1	0	0	0	0	0	0	0	2
9088	2	2017-03-06 04:18:02	0.0	0.0	0.0	0.0	0.0	0.0	53.34	0.0	13.6	0	0	0	0	0	0	0	2
9089	1	2017-03-06 04:27:02	0.0	0.0	0.0	\N	\N	\N	51.32	\N	13.1	0	0	0	0	0	0	0	2
9090	2	2017-03-06 04:49:02	0.0	0.0	0.0	0.0	0.0	0.0	52.91	0.0	13.5	0	0	0	0	0	0	0	2
9091	1	2017-03-06 04:58:02	0.0	0.0	0.0	\N	\N	\N	51.17	\N	13.1	0	0	0	0	0	0	0	2
9092	2	2017-03-06 05:20:02	0.0	0.0	0.0	0.0	0.0	0.0	52.45	0.0	13.5	0	0	0	0	0	0	0	2
9093	1	2017-03-06 05:29:02	0.0	0.0	0.0	\N	\N	\N	50.90	\N	13.1	0	0	0	0	0	0	0	2
9094	2	2017-03-06 05:51:02	0.0	0.0	0.0	0.0	0.0	0.0	51.77	0.0	13.3	0	0	0	0	0	0	0	2
9095	1	2017-03-06 06:00:07	0.0	0.0	0.0	\N	\N	\N	50.70	\N	13.0	0	0	0	0	0	0	0	2
9096	2	2017-03-06 06:22:02	0.0	0.0	0.0	0.0	0.0	0.0	51.37	0.0	13.3	0	0	0	0	0	0	0	2
9097	1	2017-03-06 06:31:02	0.0	0.0	0.0	\N	\N	\N	50.73	\N	13.0	0	0	0	0	0	0	0	2
9098	2	2017-03-06 06:53:02	0.0	0.0	0.0	0.0	0.0	0.0	50.52	0.0	13.0	0	0	0	0	0	0	0	2
9099	1	2017-03-06 07:02:02	0.0	0.0	0.0	\N	\N	\N	50.63	\N	13.0	0	0	0	0	0	0	0	2
9100	2	2017-03-06 07:24:02	0.0	0.0	0.0	0.0	0.0	0.0	50.86	0.0	13.1	0	0	0	0	0	0	0	2
9101	1	2017-03-06 07:33:02	0.0	0.0	0.0	\N	\N	\N	50.71	\N	13.0	0	0	0	0	0	0	0	2
9102	2	2017-03-06 07:55:02	0.0	0.0	0.0	0.0	0.0	0.0	49.81	0.0	13.0	0	0	0	0	0	0	0	2
9103	1	2017-03-06 08:04:02	0.0	0.0	0.0	\N	\N	\N	50.54	\N	13.0	0	0	0	0	0	0	0	2
9104	2	2017-03-06 08:26:02	0.0	0.0	0.0	0.0	0.0	0.0	50.07	0.0	12.9	0	0	0	0	0	0	0	2
9105	1	2017-03-06 08:35:02	0.0	0.0	0.0	\N	\N	\N	50.36	\N	13.0	0	0	0	0	0	0	0	2
9106	2	2017-03-06 08:57:02	0.0	0.0	0.0	0.0	0.0	0.0	49.65	0.0	12.8	0	0	0	0	0	0	0	2
9107	1	2017-03-06 09:06:02	0.0	0.0	0.0	\N	\N	\N	50.38	\N	13.0	0	0	0	0	0	0	0	2
9108	2	2017-03-06 09:28:02	0.0	0.0	0.0	0.0	0.0	0.0	49.19	0.0	12.8	0	0	0	0	0	0	0	2
9109	1	2017-03-06 09:37:02	0.0	0.0	0.0	\N	\N	\N	50.17	\N	13.0	0	0	0	0	0	0	0	2
\.


--
-- TOC entry 2371 (class 0 OID 0)
-- Dependencies: 195
-- Name: data_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('data_log_id_seq', 9109, true);


--
-- TOC entry 2331 (class 0 OID 32870)
-- Dependencies: 199
-- Data for Name: inbox; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY inbox (id, sender, message_date, receive_date, text, request_id, gateway_id, message_type, encoding) FROM stdin;
1	085315718563	2016-10-12 00:17:59	2016-10-12 00:17:51	Time=12-10-2016 14:13:46\n\nGV=198.6,194.3,204.4\n\nGI=0.0,0.0,0.0\n\nBV=48.31\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=1\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
2	085315718563	2016-10-12 00:20:50	2016-10-12 00:20:41	Time=12-10-2016 14:16:18\n\nGV=198.5,190.3,201.8\n\nGI=0.0,0.0,0.0\n\nBV=48.17\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
3	085315718563	2016-10-12 14:48:39	2016-10-12 14:48:30	Time=12-10-2016 14:41:00\n\nGV=201.3,196.7,206.6\n\nGI=0.0,0.0,0.0\n\nBV=48.18\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
4	085315718563	2016-10-12 15:56:10	2016-10-12 15:56:01	Time=12-10-2016 15:41:01\n\nGV=202.4,200.7,205.1\n\nGI=0.0,0.0,0.0\n\nBV=48.82\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
5	085315718563	2016-10-12 15:56:36	2016-10-12 15:56:27	Time=12-10-2016 15:41:24\n\nGV=202.2,195.6,205.1\n\nGI=0.0,0.0,0.0\n\nBV=48.24\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
6	085315718563	2016-10-12 15:57:01	2016-10-12 15:57:27	Time=12-10-2016 15:41:46\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=49.17\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
7	085315718563	2016-10-12 17:24:32	2016-10-12 17:24:54	Time=12-10-2016 17:17:00\n\nGV=197.4,193.8,200.3\n\nGI=0.0,0.0,0.0\n\nBV=49.01\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
8	085315718563	2016-10-12 18:32:01	2016-10-12 18:31:55	Time=12-10-2016 18:17:01\n\nGV=191.1,184.3,191.1\n\nGI=0.0,0.0,0.0\n\nBV=48.43\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
9	085315718563	2016-10-12 18:33:08	2016-10-12 18:32:59	Time=12-10-2016 18:18:00\n\nGV=192.9,186.0,192.3\n\nGI=0.0,0.0,0.0\n\nBV=48.71\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
10	085315718563	2016-10-12 18:33:31	2016-10-12 18:33:22	Time=12-10-2016 18:18:21\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.29\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
11	085315718563	2016-10-12 19:39:29	2016-10-12 19:39:20	Time=12-10-2016 19:17:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.04\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
12	085315718563	2016-10-12 20:46:57	2016-10-12 20:47:21	Time=12-10-2016 20:17:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.56\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
13	085315718563	2016-10-12 20:48:11	2016-10-12 20:48:21	Time=12-10-2016 20:18:06\n\nGV=201.8,195.5,203.5\n\nGI=0.0,0.0,0.0\n\nBV=48.59\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
14	085315718563	2016-10-13 11:25:16	2016-10-13 11:25:06	Time=13-10-2016 11:10:01\n\nGV=205.0,201.1,206.0\n\nGI=0.0,0.0,0.0\n\nBV=48.62\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=1\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
15	085315718563	2016-10-13 11:25:56	2016-10-13 11:25:46	Time=13-10-2016 11:10:36\n\nGV=209.0,204.6,210.9\n\nGI=0.0,0.0,0.0\n\nBV=48.43\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=1\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
16	085315718563	2016-10-13 11:26:18	2016-10-13 11:26:09	Time=13-10-2016 11:10:56\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.59\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=1\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
17	085315718563	2016-10-13 12:18:13	2016-10-13 12:18:10	Time=13-10-2016 11:56:56\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.23\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
18	085315718563	2016-10-13 12:31:25	2016-10-13 12:31:15	Time=13-10-2016 12:31:16\n\nGV=212.3,206.1,214.0\n\nGI=0.0,0.0,0.0\n\nBV=48.34\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
19	085315718563	2016-10-13 12:35:18	2016-10-13 12:35:15	Time=13-10-2016 12:35:08\n\nGV=211.9,204.7,209.9\n\nGI=0.0,0.0,0.0\n\nBV=48.80\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=1\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
20	085315718563	2016-10-13 12:36:17	2016-10-13 12:36:15	Time=13-10-2016 12:36:00\n\nGV=212.2,205.1,212.0\n\nGI=0.0,0.0,0.0\n\nBV=48.41\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
21	085315718563	2016-10-13 13:38:18	2016-10-13 13:38:16	Time=13-10-2016 13:31:00\n\nGV=203.0,198.8,203.5\n\nGI=0.0,0.0,0.0\n\nBV=48.26\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
22	085315718563	2016-10-13 14:16:58	2016-10-13 14:16:48	Time=13-10-2016 14:05:18\n\nGV=204.9,197.3,203.6\n\nGI=0.0,0.0,0.0\n\nBV=48.93\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=1\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
23	085315718563	2016-10-13 14:22:02	2016-10-13 14:21:53	Time=13-10-2016 14:09:48\n\nGV=207.3,203.6,211.2\n\nGI=0.0,0.0,0.0\n\nBV=48.44\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
24	085315718563	2016-10-13 14:45:56	2016-10-13 14:45:53	Time=13-10-2016 14:31:01\n\nGV=198.0,194.0,201.8\n\nGI=0.0,0.0,0.0\n\nBV=48.19\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
25	085315718563	2016-10-13 14:46:52	2016-10-13 14:46:54	Time=13-10-2016 14:31:51\n\nGV=199.9,194.9,199.9\n\nGI=0.0,0.0,0.0\n\nBV=48.35\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
26	085315718563	2016-10-13 14:47:15	2016-10-13 14:47:06	Time=13-10-2016 14:32:11\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=49.05\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
27	0811230444	2016-10-13 15:47:31	2016-10-13 15:47:22	tess	\N	085210588635	\N	7
28	085315718563	2016-10-13 15:49:45	2016-10-13 15:49:36	Time=13-10-2016 15:27:42\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.59\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=1\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
29	085315718563	2016-10-13 15:51:15	2016-10-13 15:51:06	Time=13-10-2016 15:29:02\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.35\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
30	085315718563	2016-10-13 15:53:29	2016-10-13 15:53:20	Time=13-10-2016 15:31:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.56\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
31	085315718563	2016-10-13 17:01:15	2016-10-13 17:01:07	Time=13-10-2016 16:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.77\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
32	085315718563	2016-10-13 17:02:06	2016-10-13 17:01:57	Time=13-10-2016 16:56:46\n\nGV=201.7,196.5,202.5\n\nGI=0.0,0.0,0.0\n\nBV=48.49\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
33	0811230444	2016-10-13 17:26:52	2016-10-13 17:26:57	teeess	\N	085210588635	\N	7
34	085315718563	2016-10-13 17:28:34	2016-10-13 17:28:25	Time=13-10-2016 17:20:17\n\nGV=196.5,191.1,198.8\n\nGI=0.0,0.0,0.0\n\nBV=48.63\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=1\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
35	085315718563	2016-10-13 17:29:12	2016-10-13 17:29:25	Time=13-10-2016 17:20:51\n\nGV=199.6,195.9,203.7\n\nGI=0.0,0.0,0.0\n\nBV=48.53\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
36	085315718563	2016-10-13 18:08:46	2016-10-13 18:08:36	Time=13-10-2016 17:56:00\n\nGV=196.6,191.2,203.3\n\nGI=0.0,0.0,0.0\n\nBV=48.74\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
37	085315718563	2016-10-13 19:16:16	2016-10-13 19:16:06	Time=13-10-2016 18:56:00\n\nGV=208.3,201.6,207.0\n\nGI=0.0,0.0,0.0\n\nBV=48.79\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
38	085315718563	2016-10-13 19:17:10	2016-10-13 19:17:06	Time=13-10-2016 18:56:49\n\nGV=206.4,201.2,207.2\n\nGI=0.0,0.0,0.0\n\nBV=48.22\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
39	085315718563	2016-10-13 19:17:35	2016-10-13 19:17:26	Time=13-10-2016 18:57:11\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.87\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
40	085315718563	2016-10-13 20:23:45	2016-10-13 20:23:35	Time=13-10-2016 19:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.47\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
41	085315718563	2016-10-13 21:31:13	2016-10-14 09:51:34	Time=13-10-2016 20:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.33\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
42	085315718563	2016-10-13 21:32:15	2016-10-14 09:51:35	Time=13-10-2016 20:56:56\n\nGV=198.1,192.8,201.5\n\nGI=0.0,0.0,0.0\n\nBV=48.64\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
43	085315718563	2016-10-13 22:38:40	2016-10-14 09:51:35	Time=13-10-2016 21:56:00\n\nGV=210.8,204.6,215.5\n\nGI=0.0,0.0,0.0\n\nBV=48.93\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
44	085315718563	2016-10-13 23:46:06	2016-10-14 09:51:36	Time=13-10-2016 22:56:01\n\nGV=217.5,209.6,219.2\n\nGI=0.0,0.0,0.0\n\nBV=48.96\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
45	085315718563	2016-10-13 23:47:11	2016-10-14 09:51:36	Time=13-10-2016 22:56:58\n\nGV=217.6,211.2,217.1\n\nGI=0.0,0.0,0.0\n\nBV=48.57\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
46	085315718563	2016-10-13 23:47:36	2016-10-14 09:51:37	Time=13-10-2016 22:57:21\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.20\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
47	085315718563	2016-10-14 00:53:31	2016-10-14 09:51:37	Time=13-10-2016 23:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.60\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
48	085315718563	2016-10-14 02:00:54	2016-10-14 09:51:38	Time=14-10-2016 00:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.77\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
49	085315718563	2016-10-14 02:02:08	2016-10-14 09:51:38	Time=14-10-2016 00:57:06\n\nGV=213.9,208.4,217.0\n\nGI=0.0,0.0,0.0\n\nBV=48.68\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
50	085315718563	2016-10-14 03:08:18	2016-10-14 09:51:39	Time=14-10-2016 01:56:01\n\nGV=215.6,213.4,221.5\n\nGI=0.0,0.0,0.0\n\nBV=48.10\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
51	085315718563	2016-10-14 04:15:42	2016-10-14 09:51:39	Time=14-10-2016 02:56:01\n\nGV=210.4,205.6,212.9\n\nGI=0.0,0.0,0.0\n\nBV=48.47\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
52	085315718563	2016-10-14 04:16:58	2016-10-14 09:51:40	Time=14-10-2016 02:57:08\n\nGV=214.0,207.7,214.9\n\nGI=0.0,0.0,0.0\n\nBV=48.46\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
53	085315718563	2016-10-14 04:17:23	2016-10-14 09:51:40	Time=14-10-2016 02:57:31\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.28\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
54	0811230444	2016-10-14 05:09:12	2016-10-14 09:51:41	tesss	\N	085210588635	\N	7
55	085315718563	2016-10-14 05:23:03	2016-10-14 09:51:41	Time=14-10-2016 03:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.32\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
56	085315718563	2016-10-14 06:30:26	2016-10-14 09:51:41	Time=14-10-2016 04:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.45\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
57	085315718563	2016-10-14 06:31:50	2016-10-14 09:51:42	Time=14-10-2016 04:57:16\n\nGV=194.0,188.4,197.8\n\nGI=0.0,0.0,0.0\n\nBV=48.24\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
58	085315718563	2016-10-14 07:37:51	2016-10-14 09:51:42	Time=14-10-2016 05:56:01\n\nGV=199.4,197.1,201.7\n\nGI=0.0,0.0,0.0\n\nBV=49.09\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
59	085315718563	2016-10-14 08:45:40	2016-10-14 09:51:43	Time=14-10-2016 06:56:01\n\nGV=193.4,188.1,194.9\n\nGI=0.0,0.0,0.0\n\nBV=48.35\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
60	085315718563	2016-10-14 08:46:58	2016-10-14 09:51:43	Time=14-10-2016 06:57:19\n\nGV=198.7,188.2,194.7\n\nGI=0.0,0.0,0.0\n\nBV=48.66\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
61	085315718563	2016-10-14 08:47:14	2016-10-14 09:51:44	Time=14-10-2016 06:57:41\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.41\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
62	085315718563	2016-10-14 09:52:55	2016-10-14 09:52:45	Time=14-10-2016 07:56:00\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.29\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
63	085315718563	2016-10-14 11:00:31	2016-10-14 11:00:21	Time=14-10-2016 08:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.18\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
64	085315718563	2016-10-14 11:02:07	2016-10-14 11:01:57	Time=14-10-2016 08:57:26\n\nGV=204.3,197.8,206.9\n\nGI=0.0,0.0,0.0\n\nBV=48.67\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
65	085210731792	2016-10-14 12:43:01	2016-10-14 14:21:05	Ayah isiin dl plsa as 20rb di no 082323290162 skrng penting	\N	085210588635	\N	7
66	085315718563	2016-10-14 13:15:51	2016-10-14 14:21:06	Time=14-10-2016 10:56:01\n\nGV=202.1,198.5,202.4\n\nGI=0.0,0.0,0.0\n\nBV=48.29\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
67	085315718563	2016-10-14 12:08:08	2016-10-14 14:21:05	Time=14-10-2016 09:56:01\n\nGV=210.0,204.0,209.9\n\nGI=0.0,0.0,0.0\n\nBV=48.91\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
68	085315718563	2016-10-14 13:17:30	2016-10-14 14:21:06	Time=14-10-2016 10:57:29\n\nGV=197.9,193.3,200.9\n\nGI=0.0,0.0,0.0\n\nBV=48.66\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
69	085315718563	2016-10-14 13:17:55	2016-10-14 14:21:07	Time=14-10-2016 10:57:51\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.42\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
70	085315718563	2016-10-14 14:23:27	2016-10-14 14:24:04	Time=14-10-2016 11:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.68\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
71	085315718563	2016-10-14 15:31:05	2016-10-14 15:30:55	Time=14-10-2016 12:56:00\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=47.71\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
72	085315718563	2016-10-14 15:32:53	2016-10-14 15:32:55	Time=14-10-2016 12:57:36\n\nGV=198.0,193.4,199.1\n\nGI=0.0,0.0,0.0\n\nBV=48.29\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
73	085315718563	2016-10-14 16:38:38	2016-10-14 16:38:56	Time=14-10-2016 13:56:01\n\nGV=203.6,196.5,206.2\n\nGI=0.0,0.0,0.0\n\nBV=48.68\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
74	085315718563	2016-10-14 17:46:09	2016-10-14 17:45:59	Time=14-10-2016 14:56:00\n\nGV=201.5,197.8,203.1\n\nGI=0.0,0.0,0.0\n\nBV=48.47\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
75	085315718563	2016-10-14 17:48:01	2016-10-14 17:47:59	Time=14-10-2016 14:57:39\n\nGV=205.2,200.6,205.5\n\nGI=0.0,0.0,0.0\n\nBV=47.81\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
76	085315718563	2016-10-14 17:48:24	2016-10-14 17:48:14	Time=14-10-2016 14:58:00\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.02\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
77	085315718563	2016-10-14 18:53:39	2016-10-14 18:54:15	Time=14-10-2016 15:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.28\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
78	085315718563	2016-10-15 07:15:37	2016-10-15 07:15:27	Time=15-10-2016 02:56:01\n\nGV=195.7,189.5,194.4\n\nGI=0.0,0.0,0.0\n\nBV=48.31\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
79	085315718563	2016-10-15 07:18:01	2016-10-15 07:17:51	Time=15-10-2016 02:58:09\n\nGV=199.4,192.8,200.0\n\nGI=0.0,0.0,0.0\n\nBV=48.17\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
80	085315718563	2016-10-15 07:18:26	2016-10-15 07:18:51	Time=15-10-2016 02:58:31\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.11\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
81	085315718563	2016-10-15 08:23:07	2016-10-15 08:22:57	Time=15-10-2016 03:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.08\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
82	085315718563	2016-10-15 09:30:42	2016-10-15 09:30:58	Time=15-10-2016 04:56:00\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.58\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
86	085315718563	2016-10-15 11:45:53	2016-10-15 11:45:54	Time=15-10-2016 06:56:01\n\nGV=204.3,201.8,205.3\n\nGI=0.0,0.0,0.0\n\nBV=48.61\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
83	085315718563	2016-10-15 09:33:15	2016-10-15 09:33:04	Time=15-10-2016 04:58:16\n\nGV=183.2,180.5,186.8\n\nGI=0.0,0.0,0.0\n\nBV=48.10\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
84	085315718563	2016-10-15 10:38:19	2016-10-15 10:38:09	Time=15-10-2016 05:56:01\n\nGV=193.7,189.6,194.8\n\nGI=0.0,0.0,0.0\n\nBV=48.96\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
85	OPTIN TSEL	2016-10-15 11:37:04	2016-10-15 11:36:53	Ambil bonus harianmu di *600# (Bebas Pulsa). Dptkan gratis nelpon atau internetan dan promo lainnya sesuai hobimu!	\N	085210588635	\N	7
87	085315718563	2016-10-15 11:48:28	2016-10-15 11:48:18	Time=15-10-2016 06:58:19\n\nGV=203.0,199.6,206.2\n\nGI=0.0,0.0,0.0\n\nBV=48.51\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
88	085315718563	2016-10-15 11:48:53	2016-10-15 11:48:43	Time=15-10-2016 06:58:41\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.60\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
89	085315718563	2016-10-15 12:53:27	2016-10-15 12:53:17	Time=15-10-2016 07:56:00\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.60\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
90	085315718563	2016-10-15 14:01:03	2016-10-15 14:01:17	Time=15-10-2016 08:56:00\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.53\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
91	085315718563	2016-10-15 14:03:47	2016-10-15 14:04:17	Time=15-10-2016 08:58:26\n\nGV=200.0,193.6,200.8\n\nGI=0.0,0.0,0.0\n\nBV=48.55\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
92	085315718563	2016-10-15 15:08:38	2016-10-15 15:08:28	Time=15-10-2016 09:56:01\n\nGV=199.9,196.1,204.6\n\nGI=0.0,0.0,0.0\n\nBV=47.64\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
93	085315718563	2016-10-15 16:16:10	2016-10-15 16:16:29	Time=15-10-2016 10:56:00\n\nGV=205.7,200.7,208.1\n\nGI=0.0,0.0,0.0\n\nBV=48.60\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nRS=1\n\nBS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
94	085315718563	2016-10-15 16:19:22	2016-10-15 16:19:30	Time=15-10-2016 10:58:51\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.21\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
95	085315718563	2016-10-15 17:23:39	2016-10-15 17:23:30	Time=15-10-2016 11:56:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.67\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nRS=0\n\nBS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
96	085315718563	2016-10-15 18:59:05	2016-10-15 18:58:54	Time=15-10-2016 18:58:56\n\nGV=207.2,200.1,204.8\n\nGI=0.0,0.0,0.0\n\nBV=48.68\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
97	085315718563	2016-10-15 18:59:27	2016-10-15 18:59:18	Time=15-10-2016 18:59:18\n\nGV=204.4,198.9,206.4\n\nGI=0.0,0.0,0.0\n\nBV=48.46\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
98	085315718563	2016-10-15 20:58:13	2016-10-16 10:39:15	Time=15-10-2016 20:58:01\n\nGV=198.6,194.1,204.5\n\nGI=0.0,0.0,0.0\n\nBV=48.73\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
99	085315718563	2016-10-15 19:58:13	2016-10-16 10:39:15	Time=15-10-2016 19:58:01\n\nGV=202.7,196.9,205.1\n\nGI=0.0,0.0,0.0\n\nBV=48.07\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
100	085315718563	2016-10-15 20:59:34	2016-10-16 10:39:16	Time=15-10-2016 20:59:22\n\nGV=195.5,190.7,198.3\n\nGI=0.0,0.0,0.0\n\nBV=48.61\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
101	085315718563	2016-10-15 20:59:59	2016-10-16 10:39:16	Time=15-10-2016 20:59:46\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.74\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
102	085315718563	2016-10-15 21:58:13	2016-10-16 10:39:16	Time=15-10-2016 21:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.81\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
103	085315718563	2016-10-15 22:58:13	2016-10-16 10:39:17	Time=15-10-2016 22:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.44\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
104	085315718563	2016-10-15 22:59:48	2016-10-16 10:39:17	Time=15-10-2016 22:59:36\n\nGV=212.3,206.1,214.9\n\nGI=0.0,0.0,0.0\n\nBV=48.14\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
105	085315718563	2016-10-15 23:58:13	2016-10-16 10:39:18	Time=15-10-2016 23:58:01\n\nGV=214.6,208.2,215.1\n\nGI=0.0,0.0,0.0\n\nBV=48.67\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
106	085315718563	2016-10-16 00:58:12	2016-10-16 10:39:18	Time=16-10-2016 00:58:01\n\nGV=220.2,215.3,221.7\n\nGI=0.0,0.0,0.0\n\nBV=48.32\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
107	085315718563	2016-10-16 01:00:20	2016-10-16 10:39:19	Time=16-10-2016 01:00:12\n\nGV=218.6,212.4,223.2\n\nGI=0.0,0.0,0.0\n\nBV=48.48\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
108	085315718563	2016-10-16 01:00:44	2016-10-16 10:39:19	Time=16-10-2016 01:00:36\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.42\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
109	085315718563	2016-10-16 01:58:13	2016-10-16 10:39:20	Time=16-10-2016 01:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.33\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
110	085315718563	2016-10-16 02:58:12	2016-10-16 10:39:20	Time=16-10-2016 02:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.70\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
111	085315718563	2016-10-16 03:00:34	2016-10-16 10:39:21	Time=16-10-2016 03:00:26\n\nGV=220.9,214.6,221.7\n\nGI=0.0,0.0,0.0\n\nBV=48.28\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
112	085315718563	2016-10-16 03:00:58	2016-10-16 10:39:21	Time=16-10-2016 03:00:50\n\nGV=222.0,216.0,220.9\n\nGI=0.0,0.0,0.0\n\nBV=48.47\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
113	085315718563	2016-10-16 03:58:12	2016-10-16 10:39:22	Time=16-10-2016 03:58:01\n\nGV=218.1,213.8,220.1\n\nGI=0.0,0.0,0.0\n\nBV=48.34\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
114	085315718563	2016-10-16 04:58:12	2016-10-16 10:39:22	Time=16-10-2016 04:58:01\n\nGV=200.5,195.0,202.6\n\nGI=0.0,0.0,0.0\n\nBV=48.82\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
115	085315718563	2016-10-16 05:01:06	2016-10-16 10:39:23	Time=16-10-2016 05:00:58\n\nGV=193.9,189.6,199.0\n\nGI=0.0,0.0,0.0\n\nBV=48.94\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
116	085315718563	2016-10-16 05:01:29	2016-10-16 10:39:23	Time=16-10-2016 05:01:21\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.37\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
117	085315718563	2016-10-16 05:58:12	2016-10-16 10:39:23	Time=16-10-2016 05:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.92\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
118	0811230444	2016-10-16 06:05:06	2016-10-16 10:39:24	tess	\N	085210588635	\N	7
119	085315718563	2016-10-16 06:58:12	2016-10-16 10:39:24	Time=16-10-2016 06:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.73\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
120	085315718563	2016-10-16 07:01:19	2016-10-16 10:39:25	Time=16-10-2016 07:01:11\n\nGV=200.6,197.8,204.7\n\nGI=0.0,0.0,0.0\n\nBV=48.67\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
121	085315718563	2016-10-16 07:01:44	2016-10-16 10:39:25	Time=16-10-2016 07:01:36\n\nGV=203.6,196.9,204.9\n\nGI=0.0,0.0,0.0\n\nBV=48.59\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
122	085315718563	2016-10-16 07:58:12	2016-10-16 10:39:26	Time=16-10-2016 07:58:01\n\nGV=183.2,176.6,183.0\n\nGI=0.0,0.0,0.0\n\nBV=48.41\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
123	085315718563	2016-10-16 08:58:12	2016-10-16 10:39:26	Time=16-10-2016 08:58:01\n\nGV=182.6,178.1,184.4\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
124	085315718563	2016-10-16 09:01:51	2016-10-16 10:39:27	Time=16-10-2016 09:01:44\n\nGV=188.4,183.8,193.7\n\nGI=0.0,0.0,0.0\n\nBV=48.59\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
125	085315718563	2016-10-16 09:02:14	2016-10-16 10:39:27	Time=16-10-2016 09:02:06\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.35\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
126	085315718563	2016-10-16 09:58:12	2016-10-16 10:39:28	Time=16-10-2016 09:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.32\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
127	085315718563	2016-10-16 10:58:11	2016-10-16 10:58:01	Time=16-10-2016 10:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.38\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
128	085315718563	2016-10-16 11:02:07	2016-10-16 11:02:01	Time=16-10-2016 11:02:00\n\nGV=203.7,198.8,206.0\n\nGI=0.0,0.0,0.0\n\nBV=48.71\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
129	085315718563	2016-10-16 11:02:29	2016-10-16 11:02:18	Time=16-10-2016 11:02:22\n\nGV=204.6,200.0,206.6\n\nGI=0.0,0.0,0.0\n\nBV=48.77\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
130	085315718563	2016-10-16 11:58:12	2016-10-16 11:58:19	Time=16-10-2016 11:58:01\n\nGV=205.8,200.9,207.2\n\nGI=0.0,0.0,0.0\n\nBV=48.47\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
131	085315718563	2016-10-16 13:02:37	2016-10-16 13:02:26	Time=16-10-2016 13:02:30\n\nGV=199.6,193.9,199.5\n\nGI=0.0,0.0,0.0\n\nBV=49.05\n\nBI=0.0\n\nGBV=1.1\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
132	085315718563	2016-10-16 13:02:58	2016-10-16 13:02:48	Time=16-10-2016 13:02:51\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.35\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
133	085315718563	2016-10-16 14:58:11	2016-10-16 20:33:17	Time=16-10-2016 14:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.98\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
134	085315718563	2016-10-16 13:58:11	2016-10-16 20:33:17	Time=16-10-2016 13:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.58\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
135	085315718563	2016-10-16 15:02:53	2016-10-16 20:33:18	Time=16-10-2016 15:02:46\n\nGV=208.2,200.0,207.2\n\nGI=0.0,0.0,0.0\n\nBV=48.38\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
136	085315718563	2016-10-16 15:03:14	2016-10-16 20:33:18	Time=16-10-2016 15:03:08\n\nGV=204.3,199.0,209.2\n\nGI=0.0,0.0,0.0\n\nBV=48.44\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
137	085315718563	2016-10-16 15:58:11	2016-10-16 20:33:19	Time=16-10-2016 15:58:01\n\nGV=204.5,199.6,205.3\n\nGI=0.0,0.0,0.0\n\nBV=48.61\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
138	085315718563	2016-10-16 16:58:11	2016-10-16 20:33:19	Time=16-10-2016 16:58:01\n\nGV=202.8,199.9,207.7\n\nGI=0.0,0.0,0.0\n\nBV=48.62\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
139	085315718563	2016-10-16 17:03:26	2016-10-16 20:33:19	Time=16-10-2016 17:03:19\n\nGV=205.5,198.0,205.3\n\nGI=0.0,0.0,0.0\n\nBV=48.62\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
140	085315718563	2016-10-16 17:03:48	2016-10-16 20:33:20	Time=16-10-2016 17:03:41\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.90\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
141	085315718563	2016-10-16 17:58:11	2016-10-16 20:33:20	Time=16-10-2016 17:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.50\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
142	085315718563	2016-10-16 18:58:11	2016-10-16 20:33:21	Time=16-10-2016 18:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.32\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
143	085315718563	2016-10-16 19:03:43	2016-10-16 20:33:21	Time=16-10-2016 19:03:36\n\nGV=197.0,192.4,199.7\n\nGI=0.0,0.0,0.0\n\nBV=47.94\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
144	085315718563	2016-10-16 19:04:03	2016-10-16 20:33:22	Time=16-10-2016 19:03:57\n\nGV=198.7,192.9,198.1\n\nGI=0.0,0.0,0.0\n\nBV=48.71\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
145	085315718563	2016-10-16 19:58:11	2016-10-16 20:33:22	Time=16-10-2016 19:58:01\n\nGV=192.6,187.7,195.2\n\nGI=0.0,0.0,0.0\n\nBV=48.37\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
146	085315718563	2016-10-16 20:58:11	2016-10-16 20:58:14	Time=16-10-2016 20:58:01\n\nGV=201.3,194.7,204.8\n\nGI=0.0,0.0,0.0\n\nBV=48.68\n\nBI=0.0\n\nGBV=1.3\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
147	085315718563	2016-10-16 21:04:11	2016-10-16 21:04:00	Time=16-10-2016 21:04:05\n\nGV=203.8,199.4,207.8\n\nGI=0.0,0.0,0.0\n\nBV=48.42\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
148	085315718563	2016-10-16 21:04:33	2016-10-16 21:05:00	Time=16-10-2016 21:04:26\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.55\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
149	085315718563	2016-10-16 21:58:11	2016-10-16 21:58:01	Time=16-10-2016 21:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.72\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
150	085315718563	2016-10-16 22:58:10	2016-10-16 22:58:00	Time=16-10-2016 22:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.58\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
151	085315718563	2016-10-16 23:04:27	2016-10-16 23:04:17	Time=16-10-2016 23:04:21\n\nGV=214.5,208.3,219.6\n\nGI=0.0,0.0,0.0\n\nBV=48.52\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
152	085315718563	2016-10-16 23:04:49	2016-10-16 23:04:38	Time=16-10-2016 23:04:43\n\nGV=212.7,209.0,218.4\n\nGI=0.0,0.0,0.0\n\nBV=48.64\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
153	085315718563	2016-10-16 23:58:10	2016-10-16 23:58:00	Time=16-10-2016 23:58:01\n\nGV=215.8,211.9,218.2\n\nGI=0.0,0.0,0.0\n\nBV=48.76\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
154	085315718563	2016-10-17 01:58:10	2016-10-17 01:58:00	Time=17-10-2016 01:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.17\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
155	085315718563	2016-10-17 02:58:10	2016-10-17 02:57:59	Time=17-10-2016 02:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.18\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
156	085315718563	2016-10-17 03:05:12	2016-10-17 03:05:01	Time=17-10-2016 03:05:06\n\nGV=218.1,214.4,220.9\n\nGI=0.0,0.0,0.0\n\nBV=48.21\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
157	085315718563	2016-10-17 03:05:35	2016-10-17 03:05:24	Time=17-10-2016 03:05:29\n\nGV=218.6,212.5,220.7\n\nGI=0.0,0.0,0.0\n\nBV=48.69\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
158	085315718563	2016-10-17 03:58:10	2016-10-17 03:58:00	Time=17-10-2016 03:58:01\n\nGV=216.5,213.5,221.4\n\nGI=0.0,0.0,0.0\n\nBV=48.78\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
159	085315718563	2016-10-17 04:58:10	2016-10-17 04:57:59	Time=17-10-2016 04:58:01\n\nGV=186.6,181.4,189.1\n\nGI=0.0,0.0,0.0\n\nBV=49.18\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
160	085315718563	2016-10-17 05:05:42	2016-10-17 05:05:32	Time=17-10-2016 05:05:37\n\nGV=192.2,185.7,195.2\n\nGI=0.0,0.0,0.0\n\nBV=48.49\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
161	085315718563	2016-10-17 05:06:06	2016-10-17 05:06:32	Time=17-10-2016 05:06:00\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.64\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
162	085315718563	2016-10-17 05:58:10	2016-10-17 05:57:59	Time=17-10-2016 05:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.27\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
163	085315718563	2016-10-17 06:58:10	2016-10-17 06:58:27	Time=17-10-2016 06:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.97\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
165	085315718563	2016-10-17 07:06:21	2016-10-17 07:06:28	Time=17-10-2016 07:06:15\n\nGV=197.0,192.8,198.2\n\nGI=0.0,0.0,0.0\n\nBV=48.80\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
164	085315718563	2016-10-17 07:05:56	2016-10-17 07:06:28	Time=17-10-2016 07:05:51\n\nGV=198.5,190.7,198.3\n\nGI=0.0,0.0,0.0\n\nBV=48.73\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
166	085315718563	2016-10-17 07:58:09	2016-10-17 07:57:59	Time=17-10-2016 07:58:01\n\nGV=186.4,179.2,189.6\n\nGI=0.0,0.0,0.0\n\nBV=48.98\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
167	085315718563	2016-10-17 08:58:09	2016-10-17 08:58:00	Time=17-10-2016 08:58:01\n\nGV=201.9,194.3,200.8\n\nGI=0.0,0.0,0.0\n\nBV=48.85\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
168	085315718563	2016-10-17 09:06:28	2016-10-17 09:07:00	Time=17-10-2016 09:06:23\n\nGV=200.9,194.9,200.6\n\nGI=0.0,0.0,0.0\n\nBV=48.91\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
169	085315718563	2016-10-17 09:06:51	2016-10-17 09:07:01	Time=17-10-2016 09:06:46\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.43\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
170	087825411059	2016-10-17 20:30:23	2016-10-17 20:31:15	Time=29-09-2016 17:00:00\n\nGv=220.25,220.02,219.50\n\nGi=3.32,3.30,3.23\n\nBv=48.55\n\nBi=3.40\n\nGbv=20.34\n\nGo=0\n\nRs=1\n\nBs=1\n\nGf=0\n\nLf=0\n\nRf=0\n\nBlv=0\n\nCdc=1	\N	085210588635	\N	7
171	085315718563	2016-10-17 20:58:08	2016-10-17 20:58:03	Time=17-10-2016 20:58:01\n\nGV=202.2,193.8,201.7\n\nGI=0.0,0.0,0.0\n\nBV=48.83\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
172	085315718563	2016-10-17 21:58:08	2016-10-17 21:58:04	Time=17-10-2016 21:58:01\n\nGV=207.2,199.4,206.6\n\nGI=0.0,0.0,0.0\n\nBV=48.72\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
173	085315718563	2016-10-17 22:08:49	2016-10-17 22:09:05	Time=17-10-2016 22:08:45\n\nGV=205.7,200.9,206.3\n\nGI=0.0,0.0,0.0\n\nBV=48.61\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
174	085315718563	2016-10-17 22:08:49	2016-10-17 22:09:06	Time=17-10-2016 22:08:45\n\nGV=205.7,200.9,206.3\n\nGI=0.0,0.0,0.0\n\nBV=48.61\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
175	085315718563	2016-10-17 22:09:10	2016-10-17 22:09:06	Time=17-10-2016 22:09:06\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.79\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
176	085315718563	2016-10-17 22:58:08	2016-10-17 22:58:13	Time=17-10-2016 22:58:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.68\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
177	087825411059	2016-10-18 06:48:27	2016-10-18 06:48:32	Time=29-09-2016 19:00:00\n\nGv=220.25,220.02,219.50\n\nGi=3.32,3.30,3.23\n\nBv=48.55\n\nBi=3.40\n\nGbv=20.34\n\nGo=0\n\nRs=1\n\nBs=1\n\nGf=0\n\nLf=0\n\nRf=0\n\nBlv=0\n\nCdc=2	\N	Modem1	\N	7
178	085315718563	2016-10-18 14:02:11	2016-10-18 14:02:06	Time=18-10-2016 11:12:31\n\nGV=203.9,198.0,204.4\n\nGI=0.0,0.0,0.0\n\nBV=48.30\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
179	085315718563	2016-10-18 14:02:36	2016-10-18 14:02:31	Time=18-10-2016 11:12:56\n\nGV=200.7,194.7,201.2\n\nGI=0.0,0.0,0.0\n\nBV=48.37\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	085210588635	\N	7
180	087825411059	2016-10-18 14:34:11	2016-10-18 14:34:15	Time=29-09-2016 19:00:00\n\nGv=220.25,220.02,219.50\n\nGi=3.32,3.30,3.23\n\nBv=48.55\n\nBi=3.40\n\nGbv=20.34\n\nGo=0\n\nRs=1\n\nBs=1\n\nGf=0\n\nLf=0\n\nRf=0\n\nBlv=0\n\nCdc=2	\N	Modem1	\N	7
181	085315718563	2016-10-18 15:01:08	2016-10-18 15:01:03	Time=18-10-2016 15:01:01\n\nGV=203.2,195.3,204.1\n\nGI=0.0,0.0,0.0\n\nBV=48.34\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
182	085315718563	2016-10-18 16:01:08	2016-10-18 16:01:05	Time=18-10-2016 16:01:01\n\nGV=195.2,190.1,198.7\n\nGI=0.0,0.0,0.0\n\nBV=48.66\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
183	085315718563	2016-10-18 17:01:08	2016-10-18 17:01:11	Time=18-10-2016 17:01:01\n\nGV=209.3,203.6,209.3\n\nGI=0.0,0.0,0.0\n\nBV=48.74\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
184	085315718563	2016-10-18 17:02:47	2016-10-18 17:02:42	Time=18-10-2016 17:02:40\n\nGV=204.7,199.0,206.6\n\nGI=0.0,0.0,0.0\n\nBV=48.51\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
185	085315718563	2016-10-18 17:03:08	2016-10-18 17:03:04	Time=18-10-2016 17:03:00\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=49.01\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
186	085315718563	2016-10-18 18:01:08	2016-10-18 18:01:12	Time=18-10-2016 18:01:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.63\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
187	085315718563	2016-10-18 19:01:08	2016-10-18 19:01:12	Time=18-10-2016 19:01:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.99\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
188	085315718563	2016-10-18 19:01:08	2016-10-18 19:01:11	Time=18-10-2016 19:01:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.99\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
189	085315718563	2016-10-18 19:03:03	2016-10-18 19:03:04	Time=18-10-2016 19:02:56\n\nGV=188.9,182.3,190.3\n\nGI=0.0,0.0,0.0\n\nBV=48.26\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
190	085315718563	2016-10-18 19:03:25	2016-10-18 19:03:25	Time=18-10-2016 19:03:18\n\nGV=189.7,185.1,190.1\n\nGI=0.0,0.0,0.0\n\nBV=48.39\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
191	085315718563	2016-10-18 20:01:07	2016-10-18 20:01:03	Time=18-10-2016 20:01:01\n\nGV=196.0,190.3,201.1\n\nGI=0.0,0.0,0.0\n\nBV=48.63\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
192	085315718563	2016-10-18 21:01:07	2016-10-18 21:01:03	Time=18-10-2016 21:01:01\n\nGV=199.7,193.6,201.8\n\nGI=0.0,0.0,0.0\n\nBV=49.17\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
193	085315718563	2016-10-18 22:01:07	2016-10-18 22:01:09	Time=18-10-2016 22:01:01\n\nGV=195.8,193.0,199.4\n\nGI=0.0,0.0,0.0\n\nBV=48.72\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
194	085315718563	2016-10-18 22:03:37	2016-10-18 22:03:31	Time=18-10-2016 22:03:30\n\nGV=194.8,192.7,195.6\n\nGI=0.0,0.0,0.0\n\nBV=48.15\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
195	085315718563	2016-10-18 22:03:58	2016-10-18 22:03:52	Time=18-10-2016 22:03:51\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.72\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
196	085315718563	2016-10-18 23:01:07	2016-10-18 23:01:03	Time=18-10-2016 23:01:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.40\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
197	085315718563	2016-10-19 00:01:07	2016-10-19 00:01:09	Time=19-10-2016 00:01:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.81\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
198	085315718563	2016-10-19 00:03:53	2016-10-19 00:03:52	Time=19-10-2016 00:03:46\n\nGV=209.9,205.6,210.5\n\nGI=0.0,0.0,0.0\n\nBV=48.59\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
199	085315718563	2016-10-19 00:04:14	2016-10-19 00:04:13	Time=19-10-2016 00:04:08\n\nGV=210.8,204.8,209.7\n\nGI=0.0,0.0,0.0\n\nBV=48.34\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
200	085315718563	2016-10-19 01:01:07	2016-10-19 01:01:11	Time=19-10-2016 01:01:01\n\nGV=209.6,202.6,210.9\n\nGI=0.0,0.0,0.0\n\nBV=48.70\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
201	085315718563	2016-10-19 02:01:07	2016-10-19 02:01:11	Time=19-10-2016 02:01:01\n\nGV=213.5,209.0,215.9\n\nGI=0.0,0.0,0.0\n\nBV=48.43\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
202	085315718563	2016-10-19 03:01:07	2016-10-19 03:01:11	Time=19-10-2016 03:01:01\n\nGV=217.2,212.5,219.0\n\nGI=0.0,0.0,0.0\n\nBV=48.54\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
203	085315718563	2016-10-19 03:04:26	2016-10-19 03:04:23	Time=19-10-2016 03:04:20\n\nGV=212.4,207.4,217.2\n\nGI=0.0,0.0,0.0\n\nBV=48.34\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
204	085315718563	2016-10-19 03:04:47	2016-10-19 03:04:44	Time=19-10-2016 03:04:41\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.54\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
205	085315718563	2016-10-19 04:01:07	2016-10-19 04:01:02	Time=19-10-2016 04:01:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.66\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
206	085315718563	2016-10-19 05:01:07	2016-10-19 05:01:09	Time=19-10-2016 05:01:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.71\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
207	085315718563	2016-10-19 05:04:42	2016-10-19 05:04:41	Time=19-10-2016 05:04:36\n\nGV=191.1,184.9,190.1\n\nGI=0.0,0.0,0.0\n\nBV=48.52\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
208	085315718563	2016-10-19 05:05:04	2016-10-19 05:05:02	Time=19-10-2016 05:04:58\n\nGV=192.2,186.7,193.4\n\nGI=0.0,0.0,0.0\n\nBV=48.37\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
209	085315718563	2016-10-19 06:01:06	2016-10-19 06:01:04	Time=19-10-2016 06:01:01\n\nGV=188.2,184.2,193.4\n\nGI=0.0,0.0,0.0\n\nBV=49.07\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
210	085315718563	2016-10-19 07:01:06	2016-10-19 07:01:06	Time=19-10-2016 07:01:01\n\nGV=197.6,191.6,197.4\n\nGI=0.0,0.0,0.0\n\nBV=48.42\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
211	085315718563	2016-10-19 09:01:06	2016-10-19 09:01:06	Time=19-10-2016 09:01:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.14\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
212	085315718563	2016-10-19 11:03:09	2016-10-19 11:03:14	Time=19-10-2016 11:03:01\n\nGV=194.3,192.2,197.9\n\nGI=0.0,0.0,0.0\n\nBV=48.82\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
213	085315718563	2016-10-19 12:03:09	2016-10-19 12:03:12	Time=19-10-2016 12:03:01\n\nGV=205.7,200.8,208.8\n\nGI=0.0,0.0,0.0\n\nBV=48.27\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
214	085315718563	2016-10-19 12:04:24	2016-10-19 12:04:24	Time=19-10-2016 12:04:17\n\nGV=206.3,201.7,211.5\n\nGI=0.0,0.0,0.0\n\nBV=48.78\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
215	085315718563	2016-10-19 12:04:49	2016-10-19 12:04:45	Time=19-10-2016 12:04:41\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.23\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
216	085315718563	2016-10-19 12:04:49	2016-10-19 12:04:45	Time=19-10-2016 12:04:41\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.23\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
217	085315718563	2016-10-19 13:03:09	2016-10-19 13:03:13	Time=19-10-2016 13:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.58\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
218	085315718563	2016-10-19 14:03:09	2016-10-19 14:03:11	Time=19-10-2016 14:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.49\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
219	085315718563	2016-10-19 14:04:39	2016-10-19 14:04:41	Time=19-10-2016 14:04:31\n\nGV=203.8,198.8,205.9\n\nGI=0.0,0.0,0.0\n\nBV=48.86\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
220	085315718563	2016-10-19 14:05:03	2016-10-19 14:05:04	Time=19-10-2016 14:04:55\n\nGV=204.9,199.8,206.1\n\nGI=0.0,0.0,0.0\n\nBV=48.26\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
221	085315718563	2016-10-19 15:03:08	2016-10-19 15:03:07	Time=19-10-2016 15:03:01\n\nGV=201.6,194.5,202.6\n\nGI=0.0,0.0,0.0\n\nBV=48.73\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
222	085315718563	2016-10-19 16:03:08	2016-10-19 18:21:24	Time=19-10-2016 16:03:01\n\nGV=202.2,198.2,205.8\n\nGI=0.0,0.0,0.0\n\nBV=48.89\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
223	085315718563	2016-10-19 17:03:08	2016-10-19 18:21:25	Time=19-10-2016 17:03:01\n\nGV=202.3,194.4,201.3\n\nGI=0.0,0.0,0.0\n\nBV=48.49\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
224	085315718563	2016-10-19 17:05:14	2016-10-19 18:21:25	Time=19-10-2016 17:05:07\n\nGV=206.7,198.6,205.5\n\nGI=0.0,0.0,0.0\n\nBV=48.44\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
225	085315718563	2016-10-19 17:05:39	2016-10-19 18:21:26	Time=19-10-2016 17:05:31\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.22\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
226	085315718563	2016-10-19 18:03:08	2016-10-19 18:21:26	Time=19-10-2016 18:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.62\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
227	081224852002	2016-10-19 18:23:00	2016-10-19 18:22:57	Test	\N	Modem1	\N	7
228	085315718563	2016-10-19 19:03:08	2016-10-19 19:03:14	Time=19-10-2016 19:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.48\n\nBI=0.0\n\nGBV=1.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
229	085315718563	2016-10-19 19:05:28	2016-10-19 19:05:26	Time=19-10-2016 19:05:21\n\nGV=194.0,188.4,198.5\n\nGI=0.0,0.0,0.0\n\nBV=48.63\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
230	085315718563	2016-10-19 19:05:52	2016-10-19 19:05:57	Time=19-10-2016 19:05:45\n\nGV=193.1,187.9,196.0\n\nGI=0.0,0.0,0.0\n\nBV=48.64\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
231	085315718563	2016-10-19 20:03:08	2016-10-19 20:03:05	Time=19-10-2016 20:03:01\n\nGV=193.8,187.5,193.9\n\nGI=0.0,0.0,0.0\n\nBV=48.45\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
232	085315718563	2016-10-19 21:03:07	2016-10-19 21:03:05	Time=19-10-2016 21:03:01\n\nGV=196.3,191.4,200.8\n\nGI=0.0,0.0,0.0\n\nBV=48.28\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
233	085315718563	2016-10-19 22:06:28	2016-10-19 22:53:42	Time=19-10-2016 22:06:21\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.57\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
234	085315718563	2016-10-19 22:03:07	2016-10-19 22:53:41	Time=19-10-2016 22:03:01\n\nGV=195.3,189.2,198.4\n\nGI=0.0,0.0,0.0\n\nBV=48.49\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
235	085315718563	2016-10-19 22:06:04	2016-10-19 22:53:42	Time=19-10-2016 22:05:57\n\nGV=199.1,195.0,199.9\n\nGI=0.0,0.0,0.0\n\nBV=48.53\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
236	0811230444	2016-10-19 22:35:12	2016-10-19 22:53:43	tesss	\N	Modem1	\N	7
237	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:29	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
238	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:29	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
239	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:30	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
240	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:31	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
241	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:31	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
242	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:31	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
243	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:32	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
244	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:32	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
245	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:33	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
246	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:33	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
249	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:35	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
253	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:37	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
260	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:40	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
274	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:47	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
281	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:49	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
247	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:34	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
250	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:35	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
256	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:38	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
269	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:44	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
271	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:45	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
280	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:49	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
248	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:34	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
252	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:36	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
257	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:39	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
261	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:40	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
263	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:41	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
279	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:48	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
289	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:53	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
251	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:35	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
264	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:41	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
278	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:45	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
283	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:50	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
286	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:52	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
254	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:37	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
258	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:39	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
262	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:40	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
276	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:47	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
255	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:38	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
259	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:36	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
265	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:42	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
266	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:42	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
267	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:43	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
268	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:43	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
270	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:44	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
272	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:46	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
273	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:46	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
275	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:44	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
277	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:48	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
282	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:50	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
284	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:51	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
285	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:51	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
287	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:52	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
288	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:49	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
290	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:53	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
291	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:54	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
292	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:54	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
293	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:55	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
294	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:55	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
295	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:56	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
296	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:56	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
297	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:56	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
298	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:57	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
299	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:57	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
300	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:58	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
301	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:58	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
302	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:59	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
303	085315718563	2016-10-19 23:03:08	2016-10-19 23:55:59	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
304	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:00	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
305	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:00	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
306	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:01	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
307	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:01	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
308	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:01	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
309	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:02	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
310	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:03	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
311	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:03	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
312	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:04	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
313	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:04	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
314	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:04	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
315	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:05	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
319	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:07	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
322	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:08	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
336	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:15	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
316	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:05	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
328	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:11	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
332	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:12	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
337	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:15	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
345	085315718563	2016-10-20 00:06:42	2016-10-20 00:06:41	Time=20-10-2016 00:06:35\n\nGV=200.8,198.4,202.2\n\nGI=0.0,0.0,0.0\n\nBV=48.71\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
317	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:06	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
330	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:12	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
335	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:14	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
318	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:06	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
333	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:13	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
340	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:14	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
320	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:07	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
323	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:09	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
338	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:15	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
343	085315718563	2016-10-20 00:06:18	2016-10-20 00:06:19	Time=20-10-2016 00:06:11\n\nGV=200.1,194.5,203.5\n\nGI=0.0,0.0,0.0\n\nBV=48.67\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
321	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:08	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
325	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:10	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
324	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:09	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
339	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:16	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
326	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:10	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
329	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:08	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
327	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:11	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
331	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:12	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
341	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:02	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
334	085315718563	2016-10-19 23:03:08	2016-10-19 23:56:13	Time=19-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.25\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
342	085315718563	2016-10-20 00:03:08	2016-10-20 00:03:06	Time=20-10-2016 00:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.63\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
344	085315718563	2016-10-20 00:06:18	2016-10-20 00:06:19	Time=20-10-2016 00:06:11\n\nGV=200.1,194.5,203.5\n\nGI=0.0,0.0,0.0\n\nBV=48.67\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
346	085315718563	2016-10-20 06:03:07	2016-10-20 06:03:36	Time=20-10-2016 06:03:01\n\nGV=186.7,182.5,192.2\n\nGI=0.0,0.0,0.0\n\nBV=48.13\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
347	085315718563	2016-10-20 07:03:07	2016-10-20 07:03:09	Time=20-10-2016 07:03:01\n\nGV=199.9,198.8,203.2\n\nGI=0.0,0.0,0.0\n\nBV=48.46\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
348	085315718563	2016-10-20 08:03:07	2016-10-20 08:03:02	Time=20-10-2016 08:03:01\n\nGV=193.6,189.4,196.3\n\nGI=0.0,0.0,0.0\n\nBV=48.84\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
349	085315718563	2016-10-20 08:07:43	2016-10-20 08:07:46	Time=20-10-2016 08:07:37\n\nGV=198.6,196.4,203.8\n\nGI=0.0,0.0,0.0\n\nBV=48.65\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
350	085315718563	2016-10-20 08:08:06	2016-10-20 08:08:07	Time=20-10-2016 08:08:00\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.40\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
351	085315718563	2016-10-20 09:03:07	2016-10-20 09:03:03	Time=20-10-2016 09:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.56\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
352	085315718563	2016-10-20 17:03:06	2016-10-20 17:03:02	Time=20-10-2016 17:03:01\n\nGV=202.9,197.9,208.1\n\nGI=0.0,0.0,0.0\n\nBV=48.93\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
353	085315718563	2016-10-20 18:03:06	2016-10-20 18:03:01	Time=20-10-2016 18:03:01\n\nGV=193.5,188.3,195.8\n\nGI=0.0,0.0,0.0\n\nBV=48.66\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
354	085315718563	2016-10-20 18:09:22	2016-10-20 18:09:28	Time=20-10-2016 18:09:17\n\nGV=196.8,193.2,200.8\n\nGI=0.0,0.0,0.0\n\nBV=48.49\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
355	085315718563	2016-10-20 18:09:47	2016-10-20 18:09:49	Time=20-10-2016 18:09:41\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.56\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
356	085315718563	2016-10-20 19:03:05	2016-10-20 19:03:04	Time=20-10-2016 19:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.34\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
357	085315718563	2016-10-20 20:03:05	2016-10-20 20:03:05	Time=20-10-2016 20:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.78\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
358	085315718563	2016-10-20 20:09:36	2016-10-20 20:09:40	Time=20-10-2016 20:09:31\n\nGV=202.7,197.2,203.3\n\nGI=0.0,0.0,0.0\n\nBV=48.39\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
359	085315718563	2016-10-20 20:10:00	2016-10-20 20:09:56	Time=20-10-2016 20:09:55\n\nGV=200.7,194.9,202.4\n\nGI=0.0,0.0,0.0\n\nBV=48.41\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
360	085315718563	2016-10-20 21:03:05	2016-10-20 21:03:06	Time=20-10-2016 21:03:01\n\nGV=202.9,196.5,204.6\n\nGI=0.0,0.0,0.0\n\nBV=48.36\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
361	085315718563	2016-10-20 22:03:05	2016-10-20 22:03:07	Time=20-10-2016 22:03:01\n\nGV=204.7,196.3,202.1\n\nGI=0.0,0.0,0.0\n\nBV=48.43\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
362	085315718563	2016-10-21 06:03:04	2016-10-21 06:03:03	Time=21-10-2016 06:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.50\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
363	085315718563	2016-10-21 06:11:15	2016-10-21 06:11:20	Time=21-10-2016 06:11:11\n\nGV=200.8,194.9,202.2\n\nGI=0.0,0.0,0.0\n\nBV=48.83\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
364	085315718563	2016-10-21 06:11:39	2016-10-21 06:11:40	Time=21-10-2016 06:11:35\n\nGV=204.0,196.9,204.2\n\nGI=0.0,0.0,0.0\n\nBV=48.61\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
365	085315718563	2016-10-21 07:03:04	2016-10-21 07:03:05	Time=21-10-2016 07:03:01\n\nGV=199.8,195.7,198.7\n\nGI=0.0,0.0,0.0\n\nBV=48.58\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
366	085315718563	2016-10-21 08:03:04	2016-10-21 08:03:04	Time=21-10-2016 08:03:01\n\nGV=199.8,193.4,200.8\n\nGI=0.0,0.0,0.0\n\nBV=48.56\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
367	085315718563	2016-10-21 08:03:04	2016-10-21 08:03:05	Time=21-10-2016 08:03:01\n\nGV=199.8,193.4,200.8\n\nGI=0.0,0.0,0.0\n\nBV=48.56\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
368	085315718563	2016-10-21 09:03:04	2016-10-21 09:03:05	Time=21-10-2016 09:03:01\n\nGV=203.2,199.6,204.7\n\nGI=0.0,0.0,0.0\n\nBV=48.54\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
369	085315718563	2016-10-21 09:11:51	2016-10-21 09:11:50	Time=21-10-2016 09:11:47\n\nGV=208.4,200.0,207.9\n\nGI=0.0,0.0,0.0\n\nBV=48.39\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
370	085315718563	2016-10-21 09:12:15	2016-10-21 09:12:12	Time=21-10-2016 09:12:11\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.51\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
371	085315718563	2016-10-21 10:03:04	2016-10-21 10:02:59	Time=21-10-2016 10:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.63\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
372	085315718563	2016-10-21 10:03:04	2016-10-21 10:02:59	Time=21-10-2016 10:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.63\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
373	085315718563	2016-10-21 11:03:04	2016-10-21 11:03:01	Time=21-10-2016 11:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.30\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
374	085315718563	2016-10-21 11:12:04	2016-10-21 11:12:05	Time=21-10-2016 11:12:00\n\nGV=212.1,206.5,214.3\n\nGI=0.0,0.0,0.0\n\nBV=48.95\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
375	085315718563	2016-10-21 11:12:29	2016-10-21 11:12:26	Time=21-10-2016 11:12:25\n\nGV=214.6,208.3,214.5\n\nGI=0.0,0.0,0.0\n\nBV=48.53\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
376	085315718563	2016-10-21 12:03:04	2016-10-21 12:03:04	Time=21-10-2016 12:03:01\n\nGV=212.3,208.2,214.3\n\nGI=0.0,0.0,0.0\n\nBV=48.99\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
377	085315718563	2016-10-21 13:03:04	2016-10-21 13:03:00	Time=21-10-2016 13:03:01\n\nGV=204.6,197.0,205.2\n\nGI=0.0,0.0,0.0\n\nBV=48.99\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
378	085315718563	2016-10-21 14:03:04	2016-10-21 14:03:03	Time=21-10-2016 14:03:01\n\nGV=205.2,201.3,210.9\n\nGI=0.0,0.0,0.0\n\nBV=48.73\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
379	085315718563	2016-10-21 14:12:40	2016-10-21 14:12:40	Time=21-10-2016 14:12:37\n\nGV=206.8,199.8,210.1\n\nGI=0.0,0.0,0.0\n\nBV=48.82\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
380	085315718563	2016-10-21 14:13:04	2016-10-21 14:13:02	Time=21-10-2016 14:13:00\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.11\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
381	085315718563	2016-10-21 15:03:03	2016-10-21 15:03:02	Time=21-10-2016 15:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.12\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
382	085315718563	2016-10-21 16:03:03	2016-10-21 16:03:04	Time=21-10-2016 16:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.76\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
383	085315718563	2016-10-21 16:12:54	2016-10-21 16:12:50	Time=21-10-2016 16:12:51\n\nGV=206.5,201.5,208.0\n\nGI=0.0,0.0,0.0\n\nBV=48.45\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
384	085315718563	2016-10-21 16:13:18	2016-10-21 16:13:21	Time=21-10-2016 16:13:15\n\nGV=205.2,200.0,207.6\n\nGI=0.0,0.0,0.0\n\nBV=48.43\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
385	085315718563	2016-10-21 17:03:03	2016-10-21 17:03:01	Time=21-10-2016 17:03:01\n\nGV=213.1,207.6,214.8\n\nGI=0.0,0.0,0.0\n\nBV=48.10\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
386	085315718563	2016-10-21 18:03:03	2016-10-21 18:03:07	Time=21-10-2016 18:03:01\n\nGV=200.0,194.8,202.6\n\nGI=0.0,0.0,0.0\n\nBV=48.38\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
387	085315718563	2016-10-21 19:03:03	2016-10-21 19:03:09	Time=21-10-2016 19:03:01\n\nGV=200.8,196.3,203.7\n\nGI=0.0,0.0,0.0\n\nBV=48.53\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
388	085315718563	2016-10-21 19:13:30	2016-10-21 19:13:26	Time=21-10-2016 19:13:27\n\nGV=204.6,200.0,206.2\n\nGI=0.0,0.0,0.0\n\nBV=48.29\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
389	085315718563	2016-10-21 19:13:54	2016-10-21 19:13:57	Time=21-10-2016 19:13:51\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=49.06\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
390	085315718563	2016-10-22 05:15:09	2016-10-22 05:15:12	Time=22-10-2016 05:15:07\n\nGV=199.9,195.7,203.5\n\nGI=0.0,0.0,0.0\n\nBV=48.36\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
391	085315718563	2016-10-22 05:15:33	2016-10-22 05:15:33	Time=22-10-2016 05:15:31\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.62\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
392	085315718563	2016-10-22 06:03:02	2016-10-22 06:03:05	Time=22-10-2016 06:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.69\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
393	085315718563	2016-10-22 07:03:02	2016-10-22 07:03:05	Time=22-10-2016 07:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.56\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
394	085315718563	2016-10-22 07:15:23	2016-10-22 07:15:22	Time=22-10-2016 07:15:21\n\nGV=186.4,184.2,189.8\n\nGI=0.0,0.0,0.0\n\nBV=48.28\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
395	085315718563	2016-10-22 07:15:47	2016-10-22 07:15:44	Time=22-10-2016 07:15:45\n\nGV=188.6,184.7,192.1\n\nGI=0.0,0.0,0.0\n\nBV=48.92\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
396	085315718563	2016-10-22 08:03:02	2016-10-22 08:02:56	Time=22-10-2016 08:03:01\n\nGV=198.2,190.5,196.7\n\nGI=0.0,0.0,0.0\n\nBV=48.62\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
397	085315718563	2016-10-22 09:03:02	2016-10-22 09:02:56	Time=22-10-2016 09:03:01\n\nGV=201.4,195.9,204.9\n\nGI=0.0,0.0,0.0\n\nBV=48.87\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
398	085315718563	2016-10-22 10:03:02	2016-10-22 10:02:59	Time=22-10-2016 10:03:01\n\nGV=192.7,188.9,195.2\n\nGI=0.0,0.0,0.0\n\nBV=48.66\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
399	085315718563	2016-10-22 10:15:58	2016-10-22 10:15:54	Time=22-10-2016 10:15:57\n\nGV=201.9,196.4,207.3\n\nGI=0.0,0.0,0.0\n\nBV=48.02\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
400	085315718563	2016-10-22 10:16:23	2016-10-22 10:16:26	Time=22-10-2016 10:16:21\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.42\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
401	085315718563	2016-10-22 11:03:01	2016-10-22 11:02:57	Time=22-10-2016 11:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.51\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
402	085315718563	2016-10-22 13:03:01	2016-10-22 13:02:57	Time=22-10-2016 13:03:01\n\nGV=205.1,202.7,210.7\n\nGI=0.0,0.0,0.0\n\nBV=48.55\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
403	085315718563	2016-10-22 14:03:01	2016-10-22 14:02:57	Time=22-10-2016 14:03:01\n\nGV=210.8,204.6,211.9\n\nGI=0.0,0.0,0.0\n\nBV=48.74\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
404	085315718563	2016-10-22 15:03:01	2016-10-22 15:02:57	Time=22-10-2016 15:03:01\n\nGV=207.8,202.2,210.5\n\nGI=0.0,0.0,0.0\n\nBV=48.54\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
405	085315718563	2016-10-22 15:16:48	2016-10-22 15:16:47	Time=22-10-2016 15:16:47\n\nGV=206.0,200.8,208.2\n\nGI=0.0,0.0,0.0\n\nBV=48.75\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
406	085315718563	2016-10-22 15:17:12	2016-10-22 15:20:46	Time=22-10-2016 15:17:11\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.39\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
407	085315718563	2016-10-22 16:03:01	2016-10-22 16:02:55	Time=22-10-2016 16:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.68\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
408	085315718563	2016-10-22 17:03:01	2016-10-22 17:02:55	Time=22-10-2016 17:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.54\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
409	085315718563	2016-10-22 17:17:02	2016-10-22 17:17:05	Time=22-10-2016 17:17:00\n\nGV=211.1,205.5,214.8\n\nGI=0.0,0.0,0.0\n\nBV=48.45\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
410	085315718563	2016-10-22 17:17:26	2016-10-22 17:17:26	Time=22-10-2016 17:17:25\n\nGV=211.8,210.0,214.4\n\nGI=0.0,0.0,0.0\n\nBV=49.08\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
411	085315718563	2016-10-22 18:03:01	2016-10-22 18:02:56	Time=22-10-2016 18:03:01\n\nGV=198.2,192.6,200.0\n\nGI=0.0,0.0,0.0\n\nBV=48.68\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
412	085315718563	2016-10-22 19:03:01	2016-10-22 19:02:56	Time=22-10-2016 19:03:01\n\nGV=211.7,204.0,212.0\n\nGI=0.0,0.0,0.0\n\nBV=48.79\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
413	085315718563	2016-10-22 20:03:01	2016-10-22 20:02:56	Time=22-10-2016 20:03:01\n\nGV=208.5,205.4,209.5\n\nGI=0.0,0.0,0.0\n\nBV=49.12\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
414	085315718563	2016-10-22 20:17:37	2016-10-22 20:17:48	Time=22-10-2016 20:17:37\n\nGV=207.9,203.9,211.2\n\nGI=0.0,0.0,0.0\n\nBV=48.24\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
415	0811230444	2016-10-23 04:52:56	2016-10-23 04:52:54	tesss	\N	Modem1	\N	7
416	087825411059	2016-10-23 05:42:58	2016-10-23 05:46:46	Time=29-09-2016 19:00:00\n\nGv=220.25,220.02,219.50\n\nGi=3.32,3.30,3.23\n\nBv=48.55\n\nBi=3.40\n\nGbv=20.34\n\nGo=0\n\nRs=1\n\nBs=1\n\nGf=0\n\nLf=0\n\nRf=0\n\nBlv=0\n\nCdc=2	\N	Modem1	\N	7
417	087825411059	2016-10-23 06:01:32	2016-10-23 06:04:15	Time=29-09-2016 19:00:00\n\nGv=220.25,220.02,219.50\n\nGi=3.32,3.30,3.23\n\nBv=48.55\n\nBi=3.40\n\nGbv=20.34\n\nGo=0\n\nRs=1\n\nBs=1\n\nGf=0\n\nLf=0\n\nRf=0\n\nBlv=0\n\nCdc=2	\N	Modem1	\N	7
418	085315718563	2016-10-23 07:02:59	2016-10-23 07:03:02	Time=23-10-2016 07:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.62\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
419	085315718563	2016-10-23 08:02:59	2016-10-23 08:03:01	Time=23-10-2016 08:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.43\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
420	085315718563	2016-10-23 08:19:31	2016-10-23 08:19:26	Time=23-10-2016 08:19:31\n\nGV=185.9,179.6,187.0\n\nGI=0.0,0.0,0.0\n\nBV=48.51\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
421	085315718563	2016-10-23 08:19:55	2016-10-23 08:19:53	Time=23-10-2016 08:19:55\n\nGV=187.8,184.1,186.6\n\nGI=0.0,0.0,0.0\n\nBV=48.91\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
422	085315718563	2016-10-23 09:02:59	2016-10-23 09:03:02	Time=23-10-2016 09:03:01\n\nGV=192.1,186.1,192.7\n\nGI=0.0,0.0,0.0\n\nBV=48.61\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
423	085315718563	2016-10-23 10:02:59	2016-10-23 10:03:02	Time=23-10-2016 10:03:01\n\nGV=192.1,187.9,191.9\n\nGI=0.0,0.0,0.0\n\nBV=48.79\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
424	085315718563	2016-10-23 11:02:59	2016-10-23 11:03:01	Time=23-10-2016 11:03:01\n\nGV=187.6,184.1,187.5\n\nGI=0.0,0.0,0.0\n\nBV=48.48\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
425	085315718563	2016-10-23 11:02:59	2016-10-23 11:03:02	Time=23-10-2016 11:03:01\n\nGV=187.6,184.1,187.5\n\nGI=0.0,0.0,0.0\n\nBV=48.48\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
429	085315718563	2016-10-23 13:02:59	2016-10-23 13:02:53	Time=23-10-2016 13:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.37\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
431	085315718563	2016-10-23 13:20:44	2016-10-23 13:20:46	Time=23-10-2016 13:20:45\n\nGV=207.1,202.7,209.9\n\nGI=0.0,0.0,0.0\n\nBV=48.73\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
437	085315718563	2016-10-23 17:02:58	2016-10-23 17:02:51	Time=23-10-2016 17:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.48\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
439	085315718563	2016-10-23 18:21:10	2016-10-23 18:21:07	Time=23-10-2016 18:21:11\n\nGV=203.4,199.7,205.3\n\nGI=0.0,0.0,0.0\n\nBV=48.66\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
440	085315718563	2016-10-23 18:21:34	2016-10-23 18:21:28	Time=23-10-2016 18:21:35\n\nGV=201.9,196.7,207.9\n\nGI=0.0,0.0,0.0\n\nBV=48.77\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
426	085315718563	2016-10-23 11:20:06	2016-10-23 11:20:03	Time=23-10-2016 11:20:07\n\nGV=187.2,181.4,188.5\n\nGI=0.0,0.0,0.0\n\nBV=48.96\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
427	085315718563	2016-10-23 11:20:30	2016-10-23 11:20:24	Time=23-10-2016 11:20:31\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.62\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
428	085315718563	2016-10-23 12:02:59	2016-10-23 12:02:53	Time=23-10-2016 12:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.51\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
430	085315718563	2016-10-23 13:20:20	2016-10-23 13:20:15	Time=23-10-2016 13:20:21\n\nGV=205.6,201.7,208.9\n\nGI=0.0,0.0,0.0\n\nBV=48.51\n\nBI=0.0\n\nGBV=1.1\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
432	085315718563	2016-10-23 14:02:58	2016-10-23 14:02:54	Time=23-10-2016 14:03:01\n\nGV=200.7,197.8,201.8\n\nGI=0.0,0.0,0.0\n\nBV=48.56\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
433	085315718563	2016-10-23 15:02:58	2016-10-23 15:02:54	Time=23-10-2016 15:03:01\n\nGV=201.5,196.5,206.5\n\nGI=0.0,0.0,0.0\n\nBV=48.97\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
434	085315718563	2016-10-23 16:02:58	2016-10-23 16:02:54	Time=23-10-2016 16:03:01\n\nGV=204.0,199.2,208.9\n\nGI=0.0,0.0,0.0\n\nBV=48.43\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
435	085315718563	2016-10-23 16:20:56	2016-10-23 16:20:56	Time=23-10-2016 16:20:57\n\nGV=209.1,204.3,208.8\n\nGI=0.0,0.0,0.0\n\nBV=48.64\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
436	085315718563	2016-10-23 16:21:20	2016-10-23 16:21:17	Time=23-10-2016 16:21:21\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.26\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
438	085315718563	2016-10-23 18:02:58	2016-10-23 18:02:54	Time=23-10-2016 18:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.60\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
441	085315718563	2016-10-23 19:02:58	2016-10-23 19:02:56	Time=23-10-2016 19:03:01\n\nGV=201.0,193.6,202.2\n\nGI=0.0,0.0,0.0\n\nBV=48.39\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
442	085315718563	2016-10-23 21:02:58	2016-10-23 21:02:56	Time=23-10-2016 21:03:01\n\nGV=200.5,198.2,204.0\n\nGI=0.0,0.0,0.0\n\nBV=47.95\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
443	085315718563	2016-10-23 21:21:45	2016-10-23 21:21:39	Time=23-10-2016 21:21:47\n\nGV=201.2,195.8,201.3\n\nGI=0.0,0.0,0.0\n\nBV=48.77\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
444	085315718563	2016-10-23 21:22:09	2016-10-23 21:22:10	Time=23-10-2016 21:22:11\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.50\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
445	085315718563	2016-10-23 22:02:58	2016-10-23 22:02:57	Time=23-10-2016 22:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.71\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
446	085315718563	2016-10-23 22:02:58	2016-10-23 22:02:57	Time=23-10-2016 22:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.71\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
447	085315718563	2016-10-23 23:02:58	2016-10-23 23:02:57	Time=23-10-2016 23:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.50\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
448	085315718563	2016-10-23 23:21:59	2016-10-23 23:22:00	Time=23-10-2016 23:22:00\n\nGV=210.4,206.4,214.5\n\nGI=0.0,0.0,0.0\n\nBV=48.63\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
449	085315718563	2016-10-23 23:22:23	2016-10-23 23:22:21	Time=23-10-2016 23:22:25\n\nGV=212.0,206.4,214.9\n\nGI=0.0,0.0,0.0\n\nBV=48.32\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
450	085315718563	2016-10-24 00:02:57	2016-10-24 00:02:54	Time=24-10-2016 00:03:01\n\nGV=217.2,213.1,221.8\n\nGI=0.0,0.0,0.0\n\nBV=48.31\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
451	085315718563	2016-10-24 01:02:58	2016-10-24 01:02:58	Time=24-10-2016 01:03:01\n\nGV=216.6,215.7,221.3\n\nGI=0.0,0.0,0.0\n\nBV=48.46\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
452	085315718563	2016-10-24 02:02:57	2016-10-24 02:02:51	Time=24-10-2016 02:03:01\n\nGV=216.8,213.2,220.9\n\nGI=0.0,0.0,0.0\n\nBV=48.54\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
453	085315718563	2016-10-24 02:22:35	2016-10-24 02:22:30	Time=24-10-2016 02:22:37\n\nGV=212.5,206.2,213.4\n\nGI=0.0,0.0,0.0\n\nBV=48.38\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
454	085315718563	2016-10-24 02:22:58	2016-10-24 02:22:51	Time=24-10-2016 02:23:00\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.40\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
455	085315718563	2016-10-24 03:02:57	2016-10-24 03:02:58	Time=24-10-2016 03:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.39\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
456	085315718563	2016-10-24 04:02:57	2016-10-24 04:02:58	Time=24-10-2016 04:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.07\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
457	085315718563	2016-10-24 04:22:49	2016-10-24 04:22:42	Time=24-10-2016 04:22:51\n\nGV=209.6,204.3,210.6\n\nGI=0.0,0.0,0.0\n\nBV=48.68\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
458	085315718563	2016-10-24 04:23:13	2016-10-24 04:23:13	Time=24-10-2016 04:23:15\n\nGV=208.8,203.1,209.8\n\nGI=0.0,0.0,0.0\n\nBV=49.21\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
459	085315718563	2016-10-24 05:02:57	2016-10-24 05:03:00	Time=24-10-2016 05:03:01\n\nGV=203.9,195.1,204.2\n\nGI=0.0,0.0,0.0\n\nBV=48.73\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
460	085315718563	2016-10-24 06:02:57	2016-10-24 06:02:59	Time=24-10-2016 06:03:01\n\nGV=198.1,193.6,200.0\n\nGI=0.0,0.0,0.0\n\nBV=49.16\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
461	085315718563	2016-10-24 07:02:57	2016-10-24 07:02:57	Time=24-10-2016 07:03:01\n\nGV=204.9,201.0,209.2\n\nGI=0.0,0.0,0.0\n\nBV=47.76\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=1\n\nRS=1\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
462	085315718563	2016-10-24 07:23:24	2016-10-24 07:23:23	Time=24-10-2016 07:23:27\n\nGV=205.5,199.2,209.4\n\nGI=0.0,0.0,0.0\n\nBV=48.53\n\nBI=0.0\n\nGBV=0.0\n\nGO=1\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
463	085315718563	2016-10-24 07:23:48	2016-10-24 07:23:44	Time=24-10-2016 07:23:51\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.68\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
464	085315718563	2016-10-24 08:02:57	2016-10-24 08:03:00	Time=24-10-2016 08:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.38\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
465	085315718563	2016-10-24 09:02:57	2016-10-24 09:02:50	Time=24-10-2016 09:03:01\n\nGV=0.0,0.0,0.0\n\nGI=0.0,0.0,0.0\n\nBV=48.74\n\nBI=0.0\n\nGBV=0.0\n\nGO=0\n\nBS=0\n\nRS=0\n\nGF=0\n\nLF=0\n\nRF=0\n\nBLV=0\n\nCDC=2	\N	Modem1	\N	7
\.


--
-- TOC entry 2372 (class 0 OID 0)
-- Dependencies: 200
-- Name: inbox_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('inbox_id_seq', 465, true);


--
-- TOC entry 2333 (class 0 OID 32879)
-- Dependencies: 201
-- Data for Name: modem; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY modem (id, name, phone, port, baud_rate, pin, brand, model, enabled) FROM stdin;
1	Modem1	\N	COM12	115200	0000	\N	\N	t
\.


--
-- TOC entry 2373 (class 0 OID 0)
-- Dependencies: 202
-- Name: modem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('modem_id_seq', 1, true);


--
-- TOC entry 2322 (class 0 OID 32795)
-- Dependencies: 184
-- Data for Name: node; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY node (id, phone, name, subnet_id, customer_id, genset_vr, genset_vs, genset_vt, genset_cr, genset_cs, genset_ct, batt_volt, batt_curr, genset_batt_volt, genset_status, recti_status, genset_fail, low_fuel, recti_fail, batt_low, created_at, updated_at, latitude, longitude, cdc_mode, breaker_status) FROM stdin;
2	081272416105	TRITUNGGAL	6	1	0.0	0.0	0.0	0.0	0.0	0.0	49.19	0.0	12.8	0	0	0	0	0	0	2016-10-09 18:29:26.384	2017-03-06 09:28:02	-2.54075	104.16383	2	0
1	081294625941	MEDCO TABUAN	6	1	0.0	0.0	0.0	\N	\N	\N	50.17	\N	13.0	0	0	0	0	0	0	2016-09-28 14:18:16.972	2017-03-06 09:37:02	-2.72228	104.21356	2	0
\.


--
-- TOC entry 2374 (class 0 OID 0)
-- Dependencies: 203
-- Name: node_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('node_id_seq', 2, true);


--
-- TOC entry 2336 (class 0 OID 32889)
-- Dependencies: 204
-- Data for Name: outbox; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY outbox (id, recipient, text, create_date, sent_date, reply_date, reply_text, request_id, status, gateway_id, message_type) FROM stdin;
\.


--
-- TOC entry 2375 (class 0 OID 0)
-- Dependencies: 205
-- Name: outbox_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('outbox_id_seq', 1, false);


--
-- TOC entry 2338 (class 0 OID 32903)
-- Dependencies: 207
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY role (id, name) FROM stdin;
1	SYSTEM
2	ADMIN
3	OPERATOR
\.


--
-- TOC entry 2376 (class 0 OID 0)
-- Dependencies: 208
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('role_id_seq', 3, true);


--
-- TOC entry 2340 (class 0 OID 32908)
-- Dependencies: 209
-- Data for Name: running_hour; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY running_hour (id, node_id, ddate, val) FROM stdin;
2	2	2017-01-10	5.23527765
1	1	2017-01-24	0
3	2	2017-01-11	3.04166675
4	2	2017-01-12	0
5	2	2017-01-13	0
26	2	2017-02-24	6.08972216
38	1	2017-03-02	4.11055565
39	2	2017-03-02	5.19027758
28	1	2017-02-25	4.08777761
29	2	2017-02-25	6.80416679
25	2	2017-02-23	3.82277775
24	1	2017-02-23	6.43916655
41	1	2017-03-03	2.0666666
40	2	2017-03-03	5.19083357
42	1	2017-03-04	3.24888897
43	2	2017-03-04	5.54805565
30	1	2017-02-26	4.59250021
31	2	2017-02-26	5.69888878
23	1	2017-02-22	0.881944418
32	1	2017-02-27	4.08833313
33	2	2017-02-27	5.19083357
44	2	2017-03-05	5.16666651
45	1	2017-03-05	4.08916664
46	2	2017-03-06	2.58333325
35	2	2017-02-28	5.18916655
34	1	2017-02-28	4.08916664
27	1	2017-02-24	5.53249979
37	1	2017-03-01	1.53916669
36	2	2017-03-01	5.19055557
\.


--
-- TOC entry 2377 (class 0 OID 0)
-- Dependencies: 210
-- Name: running_hour_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('running_hour_id_seq', 46, true);


--
-- TOC entry 2323 (class 0 OID 32809)
-- Dependencies: 185
-- Data for Name: severity; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY severity (id, name, color) FROM stdin;
1	CRITICAL	#FF0000
2	MAJOR	#00FF00
3	MINOR	#FF0000
4	WARNING	#FF0000
\.


--
-- TOC entry 2378 (class 0 OID 0)
-- Dependencies: 211
-- Name: severity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('severity_id_seq', 4, true);


--
-- TOC entry 2324 (class 0 OID 32812)
-- Dependencies: 186
-- Data for Name: subnet; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY subnet (id, name, parent_id, customer_id) FROM stdin;
4	SUMBAGSEL	\N	1
5	JABOTABEK	\N	1
1	JABAR	\N	1
2	BOGOR	1	1
3	BANDUNG	1	1
6	PALEMBANG	4	1
\.


--
-- TOC entry 2379 (class 0 OID 0)
-- Dependencies: 212
-- Name: subnet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('subnet_id_seq', 6, true);


--
-- TOC entry 2344 (class 0 OID 32918)
-- Dependencies: 213
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY test (id, name, val) FROM stdin;
02d9e6d5-9467-382e-8f9b-9300a64ac3cd	asep	9500.27539
\.


--
-- TOC entry 2345 (class 0 OID 32921)
-- Dependencies: 214
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: sinergi
--

COPY users (id, username, password, name, role_id, customer_id) FROM stdin;
1	sa	48a365b4ce1e322a55ae9017f3daf0c0	System	1	\N
3	infra	2d0059c6b6b34a757c93f800bcb3f37c	Operator Infra	3	1
4	Gunawan	21232f297a57a5a743894a0e4a801fc3	Gunawan	2	1
2	admin	21232f297a57a5a743894a0e4a801fc3	Administrator	2	\N
\.


--
-- TOC entry 2380 (class 0 OID 0)
-- Dependencies: 215
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sinergi
--

SELECT pg_catalog.setval('users_id_seq', 4, true);


--
-- TOC entry 2136 (class 2606 OID 32941)
-- Name: alarm_list_name_key; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_list
    ADD CONSTRAINT alarm_list_name_key UNIQUE (name);


--
-- TOC entry 2138 (class 2606 OID 32943)
-- Name: alarm_list_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_list
    ADD CONSTRAINT alarm_list_pkey PRIMARY KEY (id);


--
-- TOC entry 2140 (class 2606 OID 32945)
-- Name: alarm_log_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_log
    ADD CONSTRAINT alarm_log_pkey PRIMARY KEY (id);


--
-- TOC entry 2152 (class 2606 OID 32947)
-- Name: alarm_temp_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_temp
    ADD CONSTRAINT alarm_temp_pkey PRIMARY KEY (id);


--
-- TOC entry 2154 (class 2606 OID 32949)
-- Name: customer_name_key; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_name_key UNIQUE (name);


--
-- TOC entry 2156 (class 2606 OID 32951)
-- Name: customer_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- TOC entry 2158 (class 2606 OID 32953)
-- Name: data_log_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY data_log
    ADD CONSTRAINT data_log_pkey PRIMARY KEY (id);


--
-- TOC entry 2160 (class 2606 OID 32955)
-- Name: inbox_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY inbox
    ADD CONSTRAINT inbox_pkey PRIMARY KEY (id);


--
-- TOC entry 2162 (class 2606 OID 32957)
-- Name: modem_name_key; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY modem
    ADD CONSTRAINT modem_name_key UNIQUE (name);


--
-- TOC entry 2164 (class 2606 OID 32959)
-- Name: modem_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY modem
    ADD CONSTRAINT modem_pkey PRIMARY KEY (id);


--
-- TOC entry 2142 (class 2606 OID 32961)
-- Name: node_phone_key; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY node
    ADD CONSTRAINT node_phone_key UNIQUE (phone);


--
-- TOC entry 2144 (class 2606 OID 32963)
-- Name: node_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY node
    ADD CONSTRAINT node_pkey PRIMARY KEY (id);


--
-- TOC entry 2166 (class 2606 OID 32965)
-- Name: outbox_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY outbox
    ADD CONSTRAINT outbox_pkey PRIMARY KEY (id);


--
-- TOC entry 2168 (class 2606 OID 32967)
-- Name: role_name_key; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY role
    ADD CONSTRAINT role_name_key UNIQUE (name);


--
-- TOC entry 2170 (class 2606 OID 32969)
-- Name: role_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- TOC entry 2174 (class 2606 OID 32971)
-- Name: running_hour_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY running_hour
    ADD CONSTRAINT running_hour_pkey PRIMARY KEY (id);


--
-- TOC entry 2146 (class 2606 OID 32973)
-- Name: severity_name_key; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY severity
    ADD CONSTRAINT severity_name_key UNIQUE (name);


--
-- TOC entry 2148 (class 2606 OID 32975)
-- Name: severity_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY severity
    ADD CONSTRAINT severity_pkey PRIMARY KEY (id);


--
-- TOC entry 2150 (class 2606 OID 32977)
-- Name: subnet_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY subnet
    ADD CONSTRAINT subnet_pkey PRIMARY KEY (id);


--
-- TOC entry 2176 (class 2606 OID 32979)
-- Name: test_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY test
    ADD CONSTRAINT test_pkey PRIMARY KEY (id);


--
-- TOC entry 2178 (class 2606 OID 32981)
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 2180 (class 2606 OID 32983)
-- Name: users_username_key; Type: CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 2171 (class 1259 OID 32984)
-- Name: run_hour_date_idx; Type: INDEX; Schema: public; Owner: sinergi
--

CREATE INDEX run_hour_date_idx ON running_hour USING btree (ddate);


--
-- TOC entry 2172 (class 1259 OID 32985)
-- Name: run_hour_node_idx; Type: INDEX; Schema: public; Owner: sinergi
--

CREATE INDEX run_hour_node_idx ON running_hour USING btree (node_id);


--
-- TOC entry 2196 (class 2620 OID 32986)
-- Name: trg_alarm_delete; Type: TRIGGER; Schema: public; Owner: sinergi
--

CREATE TRIGGER trg_alarm_delete BEFORE DELETE ON alarm_temp FOR EACH ROW EXECUTE PROCEDURE trg_alarm_delete();


--
-- TOC entry 2197 (class 2620 OID 32987)
-- Name: trg_alarm_insert; Type: TRIGGER; Schema: public; Owner: sinergi
--

CREATE TRIGGER trg_alarm_insert AFTER INSERT ON alarm_temp FOR EACH ROW EXECUTE PROCEDURE trg_alarm_insert();


--
-- TOC entry 2195 (class 2620 OID 32988)
-- Name: trg_node_update; Type: TRIGGER; Schema: public; Owner: sinergi
--

CREATE TRIGGER trg_node_update BEFORE UPDATE ON node FOR EACH ROW EXECUTE PROCEDURE trg_node_update();


--
-- TOC entry 2181 (class 2606 OID 32989)
-- Name: alarm_list_severity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_list
    ADD CONSTRAINT alarm_list_severity_id_fkey FOREIGN KEY (severity_id) REFERENCES severity(id) ON DELETE SET NULL;


--
-- TOC entry 2182 (class 2606 OID 32994)
-- Name: alarm_log_alarm_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_log
    ADD CONSTRAINT alarm_log_alarm_list_id_fkey FOREIGN KEY (alarm_list_id) REFERENCES alarm_list(id) ON DELETE SET NULL;


--
-- TOC entry 2183 (class 2606 OID 32999)
-- Name: alarm_log_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_log
    ADD CONSTRAINT alarm_log_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(id) ON DELETE CASCADE;


--
-- TOC entry 2184 (class 2606 OID 33004)
-- Name: alarm_log_severity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_log
    ADD CONSTRAINT alarm_log_severity_id_fkey FOREIGN KEY (severity_id) REFERENCES severity(id) ON DELETE SET NULL;


--
-- TOC entry 2189 (class 2606 OID 33009)
-- Name: alarm_temp_alarm_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_temp
    ADD CONSTRAINT alarm_temp_alarm_list_id_fkey FOREIGN KEY (alarm_list_id) REFERENCES alarm_list(id) ON DELETE SET NULL;


--
-- TOC entry 2190 (class 2606 OID 33014)
-- Name: alarm_temp_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_temp
    ADD CONSTRAINT alarm_temp_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(id) ON DELETE CASCADE;


--
-- TOC entry 2191 (class 2606 OID 33019)
-- Name: alarm_temp_severity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY alarm_temp
    ADD CONSTRAINT alarm_temp_severity_id_fkey FOREIGN KEY (severity_id) REFERENCES severity(id) ON DELETE SET NULL;


--
-- TOC entry 2192 (class 2606 OID 33024)
-- Name: data_log_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY data_log
    ADD CONSTRAINT data_log_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(id) ON DELETE CASCADE;


--
-- TOC entry 2185 (class 2606 OID 33029)
-- Name: node_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY node
    ADD CONSTRAINT node_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE SET NULL;


--
-- TOC entry 2186 (class 2606 OID 33034)
-- Name: node_subnet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY node
    ADD CONSTRAINT node_subnet_id_fkey FOREIGN KEY (subnet_id) REFERENCES subnet(id) ON DELETE CASCADE;


--
-- TOC entry 2193 (class 2606 OID 33039)
-- Name: running_hour_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY running_hour
    ADD CONSTRAINT running_hour_node_id_fkey FOREIGN KEY (node_id) REFERENCES node(id) ON DELETE CASCADE;


--
-- TOC entry 2187 (class 2606 OID 33044)
-- Name: subnet_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY subnet
    ADD CONSTRAINT subnet_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customer(id) ON DELETE SET NULL;


--
-- TOC entry 2188 (class 2606 OID 33049)
-- Name: subnet_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY subnet
    ADD CONSTRAINT subnet_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES subnet(id) ON DELETE CASCADE;


--
-- TOC entry 2194 (class 2606 OID 33054)
-- Name: users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sinergi
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE SET NULL;
