require "../src/text-splitter"

# Basic character-based splitting example
puts "=== Character-Based Splitting ==="
puts

text = <<-TEXT
This is the first sentence of our example document. This is the second sentence, which contains more information.
This is the third sentence, demonstrating how the splitter works. And finally, this is the fourth sentence to complete our example.
TEXT

splitter = Text::Splitter.new(
  chunk_size: 100,
  chunk_overlap: 20
)

chunks = splitter.split_text(text)

puts "Original text length: #{text.size} characters"
puts "Number of chunks: #{chunks.size}"
puts

chunks.each_with_index do |chunk, i|
  puts "Chunk #{i + 1} (#{chunk.size} chars):"
  puts chunk
  puts "-" * 60
end
