# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
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

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: ["lettuce", "meat"]}
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Display list items, with new item form
get '/lists/:id' do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :list_test, layout: :layout
  # @number = id.to_i
  # @todos = session[:lists][@number][:todos]
  # erb :list, layout: :layout
end

get '/list/:id/edit' do
  'Hello World'
end

post '/lists/:id' do |id|
  # todo_name = params[:todo_name]

  # @number = id.to_i
  
  # lists = session[:lists]
  # list = lists[@number]
  # if list == nil
  #   redirect '/lists'
  # end
  # @todos = list[:todos]

  # todo_name = params[:todo_name]
  # @todos << todo_name
  # redirect '/lists/<%= @number %>'
end