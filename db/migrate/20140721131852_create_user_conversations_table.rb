class CreateUserConversationsTable < ActiveRecord::Migration
  def change
  	create_table :user_conversations do |t|
  		t.integer :user_id
  		t.integer :conversation_id
  	end
  end
end
