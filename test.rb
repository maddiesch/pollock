require 'zlib'

input = File.expand_path(__dir__ + '/PollockTests/decompress-test.txt')

compressed = Zlib::Deflate.deflate(File.read(input), 5)

File.open(input + '.zlib', 'w') { |f| f.write(compressed) }

Zlib::Inflate.inflate(File.read(input + '.zlib'))
