# encoding: utf-8

require 'date'
require 'csv'

module DailyChanges

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
