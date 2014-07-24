require 'bcrypt'

a = BCrypt::Password.create("my password")
puts a == "my password"
puts a