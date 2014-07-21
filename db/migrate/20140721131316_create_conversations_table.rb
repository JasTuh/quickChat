class CreateConversationsTable < ActiveRecord::Migration
  def change
  	create_table :conversations do |t|
  		t.string :title
  	end
  end
end
