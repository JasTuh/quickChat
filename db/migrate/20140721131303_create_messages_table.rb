class CreateMessagesTable < ActiveRecord::Migration
  def change
  	create_table :messages do |t|
  		t.string :content
  		t.integer :conversation_id
  		t.datetime :created
  	end
  end
end
