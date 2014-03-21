ThinkingSphinx::Index.define :document, :with => :active_record, :delta => true do
  indexes title, :sortable => true
  indexes body
  indexes category.title, :as => :category, :sortable => true, :facet => true
  has category_id, created_at, updated_at
  has "RADIANS(latitude)",  :as => :latitude,  :type => :float
  has "RADIANS(longitude)", :as => :longitude, :type => :float
  group_by 'latitude', 'longitude'
end