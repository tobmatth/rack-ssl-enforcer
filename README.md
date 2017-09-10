# Rack::SslEnforcer [![Build Status](https://travis-ci.org/tobmatth/rack-ssl-enforcer.svg?branch=master)](https://travis-ci.org/tobmatth/rack-ssl-enforcer)

Rack::SslEnforcer is a simple Rack middleware to enforce SSL connections. As of Version 0.2.0, Rack::SslEnforcer marks
Cookies as secure by default (HSTS must be set manually).

Tested against Ruby 1.8.7, 1.9.2, 1.9.3, 2.0.0, 2.1.10, 2.2.7, 2.3.4, 2.4.1, ruby-head, REE and the latest versions of Rubinius & JRuby.

## Installation

The simplest way to install Rack::SslEnforcer is to use [Bundler](http://gembundler.com).

Add Rack::SslEnforcer to your `Gemfile`:

```ruby
 gem 'rack-ssl-enforcer'
```

### Installing on Sinatra / Padrino application

In order for Rack::SslEnforcer to properly work it has to be at the top
of the Rack Middleware.

Using `enable :session` will place Rack::Session::Cookie before Rack::Ssl::Enforcer
and will prevent Rack::Ssl::Enforcer from marking cookies as secure.

To fix this issue do not use `enable :sessions` instead add the
Rack::Session::Cookie middleware after Rack::Ssl::Enforcer.

Eg:

```ruby
use Rack::SslEnforcer
set :session_secret, 'asdfa2342923422f1adc05c837fa234230e3594b93824b00e930ab0fb94b'

#Enable sinatra sessions
use Rack::Session::Cookie, :key => '_rack_session',
                           :path => '/',
                           :expire_after => 2592000, # In seconds
                           :secret => settings.session_secret
```

## Basic Usage

If you don't use Bundler, be sure to require Rack::SslEnforcer manually before actually using the middleware:

```ruby
 require 'rack/ssl-enforcer'
 use Rack::SslEnforcer
```

To use Rack::SslEnforcer in your Rails application, add the following line to your application config file (`config/application.rb` for Rails 3 and above, `config/environment.rb` for Rails 2):

```ruby
config.middleware.insert_before  ActionDispatch::Cookies, Rack::SslEnforcer
```
Cookies should be set before the SslEnforcer processes the headers,
but due to the middleware calls chain Rack::SslEnforcer should be inserted before the ActionDispatch::Cookies.

If all you want is SSL for your whole application, you are done! Otherwise, you can specify some options described below.

## Options

### Host constraints

You can enforce SSL connections only for certain hosts with `:only_hosts`, or prevent certain hosts from being forced to SSL with `:except_hosts`. Constraints can be a `String`, a `Regex` or an array of `String` or `Regex` (possibly mixed), as shown in the following examples:

```ruby
config.middleware.use Rack::SslEnforcer, :only_hosts => 'api.example.com'
# Please note that, for instance, both http://help.example.com/demo and https://help.example.com/demo would be accessible here

config.middleware.use Rack::SslEnforcer, :except_hosts => /[help|blog]\.example\.com$/

config.middleware.use Rack::SslEnforcer, :only_hosts => [/[secure|admin]\.example\.org$/, 'api.example.com']
```

### Path constraints

You can enforce SSL connections only for certain paths with `:only`, prevent certain paths from being forced to SSL with `:except`, or - if you don't care how certain paths are accessed - ignore them with `:ignore`. Constraints can be a `String`, a `Regex` or an array of `String` or `Regex` (possibly mixed), as shown in the following examples:

```ruby
config.middleware.use Rack::SslEnforcer, :only => '/login'
# Please note that, for instance, both http://example.com/demo and https://example.com/demo would be accessible here

config.middleware.use Rack::SslEnforcer, :only => %r{^/admin/}

config.middleware.use Rack::SslEnforcer, :except => ['/demo', %r{^/public/}]

config.middleware.use Rack::SslEnforcer, :ignore => '/assets'

# You can also combine multiple constraints
config.middleware.use Rack::SslEnforcer, :only => '/cart', :ignore => %r{/assets}, :strict => true

# And ignore based on blocks
config.middleware.use Rack::SslEnforcer, :ignore => lambda { |request| request.env["HTTP_X_IGNORE_SSL_ENFORCEMENT"] == "magic" }
```

### Method constraints

You can enforce SSL connections only for certain HTTP methods with `:only_methods`, or prevent certain HTTP methods from being forced to SSL with `:except_methods`. Constraints can be a `String` or an array of `String`, as shown in the following examples:

```ruby
# constraint as a String
config.middleware.use Rack::SslEnforcer, :only_methods => 'POST'
# Please note that, for instance, GET requests would be accessible via SSL and non-SSL connection here

config.middleware.use Rack::SslEnforcer, :except_methods => ['GET', 'HEAD']
```

Note: The `:hosts` constraint takes precedence over the `:path` constraint. Please see the tests for examples.


### Environment constraints

You can enforce SSL connections only for certain environments with `:only_environments` or prevent certain environments from being forced to SSL with `:except_environments`.
Environment constraints may be a `String`, a `Regex` or an array of `String` or `Regex` (possibly mixed), as shown in the following examples:

```ruby
config.middleware.use Rack::SslEnforcer, :except_environments => 'development'

config.middleware.use Rack::SslEnforcer, :except_environments => /^[0-9a-f]+_local$/i

config.middleware.use Rack::SslEnforcer, :only_environments => ['production', /^QA/]
```

Note: The `:environments` constraint requires one the following environment variables to be set: `RACK_ENV`, `RAILS_ENV`, `ENV`.

### User agent constraints

You can enforce SSL connections only for certain user agents with `:only_agents` or prevent certain user agents from being forced to SSL with `:except_agents`.
User agent constraints may be a `String`, a `Regex` or an array of `String` or `Regex` (possibly mixed), as shown in the following examples:

```ruby
config.middleware.use Rack::SslEnforcer, :except_agents => 'Googlebot'

config.middleware.use Rack::SslEnforcer, :except_agents => /[Googlebot|bingbot]/

config.middleware.use Rack::SslEnforcer, :only_agents => ['test-secu-bot', /custom-crawler[0-9a-f]/]
```

### Force-redirection to non-SSL connection if constraint is not matched

Use the `:strict` option to force non-SSL connection for all requests not matching the constraints you set. Examples:

```ruby
config.middleware.use Rack::SslEnforcer, :only => ["/login", /\.xml$/], :strict => true
# https://example.com/demo would be redirected to http://example.com/demo

config.middleware.use Rack::SslEnforcer, :except_hosts => 'demo.example.com', :strict => true
# https://demo.example.com would be redirected to http://demo.example.com
```

### Automatic method constraints

In the case where you have matching URLs with different HTTP methods – for instance Rails RESTful routes: `GET /users`, `POST /users`, `GET /user/:id` and `PUT /user/:id` – you may need to force POST and PUT requests to SSL connection but redirect to non-SSL connection on GET.

```ruby
config.middleware.use Rack::SslEnforcer, :only => [%r{^/users/}], :mixed => true
```

The above will allow you to POST/PUT from the secure/non-secure URLs keeping the original schema.

### HTTP Strict Transport Security (HSTS)

To set HSTS expiry and subdomain inclusion (defaults respectively to `one year` and `true`).

```ruby
config.middleware.use Rack::SslEnforcer, :hsts => { :expires => 500, :subdomains => false, :preload => false }
config.middleware.use Rack::SslEnforcer, :hsts => true # equivalent to { :expires => 31536000, :subdomains => true, :preload => false }
```
Please note that the strict option disables HSTS.

### Redirect to specific URL (e.g. if you're using a proxy)

You might need the `:redirect_to` option if the requested URL can't be determined.

```ruby
config.middleware.use Rack::SslEnforcer, :redirect_to => 'https://example.org'
```

### Redirect with specific HTTP status code

By default it redirects with HTTP status code 301(Moved Permanently). Sometimes you might need to redirect with different HTTP status code:

```ruby
config.middleware.use Rack::SslEnforcer, :redirect_code => 302
```

### Custom HTTP port

If you're using a different port than the default (80) for HTTP, you can specify it with the `:http_port` option:

```ruby
config.middleware.use Rack::SslEnforcer, :http_port => 8080
```

### Custom HTTPS port

If you're using a different port than the default (443) for HTTPS, you can specify it with the `:https_port` option:

```ruby
config.middleware.use Rack::SslEnforcer, :https_port => 444
```

### Secure cookies disabling

Finally you might want to share a cookie based session between HTTP and HTTPS.
This is not possible by default with Rack::SslEnforcer for [security reasons](http://en.wikipedia.org/wiki/HTTP_cookie#Cookie_theft_and_session_hijacking).

Nevertheless, you can set the `:force_secure_cookies` option to `false` in order to be able to share a cookie based session between HTTP and HTTPS:

```ruby
config.middleware.use Rack::SslEnforcer, :only => "/login", :force_secure_cookies => false
```

But be aware that if you do so, you have to make sure that the content of you cookie is encoded.
This can be done using a coder with [Rack::Session::Cookie](https://github.com/rack/rack/blob/master/lib/rack/session/cookie.rb#L28-42).

### Running code before redirect

You may want to run some code before rack-ssl-enforcer forces a redirect.  This code could do something like log that a redirect was done, or if this is used in a Rails app, keeping the flash when redirecting:


```ruby
config.middleware.use Rack::SslEnforcer, :only => '/login', :before_redirect => Proc.new { |request|
  #keep flash on redirect
  request.session[:flash].keep if !request.session.nil? && request.session.key?('flash') && !request.session['flash'].empty?
}
```

### Custom or empty response body

The default response body is:

```html
<html><body>You are being <a href="https://www.example.org/">redirected</a>.</body></html>
```

To supply a custom message, provide a string as `:redirect_html`:

```ruby
config.middleware.use Rack::SslEnforcer, :redirect_html => 'Redirecting!'
```

To supply a series of responses for Rack to chunk, provide a [permissable Rack body object](http://rack.rubyforge.org/doc/SPEC.html):

```ruby
config.middleware.use Rack::SslEnforcer, :redirect_html => ['<html>','<body>','Hello!','</body>','</html>']
```

To supply an empty response body, provide :redirect_html as false:

```ruby
config.middleware.use Rack::SslEnforcer, :redirect_html => false
```

## Deployment

If you run your application behind a proxy (e.g. Nginx) you may need to do some configuration on that side. If you don't you may experience an infinite redirect loop.

The reason this happens is that Rack::SslEnforcer can't detect if you are running SSL or not. The solution is to have your front-end server send extra headers for Rack::SslEnforcer to identify the request protocol.

### Nginx

In the `location` block for your app's SSL configuration, include the following proxy header configuration:

`proxy_set_header   X-Forwarded-Proto https;`

### Nginx behind Load Balancer

The following instruction has been tested behind AWS ELB, but can be adapted to work behind any load balancer.
Specifically, the options below account for termination of SSL at the load balancer (HTTP only communication between load balancer and server), and HTTP only health checks.

In the `location` block for your app's SSL configuration, reference the following proxy header configurations:

```
proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
proxy_set_header Host $http_host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for
proxy_redirect off;
```

In `config/application.rb` for Rails 3 and above, `config/environment.rb` for Rails 2, work off the following line:

```ruby
config.middleware.use Rack::SslEnforcer, ignore: lambda { |request| request.env["HTTP_X_FORWARDED_PROTO"].blank? }, strict: true
```

This ignores ELB healthchecks and development environment as ELB healthchecks aren't forwarded requests, so it wouldn't have the forwarded proto header.

Same goes for when running without a proxy (like developemnt locally), making `:except_environments => 'development'` unnecessary.

In Sinatra or other non-rails ruby applications, work off the following line:
```ruby
use Rack::SslEnforcer, :except_environments => ['development', 'test'], :ignore => '/healthcheck'
```

### Passenger

Or, if you're using mod_rails/passenger (which will ignore the proxy_xxx directives):

`passenger_set_cgi_param HTTP_X_FORWARDED_PROTO https;`

If you're sharing a single `server` block for http AND https access you can add:

`passenger_set_cgi_param HTTP_X_FORWARDED_PROTO $scheme;`

This makes sure that Rack::SslEnforcer knows it's being accessed over SSL. Just restart Nginx for these changes to take effect.

## TODO

* Cleanup tests

#### Contributors

[https://github.com/tobmatth/rack-ssl-enforcer/graphs/contributors](https://github.com/tobmatth/rack-ssl-enforcer/graphs/contributors)

## Credits

Flagging cookies as secure functionality and HSTS support is greatly inspired by [Joshua Peek's Rack::SSL](https://github.com/josh/rack-ssl).

## Note on Patches / Pull Requests

* Fork the project.
* Code your feature addition or bug fix.
* **Add tests for it.** This is important so we don't break it in a future version unintentionally.
* Commit, do not mess with Rakefile or version number. If you want to have your own version, that's fine but bump version in a commit by itself so we can ignore it when merging.
* Send a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010-2013 Tobias Matthies. See [LICENSE](https://github.com/tobmatth/rack-ssl-enforcer/blob/master/LICENSE) for details.
