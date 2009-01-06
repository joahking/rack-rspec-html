require 'rubygems'
require 'rack/request'
require 'rack/response'

module Rack
  class RSpecHTML
    def call(env)
      @req = Request.new(env)
      root = Dir.getwd
      path = @req.env['PATH_INFO']
      if path =~ /_spec.rb$/
        # clicking on an .rb runs it through spec
        result = `spec #{clean_path(path)} -f h`
        #TODO show console stderr
        result = 'sorry, there was a problem!' if result.empty?
      elsif path =~ /.feature$/
        # clicking on an .feature runs it through cucumber
        result = `cucumber #{clean_path(path)} -f html`
        #TODO show console stderr
        result = 'sorry, there was a problem!' if result.empty?
      else
        # or we show the contents
        result = "contents of directory<br/>"
        directory_path = "#{root}/#{clean_path(path)}"
        Dir.entries(directory_path).sort.each do |file|
          result << "<a href='#{path_in_dir(file)}'>#{file}</a><br/>"
        end
      end
      # and rendering
      res = Response.new
      res.write HELP
      res.write "path = #{path}<br/>"
      res.write result
      res.finish
    end

    HELP = <<-HELP
      <title>specs on #{Dir.getwd}</title>
      <ul>clicking on<li>directory: browses in</li>
                     <li>spec file: runs `spec SPEC_FILE -f h`</li>
                     <li>feature file: runs `cucumber FEATURE_FILE -f html`</li>
      </ul><br/>
    HELP

private
    # we need to remove starting slash
    def clean_path(path)
      path.sub(/^\//,'')
    end
    #relative path inside a directory
    def path_in_dir(file)
      "#{@req.env['PATH_INFO']}/#{file}".gsub('//', '/')
    end
  end
end

if $0 == __FILE__
  require 'rack'
  require 'rack/showexceptions'
  # Rack::Handler::Mongrel but then I loose console stdout
  Rack::Handler::WEBrick.run \
    Rack::ShowExceptions.new(Rack::Lint.new(Rack::RSpecHTML.new)),
    :Port => 9292
end
