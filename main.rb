#!/usr/bin/env ruby

require_relative 'lib/dailychanges'

dynadot = DailyChanges.new( 'dynadot.com' )

# p dynadot

dynadot.domain_list()
