# Automating QLoRA Fine-Tuning and Deployment

A comprehensive MLOps project for automating the QLoRA fine-tuning and deployment of Large Language Models using Docker and GitHub Actions, built on the Axolotl framework.

## Overview

This project implements a reproducible CI/CD pipeline for fine-tuning Large Language Models using QLoRA (Quantized Low-Rank Adaptation) methodology. The system is designed to:

- **Automate fine-tuning workflows** using the Axolotl framework
- **Optimize memory usage** through 4-bit quantization and LoRA techniques  
- **Enable reproducible training** with Docker containerization
- **Streamline deployment** through FastAPI and Gradio interfaces
- **Ensure code quality** with automated linting and testing
- **Support CI/CD** via GitHub Actions integration

### Key Features

- 🚀 **Efficient Fine-tuning**: QLoRA implementation targeting attention and MLP layers
- 🔧 **Modular Configuration**: YAML-based Axolotl configurations for different models
- 📦 **Containerized Deployment**: Docker support for consistent environments  
- 🎯 **Multiple Interfaces**: Both API (FastAPI) and UI (Gradio) deployment options
- 📊 **Monitoring Integration**: Weights & Biases logging and TensorBoard support
- 🔄 **Automated Workflows**: GitHub Actions for CI/CD pipeline
- 📝 **Comprehensive Logging**: Detailed training and inference logging

## Project Structure

```
QLORAX/
├── configs/                    # Configuration files
│   └── default-qlora-config.yml   # Default QLoRA training configuration
├── data/                       # Dataset storage
│   └── curated.jsonl              # Sample training data
├── notebooks/                  # Jupyter notebooks for experimentation
├── scripts/                    # Training and deployment scripts
├── .gitignore                  # Git ignore patterns
├── README.md                   # Project documentation
└── requirements.txt            # Python dependencies
```

## Setup

### Prerequisites

- Python 3.8 or higher
- CUDA-compatible GPU (recommended for training)
- At least 16GB RAM (24GB+ recommended for larger models)
- Docker (optional, for containerized deployment)

### Installation

1. **Clone the repository**:
   ```bash
   git clone <your-repo-url>
   cd QLORAX
   ```

2. **Create and activate virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Verify installation**:
   ```bash
   python -c "import axolotl; print('Axolotl installed successfully')"
   ```

### Environment Configuration

Create a `.env` file in the project root for sensitive configurations:

```bash
# Weights & Biases (optional)
WANDB_API_KEY=your_wandb_api_key
WANDB_PROJECT=qlorax-finetuning

# Hugging Face (for model uploads)
HUGGINGFACE_TOKEN=your_hf_token

# Hardware configuration
CUDA_VISIBLE_DEVICES=0
```

## Usage

### 1. Data Preparation

Prepare your training data in JSONL format with `input` and `output` fields:

```json
{"input": "Your question here", "output": "Expected model response"}
{"input": "Another question", "output": "Another response"}
```

Place your dataset file in the `data/` directory and update the path in your configuration file.

### 2. Configuration

Modify `configs/default-qlora-config.yml` to customize:

- **Base model**: Change `base_model` to your preferred model
- **Dataset path**: Update `datasets.path` to point to your data
- **Training parameters**: Adjust hyperparameters as needed
- **Output directory**: Set your preferred model output location

### 3. Fine-tuning

Run the fine-tuning process:

```bash
# Basic training
axolotl train configs/default-qlora-config.yml

# With custom configuration
axolotl train configs/your-custom-config.yml

# Resume from checkpoint
axolotl train configs/default-qlora-config.yml --resume_from_checkpoint ./models/checkpoint-100
```

### 4. Model Inference

Test your fine-tuned model:

```bash
# Interactive inference
axolotl inference configs/default-qlora-config.yml \
    --lora_model_dir ./models/tinyllama-qlora

# Batch inference
python scripts/batch_inference.py --model_path ./models/tinyllama-qlora
```

### 5. Deployment

#### Option A: FastAPI Service

```bash
# Start FastAPI server
uvicorn scripts.api_server:app --host 0.0.0.0 --port 8000
```

#### Option B: Gradio Interface

```bash
# Launch Gradio interface
python scripts/gradio_app.py --model_path ./models/tinyllama-qlora
```

### 6. Monitoring

Monitor training progress:

- **Weights & Biases**: Check your W&B dashboard for real-time metrics
- **TensorBoard**: `tensorboard --logdir ./models/tinyllama-qlora/runs`
- **Logs**: Training logs are saved in the output directory

## Configuration Reference

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `base_model` | Hugging Face model identifier | `TinyLlama/TinyLlama-1.1B-Chat-v1.0` |
| `lora_r` | LoRA rank | `64` |
| `lora_alpha` | LoRA alpha scaling | `16` |
| `learning_rate` | Training learning rate | `0.0002` |
| `num_epochs` | Number of training epochs | `3` |
| `micro_batch_size` | Batch size per device | `1` |
| `sequence_len` | Maximum sequence length | `2048` |

### Quantization Settings

The configuration uses 4-bit NF4 quantization with double quantization:

```yaml
load_in_4bit: true
bnb_4bit_quant_type: nf4
bnb_4bit_use_double_quant: true
bnb_4bit_compute_dtype: bfloat16
```

### LoRA Target Modules

QLoRA targets key attention and MLP layers:

```yaml
lora_target_modules:
  - q_proj    # Query projection
  - v_proj    # Value projection  
  - k_proj    # Key projection
  - o_proj    # Output projection
  - gate_proj # Gate projection (MLP)
  - down_proj # Down projection (MLP)
  - up_proj   # Up projection (MLP)
```

## Development

### Code Quality

Run code quality checks:

```bash
# Format code
black .
ruff check . --fix

# Run pre-commit hooks
pre-commit run --all-files
```

### Testing

```bash
# Run tests
pytest tests/

# Run with coverage
pytest --cov=src tests/
```

### Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and add tests
4. Run code quality checks
5. Submit a pull request

## Troubleshooting

### Common Issues

1. **CUDA Out of Memory**:
   - Reduce `micro_batch_size`
   - Enable `gradient_checkpointing`
   - Use smaller sequence length

2. **Model Loading Issues**:
   - Verify model name/path
   - Check Hugging Face token permissions
   - Ensure sufficient disk space

3. **Training Instability**:
   - Adjust learning rate
   - Modify warmup steps
   - Check data quality

### Performance Optimization

- **Memory**: Use gradient checkpointing and smaller batch sizes
- **Speed**: Enable flash attention if supported
- **Quality**: Experiment with different LoRA ranks and alpha values

## License

[Add your license information here]

## Citation

If you use this project in your research, please cite:

```bibtex
@misc{qlorax2024,
  title={Automating QLoRA Fine-Tuning and Deployment},
  author={[Your Name]},
  year={2024},
  url={[Your Repository URL]}
}
```

## Acknowledgments

- [Axolotl](https://github.com/OpenAccess-AI-Collective/axolotl) - Fine-tuning framework
- [QLoRA](https://arxiv.org/abs/2305.14314) - Efficient fine-tuning methodology  
- [Hugging Face](https://huggingface.co/) - Transformers and model ecosystem
- [TinyLlama](https://github.com/jzhang38/TinyLlama) - Base model for experimentation

---

For detailed API documentation and advanced usage examples, please refer to the [docs/](docs/) directory.