>There must be some way out of here
>said the "programmer" to the "chief"
>there's too much confusion
>i can get no "release" -- Bob Dylan

MonoRiel
=====

MonoRiel is an attempt to fork from mini-rail 
which is in itself a fork from another rack project(rack-golem) into
super simplistic but useful web mini-framework (MonoRiel (spanish) = monorail (english))

there's no gem for now, but somewhere in time you will:

    sudo gem install monoriel

You can use config.ru as a start up file as for any rack app based

    require 'models' # Loads your models and all ORM stuff
    require 'app' # This is the main file
    use Rack::ContentLength
    use Rack::Session::Cookies
    use Rack::Static, urls: ["/css","/js","/html"], root: "public" #Add this for static content
    #The default folder for templates is views
    run Rack::MethodOverride.new(App.new)  #Need to use this for PUT and DELETE methods

Now save this into app.rb

    require 'monoriel'

  	class App
	    include Monoriel # No classes to inherit just mixin

	before do
	  # Here you can do many things
	  # In order to help you here are some variables you can read and override:
	  # @r => the Rack::Request object
	  # @res => the Rack::Response object
	  # @action => Name of the public method that will handle the request
	  @user.login
	end

	helpers do
			#altough you can write many things in the before block
			#you always need helpers for your main app
			def help(with)
				"Helping the World!" + with
			end
		end
		
	def index(*args)
	  # Used always when no public method is found
	  # Of course you don't have to declare one and it is gonna use #not_found instead
	  # Still can have arguments
	  @articles = Post.all
	  erb :index
	end

	def page(id=nil)
	  @page = Pages[id]
	  if @page.nil?
		not_found
	  else
		erb :page
	  end
	end
	
	def form
		#write your form here
		#add _method hidden PUT as the Form Action
	end
	
	def post_page
		#You can POST Forms and Monoriel will direct to post_* methods
		@r.params["name"]
	end
	
	def best_restaurants_json
	  # Monoriel replaces dashes with underscores
	  # You can trigger this handler by visiting /best-restaurants-json
	  json_response({
		'title' => 'Best restaurants in town',
		'list' => Restaurant.full_list
	  })

	def say(listener='me', *words)
	  "Hey #{listener} I don't need ERB to tell you that #{words.join(' ')}"
	end

	def not_found(*args)
	  # This one is defined by Monoriel but here we decided to override it
	  # Like :index this method receives the arguments in order to make something with it
	  Email.alert('Many spam emails received') if args.includes?("spam")
	  super(args)
	end
	
	def error(err, *args)
	  # Again this one is defined by Monoriel and only shows up when RACK_ENV is not `nil` or `dev` or `development`
	  # Default only prints "ERROR"
	  # Here we're going to send the error message
	  # One would rarely show that to the end user but this is just a demo
	  err.message
	end

	after do
	  @user.logout
	end

	end

- You need to provide the class Page in your models.
- You can use slim, haml, scss and erb templates with Monoriel
- Please use App in Samples for testing and documentation
