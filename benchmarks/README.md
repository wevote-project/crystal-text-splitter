# Benchmarks

This directory contains performance benchmarks and optimization results for the Crystal Text Splitter library.

## Running Benchmarks

All benchmarks should be run with the `--release` flag for accurate performance measurements:

```bash
cd benchmarks
crystal run <benchmark_file>.cr --release
```

## Available Benchmarks

### Lazy Iterator Performance

**Files:**
- `benchmark_lazy_iterator.cr` - Lazy vs eager evaluation comparison
- `LAZY_ITERATOR_RESULTS.md` - Detailed analysis and results

**What it tests:**
Compares the state machine-based lazy iterator against eager `split_text()` evaluation.

**Key results:**
- 4-5x faster for first chunk and early termination
- 65-67% memory reduction
- Virtually no overhead for full iteration
- True lazy evaluation confirmed

**Run:**
```bash
crystal run benchmark_lazy_iterator.cr --release
```

---

## Available Benchmarks

### Overlap Calculation Optimization

**Files:**
- `benchmark_overlap.cr` - Isolated overlap function performance test
- `benchmark_full_split.cr` - Complete text splitting workflow test
- `BENCHMARK_RESULTS.md` - Detailed analysis and results

**What it tests:**
Compares the optimized overlap calculation (using backward character scanning) against the previous implementation (splitting entire text into word arrays).

**Key results:**
- 97-99% memory reduction for overlap calculations
- Negligible speed impact for large texts (only 3% slower at 10K words)
- Constant memory usage regardless of text size

**Run:**
```bash
crystal run benchmark_overlap.cr --release
crystal run benchmark_full_split.cr --release
```

### String Allocation Optimization

**Files:**
- `benchmark_string_concat.cr` - Micro-benchmark for string concatenation patterns
- `benchmark_string_allocation.cr` - Full workflow comparison
- `STRING_ALLOCATION_OPTIMIZATION.md` - Detailed analysis and results

**What it tests:**
Compares direct string appending vs creating intermediate variables in hot loops.

**Key results:**
- Character mode: 1.2x faster, 31% less memory
- Word mode: No performance change, improved code quality
- Reduced GC pressure

**Run:**
```bash
crystal run benchmark_string_concat.cr --release
crystal run benchmark_string_allocation.cr --release
```

## Benchmark Comparison

See `BENCHMARK_COMPARISON.md` for before/after comparison showing that the lazy iterator fix:
- ✅ Does NOT negatively impact existing benchmarks
- ✅ Actually improves performance by 2-30% in some cases
- ✅ All optimizations work together harmoniously

## Benchmark Results Summary

All three optimizations have been applied to the codebase:

1. **Overlap Calculation** (commit d2b8eda)
   - 97-99% memory savings
   - Better scalability for large documents

2. **String Allocation** (commit 230b8df)
   - 31% memory savings in character mode
   - 1.2x speedup in character mode
   - Cleaner, more maintainable code

3. **Lazy Iterator** (current branch)
   - 4-5x faster for first chunk/early termination
   - 65-67% memory reduction
   - True O(1) lazy evaluation
   - No overhead for full iteration

## Adding New Benchmarks

When adding new benchmarks:

1. Create the benchmark file in this directory
2. Name it clearly: `benchmark_<feature>.cr`
3. Document results in a markdown file: `<FEATURE>_OPTIMIZATION.md`
4. Update this README with a summary
5. Always use `--release` flag for accurate measurements
6. Include both time and memory measurements where applicable

## Notes

- Benchmarks are not included in the main test suite
- They are for development and performance analysis only
- Results may vary based on hardware and system load
- Always run multiple times to verify consistency
