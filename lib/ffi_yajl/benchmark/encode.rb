require 'rubygems'
require 'benchmark'
require 'yajl'
require 'stringio'
require 'ffi_yajl'
begin
  require 'json'
rescue LoadError
end
begin
  require 'psych'
rescue LoadError
end
begin
  require 'active_support'
rescue LoadError
end

class FFI_Yajl::Benchmark::Encode

  def run
    filename = ARGV[0] || 'benchmark/subjects/ohai.json'
    hash = File.open(filename, 'rb') { |f| Yajl::Parser.new.parse(f.read) }

    times = ARGV[1] ? ARGV[1].to_i : 1000
    puts "Starting benchmark encoding #{filename} #{times} times\n\n"
    Benchmark.bmbm { |x|
      io_encoder = Yajl::Encoder.new
      string_encoder = Yajl::Encoder.new

      x.report("FFI_Yajl::Encoder.encode (to a String)") {
        times.times {
          output = FFI_Yajl::Encoder.encode(hash)
        }
      }

      x.report("Yajl::Encoder.encode (to a String)") {
        times.times {
          output = Yajl::Encoder.encode(hash)
        }
      }

      x.report("Yajl::Encoder#encode (to an IO)") {
        times.times {
          io_encoder.encode(hash, StringIO.new)
        }
      }
      x.report("Yajl::Encoder#encode (to a String)") {
        times.times {
          output = string_encoder.encode(hash)
        }
      }
      if defined?(JSON)
        x.report("JSON.generate") {
          times.times {
            JSON.generate(hash)
          }
        }
      end
      if defined?(Psych)
        x.report("Psych.to_json") {
          times.times {
            Psych.to_json(hash)
          }
        }
        if defined?(Psych::JSON::Stream)
          x.report("Psych::JSON::Stream") {
            times.times {
              io = StringIO.new
              stream = Psych::JSON::Stream.new io
              stream.start
              stream.push hash
              stream.finish
            }
          }
        end
      end
      if defined?(ActiveSupport::JSON)
        x.report("ActiveSupport::JSON.encode") {
          times.times {
            ActiveSupport::JSON.encode(hash)
          }
        }
      end
    }
  end

end
