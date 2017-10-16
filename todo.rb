require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do 
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# show list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout  
end

# form to create new list
get "/lists/new" do
  erb :new_list, layout: :layout
end

# validate list name and return error message, return nil if name is valid
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? {|list| list[:name] == name}
    "List name must be unique."
  end
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip 
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

get "/lists/:list_id" do
  @id = params[:list_id].to_i
  @list = session[:lists][@id]
  erb :list, layout: :layout
end

get "/lists/:list_id/edit" do
  @id = params[:list_id].to_i
  @list = session[:lists][@id]
  erb :edit_list, layout: :layout
end

post "/lists/:list_id" do
  list_name = params[:list_name].strip
  @id = params[:list_id].to_i
  @list = session[:lists][@id]
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{@id}"
  end
end

post "/lists/:list_id/destroy" do
  @id = params[:list_id].to_i
  session[:lists].delete_at(@id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end
