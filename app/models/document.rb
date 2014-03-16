class Document < ActiveRecord::Base
  include PgSearch
  include Tire::Model::Search
  include Tire::Model::Callbacks

  belongs_to :category

  multisearchable :against => [:title, :body]

	pg_search_scope :search2, against: [:title, :title2], 
	using: {
	  tsearch: {
	    tsvector_column: 'tsv',
	    prefix: true
	  }
	}

  tire.mapping do
    indexes :id,            :index    => :not_analyzed
    indexes :title,         :analyzer => 'snowball', :boost => 100
    indexes :body,          :analyzer => 'snowball'
    indexes :category_id,   :index    => :not_analyzed
    indexes :body_size,     :as => 'body.size'
    indexes :category_title,:as => 'category.title'
    indexes :created_at,    :type => 'date', :include_in_all => false
  end


  def self.search(params)
    tire.search(:page => params[:page], :per_page => 10) do
      query do
        boolean do
          must { string params[:query], :default_operator => "AND" } if params[:query].present?
          must { range :created_at, :lte => Time.zone.now }
          must { term :category_id, params[:category_id] } if params[:category_id].present?

        end
      end

      sort { by "created_at", "desc" }

      facet "categories" do
        terms :category_id
      end
    end
  end
end
