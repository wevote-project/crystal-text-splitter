# Text::Splitter

[![CI](https://github.com/wevote-project/crystal-text-splitter/actions/workflows/ci.yml/badge.svg)](https://github.com/wevote-project/crystal-text-splitter/actions/workflows/ci.yml)
[![GitHub release](https://img.shields.io/github/release/wevote-project/crystal-text-splitter.svg)](https://github.com/wevote-project/crystal-text-splitter/releases)
[![License](https://img.shields.io/github/license/wevote-project/crystal-text-splitter.svg)](https://github.com/wevote-project/crystal-text-splitter/blob/main/LICENSE)

**Intelligent text chunking for RAG (Retrieval-Augmented Generation) and LLM applications in Crystal.**

Text::Splitter provides flexible, production-tested text chunking with configurable overlap to preserve context between chunks. Perfect for building semantic search, RAG pipelines, and LLM applications.

## Features

- 🎯 **Character-based splitting** - Split by character count with sentence awareness
- 📝 **Word-based splitting** - Split by word count for more semantic chunking
- 🔗 **Configurable overlap** - Preserve context between chunks for better retrieval
- 🔄 **Iterator API** - Memory-efficient streaming with lazy evaluation
- 🛡️ **Edge case handling** - Handles long sentences, empty text, and boundary conditions
- ⚡ **Zero dependencies** - Pure Crystal implementation, no external dependencies
- 🚀 **Production-tested** - Battle-tested in production RAG systems
- ⚡ **High performance** - Process 1MB in ~7ms with only 18MB memory

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  text-splitter:
    github: wevote-project/crystal-text-splitter
    version: ~> 0.1.0
```

2. Run `shards install`

## Usage

### Character-Based Splitting (Default)

Ideal for fixed-size chunks where character count matters:

```crystal
require "text-splitter"

# Create splitter with character-based chunking
splitter = Text::Splitter.new(
  chunk_size: 1000,      # Max 1000 characters per chunk
  chunk_overlap: 200     # 200 character overlap between chunks
)

text = File.read("long_document.txt")
chunks = splitter.split_text(text)

chunks.each_with_index do |chunk, i|
  puts "Chunk #{i + 1}: #{chunk.size} characters"
  puts chunk
  puts "-" * 50
end
```

### Word-Based Splitting

Better for semantic chunking and natural language processing:

```crystal
require "text-splitter"

# Create splitter with word-based chunking
splitter = Text::Splitter.new(
  chunk_size: 280,       # Max 280 words per chunk
  chunk_overlap: 50,     # 50 word overlap between chunks
  mode: :words
)

text = "Your long document text here..."
chunks = splitter.split_text(text)

# Process chunks for embedding generation
chunks.each do |chunk|
  embedding = generate_embedding(chunk)
  store_in_vector_db(chunk, embedding)
end
```

### Memory-Efficient Iterator API

For processing large documents without loading all chunks into memory:

```crystal
require "text-splitter"

splitter = Text::Splitter.new(chunk_size: 1000, chunk_overlap: 200)

# Method 1: Block syntax (most efficient - no array allocation)
splitter.each_chunk(text) do |chunk|
  # Process chunk immediately
  embedding = generate_embedding(chunk)
  store_in_db(embedding)
end

# Method 2: Iterator with lazy evaluation
splitter.each_chunk(text)
  .first(10)  # Only process first 10 chunks
  .each { |chunk| process(chunk) }

# Method 3: Transform without materializing all chunks
large_chunks = splitter.each_chunk(text)
  .select { |c| c.size > 500 }
  .map { |c| c.upcase }
  .to_a
```

**Performance:** Processing 1MB of text uses only ~18MB memory with iterators vs ~42MB with arrays.

### RAG Pipeline Example

Typical usage in a Retrieval-Augmented Generation system:

```crystal
require "text-splitter"

class DocumentProcessor
  def initialize
    @splitter = Text::Splitter.new(
      chunk_size: 500,
      chunk_overlap: 100,
      mode: :words
    )
  end

  def process_document(doc : String, metadata : Hash)
    # Split document into chunks
    chunks = @splitter.split_text(doc)

    chunks.map_with_index do |chunk, index|
      {
        text: chunk,
        metadata: metadata.merge({
          chunk_index: index,
          total_chunks: chunks.size
        })
      }
    end
  end
end

# Usage
processor = DocumentProcessor.new
bill_text = File.read("bill_text.txt")

chunks = processor.process_document(
  bill_text,
  {bill_id: "HB-123", title: "Example Bill"}
)

# Store in vector database
chunks.each do |chunk|
  embedding = OpenAI.embed(chunk[:text])
  VectorDB.store(chunk[:text], embedding, chunk[:metadata])
end
```

## API Reference

### `Text::Splitter.new`

Creates a new text splitter instance.

**Parameters:**
- `chunk_size` (Int32, required) - Maximum size of each chunk (characters or words depending on mode)
- `chunk_overlap` (Int32, required) - Overlap between chunks for context preservation
- `mode` (Symbol, optional) - Splitting mode: `:characters` (default) or `:words`

**Raises:**
- `ArgumentError` if `chunk_size` is not positive
- `ArgumentError` if `chunk_overlap` is negative
- `ArgumentError` if `chunk_overlap` >= `chunk_size`

### `#split_text(text : String) : Array(String)`

Splits the input text into chunks based on the configured mode.

**Parameters:**
- `text` (String) - The text to split into chunks

**Returns:**
- `Array(String)` - Array of text chunks (empty array if input is empty/whitespace)

## Why Overlap Matters

Overlap between chunks is crucial for RAG systems to maintain context:

```crystal
# Without overlap
chunks = ["The bill was introduced in 2024.", "It aims to reduce emissions."]
# ❌ Lost context: What bill? What aims?

# With 50-character overlap
splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 50)
chunks = splitter.split_text("The bill was introduced in 2024. It aims to reduce emissions.")
# ✅ Chunks:
#   "The bill was introduced in 2024."
#   "The bill was introduced in 2024. It aims to reduce emissions."
# Context preserved!
```

## Chunking Strategies

### When to use Character-Based Splitting

- Fixed embedding model limits (e.g., 512 tokens)
- Uniform chunk sizes required
- Processing code or structured data

### When to use Word-Based Splitting

- Natural language documents
- Semantic search applications
- Better alignment with human understanding

## Performance

Text::Splitter is highly optimized for production use:

- **Fast**: Processes 1MB of text in ~7ms (147 ops/sec)
- **Memory efficient**: Only 18MB memory per operation with iterator API
- **Streaming capable**: Process chunks without loading entire document
- **Type-safe**: Crystal's compile-time type checking prevents runtime errors

### Benchmark Results (1MB text, release build)

| Metric | Value |
|--------|-------|
| Throughput | 147 ops/sec |
| Latency | 6.79ms per 1MB |
| Memory | 17.9MB per operation |
| Chunks generated | 1,249 chunks |

## Comparison with Other Solutions

| Feature | Text::Splitter | LangChain (Python) | Manual String.split |
|---------|---------------|-------------------|-------------------|
| Sentence-aware | ✅ | ✅ | ❌ |
| Configurable overlap | ✅ | ✅ | ❌ |
| Word/char modes | ✅ | ✅ | ❌ |
| Iterator API | ✅ | ❌ | ❌ |
| Zero dependencies | ✅ | ❌ | ✅ |
| Type-safe | ✅ | ❌ | ✅ |
| Edge case handling | ✅ | ✅ | ❌ |
| Performance | 7ms/MB | ~100ms/MB | N/A |

## Real-World Usage

Text::Splitter is production-tested in:

- **Bills RAG System**: Processing legislative documents for semantic search
- Document chunking for embedding generation (OpenAI, local models)
- Building vector databases with proper context preservation
- RAG pipelines for question-answering systems

## Contributing

1. Fork it (<https://github.com/wevote-project/text-splitter/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Development

```bash
# Install dependencies
shards install

# Run tests
crystal spec

# Run linter
bin/ameba

# Format code
crystal tool format
```

## Contributors

- [Antarr Byrd](https://github.com/antarr) - creator and maintainer
- [Osama Saeed](https://github.com/alchemist-guy) - creator and maintainer

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Projects

- [LangChain](https://python.langchain.com/) - Python framework for LLM applications
- [llama_index](https://github.com/jerryjliu/llama_index) - Data framework for LLM applications
- [Pinecone](https://www.pinecone.io/) - Vector database for similarity search

## Acknowledgments

Inspired by text splitting patterns from LangChain and best practices from the RAG/LLM community. Built with ❤️ in Crystal for high-performance text processing.
