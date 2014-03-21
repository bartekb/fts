class Category < ActiveRecord::Base
  #include PgSearch
  has_many :documents
  #multisearchable :against => [:title]
end
