# Rack::SslEnforcer [![Build Status](https://secure.travis-ci.org/tobmatth/rack-ssl-enforcer.png?branch=master)](http://travis-ci.org/tobmatth/rack-ssl-enforcer)

Rack::SslEnforcer is a simple Rack middleware to enforce SSL connections. As of Version 0.2.0, Rack::SslEnforcer marks
Cookies as secure by default (HSTS must be set manually).

Tested against Ruby 1.8.7, 1.9.2, 1.9.3, ruby-head, REE and the latest versions of Rubinius & JRuby.

## Installation

The simplest way to install Rack::SslEnforcer is to use [Bundler](http://gembundler.com/).

Add Rack::SslEnforcer to your `Gemfile`:

```ruby
 gem 'rack-ssl-enforcer'
```

## Basic Usage

If you don't use Bundler, be sure to require Rack::SslEnforcer manually before actually using the middleware:

```ruby
 require 'rack/ssl-enforcer'
 use Rack::SslEnforcer
```

To use Rack::SslEnforcer in your Rails application, add the following line to your application config file (`config/application.rb` for Rails 3, `config/environment.rb` for Rails 2):

```ruby
config.middleware.use Rack::SslEnforcer
```

If all you want is SSL for your whole application, you are done! Otherwise, you can specify some options described below.

## Options

### Host contraints

You can enforce SSL connections only for certain hosts with `:only_hosts`, or prevent certain hosts from being forced to SSL with `:except_hosts`. Constraints can be a `String`, a `Regex` or an array of `String` or `Regex` (possibly mixed), as shown in the following examples:

```ruby
config.middleware.use Rack::SslEnforcer, :only_hosts => 'api.example.com'
# Please note that, for instance, both http://help.example.com/demo and https://help.example.com/demo would be accessible here

config.middleware.use Rack::SslEnforcer, :except_hosts => /[help|blog]\.example\.com$/

config.middleware.use Rack::SslEnforcer, :only_hosts => [/[secure|admin]\.example\.org$/, 'api.example.com']
```

### Path contraints

You can enforce SSL connections only for certain paths with `:only`, or prevent certain paths from being forced to SSL with `:except`. Constraints can be a `String`, a `Regex` or an array of `String` or `Regex` (possibly mixed), as shown in the following examples:

```ruby
config.middleware.use Rack::SslEnforcer, :only => '/login'
# Please note that, for instance, both http://example.com/demo and https://example.com/demo would be accessible here

config.middleware.use Rack::SslEnforcer, :only => %r{^/admin/}

config.middleware.use Rack::SslEnforcer, :except => ['/demo', %r{^/public/}]
```

### Method contraints

You can enforce SSL connections only for certain HTTP methods with `:only_methods`, or prevent certain HTTP methods from being forced to SSL with `:except_methods`. Constraints can be a `String` or an array of `String`, as shown in the following examples:

```ruby
# constraint as a String
config.middleware.use Rack::SslEnforcer, :only_methods => 'POST'
# Please note that, for instance, GET requests would be accessible via SSL and non-SSL connection here

config.middleware.use Rack::SslEnforcer, :except_methods => ['GET', 'HEAD']
```

Note: The `:hosts` constraint takes precedence over the `:path` constraint. Please see the tests for examples.

### Force-redirection to non-SSL connection if constraint is not matched

Use the `:strict` option to force non-SSL connection for all requests not matching the constraints you set. Examples:

```ruby
config.middleware.use Rack::SslEnforcer, :only => ["/login", /\.xml$/], :strict => true
# https://example.com/demo would be redirected to http://example.com/demo

config.middleware.use Rack::SslEnforcer, :except_hosts => 'demo.example.com', :strict => true
# https://demo.example.com would be redirected to http://demo.example.com
```

### Automatic method contraints

In the case where you have matching URLs with different HTTP methods – for instance Rails RESTful routes: `GET /users`, `POST /users`, `GET /user/:id` and `PUT /user/:id` – you may need to force POST and PUT requests to SSL connection but redirect to non-SSL connection on GET.

```ruby
config.middleware.use Rack::SslEnforcer, :only => [%r{^/users/}], :mixed => true
```

The above will allow you to POST/PUT from the secure/non-secure URLs keeping the original schema.

### HTTP Strict Transport Security (HSTS)

To set HSTS expiry and subdomain inclusion (defaults respectively to `one year` and `true`).

```ruby
config.middleware.use Rack::SslEnforcer, :hsts => { :expires => 500, :subdomains => false }
config.middleware.use Rack::SslEnforcer, :hsts => true # equivalent to { :expires => 31536000, :subdomains => true }
```
Please note that the strict option disables HSTS.

### Redirect to specific URL (e.g. if you're using a proxy)

You might need the `:redirect_to` option if the requested URL can't be determined.

```ruby
config.middleware.use Rack::SslEnforcer, :redirect_to => 'https://example.org'
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

## Deployment

If you run your application behind a proxy (e.g. Nginx) you may need to do some configuration on that side. If you don't you may experience an infinite redirect loop.

The reason this happens is that Rack::SslEnforcer can't detect if you are running SSL or not. The solution is to have your front-end server send extra headers for Rack::SslEnforcer to identify the request protocol.

### Nginx

In the `location` block for your app's SSL configuration, include the following proxy header configuration:

`proxy_set_header   X-Forwarded-Proto https;`

This makes sure that Rack::SslEnforcer knows it's being accessed over SSL. Just restart Nginx for these changes to take effect.

## TODO

* Cleanup tests

## Contributors

* [Dan Mayer](http://github.com/danmayer)
* [Rémy Coutable](http://github.com/rymai)
* [Thibaud Guillaume-Gentil](http://github.com/thibaudgg)
* [Paul Annesley](https://github.com/pda)
* [Saimon Moore](https://github.com/saimonmoore)

## Credits

Flagging cookies as secure functionality and HSTS support is greatly inspired by [Joshua Peek's Rack::SSL](https://github.com/josh/rack-ssl).

## Note on Patches / Pull Requests

* Fork the project.
* Code your feature addition or bug fix.
* **Add tests for it.** This is important so we don't break it in a future version unintentionally.
* Commit, do not mess with Rakefile or version number. If you want to have your own version, that's fine but bump version in a commit by itself so we can ignore it when merging.
* Send a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010-2012 Tobias Matthies. See LICENSE for details.
