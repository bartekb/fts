class CreateSearchesView < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE VIEW searches AS
            SELECT
              documents.id AS searchable_id,
              'Document' AS searchable_type,
              documents.body AS term
            FROM documents
            JOIN categories ON categories.id = documents.category_id
            UNION
            SELECT
              categories.id AS searchable_id,
              'Category' AS searchable_type,
              categories.title AS term
            FROM categories
        SQL
      end
      dir.down do
        execute <<-SQL
          DROP VIEW searches
        SQL
      end
    end
  end
end
