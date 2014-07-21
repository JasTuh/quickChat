class CreateSocketsTable < ActiveRecord::Migration
  def change
  	create_table :socks do |t|
  		t.integer :conversation_id
  		t.integer :array_index
  	end
  end
end
