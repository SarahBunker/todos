# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

configure do
  set :erb, escape_html: true
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

  def sort_lists(lists)
    complete_lists, incomplete_lists = lists.partition { |list| completed_list?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each(&block)
    complete_todos.each(&block)
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

# Check if list index is valid before loading a list.
def load_list(index)
  list = session[:lists][index] if index && session[:lists][index]
  return list if list

  session[:error] = 'The specified list was not found.'
  redirect '/lists'
end

# Display list items, with new item form
get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  erb :list, layout: :layout
end

# Edit an existing todo list
get '/lists/:id/edit' do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  erb :list_edit, layout: :layout
end

# Update an existing todo list
post '/lists/:id' do
  list_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

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
  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    '/lists'
  else
    session[:success] = 'The list has been deleted.'
    redirect '/lists'
  end
end

# Find the largest todo id and return the number one greater.
def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0
  max + 1
end

# Add a todo to a list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo = params[:todo].strip

  error = error_for_todo_name(todo)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    id = next_todo_id(@list[:todos])
    @list[:todos] << { id: id, name: todo, completed: false }
    session[:success] = 'The todo was added.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post '/lists/:list_id/todos/:todo_id/delete' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:todo_id].to_i
  @list[:todos].reject! { |todo| todo[:id] == todo_id }

  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    status 204
  else
    session[:success] = 'The todo has been deleted.'
    redirect "/lists/#{@list_id}"
  end
end

# Complete all tasks in todo list.
post '/lists/:list_id/complete_all' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = 'All todos have been completed.'
  redirect "/lists/#{@list_id}"
end

# Update status of todo
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:todo_id].to_i
  todo = @list[:todos].find { |item| item[:id] == todo_id }
  todo[:completed] = (params[:completed] == 'true')

  session[:success] = 'The todo has been updated.'
  redirect "/lists/#{@list_id}"
end
