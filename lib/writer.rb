class Writer
  class << self
    def google_drive ws_title, data
      session = GoogleDrive::Session.from_service_account_key('config/service_account.json')
      ss = session.spreadsheet_by_key(ENV['SPREADSHEET_KEY'])
      ws = ss.worksheet_by_title(ws_title) || ss.add_worksheet(ws_title)

      ws.delete_rows(1, ws.num_rows)
      ws.update_cells(1, 1, data)
      ws.save
    end

    def csv file_path, data
      require 'csv'
      File.write(file_path, data.map(&:to_csv).join)
    end
  end
end
