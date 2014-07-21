require "sinatra"
require "sinatra/activerecord"
require 'sinatra-websocket' 

configure(:development){set :database, "sqlite3:users.sqlite3"}
require 'bundler/setup' 
require 'rack-flash'

require "sinatra/activerecord"
require './models'
set :sessions, true
use Rack::Flash, :sweep => true
set :server, 'thin'
set :sockets, []
usernameTMP = ""

get '/' do
    if (session[:user_id] == nil)
        erb :login_page
    else 
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
    @user = User.find_by_username params[:username]
    if !@user && params[:password] == params[:cpassword]
        User.create(username:params[:username], email:params[:email], password:params[:password])
        @user = User.find_by_username params[:username]
        session[:user_id] = @user.id
        redirect '/'
    end
end

get '/new-convo' do
    erb :conversation_page
end
post '/addconvo' do 
    users = params[:users].split(",")
    @conversation = Conversation.create(title:params[:title])
    UserConversation.create(user_id:session[:user_id], conversation_id:@conversation.id)
    users.each do |n| 
        curUser = User.find_by_username(n)
        UserConversation.create(user_id:curUser.id, conversation_id:@conversation.id)
    end
    redirect "/conversation/#{@conversation.id}"
end

get '/conversation/:id' do
    if !request.websocket?
        @conversation = Conversation.find(params[:id])
        @a = UserConversation.where(conversation_id:params[:id])
        @users = []
        @a.each do |u| 
            @users.push(u.user_id)
        end
        usernameTMP = User.find(session[:user_id]).username
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
                    content = (User.find(ar[ar.length-1]).username +  ": " + tstring)
                    Message.create(content:content, conversation_id:cID);
                    EM.next_tick { lookUp.each{|s| settings.sockets[s.array_index].send(content) } }
                end
                ws.onclose do
                    Sock.destroy(sk)
                end
            end

            
        end
    end
end

post '/login-validation' do
    @user = User.find_by_username params[:username]
    if @user && @user.password == params[:password]
        session[:user_id] = @user.id
        redirect '/'
    else
        flash[:message] = "Try again"
        erb :login_page
    end
end

# get '/conversationList' do
#     @conversations = 
# end