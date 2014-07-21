class User < ActiveRecord::Base
	has_many :user_conversations
	has_many :conversations, through: :user_conversations
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