require 'rack'
require 'tilt'

module Minitrain
  
  def self.included(klass)
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
    end
  end
  
  module ClassMethods
    attr_reader :before_block, :helpers_block, :after_block
    def before(&block); @before_block = block; end
    def helpers(&block); @helpers_block = block; end
    def after(&block); @after_block = block; end
    def dispatcher(&block); @dispatcher_block = block; end
    def dispatcher_block
      @dispatcher_block || proc{
        @path_atoms = @r.path_info.split('/').find_all{|s| s!=''}
        @action, *@action_arguments = @path_atoms
        @met = @r.request_method == "GET" ?  "" : @r.request_method.downcase + "_"
        @action = @met + @action unless @action.nil?
        unless public_methods.include?(@action)||(@action&&public_methods.include?(@action.to_sym))
          if public_methods.include?('index')||public_methods.include?(:index) # For different RUBY_VERSION(s)
            @action, @action_arguments = 'index', @path_atoms
          else
            @action, @action_arguments = 'not_found', @path_atoms
          end
        end
        instance_eval(&self.class.before_block) unless self.class.before_block.nil?
        instance_eval(&self.class.helpers_block) unless self.class.helpers_block.nil?
        begin
          @res.write(self.__send__(@action,*@action_arguments))
        rescue ArgumentError => e
          failed_method = e.backtrace[0][/`.*'$/][1..-2]
          raise unless failed_method==@action
          @res.write(self.__send__('not_found', @path_atoms))
        end
        instance_eval(&self.class.after_block) unless self.class.after_block.nil?
      }
    end
  end
  
  module InstanceMethods
    
    DEV_ENV = [nil,'development','dev']
    
    def initialize(app=nil); @app = app; end
    def call(env); dup.call!(env); end
    
    def call!(env)
      catch(:response) {
        @r = ::Rack::Request.new(env)
        @res = ::Rack::Response.new
        @session = env['rack.session'] || {}
        begin
          instance_eval(&self.class.dispatcher_block)
        rescue => e
          raise if DEV_ENV.include?(ENV['RACK_ENV'])
          @res.write(self.__send__('error', e, @path_atoms))
        end
        @res.status==404&&!@app.nil? ? @app.call(env) : @res.finish
      }
    end
    
    def not_found(*args)
      @res.status = 404
      @res.headers['X-Cascade']='pass'
      "NOT FOUND: #{@r.path_info}"
    end
    
    def error(e, *args)
      puts "\n", e.class, e.message, e.backtrace # Log the error anyway
      @res.status = 500
      "ERROR 500"
    end
    
    def tpl(template, extention)
			key = (template.to_s + extention.gsub(/[.]/,"_")).to_sym
      @@tilt_cache ||= {}
      if @@tilt_cache.has_key?(key)
        template_obj = @@tilt_cache[key]
      else
        views_location = @r.env['views'] || ::Dir.pwd+'/views/'
        views_location << '/' unless views_location[-1]==?/
        template_obj = Tilt.new("#{views_location}#{template}#{extention}")
        @@tilt_cache.store(key,template_obj) if ENV['RACK_ENV']=='production'
      end
      @res['Content-Type'] = "text/html;charset=utf-8"
      template_obj.render(self)
    end
    
	def erb(template)
		tpl(template,'.erb')
	end
	
	def slim(template)
		tpl(template,'.slim')
	end
	
	def haml(template)
		tpl(template,'.haml')
	end

	def scss(template)
		tpl(template,'.scss')
	end
  end
  
end
