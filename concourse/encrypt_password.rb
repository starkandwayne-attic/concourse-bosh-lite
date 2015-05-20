#!/usr/bin/env ruby

password=ARGV[0]
if !password || password.size == 0
  $stderr.puts "USAGE: ./encrypt_password.rb PASSWORD"
  exit 1
end
require 'bcrypt'
print BCrypt::Password.create password, cost: 4
