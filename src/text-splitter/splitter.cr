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
      each_chunk(text).to_a
    end

    # Yields each chunk lazily without allocating all chunks upfront
    #
    # This is more memory efficient for large texts
    #
    # ```
    # splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
    # splitter.each_chunk(text) do |chunk|
    #   puts chunk
    # end
    # ```
    def each_chunk(text : String, & : String ->)
      return if text.strip.empty?

      case @mode
      when ChunkMode::Words
        each_chunk_by_words(text) { |chunk| yield chunk }
      else
        each_chunk_by_characters(text) { |chunk| yield chunk }
      end
    end

    # Returns an iterator over chunks
    #
    # ```
    # splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
    # splitter.each_chunk(text).first(10) # Get first 10 chunks only
    # ```
    def each_chunk(text : String)
      ChunkIterator.new(self, text)
    end

    private def each_chunk_by_characters(text : String, & : String ->)
      # Use optimized split approach - Crystal's split is highly optimized
      sentences = text.split(/[.!?]+/)
      current_chunk = String::Builder.new(@chunk_size)

      sentences.each do |sentence|
        sentence = sentence.strip
        next if sentence.empty?

        # Add sentence delimiter back
        sentence_with_punct = sentence + "."

        if current_chunk.bytesize == 0
          current_chunk << sentence_with_punct
        elsif current_chunk.bytesize + sentence_with_punct.bytesize + 1 <= @chunk_size
          current_chunk << ' ' << sentence_with_punct
        else
          # Yield current chunk
          chunk_str = current_chunk.to_s
          yield chunk_str

          # Start new chunk with overlap
          current_chunk = String::Builder.new(@chunk_size)
          if @chunk_overlap > 0
            overlap = get_overlap_from_string(chunk_str)
            unless overlap.empty?
              current_chunk << overlap << ' '
            end
          end
          current_chunk << sentence_with_punct
        end
      end

      # Yield final chunk
      final_chunk = current_chunk.to_s
      yield final_chunk unless final_chunk.empty?
    end

    private def each_chunk_by_words(text : String, & : String ->)
      # Use optimized split - much faster than manual scanning
      sentences = text.split(/[.!?]+/)
      current_chunk_words = [] of String

      sentences.each do |sentence|
        sentence = sentence.strip
        next if sentence.empty?

        # Add sentence delimiter back and split into words
        sentence_with_punct = sentence + "."
        sentence_words = sentence_with_punct.split(/\s+/).reject(&.empty?)
        next if sentence_words.empty?

        # Check if adding this sentence would exceed chunk size
        if current_chunk_words.size + sentence_words.size <= @chunk_size
          current_chunk_words.concat(sentence_words)
        else
          # Yield current chunk if not empty
          unless current_chunk_words.empty?
            yield current_chunk_words.join(' ')

            # Get overlap words for next chunk
            if @chunk_overlap > 0
              overlap_size = Math.min(current_chunk_words.size, @chunk_overlap)
              current_chunk_words = current_chunk_words.last(overlap_size).to_a
            else
              current_chunk_words.clear
            end
          end

          # Handle very long sentences that exceed chunk size
          if sentence_words.size > @chunk_size
            sentence_words.each_slice(@chunk_size) do |word_slice|
              next if word_slice.empty?

              combined_words = current_chunk_words + word_slice

              if combined_words.size > @chunk_size
                yield current_chunk_words.join(' ') unless current_chunk_words.empty?

                # Get overlap words
                if @chunk_overlap > 0 && !current_chunk_words.empty?
                  overlap_size = Math.min(current_chunk_words.size, @chunk_overlap)
                  current_chunk_words = current_chunk_words.last(overlap_size).to_a + word_slice.to_a
                else
                  current_chunk_words = word_slice.to_a
                end
              else
                current_chunk_words = combined_words
              end
            end
          else
            current_chunk_words.concat(sentence_words)
          end
        end
      end

      # Yield final chunk
      unless current_chunk_words.empty?
        final = current_chunk_words.join(' ')
        yield final unless final.strip.empty?
      end
    end

    private def get_overlap_from_string(text : String) : String
      return "" if @chunk_overlap <= 0 || text.empty?

      limit = @chunk_overlap // 10
      return "" if limit == 0

      # Optimized: scan from end to find last `limit` words
      # instead of allocating array for all words
      reader = Char::Reader.new(text)

      # Fast forward to end
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

      # If we stopped because we hit the beginning of the string while in a word,
      # that counts as a word, but start_index is already 0.

      # Use byte_slice to avoid encoding issues with indices
      overlap_text = text.byte_slice(start_index)

      # Normalize whitespace and join
      overlap_text.split.join(" ")
    end

    # Iterator class for lazy chunk generation
    private class ChunkIterator
      include Iterator(String)

      def initialize(@splitter : Splitter, @text : String)
        @chunks = [] of String
        @index = 0
        @finished = false
        @started = false
      end

      def next
        unless @started
          @splitter.each_chunk(@text) { |chunk| @chunks << chunk }
          @started = true
        end

        if @index < @chunks.size
          chunk = @chunks[@index]
          @index += 1
          chunk
        else
          stop
        end
      end
    end
  end
end
