class CreateUsersTable < ActiveRecord::Migration
  def change
  	create_table :users do |t|
  		t.string :username
  		t.string :email
  		t.string :password_hash
  		t.string :fname
  		t.string :lname
  	end
  end
end
