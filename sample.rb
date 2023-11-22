#!/usr/bin/env ruby
require 'phashion'
require 'phashion/version'

# write fingerprint for the same image to spot an eventual difference in library versions
File.open('sample.txt','a') do |f|
  f.puts "#{Time.now.strftime '%F %T'}\t#{Phashion::VERSION}\t#{'%016x' % Phashion::Image.new('test/png/linux.png').fingerprint}"
end
