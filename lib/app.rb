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
require File.expand_path("../../config/env",__FILE__)

require "./lib/image"

class ImageServiceApp < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  set :views, ["templates"]
  set :root, File.expand_path("../../", __FILE__)
  register Sinatra::AssetPack

  assets {
    serve '/js', :from => 'assets/javascripts'
    serve '/css', :from => 'assets/stylesheets'

    js :application, "/js/application.js", [
      '/js/jquery-1.11.0.min.js',
      '/js/**/*.js'
    ]

    css :application, "/css/application.css", [
      '/css/**/*.css'
    ]

    css_compression :yui
    js_compression  :uglify
  }

  get "/" do
    haml :index
  end

  get "/images" do
    @images = Image.all
    haml :images
  end

  post "/images" do
    image = Image.from_params(params[:file])
    redirect to("/images/#{image.token}")
  end

  get "/settings" do
    haml :settings
  end

  put "/settings" do
    OutputSettings.add(params[:option].to_a[0]).save
    haml :settings_partial, layout: false
  end

  delete "/settings" do
    OutputSettings.del(params[:option].to_a[0]).save
    "deleted"
  end

  get "/images/:id" do
    @image = Image.find_by(token: params[:id])
    haml :image
  end

  get "/display" do
    @url = params[:url]
    haml :display
  end
end