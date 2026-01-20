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

        if current_chunk.bytesize == 0
          current_chunk << sentence << '.'
        elsif current_chunk.bytesize + sentence.bytesize + 2 <= @chunk_size
          current_chunk << ' ' << sentence << '.'
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
          current_chunk << sentence << '.'
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

        sentence_words = "#{sentence}.".split(/\s+/).reject(&.empty?)
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

    protected def get_overlap_from_string(text : String) : String
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

    # Iterator class for lazy chunk generation using a state machine
    # Processes text incrementally without loading all chunks into memory
    private class ChunkIterator
      include Iterator(String)

      @current_words : Array(String)

      def initialize(@splitter : Splitter, @text : String)
        @sentences = @text.split(/[.!?]+/)
        @sentence_index = 0
        @current_chunk = String::Builder.new(@splitter.chunk_size)
        @current_words = [] of String
        @finished = false
      end

      def next
        return stop if @finished

        case @splitter.mode
        when ChunkMode::Characters
          next_chunk_characters
        else
          next_chunk_words
        end
      end

      private def next_chunk_characters
        while @sentence_index < @sentences.size
          sentence = @sentences[@sentence_index].strip
          @sentence_index += 1
          next if sentence.empty?

          if @current_chunk.bytesize == 0
            @current_chunk << sentence << '.'
          elsif @current_chunk.bytesize + sentence.bytesize + 2 <= @splitter.chunk_size
            @current_chunk << ' ' << sentence << '.'
          else
            # Chunk is ready, prepare next chunk with overlap
            result = @current_chunk.to_s
            @current_chunk = String::Builder.new(@splitter.chunk_size)

            if @splitter.chunk_overlap > 0
              overlap = @splitter.get_overlap_from_string(result)
              @current_chunk << overlap << ' ' unless overlap.empty?
            end

            @current_chunk << sentence << '.'
            return result
          end
        end

        # Return final chunk if any content remains
        final = @current_chunk.to_s
        @finished = true
        final.empty? ? stop : final
      end

      private def next_chunk_words
        while @sentence_index < @sentences.size
          sentence = @sentences[@sentence_index].strip
          @sentence_index += 1
          next if sentence.empty?

          words = "#{sentence}.".split(/\s+/).reject(&.empty?)
          next if words.empty?

          if @current_words.size + words.size <= @splitter.chunk_size
            @current_words.concat(words)
          else
            # Chunk is ready
            unless @current_words.empty?
              result = @current_words.join(' ')

              # Prepare next chunk with overlap
              if @splitter.chunk_overlap > 0
                overlap_size = Math.min(@current_words.size, @splitter.chunk_overlap)
                @current_words = @current_words.last(overlap_size).to_a
              else
                @current_words.clear
              end

              @current_words.concat(words)
              return result
            end

            # Very long sentence that exceeds chunk size
            if words.size > @splitter.chunk_size
              words.each_slice(@splitter.chunk_size) do |slice|
                combined = @current_words + slice

                if combined.size > @splitter.chunk_size
                  unless @current_words.empty?
                    result = @current_words.join(' ')
                    if @splitter.chunk_overlap > 0
                      overlap_size = Math.min(@current_words.size, @splitter.chunk_overlap)
                      @current_words = @current_words.last(overlap_size).to_a + slice.to_a
                    else
                      @current_words = slice.to_a
                    end
                    return result
                  end
                else
                  @current_words = combined
                end
              end
            else
              @current_words.concat(words)
            end
          end
        end

        # Return final chunk
        @finished = true
        @current_words.empty? ? stop : @current_words.join(' ')
      end
    end
  end
end
