require 'app'

use Rack::CommonLogger

run Rack::URLMap.new({
  '/'     => App.method(:index),
  '/auth' => App.method(:auth),
  '/api'  => App.method(:api)
})


