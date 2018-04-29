namespace :rb do
  task :fetch do
    URL = 'http://sv.rampagebattle.com/compe'
    AGENT = Mechanize.new

    PREF_REGEXP = %r[(北海道|青森県|岩手県|宮城県|秋田県|山形県|福島県|茨城県|栃木県|群馬県|埼玉県|千葉県|東京都|神奈川県|新潟県|富山県|石川県|福井県|山梨県|長野県|岐阜県|静岡県|愛知県|三重県|滋賀県|京都府|大阪府|兵庫県|奈良県|和歌山県|鳥取県|島根県|岡山県|広島県|山口県|徳島県|香川県|愛媛県|高知県|福岡県|佐賀県|長崎県|熊本県|大分県|宮崎県|鹿児島県|沖縄県)]
    HEADER = %w[Date Place Pref URL Shop Fee]
    event_urls = []
    page = AGENT.get(URL)
    loop do
      event_urls << page.links.select{|l| l.href =~ /compe\/\d+\z/ }.map{|l| l.resolved_uri.to_s }

      next_link = page.links.select.find{|l| l.text == '»' }
      if next_link
        page = AGENT.get(URL + next_link.href)
      else
        break
      end
    end

    events = event_urls.flatten.map do |url|
      page = AGENT.get(url)
      date = page.search('ul.list-compe > li')[0].text.gsub(/.+：/, '')
      shop = page.search('ul.list-compe > li')[1].text.gsub(/.+：/, '')
      place = page.search('ul.list-compe > li')[2].text.gsub(/.+：/, '')
      pref = place.scan(PREF_REGEXP).first&.first
      fee = page.search('ul.list-compe > li')[3].text.gsub(/.+：/, '')
      [date, place, pref, url, shop, fee]
    end
    events.unshift(HEADER)

    session = GoogleDrive::Session.from_service_account_key('config/service_account.json')
    ws = session.spreadsheet_by_key(ENV['SPREADSHEET_KEY']).worksheets[1]

    ws.delete_rows(1, ws.num_rows)
    ws.update_cells(1, 1, events)
    ws.save
  end
end
