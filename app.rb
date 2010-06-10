class App
  
  FB_HOST = 'https://graph.facebook.com'
  APP_ID = '146704267370'
  APP_SECRET = '7305580388d784ca83ce3661ddefeea6'
  @@auth_tok = ''
  
  def self.index(env)
    
    App::render_view('index', 
                     {'APPID' => App::APP_ID,
                      'AUTHTOK' => @@auth_tok })
  end
  
  def self.auth(env)
    
    query = env['QUERY_STRING']
    
    initiate = query.match('initiate')
    
    if initiate
      # do the redirect
      fb_endpoint = App::FB_HOST + "/oauth/authorize?" + 
                      "client_id=" + App::APP_ID +
                      "&redirect_uri=http://" + env['SERVER_NAME'] + '/auth'
                      
      [302, {"Location" => fb_endpoint}, '']
      
    else
      # should be receiving data
      App::render_view('api', {"ENV" => env.inspect})
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

  
  def self.render_view(name, values={})
    
    view_dir = "views"
    
    base = ''
    # Always wrap in base.html
    File.open("#{view_dir}/base.html", "r") do |f|
      base += f.read
    end
    
    view = ''
    File.open("#{view_dir}/#{name}.html") do |f|
      view += f.read
    end
    
    markup = base.gsub("!!YIELD!!", view)
    
    # Now sub the values
    values.each do |k, v|
      markup.gsub!("!!#{k}!!", v)
    end
    
    return [200, {"Content-Type" => "text/html"}, markup]
  
  end
end
