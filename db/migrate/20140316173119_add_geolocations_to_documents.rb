class AddGeolocationsToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :latitude, :float
    add_column :documents, :longitude, :float
  end
end
