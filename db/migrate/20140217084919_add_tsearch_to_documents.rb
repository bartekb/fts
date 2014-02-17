class AddTsearchToDocuments < ActiveRecord::Migration
  def up
    # execute the below line after table alter if plpgsql lang is missed
#      CREATE LANGUAGE plpgsql;
    execute(<<-'eosql'.strip)
      ALTER TABLE documents ADD COLUMN tsv tsvector;

      CREATE FUNCTION documents_generate_tsvector() RETURNS trigger AS $$
        begin
          new.tsv :=
            setweight(to_tsvector('pg_catalog.english', coalesce(new.title,'')), 'A') ||
            setweight(to_tsvector('pg_catalog.english', coalesce(new.title2,'')), 'B');
          return new;
        end
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER tsvector_documents_upsert_trigger BEFORE INSERT OR UPDATE
        ON documents
        FOR EACH ROW EXECUTE PROCEDURE documents_generate_tsvector();

      UPDATE documents SET tsv =
        setweight(to_tsvector('pg_catalog.english', coalesce(title,'')), 'A') ||
        setweight(to_tsvector('pg_catalog.english', coalesce(title2,'')), 'B');

      CREATE INDEX documents_tsv_idx ON documents USING gin(tsv);
    eosql

    Document.all.each{ |c| c.touch }
  end

  def down
    execute(<<-'eosql'.strip)
      DROP INDEX IF EXISTS documents_tsv_idx;
      DROP TRIGGER IF EXISTS tsvector_documents_upsert_trigger ON documents;
      DROP FUNCTION IF EXISTS documents_generate_tsvector();
      ALTER TABLE documents DROP COLUMN tsv;
    eosql
  end
end
