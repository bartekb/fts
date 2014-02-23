unless Category.count > 0
  10.times do |i|
    category = Category.new
    category.title = "Category #{i+1}"
    category.save!
    10.times do |i|
      document = Document.new
      document.title = "Document #{category.id}.#{i+1}"
      document.body = Faker::Lorem.paragraphs(10).join
      document.category = category
      document.save!
    end
  end
end

unless Article.count > 0
  100.times do |i|
    Article.transaction do
      article = Article.new
      article.title = Faker::Lorem.words(5).join(" ")
      article.content = Faker::Lorem.paragraphs.join
      article.save!
    end
  end
end
