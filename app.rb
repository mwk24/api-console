class App
  
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'cgi'
  
  FB_DOMAIN = 'graph.facebook.com'
  FB_BASE = 'https://' + FB_DOMAIN
  FB_OLD_DOMAIN = 'api.facebook.com'
  APP_HOST = 'http://strong-sunrise-54.heroku.com'
  APP_ID = '146704267370'
  APP_SECRET = '7305580388d784ca83ce3661ddefeea6'
  @@access_tok = ''
  
  def self.index(env)

    App::render_view('index', 
                     {'APPID' => App::APP_ID,
                      'AUTHTOK' => @@access_tok},
                      env.inspect)
  end
  
  def self.auth(env)
    
    redirect_uri = env['rack.url_scheme'] + "://" + env['HTTP_HOST'] + '/auth'
    
    # no token yet
    if @@access_tok.empty?
      
      code = App::query_val(env, 'code')
      
      # we have a code already, fetch access token
      if App::query_val(env, 'code')
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
      
      # no code yet - need to redirect and get one
      else
        verify_endpoint = App::FB_BASE + "/oauth/authorize?" + 
                          "client_id=" + App::APP_ID +
                          "&redirect_uri=" + redirect_uri

        return [302, {"Content-Type" => "text/html", "Location" => verify_endpoint}, '']
      
      end
      
      # if we got here we should have a token, so redirect to api
      return [302, {"Content-Type" => "text/html", "Location" => '/api'}, '']
    end
  end
  
  def self.api(env)
    
    api_call = App::query_val(env, 'req')
    api_type = App::query_val(env, 'api_type')
    
    if api_call and api_type
    
      if api_type == 'fql'
        domain = App::FB_OLD_DOMAIN
        path = '/method/fql.query?query=' + api_call
      elsif api_type == 'graph'
        domain = App::FB_DOMAIN
        path = '/' + CGI.unescape(api_call)
      elsif api_type == 'old'
        domain = App::FB_OLD_DOMAIN
        path = '/method/' + api_call
      end
      
      if App::query_val(env, 'no_tok')
        full_path = path
        tok_info = '(no token)'
      else
        full_path = path + '&access_token=' + @@access_tok
      end
      
        
      http = Net::HTTP.new(domain, 443)
      http.use_ssl = true
      
      start = Time.now
      res, data = http.get(full_path)
      elapsed = Time.now - start
      
      req_url = domain + path
    end
    
    App::render_view('api', 
                     {'TOK' => @@access_tok, 'REQ' => api_call, 'RET' => data, 'URL' => req_url, 'ELAPSED' => elapsed.to_s, 'TYPE' => api_type, 'TOKEN_INFO' => tok_info })
    
  end
  
  def self.extract_val(serialized, key, default=nil)
    
    params = serialized.strip.split('&')   
    params.each do |p|
      split = p.split('=')
      if split[0] == key
        return split[1].strip rescue default
      end
    end
    return default
  end
  
  def self.query_val(env, key, default=nil)
    query = env['QUERY_STRING']
    return App::extract_val(query, key, default)
  end
  
  def self.render_view(name, values={}, dump='', cookie='')
    
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
      v ||= ''
      markup.gsub!("!!#{k}!!", CGI.unescape(v))
    end
    
    # dump area for general inspection
    markup += ('<br/><br/><br/>--------------<br/>' + dump)
    
    return [200, {"Content-Type" => "text/html", "Set-Cookie" => "#{cookie}\naccess_tok=#{@@access_tok}"}, markup]
  
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
  
end
