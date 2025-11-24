module Text
  # Text::Splitter intelligently splits text into chunks for LLM/RAG applications.
  #
  # It supports two splitting modes:
  # - **Characters**: Splits based on character count (default)
  # - **Words**: Splits based on word count (more semantic)
  #
  # Both modes respect sentence boundaries and support configurable overlap
  # to preserve context between chunks.
  #
  # ## Example
  #
  # ```
  # # Character-based splitting
  # splitter = Text::Splitter.new(
  #   chunk_size: 1000,
  #   chunk_overlap: 200
  # )
  #
  # chunks = splitter.split_text("Your long document...")
  # # => ["First chunk...", "Second chunk with overlap..."]
  #
  # # Word-based splitting
  # word_splitter = Text::Splitter.new(
  #   chunk_size: 280,
  #   chunk_overlap: 50,
  #   mode: :words
  # )
  # ```
  class Splitter
    enum ChunkMode
      # Split by character count
      Characters
      # Split by word count
      Words
    end

    # Size of each chunk (characters or words depending on mode)
    getter chunk_size : Int32

    # Amount of overlap between chunks (characters or words depending on mode)
    getter chunk_overlap : Int32

    # Splitting mode (characters or words)
    getter mode : ChunkMode

    # Creates a new text splitter
    #
    # - `chunk_size`: Maximum size of each chunk (in characters or words)
    # - `chunk_overlap`: Overlap between chunks for context preservation
    # - `mode`: Splitting mode (`:characters` or `:words`)
    def initialize(@chunk_size : Int32, @chunk_overlap : Int32, @mode : ChunkMode = ChunkMode::Characters)
      raise ArgumentError.new("chunk_size must be positive") if @chunk_size <= 0
      raise ArgumentError.new("chunk_overlap must be non-negative") if @chunk_overlap < 0
      raise ArgumentError.new("chunk_overlap must be less than chunk_size") if @chunk_overlap >= @chunk_size
    end

    # Splits text into chunks based on the configured mode
    #
    # Returns an empty array if text is empty or only whitespace
    #
    # ```
    # splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
    # chunks = splitter.split_text("Long document text here...")
    # ```
    def split_text(text : String) : Array(String)
      return [] of String if text.strip.empty?

      case @mode
      when ChunkMode::Words
        split_by_words(text)
      else
        split_by_characters(text)
      end
    end

    private def split_by_characters(text : String) : Array(String)
      chunks = [] of String
      sentences = text.split(/[.!?]+/)
      current_chunk = ""

      sentences.each do |sentence|
        sentence = sentence.strip
        next if sentence.empty?

        # Add sentence delimiter back
        sentence += "."

        if current_chunk.size + sentence.size + 1 <= @chunk_size
          current_chunk += " " unless current_chunk.empty?
          current_chunk += sentence
        else
          # Save current chunk if it's not empty
          chunks << current_chunk unless current_chunk.empty?

          # Start new chunk with overlap
          overlap_text = get_overlap_text(current_chunk)
          current_chunk = overlap_text.empty? ? sentence : "#{overlap_text} #{sentence}"
        end
      end

      # Don't forget the last chunk
      chunks << current_chunk unless current_chunk.empty?

      chunks
    end

    private def split_by_words(text : String) : Array(String)
      chunks = [] of String
      sentences = text.split(/[.!?]+/)
      current_chunk_words = [] of String

      sentences.each do |sentence|
        sentence = sentence.strip
        next if sentence.empty?

        # Add sentence delimiter back
        sentence += "."

        # Split into words, preserving punctuation attached to words
        sentence_words = sentence.split(/\s+/).reject(&.empty?)

        # Safety check: skip empty sentence_words
        next if sentence_words.empty?

        # Check if adding this sentence would exceed chunk size
        if current_chunk_words.size + sentence_words.size <= @chunk_size
          # Add sentence to current chunk
          current_chunk_words.concat(sentence_words)
        else
          # Save current chunk if not empty
          if !current_chunk_words.empty?
            chunks << current_chunk_words.join(" ")

            # Get overlap words for next chunk
            overlap_words = get_overlap_words(current_chunk_words)
            current_chunk_words = overlap_words
          end

          # Handle very long sentences that exceed chunk size
          if sentence_words.size > @chunk_size
            # Split long sentence into multiple chunks
            sentence_words.each_slice(@chunk_size) do |word_slice|
              # Ensure word_slice is not empty
              next if word_slice.empty?

              # Add current words to chunk
              combined_words = current_chunk_words + word_slice

              if combined_words.size > @chunk_size
                # Save current chunk
                chunks << current_chunk_words.join(" ") unless current_chunk_words.empty?
                current_chunk_words = word_slice.to_a
              else
                current_chunk_words = combined_words
              end
            end
          else
            # Normal case: add sentence to new chunk
            current_chunk_words.concat(sentence_words)
          end
        end
      end

      # Don't forget the last chunk
      chunks << current_chunk_words.join(" ") unless current_chunk_words.empty?

      # Safety validation: remove any empty chunks
      chunks.reject(&.strip.empty?)
    end

    private def get_overlap_text(text : String) : String
      return "" if @chunk_overlap <= 0

      words = text.split
      overlap_words = words.last([words.size, @chunk_overlap // 10].min)
      overlap_words.join(" ")
    end

    private def get_overlap_words(words : Array(String)) : Array(String)
      return [] of String if @chunk_overlap <= 0 || words.empty?

      # For word mode, overlap is already in words
      overlap_size = Math.min(words.size, @chunk_overlap)
      words.last(overlap_size).to_a
    end
  end
end
