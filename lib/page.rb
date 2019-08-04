class Page
  attr_reader :books
  def initialize(page_uri, required_categories, to_date, db_client)
    doc = Nokogiri::HTML(open(page_uri))
    posts = doc.css('div.post')

    @db_client = db_client

    all_books = posts.map { |post| Book.new(post) }
    @has_next_page = true

    @books = all_books.select { |book| book.in_category?(required_categories) }

    @books.each do |book| 
      sleep 0.5; 
      book.get_details
      @has_next_page = book.publish_date < to_date if @has_next_page
    end
    @to_date = to_date
  end

  def books
    size = @books.count
    @books = @books.select { |book| book.publish_date >= @to_date && book.is_not_read?(@db_client) }
    [@books, @has_next_page]
  end
end