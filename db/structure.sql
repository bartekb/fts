--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: documents_generate_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION documents_generate_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        begin
          new.tsv :=
            setweight(to_tsvector('pg_catalog.english', coalesce(new.title,'')), 'A') ||
            setweight(to_tsvector('pg_catalog.english', coalesce(new.title2,'')), 'B');
          return new;
        end
      $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: articles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE articles (
    id integer NOT NULL,
    title character varying(255),
    content text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: articles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE articles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE articles_id_seq OWNED BY articles.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE categories (
    id integer NOT NULL,
    title character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE categories_id_seq OWNED BY categories.id;


--
-- Name: documents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE documents (
    id integer NOT NULL,
    title character varying(255),
    body text,
    category_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    title2 character varying(255),
    tsv tsvector
);


--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE documents_id_seq OWNED BY documents.id;


--
-- Name: pg_search_documents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pg_search_documents (
    id integer NOT NULL,
    content text,
    searchable_id integer,
    searchable_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pg_search_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pg_search_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pg_search_documents_id_seq OWNED BY pg_search_documents.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: searches; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW searches AS
         SELECT documents.id AS searchable_id,
            'Document'::text AS searchable_type,
            documents.body AS term
           FROM (documents
      JOIN categories ON ((categories.id = documents.category_id)))
UNION
         SELECT categories.id AS searchable_id,
            'Category'::text AS searchable_type,
            categories.title AS term
           FROM categories;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY articles ALTER COLUMN id SET DEFAULT nextval('articles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories ALTER COLUMN id SET DEFAULT nextval('categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY documents ALTER COLUMN id SET DEFAULT nextval('documents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pg_search_documents ALTER COLUMN id SET DEFAULT nextval('pg_search_documents_id_seq'::regclass);


--
-- Name: articles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: pg_search_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pg_search_documents
    ADD CONSTRAINT pg_search_documents_pkey PRIMARY KEY (id);


--
-- Name: documents_tsv_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX documents_tsv_idx ON documents USING gin (tsv);


--
-- Name: index_categories_on_title; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_categories_on_title ON categories USING gin (to_tsvector('english'::regconfig, (title)::text));


--
-- Name: index_documents_on_body; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_documents_on_body ON documents USING gin (to_tsvector('english'::regconfig, body));


--
-- Name: index_documents_on_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_documents_on_category_id ON documents USING btree (category_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: tsvector_documents_upsert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_documents_upsert_trigger BEFORE INSERT OR UPDATE ON documents FOR EACH ROW EXECUTE PROCEDURE documents_generate_tsvector();


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20140115100157');

INSERT INTO schema_migrations (version) VALUES ('20140115102625');

INSERT INTO schema_migrations (version) VALUES ('20140115113628');

INSERT INTO schema_migrations (version) VALUES ('20140115114245');

INSERT INTO schema_migrations (version) VALUES ('20140115130334');

INSERT INTO schema_migrations (version) VALUES ('20140217083005');

INSERT INTO schema_migrations (version) VALUES ('20140217084919');

INSERT INTO schema_migrations (version) VALUES ('20140223102122');
