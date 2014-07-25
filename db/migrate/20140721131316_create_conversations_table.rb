class CreateConversationsTable < ActiveRecord::Migration
  def change
  	create_table :conversations do |t|
  		t.string :title
  		t.string :secret
  		t.string :created
  		t.integer :time
  	end
  end
end
