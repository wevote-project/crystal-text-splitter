require "../src/text-splitter"

# Simulated RAG pipeline example
puts "=== RAG Pipeline Example ==="
puts

# Simulated document (like a bill or article)
document = <<-TEXT
SENATE BILL NO. 123
"Clean Energy Future Act"

SECTION 1. FINDINGS AND PURPOSE
The Legislature finds and declares all of the following:
(a) Climate change poses a significant threat to our environment.
(b) Transitioning to renewable energy is essential for sustainability.
(c) Investment in clean energy creates economic opportunities.

SECTION 2. DEFINITIONS
For purposes of this act:
(a) "Renewable energy" means energy from solar, wind, or hydroelectric sources.
(b) "Clean energy" includes renewable energy and energy efficiency measures.

SECTION 3. IMPLEMENTATION
The Department shall develop programs to:
(1) Increase renewable energy production by 50% by 2030.
(2) Provide incentives for clean energy adoption.
(3) Monitor progress toward emission reduction goals.
TEXT

# Configure splitter for optimal RAG chunking
splitter = Text::Splitter.new(
  chunk_size: 200,   # Reasonable size for embeddings
  chunk_overlap: 40, # Preserve context
  mode: Text::Splitter::ChunkMode::Characters
)

# Split document
chunks = splitter.split_text(document)

puts "Document: SENATE BILL NO. 123"
puts "Total length: #{document.size} characters"
puts "Number of chunks for embedding: #{chunks.size}"
puts

# Simulate processing each chunk
chunks.each_with_index do |chunk, i|
  puts "Processing Chunk #{i + 1}:"
  puts "  Length: #{chunk.size} characters"
  puts "  Preview: #{chunk[0..50]}..."

  # In a real RAG system, you would:
  # 1. Generate embedding: embedding = OpenAI.embed(chunk)
  # 2. Store in vector DB: VectorDB.store(chunk, embedding, metadata)
  puts "  → [Simulated] Generated embedding"
  puts "  → [Simulated] Stored in vector database"
  puts
end

puts "✅ RAG pipeline processing complete!"
puts "All chunks embedded and stored for semantic search."
