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
