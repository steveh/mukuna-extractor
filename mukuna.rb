require 'rubygems'
require 'hpricot'
require 'rss/maker'
require 'ramaze'
require 'open-uri'

class Gig

  attr_accessor :url, :title, :tags, :date, :location, :price
  
end

class GigGuide

  attr_reader :gigs

  def initialize
  
    #doc = Hpricot(open("http://www.mukuna.co.nz/index.htm"))
    doc = Hpricot(File.open("index.htm"))

    @gigs = []
    
    (doc/"div#mainbox2 tr.vevent").each do |gigrow|
    
 #     begin
      
        gig = Gig.new
        
        col1 = (gigrow/"td:nth-child(0)")

	unless (col1/"a.url").inner_html == ""

	        gig.url = "http://www.mukuna.co.nz" + (col1/"a.url").attr("href")
		gig.title = (col1/"a.url").inner_html
		gig.tags = (col1/"span.description").inner_html

	else

		gig.title = col1.search("*")[1].to_s

	end

        gig.date = Time.parse((col1/"abbr.dtstart").attr("title"))
        
        location_pieces = (gigrow/"td:nth-child(1)").search("*")
        gig.location = [location_pieces[2], location_pieces[4]].join(", ")
        
        gig.price = (gigrow/"td:nth-child(2)").inner_html
        
        @gigs << gig
      
      # ignore malformed rows
      #rescue NoMethodError

#	puts "Failed to parse " + gigrow.inspect
      
 #     end
      
    end
  
  end
  
  def rss
  
    RSS::Maker.make("2.0") do |maker|

      maker.channel.about = "Auckland Gig Guide"
      maker.channel.title = "Mukuna"
      maker.channel.description = "Mukuna Auckland Gig Guide"
      maker.channel.link = "http://www.mukuna.co.nz/"
      
      maker.image.title = "Mukuna Logo"
      maker.image.url = "http://www.mukuna.co.nz/img/mukuna.gif"
    
      for gig in @gigs
        maker.items.new_item do |item|
          item.link = gig.url
          item.title = gig.title + ", " + gig.date.strftime("%a %d %b")
          item.date = gig.date
          item.description = [gig.location, gig.price, gig.tags].reject(&:nil?).join(", ")
        end
      end
      
    end

  end

end
 
class MainController < Ramaze::Controller

  def index
  
    guide = GigGuide.new

    guide.rss
    
  end
  
end

Ramaze.start :adapter => :mongrel, :port => 7000
