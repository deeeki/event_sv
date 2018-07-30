namespace :eb do
  task :fetch do
    URL = 'https://dqr.minnanosakaba.jp/compe'
    AGENT = Mechanize.new

    PREF_REGEXP = %r[(北海道|青森県|岩手県|宮城県|秋田県|山形県|福島県|茨城県|栃木県|群馬県|埼玉県|千葉県|東京都|神奈川県|新潟県|富山県|石川県|福井県|山梨県|長野県|岐阜県|静岡県|愛知県|三重県|滋賀県|京都府|大阪府|兵庫県|奈良県|和歌山県|鳥取県|島根県|岡山県|広島県|山口県|徳島県|香川県|愛媛県|高知県|福岡県|佐賀県|長崎県|熊本県|大分県|宮崎県|鹿児島県|沖縄県)]
    HEADER = %w[Date Place Pref URL Shop Fee]
    event_urls = []
    index = 1
    loop do
      page = AGENT.get(URL + "?page=#{index}")
      urls = page.links.select{|l| l.href =~ /compe\/\d+/ }.map{|l| l.resolved_uri.to_s.gsub(/;.+/, '') }

      break if urls.empty?

      event_urls << urls
      index += 1
    end

    events = event_urls.flatten.map do |url|
      page = AGENT.get(url)
      date = page.search('div.cont-block > ul.list-unstyled > li')[1].text.gsub(/.+：/, '')
      shop = page.search('h4.title-main > strong')[0].text.gsub(/\s/, '').gsub(/\-.+/, '').strip
      place = page.search('div.cont-block > ul.list-unstyled > li')[6].text.gsub(/.+：/, '')
      pref = place.scan(PREF_REGEXP).first&.first
      fee = page.search('div.cont-block > ul.list-unstyled > li')[4].text.gsub(/.+：/, '')
      [date, place, pref, url, shop, fee]
    end
    events.unshift(HEADER)

    Writer.google_drive('EB', events)
  end
end
