require 'trello'
require 'base64'
require 'net/http'
require 'uri'

class Album
  def initialize
    @logger = Logger.new("#{Rails.root}/log/trello.log")
    @logger.info("------------------------------------" + Time.new.strftime("%Y-%m-%d %H:%M:%S") + "------------------------------------------")

    Trello.configure do |config|
      config.developer_public_key = ENV['TRELLO_PUBLIC_KEY']
      config.member_token = ENV['TRELLO_MEMBER_TOKEN']
      config.http_client = 'rest-client'
    end
    result = start()

  end

  
  def start

    token = get_token

    @logger.info("Usaremos el token :  #{token} ")
    years = []
    decades = []
    board = Trello::Board.create(name: "Albums")

    
    File.open("#{Rails.root}/lib/discography.txt", "r").each_line do |line|
      data = line.split(/\n/).first
      data = data.split(' ')
      release_year = data.first
      album_name = data.drop(1).join(' ')
      years.push([release_year,album_name])
    end
    years = years.sort
    years.each do |album|
      date = album.first
      decade = date.split('')[2] + "0s"
      name = album.last
      if decades.include?(decade)
        id_list = board.lists.find(name: decade).first.id
        card = Trello::Card.new(name: name, idList: id_list)

        url = URI("https://api.spotify.com/v1/search?q=#{URI.encode(name)} Bob Dylan&type=album&access_token=#{token}")
        puts url
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(url)
        response = http.request(request)
        cover = JSON.parse(response.body)["albums"]["items"][0]["images"][1]["url"]
        @logger.info("Usaremos el cover :  #{cover} ")
        card.save
        card.add_attachment(cover)

      else  
        list = Trello::List.new(name: decade, idBoard: board.id)
        list.save
        card = Trello::Card.new(name: name, idList: list.id)

        url = URI("https://api.spotify.com/v1/search?q=#{URI.encode(name)} Bob Dylan&type=album&access_token=#{token}")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(url)
        response = http.request(request)
        cover = JSON.parse(response.body)["albums"]["items"][0]["images"][1]["url"]
        @logger.info("Usaremos el cover :  #{cover} ")
        card.save
        card.add_attachment(cover)
        decades.push(decade)
      end
    end
  end

  def get_token
    client_id = ENV['SPOTIFY_CLIENT_ID']
    client_secret = ENV['SPOTIFY_CLIENT_SECRET']

    
    url = URI('https://accounts.spotify.com/api/token')
    base_string = Base64.strict_encode64(client_id + ":" + client_secret)
    headers = 
    {
      "content-type" => "application/x-www-form-urlencoded",
      "authorization" => "Basic " + base_string,
    }
    body = "grant_type=client_credentials"

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url, initheader = headers)
    request.body = body
    begin
      response = http.request(request)
      token = JSON.parse(response.body)["access_token"]
      @logger.info("Nuevo token :  #{token} ")
      return token
    rescue StandardError => e
      @logger.error("Ocurrio un error: #{e}")
    end
  end
end


