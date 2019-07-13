module ApplicationHelper
  def fetch_url(url)
    begin
      puts "Fetching data from #{url}"
      return JSON.parse(open(url).read)
    rescue OpenURI::HTTPError => e
      return nil
    end
  end
end
