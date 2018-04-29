namespace :es do
  task :fetch do
    URL = 'https://event.shadowverse.jp/eventsupport/'
    AGENT = Mechanize.new

    PREF_REGEXP = %r[(北海道|青森県|岩手県|宮城県|秋田県|山形県|福島県|茨城県|栃木県|群馬県|埼玉県|千葉県|東京都|神奈川県|新潟県|富山県|石川県|福井県|山梨県|長野県|岐阜県|静岡県|愛知県|三重県|滋賀県|京都府|大阪府|兵庫県|奈良県|和歌山県|鳥取県|島根県|岡山県|広島県|山口県|徳島県|香川県|愛媛県|高知県|福岡県|佐賀県|長崎県|熊本県|大分県|宮崎県|鹿児島県|沖縄県)]
    HEADER = %w[Date Place Pref Emblem Format Mode URL Shop Title]
    event_urls = []
    page = AGENT.get(URL)
    loop do
      event_urls << page.links.select{|l| l.href.start_with?('/eventsupport/detail') }.map{|l| l.resolved_uri.to_s }

      next_link = page.at('div.next > a')
      if next_link
        page = AGENT.get(URL + next_link['href'])
      else
        break
      end
    end

    events = event_urls.flatten.map do |url|
      page = AGENT.get(url)
      shop = page.at('div.title-header > div.shop').text.strip
      date = page.at('div.date > div.text').text.strip
      title = page.at('div.event > div.text').text.strip
      place = page.at('div.shop > div.text').text.strip
      pref = place.scan(PREF_REGEXP).first&.first
      info = page.at('div.event-info > div.text').text.strip
      emblem = info.scan(%r[■参加賞エンブレム\s*(.*)\s*]).first&.first&.strip
      format = info.scan(%r[■試合方式1\s*(.*)\s*]).first&.first&.strip
      mode = info.scan(%r[■試合方式2\s*(.*)\s*]).first&.first&.strip
      [date, place, pref, emblem, format, mode, url, shop, title]
    end
    events.unshift(HEADER)

    session = GoogleDrive::Session.from_service_account_key('config/service_account.json')
    ws = session.spreadsheet_by_key(ENV['SPREADSHEET_KEY']).worksheets[0]

    ws.delete_rows(1, ws.num_rows)
    ws.update_cells(1, 1, events)
    ws.save
  end
end
