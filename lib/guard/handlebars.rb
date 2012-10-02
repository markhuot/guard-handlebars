require 'guard'
require 'guard/guard'
require 'guard/watcher'

module Guard
  class Handlebars < Guard
    
    def initialize(watchers = [], options = {})
      watchers = [] if !watchers
      watchers << ::Guard::Watcher.new(%r{#{ options[:input] }/(.+\.handlebars)}) if options[:input]

      options[:output] ||= options[:input]

      flags = []
      flags << 'm' if options[:min]
      flags << 's' if options[:simple]
      flags << 'r' if options[:root]
      flags << 'o' if options[:knownOnly]
      flags << 'k' if options[:known]
      options[:flags] = flags.size > 0 ? "-#{flags.join()}" : ''

      super(watchers, {
        :notifications => true
      }.merge(options))
    end
    
    def run_all
      run_on_change(Watcher.match_files(self, Dir.glob(File.join('**', '*.*'))))
    end
  
    def run_on_change(paths)
      begin
        if @options[:compile]
          if File.exists? options[:input]
            com = "handlebars #{@options[:input]} #{@options[:flags]} -f #{@options[:output]}"
            result = `#{com}`
          end
        else
          paths.each do |file|
            output_file = nil
            time = Benchmark.realtime do
              output_file = compile file
            end
            benchmark = "[\e[33m%2.2fs\e[0m] " % time
            ::Guard::UI.info("\t\e[1;37mHandlebars\e[0m %s%s" % [benchmark, "#{File.basename(file)} -> #{File.basename(output_file)}"], {})
          end
        end
      rescue StandardError => error
        puts "ERROR COMPILING #{error}"
      end

      ::Guard::Notifier.notify("Compiled handlebars for #{paths.join(', ')}", :title => "Handlebars", :image => :success) if @options[:notifications]
    end

    def compile(file)
      output = output_path file
      FileUtils.mkdir_p File.dirname(output)

      content = File.new(file).read
      begin
        com = "handlebars #{file}"
        result = `#{com}`
      rescue StandardError => error
        puts "Error in #{File.basename(file)}"
      end

      File.open(output, 'w') { |f| f.write(result) }

      output
    end

    def output_path(file)
      file = @options[:input] ? file.sub(%r(^#{@options[:input]}/?), '') : file
      @options[:output] + '/' + file.sub(%r(\.handlebars$), '.js')
    end
    
  end
end
