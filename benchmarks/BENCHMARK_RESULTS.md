# Benchmark Results: Overlap Calculation Optimization

Branch: `perf-optimize-overlap-calculation-574547704945957741`

## Overview

This benchmark compares the optimized overlap calculation (using backward character scanning) against the previous implementation (splitting entire text into word arrays).

## Test Setup

- **Hardware**: Run on local machine with release build (`--release` flag)
- **Overlap Configuration**: chunk_overlap = 200 (limit = 20 words)
- **Test Data**: Generated Lorem ipsum style text with varying word counts

---

## Results Part 1: Isolated Overlap Function Performance

### Speed (Iterations Per Second)

| Text Size | Old Method (split all) | New Method (scan backward) | Relative Speed |
|-----------|------------------------|----------------------------|----------------|
| 100 words | 511.92k/s (1.95µs) | 342.63k/s (2.92µs) | 1.49× slower |
| 500 words | 111.28k/s (8.99µs) | 82.99k/s (12.05µs) | 1.34× slower |
| 1,000 words | 55.89k/s (17.89µs) | 45.95k/s (21.76µs) | 1.22× slower |
| 5,000 words | 9.87k/s (101.35µs) | 9.26k/s (108.05µs) | 1.07× slower |
| 10,000 words | 4.81k/s (207.78µs) | 4.69k/s (213.44µs) | **1.03× slower** |

**Key Finding**: The performance gap narrows as text size increases. For large texts (10K+ words), the speed difference is negligible (3%).

### Memory Allocation (10,000 iterations)

| Text Size | Old Method | New Method | Memory Saved |
|-----------|-----------|------------|--------------|
| 1,000 words | 475.47 MB | 12.36 MB | **97.4%** |
| 5,000 words | 3,047.48 MB | 12.36 MB | **99.6%** |
| 10,000 words | 6,748.35 MB | 12.36 MB | **99.8%** |

**Key Finding**: Massive memory savings! The new method uses a constant ~12 MB regardless of text size, while the old method's memory usage scales linearly with text size.

### Memory Per Operation

| Text Size | Old Method | New Method | Reduction |
|-----------|-----------|------------|-----------|
| 100 words | 7.09 kB/op | 1.31 kB/op | 81.5% |
| 500 words | 27.1 kB/op | 1.3 kB/op | 95.2% |
| 1,000 words | 49.2 kB/op | 1.23 kB/op | 97.5% |
| 5,000 words | 312 kB/op | 1.36 kB/op | 99.6% |
| 10,000 words | 690 kB/op | 1.27 kB/op | 99.8% |

---

## Results Part 2: Full Text Splitting Workflow

### Medium Article (~5,000 words)
Chunk size: 1000 characters, Overlap: 200 characters

| Mode | Chunks | Time | Memory (100 iter) |
|------|--------|------|-------------------|
| Character | 50 | 0.53 ms | 30.3 MB |
| Word | 32 | 0.70 ms | 96.52 MB |

### Long Blog Post (~20,000 words)
Chunk size: 1000 characters, Overlap: 200 characters

| Mode | Chunks | Time | Memory (100 iter) |
|------|--------|------|-------------------|
| Character | 197 | 1.47 ms | 121.19 MB |
| Word | 128 | 2.75 ms | 385.22 MB |

### Research Paper (~50,000 words)
Chunk size: 1000 characters, Overlap: 200 characters

| Mode | Chunks | Time | Memory (100 iter) |
|------|--------|------|-------------------|
| Character | 498 | 3.61 ms | 307.85 MB |
| Word | 320 | 6.78 ms | 945.73 MB |

### Small Book Chapter (~100,000 words)
Chunk size: 1000 characters, Overlap: 200 characters

| Mode | Chunks | Time | Memory (100 iter) |
|------|--------|------|-------------------|
| Character | 1,003 | 7.31 ms | 624.65 MB |
| Word | 640 | 13.84 ms | 1,898.94 MB |

---

## Analysis

### What Changed?

**Old Implementation:**
```crystal
words = text.split
overlap_words = words.last([words.size, limit].min)
overlap_words.join(" ")
```

**New Implementation:**
- Uses `Char::Reader` to scan backward through string
- Counts words by detecting whitespace boundaries
- Stops as soon as it finds the required number of words (limit)
- Extracts substring using `byte_slice`

### Why This Matters for RAG Applications

1. **Memory Efficiency**: When processing large documents (papers, books, articles), the optimization prevents allocating massive word arrays just to extract a small overlap.

2. **Scalability**: The new method uses constant memory (~1.3 kB per operation) regardless of text size, making it suitable for processing very large documents.

3. **Performance**: While slightly slower for tiny texts, the gap becomes negligible for realistic document sizes (10K+ words).

4. **Real-world Impact**: In a typical RAG pipeline processing a 100K word document:
   - Old: Would allocate ~690 KB per overlap calculation × hundreds of chunks = significant memory pressure
   - New: Allocates ~1.27 KB per overlap calculation = minimal memory footprint

### Trade-offs

**Pros:**
- 97-99% memory reduction for overlap calculations
- Memory usage is constant regardless of text size
- Performance gap narrows for large texts (only 3% slower at 10K words)
- Better scalability for production RAG systems

**Cons:**
- 30-50% slower for very small texts (<500 words)
- More complex code (but well-commented)

### Recommendation

**This optimization is highly beneficial for:**
- Processing large documents (10K+ words)
- High-throughput RAG systems
- Memory-constrained environments
- Production applications handling diverse document sizes

**The optimization is less critical for:**
- Only processing very small texts (<500 words)
- Systems with abundant memory and small document collections

Given that most real-world RAG applications process medium to large documents, this optimization provides significant benefits with minimal downside.

---

## Running the Benchmarks

```bash
# Install dependencies
shards install

# Run overlap function benchmark
crystal run benchmark_overlap.cr --release

# Run full splitting workflow benchmark
crystal run benchmark_full_split.cr --release
```

---

## Conclusion

The overlap calculation optimization successfully achieves its goal of reducing memory allocations while maintaining acceptable performance. The **97-99% memory savings** make this a worthwhile optimization for any RAG application processing documents of realistic size.

**Performance Summary:**
- ✅ Massive memory reduction (97-99%)
- ✅ Constant memory usage regardless of text size
- ✅ Negligible speed difference for large texts
- ✅ Better production scalability
- ⚠️  Slightly slower for very small texts (acceptable trade-off)
