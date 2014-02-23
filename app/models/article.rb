class Article < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks

  tire.mapping do
    indexes :id,           :index    => :not_analyzed
    indexes :title,        :analyzer => 'snowball', :boost => 100
    indexes :content,      :analyzer => 'snowball'
    indexes :created_at, :type => 'date', :include_in_all => false
  end

  def self.title_matches(args, page)
    tire.search :page => page, :per_page => 5 do
      query {string "content:#{args}"}
      filter :terms, :title => ["est"]
      facet "only_est" do
        terms :title
      end

      sort do
        by :title
      end
    end
  end

  # def self.title_matches(args)
  #   tire.search do
  #     query do
  #       boolean do
  #         must {string "title:#{args}"}
  #         must {string "created_at:[2014-01-01 TO 2014-10-10]"}
  #       end
  #     end
  #     highlight :title
  #   end
  # end
end
