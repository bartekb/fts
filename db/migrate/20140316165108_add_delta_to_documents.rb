class AddDeltaToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :delta, :boolean, :default => true, :null => false
  end
end
