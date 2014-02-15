require 'rest_client'
require 'nokogiri'
require 'date'
require 'csv'

class DailyChanges

  BASE_URL = 'http://www.dailychanges.com'

  attr_reader :nameserver, :daily_stats

  def initialize( nameserver )
    @nameserver = nameserver
    begin
      @nameserver_page = RestClient.get("#{BASE_URL}/#{@nameserver}/")
    rescue RestClient::ResourceNotFound      
      puts 'Invalid nameserver!'
      @nameserver = nil
    end

    @daily_stats, _page = {}, Nokogiri::HTML( @nameserver_page )

    _page.css('.dc-data/p').map { |legend| legend.text }.each do |legend|
      number = legend.match(/([0-9]+) domains/)[1].to_i
      case legend
        when /added/
          @daily_stats.store( :today_added_domains, number )
        when /deleted/
          @daily_stats.store( :today_deleted_domains, number )
        when /transferred in/
          @daily_stats.store( :today_transferred_in, number )
        when /transferred out/
          @daily_stats.store( :today_transferred_out, number )
      end
    end

    @daily_stats.store( :total_domains, _page.css(".vertical-pad-10/a[@class='bold']/text()").text.gsub(/(domains|,)/, '').to_i )

    p @daily_stats
  end

end

module DailyChanges_

  def self.get_domain_list_for( server, date )

    referer, data = "http://www.dailychanges.com/#{server}/#{date.strftime}/", { :new => {}, :in => {}, :out => {} }

    raw_csv, index = `curl -s -A "Mozilla Firefox" -e "#{referer}" "http://www.dailychanges.com/export/prodominios.com/#{date.strftime}/export.csv"`.gsub("\r", "").split("\n"), 0

    raw_csv.each do |ln|
      if ln[ ln.size-1, ln.size ] == ','
        raw_csv[ index ] += "0"
      end
      index += 1
    end

    csv = CSV.parse( raw_csv[ 3, raw_csv.size ].join("\n") )

    csv.each do |d|
      state = d[1]

      if d[2] == "0"
        server = nil
      else
        server = d[2]
      end

      data[ state.to_sym ].store( d[0], server )
    end
    return data
  end

  def self.get_monthly_domain_list_for( server, date, days = 30 )
    total_data = { :new => {}, :in => {}, :out => {} }
    days.times do |n|
      date = date.prev_day()
      self.get_domain_list_for( server, date ).each do |state, domains|
        domains.each do |domain, server|
          total_data[ state ].store( domain, server )
        end
      end
    end
    return total_data
  end
end
