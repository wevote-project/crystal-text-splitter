require "./spec_helper"

describe Text::Splitter do
  describe "#initialize" do
    it "creates splitter with valid parameters" do
      splitter = Text::Splitter.new(
        chunk_size: 100,
        chunk_overlap: 20
      )

      splitter.chunk_size.should eq(100)
      splitter.chunk_overlap.should eq(20)
      splitter.mode.should eq(Text::Splitter::ChunkMode::Characters)
    end

    it "allows word mode" do
      splitter = Text::Splitter.new(
        chunk_size: 50,
        chunk_overlap: 10,
        mode: Text::Splitter::ChunkMode::Words
      )

      splitter.mode.should eq(Text::Splitter::ChunkMode::Words)
    end

    it "raises error for non-positive chunk_size" do
      expect_raises(ArgumentError, "chunk_size must be positive") do
        Text::Splitter.new(chunk_size: 0, chunk_overlap: 0)
      end

      expect_raises(ArgumentError, "chunk_size must be positive") do
        Text::Splitter.new(chunk_size: -10, chunk_overlap: 0)
      end
    end

    it "raises error for negative chunk_overlap" do
      expect_raises(ArgumentError, "chunk_overlap must be non-negative") do
        Text::Splitter.new(chunk_size: 100, chunk_overlap: -1)
      end
    end

    it "raises error when overlap >= chunk_size" do
      expect_raises(ArgumentError, "chunk_overlap must be less than chunk_size") do
        Text::Splitter.new(chunk_size: 100, chunk_overlap: 100)
      end

      expect_raises(ArgumentError, "chunk_overlap must be less than chunk_size") do
        Text::Splitter.new(chunk_size: 100, chunk_overlap: 150)
      end
    end
  end

  describe "#split_text (character mode)" do
    it "returns empty array for empty string" do
      splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
      splitter.split_text("").should eq([] of String)
    end

    it "returns empty array for whitespace-only string" do
      splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
      splitter.split_text("   \n\t  ").should eq([] of String)
    end

    it "splits single sentence into one chunk" do
      splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
      text = "This is a simple sentence."
      chunks = splitter.split_text(text)

      chunks.size.should eq(1)
      chunks[0].should eq("This is a simple sentence.")
    end

    it "splits text into multiple chunks" do
      splitter = Text::Splitter.new(chunk_size: 50, chunk_overlap: 10)
      text = "First sentence here. Second sentence here. Third sentence here."
      chunks = splitter.split_text(text)

      chunks.size.should be > 1
      chunks.each do |chunk|
        chunk.size.should be <= 50
      end
    end

    it "preserves sentence boundaries" do
      splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
      text = "Sentence one. Sentence two. Sentence three."
      chunks = splitter.split_text(text)

      chunks.each do |chunk|
        chunk.should match(/\.$/) # Should end with period
      end
    end

    it "handles text with multiple punctuation marks" do
      splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
      text = "Question? Exclamation! Normal sentence."
      chunks = splitter.split_text(text)

      chunks.should_not be_empty
    end

    it "creates overlap between chunks" do
      splitter = Text::Splitter.new(chunk_size: 80, chunk_overlap: 20)
      text = "First sentence is here. Second sentence is here. Third sentence is here. Fourth sentence is here."
      chunks = splitter.split_text(text)

      if chunks.size > 1
        # Some text from first chunk should appear in second chunk (overlap)
        chunks[1].should contain("here")
      end
    end
  end

  describe "#split_text (word mode)" do
    it "splits by word count" do
      splitter = Text::Splitter.new(
        chunk_size: 10, # 10 words per chunk
        chunk_overlap: 2,
        mode: Text::Splitter::ChunkMode::Words
      )

      text = "One two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen."
      chunks = splitter.split_text(text)

      chunks.size.should be > 1

      # Check that each chunk has reasonable word count
      chunks.each do |chunk|
        word_count = chunk.split(/\s+/).size
        word_count.should be <= 10
      end
    end

    it "handles very long sentences in word mode" do
      splitter = Text::Splitter.new(
        chunk_size: 5,
        chunk_overlap: 1,
        mode: Text::Splitter::ChunkMode::Words
      )

      # Create a sentence with more than 5 words
      text = "This is a very long sentence with many words that exceeds the chunk size."
      chunks = splitter.split_text(text)

      chunks.should_not be_empty
      # Should split the long sentence
      chunks.size.should be > 1
    end

    it "creates word-based overlap" do
      splitter = Text::Splitter.new(
        chunk_size: 8,
        chunk_overlap: 3,
        mode: Text::Splitter::ChunkMode::Words
      )

      text = "One two three four five six seven eight nine ten. Eleven twelve thirteen fourteen."
      chunks = splitter.split_text(text)

      if chunks.size > 1
        # Check for overlap (some words from end of first chunk in second chunk)
        first_words = chunks[0].split(/\s+/)
        second_words = chunks[1].split(/\s+/)

        # At least one word should overlap
        overlap_found = first_words.any? { |word| second_words.includes?(word) }
        overlap_found.should be_true
      end
    end

    it "handles empty sentences in word mode" do
      splitter = Text::Splitter.new(
        chunk_size: 10,
        chunk_overlap: 2,
        mode: Text::Splitter::ChunkMode::Words
      )

      text = "First sentence. . . Second sentence."
      chunks = splitter.split_text(text)

      chunks.should_not be_empty
    end
  end

  describe "edge cases" do
    it "handles text with only punctuation" do
      splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
      text = "... !!! ???"
      chunks = splitter.split_text(text)

      # Should handle gracefully (may be empty or minimal chunks)
      chunks.should be_a(Array(String))
    end

    it "handles very small chunk size" do
      splitter = Text::Splitter.new(chunk_size: 10, chunk_overlap: 2)
      text = "This is a test."
      chunks = splitter.split_text(text)

      chunks.should_not be_empty
    end

    it "handles chunk size larger than text" do
      splitter = Text::Splitter.new(chunk_size: 1000, chunk_overlap: 100)
      text = "Short text."
      chunks = splitter.split_text(text)

      chunks.size.should eq(1)
      chunks[0].should eq("Short text.")
    end

    it "handles text with mixed line endings" do
      splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
      text = "First line.\nSecond line.\r\nThird line."
      chunks = splitter.split_text(text)

      chunks.should_not be_empty
    end

    it "handles Unicode characters" do
      splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
      text = "日本語のテキスト。中国文本。한국어 텍스트."
      chunks = splitter.split_text(text)

      chunks.should_not be_empty
    end

    it "handles special characters and symbols" do
      splitter = Text::Splitter.new(chunk_size: 100, chunk_overlap: 20)
      text = "Code: @user#tag $100 50% & more!"
      chunks = splitter.split_text(text)

      chunks.should_not be_empty
    end
  end

  describe "real-world usage" do
    it "handles legal document text" do
      splitter = Text::Splitter.new(chunk_size: 500, chunk_overlap: 100)

      legal_text = "SECTION 1. SHORT TITLE.\n" \
                   "This Act may be cited as the \"Example Act of 2024\".\n\n" \
                   "SECTION 2. FINDINGS.\n" \
                   "Congress finds the following:\n" \
                   "(1) The first finding is here.\n" \
                   "(2) The second finding is here.\n" \
                   "(3) The third finding is here.\n\n" \
                   "SECTION 3. DEFINITIONS.\n" \
                   "In this Act:\n" \
                   "(1) TERM ONE - The definition is here.\n" \
                   "(2) TERM TWO - Another definition is here."

      chunks = splitter.split_text(legal_text)

      chunks.should_not be_empty
      chunks.each do |chunk|
        chunk.size.should be <= 500
      end
    end

    it "processes blog post content" do
      splitter = Text::Splitter.new(
        chunk_size: 280,
        chunk_overlap: 50,
        mode: Text::Splitter::ChunkMode::Words
      )

      blog_text = "Welcome to our blog! Today we're discussing text chunking for RAG applications.\n\n" \
                  "Text chunking is a crucial preprocessing step when building semantic search systems.\n" \
                  "By breaking documents into smaller, manageable pieces, we can create more precise embeddings.\n\n" \
                  "The key is finding the right balance between chunk size and overlap. Too small, and you lose context.\n" \
                  "Too large, and your embeddings become less specific. Experimentation is essential!"

      chunks = splitter.split_text(blog_text)

      chunks.should_not be_empty
      chunks.each do |chunk|
        word_count = chunk.split(/\s+/).size
        word_count.should be <= 280
      end
    end

    it "handles scientific paper abstract" do
      splitter = Text::Splitter.new(chunk_size: 300, chunk_overlap: 50)

      abstract_text = "Abstract: This study investigates the application of large language models (LLMs) in retrieval-augmented generation (RAG) systems.\n" \
                      "We propose a novel chunking strategy that preserves semantic coherence while optimizing for embedding quality.\n" \
                      "Our results demonstrate a 23% improvement in retrieval accuracy compared to baseline methods.\n" \
                      "The findings suggest that intelligent text preprocessing significantly impacts downstream task performance."

      chunks = splitter.split_text(abstract_text)

      chunks.should_not be_empty
    end
  end
end
