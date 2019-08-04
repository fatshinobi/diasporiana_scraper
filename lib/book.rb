class Book
  attr_reader :title, :uri, :category_class, :code, :publish_date, :original_date, :author, :publisher, :pages, :description

  MONTHS = {'Січень' => 'Jan', 'Лютий' => 'Feb', 'Березень' => 'Mar', 'Квітень' => 'Apr', 'Травень' => 'May', 
    'Червень' => 'Jun', 'Липень' => 'Jul', 'Серпень' => 'Aug', 'Вересень' => 'Sep', 'Жовтень' => 'Oct',
    'Листопад' => 'Nov', 'Грудень' => 'Dec'}

  def initialize(post_header)
    @uri = post_header.css('a')[0]['href']
    parsed_uri = @uri.split('/') 
    #@category_class = post_header['class'].split(' ').detect { |stl| stl.include? 'category' }.gsub('category-', '')
    @category_class = parsed_uri[-2]
    @code = parsed_uri[-1]
  end

  def in_category?(required_categories)
    required_categories.include? @category_class
  end

  def is_read?(db)
    db[:books].find(code: @code).count > 0
  end

  def is_not_read?(db)
    !is_read?(db)
  end

  def get_details
    doc = Nokogiri::HTML(open(@uri))
    post = doc.css('div.post')
    @title = post.css('h1')[0].text
    info_blocks = post.css('span.info-line')
    @original_date = info_blocks[0].text.gsub('Додано:', '').lstrip
    @publish_date = Date.parse(ukranian_date_to_english(@original_date))
    @author = info_blocks[1].text.gsub('Автор:', '').lstrip
    @publisher = info_blocks[2].text.gsub('Опубліковано:', '').lstrip
    @pages = info_blocks[3].text.gsub('Сторінок:', '').lstrip
    @description = info_blocks[4].text.gsub('Опис:', '').gsub(/\n/, '; ').lstrip
  end

  def ukranian_date_to_english(ukr_date)
    reg = Regexp.new(MONTHS.map{ |key, val| key }.join('|'))
    ukr_date.gsub(reg) { |match| MONTHS[match] }
  end

  def mark_as_read(db)
    doc = { 
      _id: BSON::ObjectId.new,
      code: @code,
      title: @title, 
      original_date: @original_date, 
      publish_date: @publish_date,
      author: @author,
      publisher: @publisher,
      pages: @pages,
      description: @description,
      uri: @uri,
      category_class: @category_class  
    }

    db[:books].insert_one doc 
  end
end