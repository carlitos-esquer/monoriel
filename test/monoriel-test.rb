require 'minitest/autorun'
require 'rack/lobster'
require 'slim'
require_relative '../lib/monoriel'


# =========
# = Basic =
# =========

class Basic
  include Monoriel
  def no_arg; 'nothing'; end  
  def with_args(a,b); '%s+%s' % [a,b]; end 
  def splat_arg(*a); a.join('+'); end
  def test_throw
    throw :response, [200,{'Content-Type'=>'text/html'},['Growl']]
    'Grrr'
  end
  def best_restaurants_rss; '<xml>test</xml>'; end
  private
  def no_way; 'This is private'; end
end
BasicR = ::Rack::MockRequest.new(::Rack::Lint.new(Basic.new))
BasicLobsterR = ::Rack::MockRequest.new(::Rack::Lint.new(Basic.new(::Rack::Lobster.new)))

# ==========
# = Filter =
# ==========

class Filter
  include Monoriel
  before{@res.write @action=='not_found' ? @action_arguments.join('+') : 'before+'}
  after{@res.write '+after'}
  def wrapped; 'wrapped'; end
end
FilterR = ::Rack::MockRequest.new(::Rack::Lint.new(Filter.new))

# ===========
# = Indexed =
# ===========

class Indexed
  include Monoriel
  before{ @res.write("action=#{@action} args=#{@action_arguments.join(',')} ") if @r['switch']=='true' }
  def index(*a); a.join('+'); end
  def exist(*a); a.join('+'); end
end
IndexedR = ::Rack::MockRequest.new(::Rack::Lint.new(Indexed.new))

# ==================
# = Simply indexed =
# ==================

class SimplyIndexed
  include Monoriel
  def index; 'index'; end
  def will_fail; please_fail; end
  private
  def please_fail(num); 'ArgumentError baby'; end
end
SimplyIndexedR = ::Rack::MockRequest.new(::Rack::Lint.new(SimplyIndexed.new))
SimplyIndexedUsedR = ::Rack::MockRequest.new(::Rack::Lint.new(SimplyIndexed.new(lambda{|env| [200,{},"#{3+nil}"]})))

# =============
# = Sessioned =
# =============

class Sessioned
  include Monoriel
  def set_val(val); @session[:val] = val; end
  def get_val; @session[:val]; end
end
SessionedR = ::Rack::MockRequest.new(::Rack::Session::Cookie.new(::Rack::Lint.new(Sessioned.new)))

# =============
# = Helpers =
# =============

class UsingHelpers
	include Monoriel
	helpers { def hola(w); "Hola " + w; end }
	def index; hola("mundo");	end
end
UsingHelpersR = ::Rack::MockRequest.new(::Rack::Lint.new(UsingHelpers.new))

# =============
# = Post method =
# =========

class UsingPostPutAndDelete
	include Monoriel
	#helpers { def params; @r.params; end }
	def post_data; @r.request_method; end
	def put_data; @r.request_method; end
	def delete_data; @r.request_method; end
end
UsingPostPutAndDeleteR = ::Rack::MockRequest.new(::Rack::Lint.new(Rack::MethodOverride.new(UsingPostPutAndDelete.new)))

# =======================
# = Templates with Blocks =
# =========

class UsingTemplatesWithBlocks
	include Monoriel
	helpers do
		def render template
			slim :layout do
				slim template.to_sym
			end
		end
	end
	def index
		render 'test'
	end
end
UsingTemplatesWithBlocksR = ::Rack::MockRequest.new(::Rack::Lint.new(Rack::MethodOverride.new(UsingTemplatesWithBlocks.new)))

# =======================
# = Templates with Blocks =
# =========

class UsingTemplatesWithoutBlocks
	include Monoriel
	def index
		slim :layout
	end
end
UsingTemplatesWithoutBlocksR = ::Rack::MockRequest.new(::Rack::Lint.new(Rack::MethodOverride.new(UsingTemplatesWithoutBlocks.new)))

# =========
# = Specs =
# =========

describe "Monoriel" do
  
  it "Should dispatch on a method with no arguments" do
    assert_equal "nothing",BasicR.get('/no_arg').body
  end
  
  it "Should dispatch on a method with arguments" do
    assert_equal "a+b",BasicR.get('/with_args/a/b').body
  end
  
  it "Should dispatch on a method with splat argument" do
    assert_equal "a+b+c+d",BasicR.get('/splat_arg/a/b/c/d').body
  end
  
  it "Should not dispatch if the method is private or does not exist" do
    r = BasicR.get('/no_way')
    assert_equal 404,r.status
    assert_equal "NOT FOUND: /no_way",r.body
    r = BasicR.get('/no')
    assert_equal 404,r.status
    assert_equal "NOT FOUND: /no",r.body
  end
  
  it "Should dispatch to appropriate underscored action when name contains '-' or '.'" do
    assert_equal "<xml>test</xml>",BasicR.get('/best-restaurants-rss').body
  end
  
  it "Should only apply '-' and '.' substitution on action names" do
    assert_equal 'best-restaurants.rss',IndexedR.get('/best-restaurants.rss').body
  end
  
  it "Should follow the rack stack if response is 404 and there are middlewares below" do
    r = BasicLobsterR.get("/no_way")
    assert_equal 200,r.status
  end
  
  it "Should provide filters" do
    assert_equal "before+wrapped+after",FilterR.get('/wrapped').body
  end
  
  it "Should provide arguments in filter when page is not_found" do
    assert_equal "a+b+c+dNOT FOUND: /a/b/c/d+after",FilterR.get('/a/b/c/d').body
  end
  
  it "Should send everything to :index if it exists and there is no matching method for first arg" do
    assert_equal 'a+b+c+d',IndexedR.get('/exist/a/b/c/d').body
    assert_equal 'a+b+c+d',IndexedR.get('/a/b/c/d').body
    assert_equal '',IndexedR.get('/').body
  end
  
  it "Should send not_found if there is an argument error on handlers" do
    assert_equal 200,SimplyIndexedR.get('/').status
    assert_equal 404,SimplyIndexedR.get('/unknown').status
    assert_equal 404,SimplyIndexedR.get('/will_fail/useless').status
    assert_raises(ArgumentError) { SimplyIndexedR.get('/will_fail') }
  end
  
  it "Should handle errors without raising an exception unless in dev mode" do
    assert_raises(ArgumentError) { SimplyIndexedR.get('/will_fail') }
    ENV['RACK_ENV'] = 'development'
    assert_raises(ArgumentError) { SimplyIndexedR.get('/will_fail') }
    ENV['RACK_ENV'] = 'production'
    @old_stdout = $stdout
    $stdout = StringIO.new
    res = SimplyIndexedR.get('/will_fail')
    logged = $stdout.dup
    $stdout = @old_stdout
    assert_equal res.status,500
    assert_match logged.string, /ArgumentError/
    ENV['RACK_ENV'] = nil
  end
  
  it "Should not use the error handler if the error occurs further down the rack stack" do
    ENV['RACK_ENV'] = 'production'
    assert_raises(TypeError) { SimplyIndexedUsedR.get('/not_found') }
    ENV['RACK_ENV'] = nil
  end
  
  it "Should set dispatch-specific variables correctly when defaulting to :index" do
    assert_equal "action=index args=a,b,c,d a+b+c+d",IndexedR.get('/a/b/c/d?switch=true').body
  end
  
  it "Should have a shortcut for session hash" do
    res = SessionedR.get('/set_val/ichigo')
    res_2 = SessionedR.get('/get_val', 'HTTP_COOKIE'=>res["Set-Cookie"])
    assert_equal 'ichigo',res_2.body
  end
  
  it "Should catch :response if needed" do
    assert_equal 'Growl',BasicR.get('/test_throw').body
  end
  
  it "Should respond with the helpers content" do
    assert_equal 'Hola mundo',UsingHelpersR.get('/').body
  end

	it "Should respond with Post method selector" do
		assert_equal "POST",UsingPostPutAndDeleteR.post("/data").body
		assert_equal "PUT",UsingPostPutAndDeleteR.put("/data").body
		assert_equal "DELETE",UsingPostPutAndDeleteR.delete("/data").body
	end	
	it "Should respond with Page in a Layout" do
		assert_equal "<h1>&lt;p&gt;Content&lt;/p&gt;</h1>",UsingTemplatesWithBlocksR.get("/").body
	end
	it "Should respond with only the Layout content" do
		assert_equal "<h1></h1>",UsingTemplatesWithoutBlocksR.get("/").body
	end
	
end
