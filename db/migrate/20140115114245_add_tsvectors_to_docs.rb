class AddTsvectorsToDocs < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE INDEX CONCURRENTLY index_categories_on_title ON categories USING gin(to_tsvector('english', title))
        SQL
        execute <<-SQL
          CREATE INDEX CONCURRENTLY index_documents_on_body ON documents USING gin(to_tsvector('english', body))
        SQL
      end
      dir.down do
        execute <<-SQL
          DROP INDEX index_categories_on_title
          DROP INDEX index_documents_on_body
        SQL
      end
    end
  end
end
