require "../src/text-splitter"

# Example demonstrating iterator usage for memory-efficient text processing

text = File.read("../README.md")
splitter = Text::Splitter.new(chunk_size: 500, chunk_overlap: 100)

puts "=== Example 1: Using block (most efficient) ==="
splitter.each_chunk(text) do |chunk|
  puts "Chunk (#{chunk.size} chars): #{chunk[0..50]}..."
  # Process chunk immediately without storing all chunks in memory
end

puts "\n=== Example 2: Using iterator (lazy evaluation) ==="
# Only process first 3 chunks
splitter.each_chunk(text).first(3).each do |chunk|
  puts "Chunk: #{chunk[0..50]}..."
end

puts "\n=== Example 3: Iterator with transformations ==="
# Chain iterator operations
chunk_sizes = splitter.each_chunk(text)
  .map(&.size)
  .select { |size| size > 400 }
  .to_a

puts "Chunks larger than 400 chars: #{chunk_sizes.size}"
puts "Sizes: #{chunk_sizes.inspect}"

puts "\n=== Example 4: Traditional array (when you need all chunks) ==="
all_chunks = splitter.split_text(text)
puts "Total chunks: #{all_chunks.size}"
puts "Average size: #{all_chunks.sum(&.size) / all_chunks.size} chars"
