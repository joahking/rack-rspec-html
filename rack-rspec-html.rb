# this is original gist: http://gist.github.com/43149

# Rack RSpec HTML is a simple Rack application to browse your spec directory
# and run *_spec.rb files living there.

# I only use it for rails, but should not be difficult to extend

# INSTALL: copy rack_rspec_html.rb into your #{RAILS_ROOT}/spec directory
# START: ruby -Ilib spec/rack_rspec_html.rb
# visit http://localhost:9292 to see your specs

require 'rubygems'
require 'rack/request'
require 'rack/response'

module Rack
  class RSpecHTML
    def call(env)
      req = Request.new(env)
      root = Dir.getwd
      path = req.env['PATH_INFO']
      if path =~ /.rb$/
        # clicking on an .rb runs it through spec
        spec_file = "spec/#{path}".gsub('//', '/')
        result = `spec #{spec_file} -f h`
        #TODO show console stderr
        result = 'sorry, there was a problem!' if result.empty?
      else
        # or we show the contents
        result = "contents of directory<br/>"
        Dir.entries("spec/#{path}").sort.each do |file|
          file_path = "#{path}/#{file}".gsub('//', '/')
          result << "<a href='#{file_path}'>#{file}</a><br/>"
        end
      end

      res = Response.new
      res.write "<title>specs on #{root}</title>"
      res.write "<ul>clicking on<li>directory: browses in</li>
<li>spec file: runs `spec SPEC_FILE -f h`</li></ul><br/>"
      res.write "path = #{path}<br/>"
      res.write result
      res.finish
    end

  end
end

if $0 == __FILE__
  require 'rack'
  require 'rack/showexceptions'
  Rack::Handler::WEBrick.run \
    Rack::ShowExceptions.new(Rack::Lint.new(Rack::RSpecHTML.new)),
    :Port => 9292
end
