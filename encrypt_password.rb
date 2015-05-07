#!/usr/bin/env ruby

password=ARGV[0]
if !password || password.size < 4
  $stderr.puts "USAGE: ./encrypt_password PASSWORD"
  exit 1
end
require 'bcrypt'
print BCrypt::Password.create password, cost: 4

