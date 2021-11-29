#!/usr/bin/env ruby

require 'tempfile'

def build(input, out)
  File.readlines(input).each do |line|
    if relative_path = line[/^require_relative\s+(["'])(\S+)\1$/, 2]
      path = File.expand_path(relative_path, File.dirname(input))
      path += ".rb"
      build(path, out)
      out.puts
    else
      out.print line
    end
  end
end

start = "src/main.rb"
output = "bin/check-codeowners"

Tempfile.open('build', File.dirname(output)) do |out|

  out.print <<~INTRO
    #!/usr/bin/env ruby

    # This is a generated file; for the source, see 'src'.
    # Build with "ruby ./script/build.rb"

  INTRO

  build(start, out)
  out.chmod 0o755
  out.flush
  File.rename out.path, output
end
