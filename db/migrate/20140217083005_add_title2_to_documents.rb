class AddTitle2ToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :title2, :string
  end
end
