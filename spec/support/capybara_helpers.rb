module CapybaraHelpers
  def wait_for_ajax(timeout = Capybara.default_wait_time)
    Timeout.timeout(timeout) do
      loop do
        active = page.evaluate_script('(window.Zepto || window.jQuery).active')
        break if active == 0
      end
    end
  end

  def wait_element_appear(selector)
    timeout = Capybara.default_wait_time
    Timeout.timeout(timeout) do
      loop do
        break if page.has_css?(selector)
      end
    end
  end

  def submit_form(selector = 'form')
    within(selector) do
      if page.has_css?('input[type=submit]')
        #puts "Click submit"
        find('input[type=submit]').click
      elsif page.has_css?('button')
        #puts "Click button"
        find('button').click
      else
        #puts "Call submit()"
        page.evaluate_script(%{document.querySelector("#{selector}").submit();})
      end
    end
  end

  def accept_confirms!
    page.evaluate_script('window.confirm = function(msg) { /* console.log(msg); */ return true; }')
  end

  def show_page
    save_page Rails.root.join( 'public', 'capybara.html' )
    %x(launchy http://localhost:3000/capybara.html)
  end

  def nokogiri_fragment(fragment)
    Nokogiri::HTML(%{
      <html>
        <head><meta http-equiv="content-type" content="text/html; charset=utf-8"></head>
        <body>
          #{fragment}
        </body>
      </html>
    })
  end

  def flash_msg(type)
    find(:flash_type, type.to_sym).text
  end

  def click_link_from_email!
    mailer_doc = nokogiri_fragment(ActionMailer::Base.deliveries.last.body)
    link = mailer_doc.at_css('a')['href']

    link = link.gsub(%r{^https?://[^/]+}, '')

    #uri = URI.parse(link)
    #uri.host = Capybara.current_session.server.host
    #uri.port = Capybara.current_session.server.port

    visit link
  end

  def be_true
    be_truthy
  end

  def be_false
    be_falsey
  end

  # Return array of hashes
  def active_admin_rows
    rows = []
    headers = []
    all(:css, 'div.index_as_table table thead tr th').each do |cell|
      headers << cell.text
    end
    all(:css, 'div.index_as_table table tbody tr').each do |row|
      cells = row.all("td")
      data = {}
      cells.each_with_index do |cell, index|
        data[headers[index]] = cell.text
      end
      rows << data.with_indifferent_access
    end
    rows
  end

  def unlock_ar!(records)
    if records.kind_of?(ActiveRecord::Base)
      records.instance_variable_set(:@readonly, false)
    elsif records.kind_of?(Array)
      records.each do |record|
        record.instance_variable_set(:@readonly, false)
      end
    elsif records.kind_of?(ActiveRecord::Relation)
      records.to_a.each do |record|
        record.instance_variable_set(:@readonly, false)
      end
    end
    records
  end

  def parse_csv(data)
    CSV.parse(data, :headers => :first_row)
  end

  def parse_xls(data)
    xls = Hash.from_xml(data)
    #require "pp"
    #pp xls
    xls["Workbook"]["Worksheet"]["ss:Name"].should == "Veritrans-Payment"
    payment_info = {}

    headers = []
    data = []
    xls["Workbook"]["Worksheet"]["Table"]["Row"].each_with_index do |row, index|
      if index == 0
        headers = row["Cell"].map {|c| c["Data"] }
      else
        data_row = {}
        headers.each_with_index do |header, cell_index|
          data_row[header] = row["Cell"][cell_index]["Data"]
        end
        data << data_row
      end
    end
    data
  end

  def with_caching(on = true)
    caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = on
    yield
  ensure
    ActionController::Base.perform_caching = caching
  end

  def without_caching(&block)
    with_caching(false, &block)
  end
end
