require "sinatra"
require "sinatra/activerecord"
require 'sinatra-websocket' 

configure(:development){set :database, "sqlite3:users.sqlite3"}
require 'bundler/setup' 
require 'rack-flash'

require "sinatra/activerecord"

require 'bcrypt'
require './models'
set :sessions, true
require './secret.rb'
use Rack::Flash, :sweep => true
set :server, 'thin'
set :sockets, []

get '/' do
    if (session[:user_id] == nil)
        erb :login_page
    else 
        @conversations = UserConversation.where(user_id:session[:user_id])
        erb :index
    end
end

get '/logout' do
    session[:user_id] = nil
    redirect '/'
end

get '/register' do
    erb :register
end
post '/register-validation' do
    @user = User.find_by_username(params[:username])

    if !@user && params[:password] == params[:cpassword]
        a = User.create(username:params[:username], email:params[:email], password:params[:password], fname:params[:fname], lname:params[:lname])
        @user = User.find_by_username params[:username]
        session[:user_id] = a.id
        redirect '/welcome'
    end
    if @user
        flash[:message] = "Username is already taken."
    else 
        flash[:message] = "Passwords do not match."
    end
    redirect '/register'
end

get '/new-convo' do
    erb :conversation_page
end
post '/addconvo' do
    timeTo = params[:timeSec].to_i
    if (timeTo < 1)
        timeTo = 5
    end
    if (params[:title] == "")
        flash[:message] = "Title cannot be blank"
        erb :conversation_page
    elsif params[:username] == ""
        flash[:message] = "Please Select A User"
        erb :conversation_page
    elsif params[:username] == "noone"
        o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
        string = (0...50).map { o[rand(o.length)] }.join
        @conversation = Conversation.create(title:params[:title], secret:string, time:timeTo)
        UserConversation.create(user_id:session[:user_id], conversation_id:@conversation.id)
        redirect "/conversation/#{@conversation.id}"
    else
        user = User.find_by_username(params[:username])
        user2= User.find(session[:user_id])
        if (user)
            o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
            string = (0...50).map { o[rand(o.length)] }.join
            @conversation = Conversation.create(title:params[:title], secret:string, time:timeTo)
            UserConversation.create(user_id:user2.id, conversation_id:@conversation.id)
            UserConversation.create(user_id:user.id, conversation_id:@conversation.id)
            redirect "/conversation/#{@conversation.id}"
        else
            erb :conversation_page
        end
    end
end

get '/join' do
    id = params[:id]
    puts "in join"
    secret = params[:ksy]
    session[:join_url] = "/join?id=#{id}&ksy=#{secret}"
    if session[:user_id] == nil
        erb :login_join
    else
        @conversation=Conversation.find(id)
        puts "#{@conversation.secret} = #{secret}"
        if @conversation.secret == secret
            puts "ALMOST THERE BUD"
        end
        if @conversation && @conversation.secret == secret
            a = UserConversation.where(user_id:session[:user_id], conversation_id:@conversation.id)
            puts "a!!!"
            puts a
            if a.blank?
                puts "HELLO"
                UserConversation.create(user_id:session[:user_id], conversation_id:@conversation.id)
            end
            redirect "/conversation/#{@conversation.id}"
        end
    end
end
post '/login-validation-join' do
    @user = User.find_by_username params[:username]
    if @user && @user.password == params[:password]
        session[:user_id] = @user.id
        redirect session[:join_url]
    else
        flash[:message] = "Try again"
        erb :login_join
    end
end
get '/register-join' do
    erb :register_join
end
post '/register-validation-join' do
    @user = User.find_by_username(params[:username])
    if !@user && params[:password] == params[:cpassword]
        User.create(username:params[:username], email:params[:email], password:params[:password], fname:params[:fname], lname:params[:lname])
        @user = User.find_by_username params[:username]
        session[:user_id] = @user.id
        redirect session[:join_url]
    end
    if @user
        flash[:message] = "Username is already taken."
    else 
        flash[:message] = "Passwords do not match."
    end
    redirect '/register-join'
end

get '/conversation/:id' do
    if !request.websocket?
        @conversation = Conversation.find(params[:id])
        @a = UserConversation.where(conversation_id:params[:id])
        @users = []
        session[:current_convo] = params[:id]
        @a.each do |u| 
            @users.push(u.user_id)
        end
        @messages = Message.where(conversation_id:params[:id])
        erb :conversation
    else
        request.websocket do |ws|
            ws.onopen do
                settings.sockets << ws
                cID = request.path_info.split("/")[2]
                loc = settings.sockets.length-1
                sk = Sock.create(array_index:loc, conversation_id:cID)
                ws.onmessage do |msg|
                    lookUp = Sock.where(conversation_id:cID)
                    ar = msg.split(",")
                    tstring = ""
                    for i in 0..ar.length-2
                        if (i != ar.length-2)
                            tstring += ar[i] + ", "
                        else
                            tstring += ar[i]
                        end
                    end
                    if tstring != ""
                        content = (User.find(ar[ar.length-1]).username +  ": " + tstring)
                        time1 = Time.new
                        a = Message.create(content:content, conversation_id:cID, created:time1);
                        EM.next_tick { lookUp.each{|s| settings.sockets[s.array_index].send(content) } }
                    end
                    ws.onclose do
                    end
                end
            end             
        end
    end
end

post '/login-validation' do
    puts "VALIDATING YOUR LOGIN"
    @user = User.find_by_username params[:username]
    if @user && @user.password == params[:password]
        session[:user_id] = @user.id
        redirect '/'
    else
        flash[:message] = "Try again"
        erb :login_page
    end
end

get '/delete/:id' do
    b = UserConversation.where(user_id:session[:user_id])
    included = false
    b.each do |c| 
        if "#{c.conversation_id}" == params[:id]
            included = true
            puts "this should print"
        end
        puts "conversation id = #{c.conversation_id} and params[:id] = #{params[:id]}"
    end
    if !included 
        redirect '/'
    else
        Conversation.destroy(params[:id])
        a = Message.where(conversation_id:params[:id]).destroy_all
        a = UserConversation.where(conversation_id:params[:id]).destroy_all
        
        redirect '/'
    end
end

post '/addFriend' do
    a = User.find_by_username(params[:username])
    if a 
        UserConversation.create(user_id:a.id, conversation_id:session[:current_convo])
    end
    redirect "/conversation/#{session[:current_convo]}"
end

get '/listOthers' do
    @users = User.all()
    erb :userlist
end


get '/makeConversation/:id' do
    o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    string = (0...50).map { o[rand(o.length)] }.join
    @usertoshow = User.find(params[:id])
    erb :conversation_page
end
post '/search' do
    @users = []
    @users.push(User.find_by_username(params[:search]))
    @users.push(User.find_by_fname(params[:search]))
    @users.push(User.find_by_lname(params[:search]))
    @users.push(User.find_by_fname(params[:search].capitalize))
    @users.push(User.find_by_lname(params[:search].capitalize))
    @users.push(User.find_by_email(params[:search]))
    b = true
    @users.each do |t|
        if t != nil
            b = false
        end
    end
    if @users == [] || b
        @users = User.all()
        flash[:message] = "No Users Were Found with \"#{params[:search]}\""
        erb :userlist
    else
        erb :userlist
    end
end

get '/welcome' do
    erb :welcome
end