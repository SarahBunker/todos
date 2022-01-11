# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining(list)
    list[:todos].count { |todo| !todo[:completed] }
  end

  def completed_list?(list)
    todos_count(list).positive? && todos_remaining(list).zero?
  end

  def list_class(list)
    'complete' if completed_list?(list)
  end
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Return an error message if name is invalid. Return nill if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    'The list name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'The list name must be unique.'
  end
end

# Return an error message if todo is invalid. Return nill if todo is valid.
def error_for_todo_name(name)
  'Todo must be between 1 and 100 characters.' unless (1..100).cover? name.size
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Display list items, with new item form
get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

# Edit an existing todo list
get '/lists/:id/edit' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  erb :list_edit, layout: :layout
end

# Update an existing todo list
post '/lists/:id' do
  list_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :list_edit, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{params[:id].to_i}"
  end
end

# Delete a list
post '/lists/:id/delete' do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = 'The list has been deleted.'
  redirect '/lists'
end

# Add a todo to a list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo = params[:todo].strip

  error = error_for_todo_name(todo)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: todo, completed: false }
    session[:success] = 'The todo was added.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post '/lists/:list_id/todos/:todo_id/delete' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  @todo_id = params[:todo_id].to_i

  @list[:todos].delete_at(@todo_id)
  session[:success] = 'The todo has been deleted.'
  redirect "/lists/#{@list_id}"
end

# Complete all tasks in todo list.
post '/lists/:list_id/complete_all' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = 'All todos have been completed.'
  redirect "/lists/#{@list_id}"
end

# Update status of todo
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  @todo_id = params[:todo_id].to_i
  @todo = @list[:todos][@todo_id]

  @todo[:completed] = (params[:completed] == 'true')

  session[:success] = 'The todo has been updated.'
  redirect "/lists/#{@list_id}"
end
