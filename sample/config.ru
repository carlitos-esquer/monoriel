#require 'models' # Loads your models and all ORM stuff
require './app' # This is the main file
# Some help from other gems
use Rack::ContentLength
use Rack::Static, urls: ["/css","/js","/html"], root: "public"
#use Rack::Session::Cookies
run Rack::MethodOverride.new(App.new)
