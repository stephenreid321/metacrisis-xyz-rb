class Post < Airrecord::Table
  self.base_key = ENV['AIRTABLE_BASE_KEY_SR']
  self.table_name = 'Posts'
end
