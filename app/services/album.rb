require 'trello'

class Album
  def initialize
    @logger = Logger.new("#{Rails.root}/log/trello.log")
    @logger.info("------------------------------------" + Time.new.strftime("%Y-%m-%d %H:%M:%S") + "------------------------------------------")

    Trello.configure do |config|
      config.developer_public_key = 'b195e42523ebdca59c7b9dcb4e04ff1b' 
      config.member_token = '1289f5c96e6aeac7d5880c67e4bf8788827db2f193b39d57d6da4c264da56f8c'
      config.http_client = 'rest-client'
    end
    result = start()

  end

  
  def start

    years = []
    decades = []
    board = Trello::Board.all.first

    
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
        card.save
      else  
        list = Trello::List.new(name: decade, idBoard: board.id)
        list.save
        card = Trello::Card.new(name: name, idList: list.id)
        card.save
        decades.push(decade)
      end
    end
  end
end