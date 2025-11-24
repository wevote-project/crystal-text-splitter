require "../src/text-splitter"

# Word-based splitting example
puts "=== Word-Based Splitting ==="
puts

text = <<-TEXT
The quick brown fox jumps over the lazy dog. This sentence contains exactly nine words total.
Here is another sentence with some more words. And one more sentence to demonstrate the overlap feature.
Finally, this last sentence completes our example document for word-based chunking.
TEXT

splitter = Text::Splitter.new(
  chunk_size: 15,      # 15 words per chunk
  chunk_overlap: 5,    # 5 words overlap
  mode: Text::Splitter::ChunkMode::Words
)

chunks = splitter.split_text(text)

puts "Original text: #{text.split(/\s+/).size} words"
puts "Number of chunks: #{chunks.size}"
puts

chunks.each_with_index do |chunk, i|
  word_count = chunk.split(/\s+/).size
  puts "Chunk #{i + 1} (#{word_count} words):"
  puts chunk
  puts "-" * 60
end
