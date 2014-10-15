require "./lib/randstr"
require "bundler"
Bundler.setup(:default)
require "sinatra"
require "sinatra/reloader"
require 'sinatra/assetpack'
require "pry"
require "sinatra"
require 'haml'
require 'sass'
require 'coffee_script'
require 'yui/compressor'
require 'sinatra/json'
require 'carrierwave'
require 'mongoid'
require 'carrierwave/mongoid'
require 'carrierwave-aliyun'
require "mini_magick"
require 'kaminari/sinatra'
require "./lib/ext"
require "logger"
require File.expand_path("../../config/env",__FILE__)

require "./lib/image"

class ImageServiceApp < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  Logger.class_eval { alias :write :'<<' }
  log_dir = File.join(File.dirname(File.expand_path("..", __FILE__)), "tmp", "logs")

  FileUtils.mkdir_p(log_dir) if !File.exists?(log_dir)

  access_log        = File.join(log_dir, "access.log")
  access_logger     = Logger.new(access_log)
  error_logger      = File.new(File.join(log_dir, "error.log"), "a+")
  error_logger.sync = true
 
  configure do
    use Rack::CommonLogger, access_logger
  end
 
  before {
    env["rack.errors"] =  error_logger
  }

  set :views, ["templates"]
  set :root, File.expand_path("../../", __FILE__)
  register Sinatra::AssetPack

  assets {
    serve "/js", :from => "assets/javascripts"
    serve "/css", :from => "assets/stylesheets"
    serve "/lily", :from => "assets/lily" # 引用 lily 样式库
    serve "/futura", :from => "mobile-ui/css/fonts" # 引用 futura 字体

    js :application, "/js/application.js", [
      '/js/lib/*.js',
      '/js/*.js'
    ]

    css :application, "/css/application.css", [
      "/css/ui.css"
    ]

    css_compression :yui
    js_compression  :uglify
  }

  before do
    headers("Access-Control-Allow-Origin" => "#{request.env["HTTP_ORIGIN"]}")
    headers("Access-Control-Allow-Credentials" => "true")
    headers("Access-Control-Allow-Methods" => "POST,GET,OPTIONS")
  end

  def img_json(image)
    content_type :json
    JSON.generate({filename: image.filename, url: image.raw.url}.merge(image.meta || {}))
  end
  
  get "/" do
    haml :index
  end

  get "/images" do
    @images = Image.page(params[:page]).per(100)
    haml :images
  end

  get "/r/:token" do
    image = Image.find_by(token: params[:token])
    redirect to(image.file.url)
  end

  options "/images" do
    200 
  end

  post "/images" do
    if params[:base64]
      image = Image.from_base64 params[:base64]

    elsif params[:remote_url]
      image = Image.from_remote_url params[:remote_url]
    
    elsif params[:file]
      image = Image.from_params(params[:file])
    
    end

    img_json(image) if image
  end

  get "/settings" do
    haml :settings
  end

  post "/settings" do
    OutputSetting.from(params[:option].to_a[0])
    haml :settings_partial, layout: false
  end

  delete "/settings" do
    OutputSetting.del(params[:option].to_a[0])
    "deleted"
  end

  get "/images/:token" do
    @image = Image.find_by(token: params[:token])
    haml :image
  end

  post "/api/upload" do
    image = Image.from_params(params[:file])
    img_json(image) if image
  end

  get "/api/images/:token" do
    @image = Image.find_by(token: params[:token])
    image_json(@image.color)
  end

  get "/display" do
    @url = params[:url]
    haml :display
  end
end
