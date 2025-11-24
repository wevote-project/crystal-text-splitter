require "./text-splitter/*"

# Text::Splitter is a flexible text chunking library for RAG (Retrieval-Augmented Generation)
# and LLM applications. It intelligently splits text into manageable chunks while preserving
# context through configurable overlap.
#
# ## Features
#
# - **Character-based splitting**: Split by character count with sentence awareness
# - **Word-based splitting**: Split by word count for more semantic chunking
# - **Configurable overlap**: Preserve context between chunks
# - **Edge case handling**: Handles long sentences, empty text, and boundary conditions
# - **Zero dependencies**: Pure Crystal implementation
#
# ## Usage
#
# ```
# require "text-splitter"
#
# # Character-based splitting (default)
# splitter = Text::Splitter.new(
#   chunk_size: 1000,
#   chunk_overlap: 200
# )
#
# text = "Your long document text here..."
# chunks = splitter.split_text(text)
# # => ["First chunk...", "Second chunk with overlap...", ...]
#
# # Word-based splitting
# word_splitter = Text::Splitter.new(
#   chunk_size: 280,      # 280 words per chunk
#   chunk_overlap: 50,    # 50 words overlap
#   mode: :words
# )
#
# chunks = word_splitter.split_text(text)
# ```
module Text
  VERSION = "0.1.0"
end
