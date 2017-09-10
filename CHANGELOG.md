# Change Log

## [Unreleased](https://github.com/tobmatth/rack-ssl-enforcer/tree/HEAD)

[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.2.9...HEAD)

**Closed issues:**

- HSTS Implementation [\#92](https://github.com/tobmatth/rack-ssl-enforcer/issues/92)
- Does not set session cookie as secure [\#91](https://github.com/tobmatth/rack-ssl-enforcer/issues/91)
- HSTS and secure cookies w/o redirect? [\#89](https://github.com/tobmatth/rack-ssl-enforcer/issues/89)
- ERR\_CONNECTION\_REFUSED [\#85](https://github.com/tobmatth/rack-ssl-enforcer/issues/85)
- Issue with IE only... strict true not working [\#80](https://github.com/tobmatth/rack-ssl-enforcer/issues/80)

**Merged pull requests:**

- README: Typo [\#100](https://github.com/tobmatth/rack-ssl-enforcer/pull/100) ([olleolleolle](https://github.com/olleolleolle))
- Travis: jruby-9.1.13.0 [\#99](https://github.com/tobmatth/rack-ssl-enforcer/pull/99) ([olleolleolle](https://github.com/olleolleolle))
- Travis: Use jruby-9.1.10.0 in CI matrix [\#97](https://github.com/tobmatth/rack-ssl-enforcer/pull/97) ([olleolleolle](https://github.com/olleolleolle))
- update instructions for configuring nginx behind ELB, add for sinatra [\#96](https://github.com/tobmatth/rack-ssl-enforcer/pull/96) ([bmishkin](https://github.com/bmishkin))
- Travis: use JRuby 9.1.7.0 [\#94](https://github.com/tobmatth/rack-ssl-enforcer/pull/94) ([olleolleolle](https://github.com/olleolleolle))
- README: Use shiny SVG badge [\#93](https://github.com/tobmatth/rack-ssl-enforcer/pull/93) ([olleolleolle](https://github.com/olleolleolle))
- Specify to insert SslEnforcer before the Cookies middleware in Rails [\#90](https://github.com/tobmatth/rack-ssl-enforcer/pull/90) ([DimaSamodurov](https://github.com/DimaSamodurov))
- Add example for HSTS preload option on README [\#87](https://github.com/tobmatth/rack-ssl-enforcer/pull/87) ([camelmasa](https://github.com/camelmasa))
- Adding MIT license to the gemspec. [\#86](https://github.com/tobmatth/rack-ssl-enforcer/pull/86) ([reiz](https://github.com/reiz))

## [v0.2.9](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.2.9) (2015-07-22)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.2.8...v0.2.9)

**Closed issues:**

- Infinite redirects behind AWS ELB [\#82](https://github.com/tobmatth/rack-ssl-enforcer/issues/82)
- Issue with Redirects [\#81](https://github.com/tobmatth/rack-ssl-enforcer/issues/81)
- POST requests [\#79](https://github.com/tobmatth/rack-ssl-enforcer/issues/79)
- How to handle URI::InvalidURIError? [\#78](https://github.com/tobmatth/rack-ssl-enforcer/issues/78)
- Cookie session state shared across http and https without disabling force\_secure\_cookies [\#58](https://github.com/tobmatth/rack-ssl-enforcer/issues/58)
- :strict option + AJAX requests [\#36](https://github.com/tobmatth/rack-ssl-enforcer/issues/36)

**Merged pull requests:**

- Add HSTS preload option [\#84](https://github.com/tobmatth/rack-ssl-enforcer/pull/84) ([gorism](https://github.com/gorism))
- added Nginx behind Load Balancer section to readme [\#83](https://github.com/tobmatth/rack-ssl-enforcer/pull/83) ([gnitnuj](https://github.com/gnitnuj))
- respect rack.url\_scheme header for proxied SSL when HTTP\_X\_FORWARDED\_PROTO blank [\#77](https://github.com/tobmatth/rack-ssl-enforcer/pull/77) ([grantspeelman](https://github.com/grantspeelman))

## [v0.2.8](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.2.8) (2014-07-18)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.2.7...v0.2.8)

**Closed issues:**

- Already encoded url parameters get encoded again when redirecting [\#75](https://github.com/tobmatth/rack-ssl-enforcer/issues/75)
- Release new version! \<3 [\#73](https://github.com/tobmatth/rack-ssl-enforcer/issues/73)

**Merged pull requests:**

- Do not encode already encoded url parameters when redirecting. [\#76](https://github.com/tobmatth/rack-ssl-enforcer/pull/76) ([oveddan](https://github.com/oveddan))
- Enable ignore blocks [\#74](https://github.com/tobmatth/rack-ssl-enforcer/pull/74) ([danielevans](https://github.com/danielevans))

## [v0.2.7](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.2.7) (2014-05-23)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.2.6...v0.2.7)

**Fixed bugs:**

- Vertical pipe characters in the URL cause an URI::InvalidURIError [\#47](https://github.com/tobmatth/rack-ssl-enforcer/issues/47)

**Closed issues:**

- Support for ruby 2.0 and Rails 4 [\#72](https://github.com/tobmatth/rack-ssl-enforcer/issues/72)
- Running code before redirect not working [\#70](https://github.com/tobmatth/rack-ssl-enforcer/issues/70)
- combine strict and non strict behaviour [\#69](https://github.com/tobmatth/rack-ssl-enforcer/issues/69)
- Is there a way to combine mutiple only, multiple ignore with strict [\#68](https://github.com/tobmatth/rack-ssl-enforcer/issues/68)
- Enforcing won't preserve HTTP methods [\#65](https://github.com/tobmatth/rack-ssl-enforcer/issues/65)
- Rack::SslEnforcer options mess up with 'localhost' [\#64](https://github.com/tobmatth/rack-ssl-enforcer/issues/64)
- New rubygems release? [\#60](https://github.com/tobmatth/rack-ssl-enforcer/issues/60)

**Merged pull requests:**

- Fixing issue \#70 - Running code before redirect not working [\#71](https://github.com/tobmatth/rack-ssl-enforcer/pull/71) ([abhasg](https://github.com/abhasg))
- URI encode before passing to URI object to deal with pathological URIs [\#67](https://github.com/tobmatth/rack-ssl-enforcer/pull/67) ([tilthouse](https://github.com/tilthouse))
- Add Ruby 2.1.0 to .travis.yml [\#66](https://github.com/tobmatth/rack-ssl-enforcer/pull/66) ([salimane](https://github.com/salimane))
- Allow for custom, default, or no body when redirecting [\#61](https://github.com/tobmatth/rack-ssl-enforcer/pull/61) ([kcm](https://github.com/kcm))

## [v0.2.6](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.2.6) (2013-09-18)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.2.5...v0.2.6)

**Closed issues:**

- Allow proc to be called before forcing a redirect [\#56](https://github.com/tobmatth/rack-ssl-enforcer/issues/56)
- force internationalization [\#54](https://github.com/tobmatth/rack-ssl-enforcer/issues/54)
- Add environment constraints [\#51](https://github.com/tobmatth/rack-ssl-enforcer/issues/51)
- @scheme leak across requests [\#48](https://github.com/tobmatth/rack-ssl-enforcer/issues/48)
- Regex [\#46](https://github.com/tobmatth/rack-ssl-enforcer/issues/46)
- SSL :ignore ignored for routable addresses, but works for static addresses [\#43](https://github.com/tobmatth/rack-ssl-enforcer/issues/43)
- SSL-only, HTTP-only, and mixed [\#39](https://github.com/tobmatth/rack-ssl-enforcer/issues/39)
- :mixed doesn't allow insecure GET [\#21](https://github.com/tobmatth/rack-ssl-enforcer/issues/21)
- Secure cookie flag forced [\#20](https://github.com/tobmatth/rack-ssl-enforcer/issues/20)

**Merged pull requests:**

- Add user agent support [\#59](https://github.com/tobmatth/rack-ssl-enforcer/pull/59) ([carmstrong](https://github.com/carmstrong))
- allow proc to be called before redirecting fixes \#56 [\#57](https://github.com/tobmatth/rack-ssl-enforcer/pull/57) ([oveddan](https://github.com/oveddan))
- Add environment constraints [\#52](https://github.com/tobmatth/rack-ssl-enforcer/pull/52) ([wyattisimo](https://github.com/wyattisimo))
- fix bug that was setting arrays as keys in default\_options hash [\#50](https://github.com/tobmatth/rack-ssl-enforcer/pull/50) ([wyattisimo](https://github.com/wyattisimo))
- Add test for nested url ignores. [\#49](https://github.com/tobmatth/rack-ssl-enforcer/pull/49) ([ktusznio](https://github.com/ktusznio))
- Update README.md [\#45](https://github.com/tobmatth/rack-ssl-enforcer/pull/45) ([potomak](https://github.com/potomak))
- Option for HTTP status code for redirection [\#44](https://github.com/tobmatth/rack-ssl-enforcer/pull/44) ([ochko](https://github.com/ochko))

## [v0.2.5](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.2.5) (2012-11-14)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.2.4...v0.2.5)

**Closed issues:**

- SSL-only, HTTP-only, and mixed [\#38](https://github.com/tobmatth/rack-ssl-enforcer/issues/38)
- Working on Heroku? [\#35](https://github.com/tobmatth/rack-ssl-enforcer/issues/35)
- Redirect not working [\#34](https://github.com/tobmatth/rack-ssl-enforcer/issues/34)
- config.middleware.use Rack::SslEnforcer breaks ajax requests [\#31](https://github.com/tobmatth/rack-ssl-enforcer/issues/31)
- Apache 2 config? [\#30](https://github.com/tobmatth/rack-ssl-enforcer/issues/30)
- hsts =\> true doesn't work [\#28](https://github.com/tobmatth/rack-ssl-enforcer/issues/28)
- Proper Nginx Config [\#26](https://github.com/tobmatth/rack-ssl-enforcer/issues/26)
- strict and HSTS are incompatible [\#8](https://github.com/tobmatth/rack-ssl-enforcer/issues/8)

**Merged pull requests:**

- Added some more documentation for nginx - specifically re. passenger [\#42](https://github.com/tobmatth/rack-ssl-enforcer/pull/42) ([ktopping](https://github.com/ktopping))
- fix README typo [\#41](https://github.com/tobmatth/rack-ssl-enforcer/pull/41) ([juno](https://github.com/juno))
- Add sinatra/padrino installation instructions. [\#37](https://github.com/tobmatth/rack-ssl-enforcer/pull/37) ([danpal](https://github.com/danpal))
- Huge cleaning and refactoring [\#33](https://github.com/tobmatth/rack-ssl-enforcer/pull/33) ([rymai](https://github.com/rymai))
- Rewrite of enforce\_ssl? and implementation of new options only\_methods and except\_methods. [\#32](https://github.com/tobmatth/rack-ssl-enforcer/pull/32) ([volontarian](https://github.com/volontarian))
- Added documentation on nginx/proxy setups [\#29](https://github.com/tobmatth/rack-ssl-enforcer/pull/29) ([ariejan](https://github.com/ariejan))

## [v0.2.4](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.2.4) (2011-09-05)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.2.3...v0.2.4)

## [v0.2.3](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.2.3) (2011-08-03)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.2.2...v0.2.3)

**Merged pull requests:**

- Update spex [\#27](https://github.com/tobmatth/rack-ssl-enforcer/pull/27) ([hassox](https://github.com/hassox))
- Removing warning [\#25](https://github.com/tobmatth/rack-ssl-enforcer/pull/25) ([honkster](https://github.com/honkster))
- Fix Rails 2.3.x projects for \(for real this time\) [\#24](https://github.com/tobmatth/rack-ssl-enforcer/pull/24) ([natacado](https://github.com/natacado))
- Custom ports, support for Rails 2.3/Rack 1.1 [\#23](https://github.com/tobmatth/rack-ssl-enforcer/pull/23) ([natacado](https://github.com/natacado))
- Make secure cookie flag optional [\#22](https://github.com/tobmatth/rack-ssl-enforcer/pull/22) ([mig-hub](https://github.com/mig-hub))

## [v0.2.2](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.2.2) (2011-03-13)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.2.1...v0.2.2)

## [v0.2.1](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.2.1) (2011-02-15)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.2.0...v0.2.1)

## [v0.2.0](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.2.0) (2010-11-17)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.1.9...v0.2.0)

## [v0.1.9](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.1.9) (2010-11-17)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.1.8...v0.1.9)

## [v0.1.8](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.1.8) (2010-09-10)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.1.6...v0.1.8)

## [v0.1.6](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.1.6) (2010-09-01)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.1.5...v0.1.6)

## [v0.1.5](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.1.5) (2010-08-31)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.1.4...v0.1.5)

## [v0.1.4](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.1.4) (2010-08-30)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.1.3...v0.1.4)

## [v0.1.3](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.1.3) (2010-08-12)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.1.1...v0.1.3)

## [v0.1.1](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.1.1) (2010-03-18)
[Full Changelog](https://github.com/tobmatth/rack-ssl-enforcer/compare/v0.1.0...v0.1.1)

## [v0.1.0](https://github.com/tobmatth/rack-ssl-enforcer/tree/v0.1.0) (2010-03-17)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*