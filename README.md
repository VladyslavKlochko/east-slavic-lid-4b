# East Slavic Zero-Shot LID Benchmark for 4B Local LLMs

Code, diagnostic dataset, and inference logs for the paper:  
**"Can Small Language Models Distinguish Rusyn, Belarusian, and Ukrainian? An Empirical Study of Hallucination and Subsumption in Local 4B Language Models"**

## Overview

This repository evaluates three 4-bit quantised (`Q4_K_M`) local language models across four configurations on zero-shot language identification with grammatical explanations ($N = 15$ parallel sentences across Ukrainian, Belarusian, and Prešov-standard Rusyn; 60 deterministic runs via `llama.cpp`).

| Model (Configuration) | Ukr. | Bel. | Rus. | Overall | Format Compliance | Mean Latency |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Ministral-3-3B-Instruct-2512** (`Direct`) | 1/5 | 2/5 | 2/5 | 33.3% | 100% | 5.76s |
| **Qwen3.5-4B** (`No-Think`, `--reasoning-budget 0`) | **5/5** | 4/5 | **4/5** | **86.7%** | 100% | 9.60s |
| **Qwen3.5-4B** (`Thinking`, default CoT) | 5/5 | **5/5** | 3/5 | 86.7% | 0% | 69.80s |
| **NVIDIA Nemotron-3.5-Bolt-E4B** (`CoT`) | **5/5** | **5/5** | 0/5 | 66.7% | 100% | 18.81s |

## Repository Structure

- `run_east_slavic_benchmark.py` — evaluation script containing the 15 parallel sentences (`U1`–`U5`, `B1`–`B5`, `R1`–`R5`), prompt template, and `llama-cli` runner (`--temp 0 -s 42 -c 8192 -n 4096`).
- `results/final_clean_logs_4096.txt` — complete raw outputs and response times for all 60 runs.
- `research/` — Typst source (`main.typ`), BibTeX bibliography (`references.bib`), and compiled PDF (`east-slavic-lid-4b.pdf`).

## Reproducing the Runs

1. Install [llama.cpp](https://github.com/ggml-org/llama.cpp) and make sure `llama-cli` is in your `PATH` (or set `LLAMA_CLI_PATH`).
2. Download the `Q4_K_M` GGUF builds into `./models/`:
   - **Ministral-3-3B-Instruct-2512:** [mistralai/Ministral-3-3B-Instruct-2512-GGUF](https://huggingface.co/mistralai/Ministral-3-3B-Instruct-2512-GGUF) → `models/mistralai_Ministral-3-3B-Instruct-2512-Q4_K_M.gguf`
   - **Qwen3.5-4B:** [bartowski/Qwen_Qwen3.5-4B-GGUF](https://huggingface.co/bartowski/Qwen_Qwen3.5-4B-GGUF) → `models/Qwen_Qwen3.5-4B-Q4_K_M.gguf`
   - **NVIDIA Nemotron-3.5-Bolt-E4B:** [nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-4GB](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-4GB) → `models/Nemotron-3.5-Bolt-E4B-Q4_K_M.gguf`
3. Run the benchmark:
   ```bash
   python run_east_slavic_benchmark.py
