require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def all_completed?(list)
    result = ''
    todos = []
    return nil if list[:todos].empty?
    if list[:todos].all? {|todo| todo[:completed] == true}
      return 'class="complete"'
    end
  end

  def get_number_of_todos_completed(list)
    count = 0
    return 0 if list.empty?
    list.each do |todo|
      if todo[:completed] == true
        count += 1
      end
    end
    count
  end

  def sort_lists_by_completed(lists)
    completed = {}
    not_completed = {}
    lists.each_with_index do |list, index|
      if all_completed?(list)
        completed[index] = list
      else
        not_completed[index] = list
      end
    end
    not_completed.merge(completed)
  end

  def sort_list_by_completed(list)
    completed = {}
    not_completed = {}
    list[:todos].each_with_index do |todo, index|
      if is_completed?(todo)
        completed[index] = todo 
      else
        not_completed[index] = todo
      end
    end
    not_completed.merge(completed)
  end

  def is_completed?(todo)
    todo[:completed] == true
  end
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

# show a specific list
get "/lists/:list_id" do
  @id = params[:list_id].to_i
  @list = session[:lists][@id]
  erb :list, layout: :layout
end

# form to edit a specific list
get "/lists/:list_id/edit" do
  @id = params[:list_id].to_i
  @list = session[:lists][@id]
  erb :edit_list, layout: :layout
end

# submit form to edit specifc list
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

# error handling for todo names
def error_for_todo_name(name)
  if !(1..100).cover?(name.size)
    "Todo name must be between 1 and 100 characters."
  elsif @list[:todos].any?{|todo| todo == name}
    "Todo name must be unique."
  end  
end

# deleting a list
post "/lists/:list_id/destroy" do
  @id = params[:list_id].to_i
  session[:lists].delete_at(@id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# submiting a new todo to a list
post "/lists/:list_id/todos" do
  @id = params[:list_id].to_i
  @list = session[:lists][@id]
  todo_name = params[:todo].strip 
  error = error_for_todo_name(todo_name)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    session[:success] = "The todo has been created."
    @list[:todos] << {name: todo_name, completed: false}
    redirect "/lists/#{@id}"
  end
end

post "/lists/:list_id/todos/:todo_id/destroy" do
  @id = params[:list_id].to_i
  @list = session[:lists][@id]
  @list[:todos].delete_at(params[:todo_id].to_i)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@id}"
end

post "/lists/:list_id/todos/:todo_id" do
  @id = params[:list_id].to_i
  @list = session[:lists][@id]
  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == 'true'
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@id}"
end

post "/lists/:list_id/complete_all" do
  @id = params[:list_id].to_i
  @list = session[:lists][@id]
  @list[:todos].each{|todo| todo[:completed] = true}
  session[:success] = "All todos have been completed."
  redirect "/lists/#{@id}"
end
