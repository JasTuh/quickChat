class CreateConversationsTable < ActiveRecord::Migration
  def change
  	create_table :conversations do |t|
  		t.string :title
  		t.string :secret
  	end
  end
end
