class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :title
      t.text :body
      t.references :category, index: true

      t.timestamps
    end
  end
end
