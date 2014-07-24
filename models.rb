class User < ActiveRecord::Base
	include BCrypt
	has_many :user_conversations
	has_many :conversations, through: :user_conversations
	# users.password_hash in the database is a :string
	def password
	  @password ||= Password.new(password_hash)
	end

	def password=(new_password)
	  @password = Password.create(new_password)
	  self.password_hash = @password
	end
end
class Conversation < ActiveRecord::Base
	has_many :messages
	has_many :user_conversations
	has_many :socks
	has_many :users, through: :user_conversations
end

class Message < ActiveRecord::Base
	belongs_to :conversation
end

class UserConversation <ActiveRecord::Base
	belongs_to :user
	belongs_to :conversation
end

class Sock < ActiveRecord::Base
	belongs_to :conversation
end