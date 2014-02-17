class Document < ActiveRecord::Base
  include PgSearch

  belongs_to :category

  multisearchable :against => [:title, :body]

	pg_search_scope :search2, against: [:title, :title2], 
	using: {
	  tsearch: {
	    tsvector_column: 'tsv',
	    prefix: true
	  }
	}
end
