require 'open-uri'
require 'nokogiri'
require 'pry'
require 'mandrill'

class Notifications
  def send_email(message)
    begin
        mandrill = Mandrill::API.new ENV['MANDRILL_API']
        message = {"headers"=>{"Reply-To"=>ENV['EMAIL_ADDRESS']},
        "merge_language"=>"mailchimp",
        "track_clicks"=>nil,
        "from_email"=>ENV['EMAIL_ADDRESS'],
        "text"=> message,
        "return_path_domain"=>nil,
        "inline_css"=>nil,
        "track_opens"=>nil,
        "to"=>
              [{"email"=>ENV['EMAIL_ADDRESS'],
                "type"=>"to",
                "name"=>"Rick Peyton"}],
        "auto_html"=>nil,
        "html"=>"<p>#{message}</p>",
        "important"=>false,
        "auto_text"=>nil,
        "subject"=>message,
        "merge"=>true,
        "signing_domain"=>nil,
        "tracking_domain"=>nil,
        "from_name"=>"Rick Peyton",
        "metadata"=>{"website"=>"ezra.rickpeyton.com"},
        "preserve_recipients"=>nil,
        "url_strip_qs"=>nil
      }
        result = mandrill.messages.send message
            # [{"reject_reason"=>"hard-bounce",
            #     "status"=>"sent",
            #     "email"=>"recipient.email@example.com",
            #     "_id"=>"abc123abc123abc123abc123abc123"}]

    rescue Mandrill::Error => e
        # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
        # A mandrill error occurred: Mandrill::UnknownSubaccountError - No subaccount exists with the id 'customer-123'    
        raise
    end
  end
end

URL = "http://store.steampowered.com/app/233450/"
@doc = Nokogiri::HTML(open(URL))

@items = @doc.xpath("//div[contains(@class, 'game_area_purchase_game_wrapper')]/div/h1").collect{ |node| node.text.strip }

@prices = @doc.xpath("//div[contains(@class, 'game_area_purchase_game_wrapper')]/div/div[contains(@class, 'game_purchase_action')]/div/div[contains(@class, 'game_purchase_price price')]").collect { |node| node.text.strip }

@games = []

@items.each_with_index do |item, index|
  @games << { title: item, price: @prices[index] }
end

@standard = @games.select{ |game| game[:title] == "Buy Prison Architect Standard" }.first

if @standard
  current_price = File.read "current_price.txt"
  if current_price == @standard[:price]
    exit
  else
    message = "Prison Architect Price Change: was #{current_price}, now #{@standard[:price]}"
    File.open "current_price.txt", "w+" do |f|
      f.write @standard[:price].strip
    end
    Notifications.new.send_email(message)
  end
else
  message = "Prison Architect Check Error"
  Notifications.new.send_email(message)
end
