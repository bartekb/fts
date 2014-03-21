class Document < ActiveRecord::Base
  # include PgSearch

  belongs_to :category

  # multisearchable :against => [:title, :body]

	# pg_search_scope :search2, against: [:title, :title2], 
	# using: {
	#   tsearch: {
	#     tsvector_column: 'tsv',
	#     prefix: true
	#   }
	# }

  searchable do
    text :title, :body
    text :category_name do
      category ? category.title : "none"
    end

    integer :category_id
    time    :created_at
    time    :updated_at
  end

end
