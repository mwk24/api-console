require 'app'
require 'hoptoad_notifier'


HoptoadNotifier.configure do |config|
  config.api_key = '9dfd2f5929da8ef3508c24e777926139'
end

use Rack::CommonLogger
use HoptoadNotifier::Rack

run Rack::URLMap.new({
  '/'     => App.method(:index),
  '/auth' => App.method(:auth),
  '/api'  => App.method(:api)
})


