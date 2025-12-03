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

## Core Concepts

### Text Chunking Fundamentals

Text chunking is the process of dividing large documents into smaller, semantically meaningful pieces (chunks). This is essential for:

- **RAG Systems**: Retrieving relevant context for LLM queries
- **Embedding Generation**: Feeding appropriately-sized text to embedding models
- **Vector Databases**: Organizing documents for similarity search
- **Context Windows**: Fitting text within LLM token limits

### Splitting Modes

**Character-Based Splitting** breaks text at character boundaries while respecting sentence limits. Use this when:
- You need fixed-size chunks
- Working with embedding models with character-level limits
- Processing code or structured data

**Word-Based Splitting** breaks text at word boundaries while maintaining sentence integrity. Use this when:
- Working with natural language documents
- Building semantic search systems
- Better alignment with human text understanding is needed

### Overlap and Context Preservation

Overlapping chunks share content at boundaries, preserving context that might otherwise be lost during retrieval. For example, with 50-character overlap:
- Chunk 1: "The bill was introduced in 2024. It aims to reduce..."
- Chunk 2: "...to reduce emissions by 50% by 2030..."

Without overlap, critical context would be missed during retrieval.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  text-splitter:
    github: wevote-project/crystal-text-splitter
    version: ~> 0.2.0
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

### Constructor: `Text::Splitter.new`

Creates a new text splitter instance.

**Parameters:**
- `chunk_size` (Int32, required) - Maximum size of each chunk (characters or words depending on mode)
- `chunk_overlap` (Int32, required) - Overlap between chunks for context preservation
- `mode` (Symbol, optional) - Splitting mode: `:characters` (default) or `:words`

**Raises:**
- `ArgumentError` if `chunk_size` is not positive
- `ArgumentError` if `chunk_overlap` is negative
- `ArgumentError` if `chunk_overlap` >= `chunk_size`

**Example:**
```crystal
# Character-based (default)
splitter = Text::Splitter.new(chunk_size: 1000, chunk_overlap: 200)

# Word-based
splitter = Text::Splitter.new(chunk_size: 280, chunk_overlap: 50, mode: :words)
```

### Method: `#split_text(text : String) : Array(String)`

Eagerly splits the input text into chunks, returning all chunks as an array.

**Parameters:**
- `text` (String) - The text to split into chunks

**Returns:**
- `Array(String)` - Array of text chunks (empty array if input is empty/whitespace)

**Use when:** You need all chunks at once or working with small-to-medium documents.

**Example:**
```crystal
text = "Your long document..."
chunks = splitter.split_text(text)
chunks.each { |chunk| process(chunk) }
```

### Method: `#each_chunk(text : String, &block : String -> Nil) : Nil`

Iteratively processes chunks using a block without materializing the full array.

**Parameters:**
- `text` (String) - The text to split into chunks
- `block` - Code block to execute for each chunk

**Returns:**
- `Nil`

**Use when:** Processing large documents or streaming scenarios to minimize memory usage.

**Example:**
```crystal
splitter.each_chunk(text) do |chunk|
  embedding = generate_embedding(chunk)
  store_in_db(embedding)
end
```

### Method: `#each_chunk(text : String) : Iterator(String)`

Returns a lazy iterator for chunk processing with functional programming patterns.

**Parameters:**
- `text` (String) - The text to split into chunks

**Returns:**
- `Iterator(String)` - Lazy iterator over chunks

**Use when:** Applying transformations or filtering before processing chunks.

**Example:**
```crystal
large_chunks = splitter.each_chunk(text)
  .select { |c| c.size > 500 }
  .map { |c| c.upcase }
  .to_a
```

## Understanding Overlap

Overlap between chunks is crucial for RAG systems to maintain context:

```crystal
# Without overlap (chunk_overlap: 0)
text = "The bill was introduced in 2024. It aims to reduce emissions by 50%."
splitter = Text::Splitter.new(chunk_size: 35, chunk_overlap: 0)
chunks = splitter.split_text(text)
# ❌ Chunks: ["The bill was introduced in 2024.", "It aims to reduce emissions by 50%."]
# Lost context: what bill? what aims?

# With overlap (chunk_overlap: 15)
splitter = Text::Splitter.new(chunk_size: 35, chunk_overlap: 15)
chunks = splitter.split_text(text)
# ✅ Overlapped chunks preserve context across boundaries
# Better for RAG retrieval!
```

**Why this matters:** In RAG systems, when a chunk is retrieved to answer a question, having overlap ensures that relevant context from adjacent chunks is preserved, improving answer quality.

## Chunking Strategy Guide

Choose your splitting configuration based on your use case:

| Use Case | Mode | Recommended Settings | Rationale |
|----------|------|----------------------|-----------|
| **Semantic Search** | `:words` | `chunk_size: 280, chunk_overlap: 50` | Matches typical embedding model token limits |
| **RAG Pipelines** | `:words` | `chunk_size: 500, chunk_overlap: 100` | Balance context preservation with retrieval efficiency |
| **LLM Context** | `:words` | `chunk_size: 2000, chunk_overlap: 200` | Respect model context window (e.g., 4K tokens) |
| **Embedding API** | `:characters` | `chunk_size: 1000, chunk_overlap: 200` | Fixed character limits for API compatibility |
| **Vector Database** | `:words` | `chunk_size: 300, chunk_overlap: 50` | Optimal balance for most vector stores |

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

## Performance

Text::Splitter is highly optimized for production use:

- **Fast**: Processes 1MB of text in ~7ms (147 ops/sec)
- **Memory efficient**: Only 18MB memory per operation with iterator API (~57% reduction vs array)
- **Streaming capable**: Process chunks without loading entire document into memory
- **Type-safe**: Crystal's compile-time type checking prevents runtime errors
- **Production-tested**: Used in production RAG systems for legislative document processing

### Benchmark Results (1MB text, release build)

| Metric | Iterator API | Array API |
|--------|--------------|-----------|
| Throughput | 147 ops/sec | 140 ops/sec |
| Latency | 6.79ms per 1MB | 7.14ms per 1MB |
| Memory | 17.9MB | 42.3MB |
| Chunks generated | 1,249 | 1,249 |

**Memory savings:** Iterator API uses ~57% less memory than array API, making it ideal for large-scale document processing.

## Advanced Usage Patterns

### Custom Processing Pipeline

```crystal
require "text-splitter"

class EmbeddingPipeline
  def initialize(splitter : Text::Splitter)
    @splitter = splitter
  end

  def process_with_metadata(text : String, document_id : String)
    results = [] of Hash(String, String | Int32)
    
    @splitter.each_chunk(text).each_with_index do |chunk, index|
      results << {
        document_id: document_id,
        chunk_index: index,
        text: chunk,
        size: chunk.size
      }
    end
    
    results
  end
end

# Usage
splitter = Text::Splitter.new(chunk_size: 500, chunk_overlap: 100, mode: :words)
pipeline = EmbeddingPipeline.new(splitter)

chunks = pipeline.process_with_metadata(file_content, "DOC-001")
```

### Filtering and Transformation

```crystal
# Process only chunks above a certain size
large_chunks = splitter.each_chunk(text)
  .select { |c| c.size > 100 }
  .map { |c| c.strip }
  .to_a

# Count chunks
total_chunks = splitter.each_chunk(text).to_a.size

# Find first chunk containing specific text
target = splitter.each_chunk(text)
  .find { |c| c.includes?("important") }
```

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

## Troubleshooting

### Empty Chunks in Output

**Problem:** Getting empty strings in chunk array

**Solution:** Empty strings are filtered out by default. If you're receiving empty chunks, verify your text input:

```crystal
text = "Your document here"
return if text.empty? || text.strip.empty?

chunks = splitter.split_text(text)
```

### Overlap Larger Than Chunk Size

**Problem:** `ArgumentError: chunk_overlap must be less than chunk_size`

**Solution:** Ensure overlap is smaller than chunk size:

```crystal
# ❌ This will fail
splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 150)

# ✅ Correct
splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 50)
```

### Too Few Chunks

**Problem:** Getting fewer chunks than expected with large `chunk_overlap`

**Solution:** High overlap with small chunk sizes can result in fewer chunks. This is expected behavior:

```crystal
text = "A B C D E"
# chunk_size: 2, chunk_overlap: 1 = fewer chunks due to high overlap ratio
splitter = Text::Splitter.new(chunk_size: 2, chunk_overlap: 1, mode: :words)
chunks = splitter.split_text(text)
# Returns fewer chunks than the raw split would suggest
```

### Memory Issues with Large Documents

**Problem:** High memory usage when processing large files

**Solution:** Use the iterator API instead of `split_text()`:

```crystal
# ❌ High memory usage - loads all chunks at once
chunks = splitter.split_text(huge_document)
chunks.each { |chunk| process(chunk) }

# ✅ Low memory usage - processes one chunk at a time
splitter.each_chunk(huge_document) do |chunk|
  process(chunk)
end
```

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
