require "./src/text-splitter"
require "benchmark"

# Generate sample texts of different sizes
def generate_text(word_count : Int32) : String
  words = ["Lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit",
           "sed", "do", "eiusmod", "tempor", "incididunt", "ut", "labore", "et", "dolore",
           "magna", "aliqua", "Ut", "enim", "ad", "minim", "veniam", "quis", "nostrud"]

  Array.new(word_count) { words.sample }.join(" ")
end

# Old implementation for comparison
def get_overlap_old_way(text : String, chunk_overlap : Int32) : String
  return "" if chunk_overlap <= 0 || text.empty?

  limit = chunk_overlap // 10
  return "" if limit == 0

  words = text.split
  overlap_words = words.last([words.size, limit].min)
  overlap_words.join(" ")
end

# New implementation (current optimized version)
def get_overlap_new_way(text : String, chunk_overlap : Int32) : String
  return "" if chunk_overlap <= 0 || text.empty?

  limit = chunk_overlap // 10
  return "" if limit == 0

  reader = Char::Reader.new(text)

  while reader.has_next?
    reader.next_char
  end

  count = 0
  in_word = false
  start_index = 0

  while reader.has_previous?
    char = reader.previous_char

    if char.whitespace?
      if in_word
        count += 1
        if count >= limit
          start_index = reader.pos + char.bytesize
          break
        end
        in_word = false
      end
    else
      in_word = true
    end
  end

  overlap_text = text.byte_slice(start_index)
  overlap_text.split.join(" ")
end

puts "Benchmarking overlap calculation optimization"
puts "=" * 60

# Test with different text sizes
text_sizes = [100, 500, 1000, 5000, 10000]
chunk_overlap = 200 # This gives us limit = 20 words

text_sizes.each do |size|
  text = generate_text(size)

  puts "\nText size: #{size} words"
  puts "-" * 60

  Benchmark.ips do |x|
    x.report("Old (split all)") do
      get_overlap_old_way(text, chunk_overlap)
    end

    x.report("New (scan backward)") do
      get_overlap_new_way(text, chunk_overlap)
    end
  end
end

puts "\n" + "=" * 60
puts "Memory allocation comparison"
puts "=" * 60

# Test memory impact with different text sizes
memory_test_sizes = [1000, 5000, 10000]

memory_test_sizes.each do |size|
  text = generate_text(size)

  old_memory = Benchmark.memory do
    10000.times { get_overlap_old_way(text, chunk_overlap) }
  end

  new_memory = Benchmark.memory do
    10000.times { get_overlap_new_way(text, chunk_overlap) }
  end

  puts "\nText size: #{size} words (10,000 iterations)"
  puts "  Old (split all):      #{(old_memory / 1024.0 / 1024.0).round(2)} MB"
  puts "  New (scan backward):  #{(new_memory / 1024.0 / 1024.0).round(2)} MB"
  puts "  Memory saved:         #{((1 - new_memory.to_f / old_memory) * 100).round(1)}%"
end

puts "\n" + "=" * 60
puts "Summary"
puts "=" * 60
puts "\nKey insights:"
puts "- The optimization shows increasing benefits as text size grows"
puts "- Old method allocates array for ALL words regardless of overlap size"
puts "- New method only scans backwards until it finds the needed words"
puts "- Significant memory savings, especially with large texts"
