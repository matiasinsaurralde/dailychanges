#!/usr/bin/env ruby

require_relative 'lib/dailychanges'

# x.x.x.x = nameserver

p DailyChanges::get_monthly_domain_list_for 'x.x.x.x', Date.today.prev_day()

