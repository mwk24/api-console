class App
  
  require 'net/http'
  require 'net/https'
  require 'uri'
  
  FB_DOMAIN = 'graph.facebook.com'
  FB_BASE = 'https://' + FB_DOMAIN
  APP_HOST = 'http://strong-sunrise-54.heroku.com'
  APP_ID = '146704267370'
  APP_SECRET = '7305580388d784ca83ce3661ddefeea6'
  @@access_tok = ''
  
  def self.index(env)
    
    App::render_view('index', 
                     {'APPID' => App::APP_ID,
                      'AUTHTOK' => @@access_tok,
                      'ENV' => env.inspect })
  end
  
  def self.auth(env)
    
    redirect_uri = env['rack.url_scheme'] + "://" + env['HTTP_HOST'] + '/auth'
    
    if App::query_val(env, 'initiate') == '1'
      # do the redirect
      verify_endpoint = App::FB_BASE + "/oauth/authorize?" + 
                        "client_id=" + App::APP_ID +
                        "&redirect_uri=" + redirect_uri
                      
      [302, {"Content-Type" => "text/html", "Location" => verify_endpoint}, '']
      
    else
      # should be receiving data
      code = App::query_val(env, 'code')
      
      # now exchange for access token
      token_path = "/oauth/access_token?" +
                       "client_id=" + App::APP_ID +
                       "&redirect_uri=" + redirect_uri + 
                       "&client_secret=" + App::APP_SECRET +
                       "&code=" + code
      
      http = Net::HTTP.new(FB_DOMAIN, 443)
      http.use_ssl = true
      
      res, data = http.get(token_path)
      
      unless data.match('error')
        # store token
        @@access_tok = App::extract_val(data, 'access_token')
      end
      
      App::render_view('api', {"TOK" => @@access_tok }, data)
    end
  end
  
  def self.api(env)
    [200, {"Content-Type" => "text/html"}, "call"]
  end
  
  def self.db_val(key)
    
    f = File.new('db.txt','r')
    
    entries = f.readlines
    
    entries.each do |e|
      split = e.split(':')
      if split[0] == key
        return split[1].strip
      end
    end
    return ''
  end
  
  
  def self.extract_val(serialized, key)
    
    params = serialized.strip.split('&')   
    params.each do |p|
      split = p.split('=')
      if split[0] == key
        return split[1].strip
      end
    end
    return nil
  end
  
  def self.query_val(env, key)
  
    query = env['QUERY_STRING']
    return App::extract_val(query, key)
    
  end
  
  def self.render_view(name, values={}, dump='')
    
    view_dir = "views"
    
    base = ''
    # Always wrap in base.html
    File.open("#{view_dir}/base.html", "r") do |f|
      base = f.read
    end
    
    view = ''
    File.open("#{view_dir}/#{name}.html") do |f|
      view = f.read
    end
    
    markup = base.gsub("!!BODY!!", view)
    
    # Now sub the values
    values.each do |k, v|
      v ||= '[EMPTY]'
      markup.gsub!("!!#{k}!!", v)
    end
    
    # dump some stuff
    markup += dump
    
    return [200, {"Content-Type" => "text/html"}, markup]
  
  end
end
