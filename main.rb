require 'rubygems'
require 'rack'
require 'app'

builder = Rack::Builder.new do
  use Rack::CommonLogger
  
  run Rack::URLMap.new({
    '/'     => App.method(:index),
    '/auth' => App.method(:auth),
    '/api'  => App.method(:api)
  })
  
end

Rack::Handler::Mongrel.run builder, :Port => 9292