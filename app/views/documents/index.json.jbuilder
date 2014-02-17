json.array!(@documents) do |document|
  json.extract! document, :id, :title, :body, :category_id
  json.url document_url(document, format: :json)
end
