#!/usr/bin/env python3
"""
QLORAX Quick Start Script
Complete fine-tuning and benchmarking pipeline
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from datetime import datetime

def run_command(command, description, check=True):
    """Run a command with proper error handling"""
    print(f"🚀 {description}")
    print(f"📋 Command: {command}")
    
    try:
        if isinstance(command, str):
            result = subprocess.run(command, shell=True, check=check, capture_output=True, text=True)
        else:
            result = subprocess.run(command, check=check, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✅ {description} completed successfully")
            if result.stdout:
                print(f"📄 Output: {result.stdout.strip()}")
        else:
            print(f"❌ {description} failed")
            if result.stderr:
                print(f"❌ Error: {result.stderr.strip()}")
            return False
    except Exception as e:
        print(f"❌ Error running {description}: {e}")
        return False
    
    return True

def validate_setup():
    """Validate the environment setup"""
    print("\n🔍 Validating setup...")
    
    # Check if we're in the right directory
    if not Path("scripts/train_production.py").exists():
        print("❌ Please run this script from the QLORAX project root directory")
        return False
    
    # Check if virtual environment is activated
    python_path = sys.executable
    if "venv" not in python_path:
        print("⚠️  Virtual environment may not be activated")
        print(f"   Python path: {python_path}")
    
    # Check key files
    required_files = [
        "scripts/train_production.py",
        "scripts/benchmark.py", 
        "configs/production-config.yaml",
        "data/training_data.jsonl",
        "data/test_data.jsonl"
    ]
    
    missing_files = []
    for file_path in required_files:
        if not Path(file_path).exists():
            missing_files.append(file_path)
    
    if missing_files:
        print(f"❌ Missing required files: {missing_files}")
        return False
    
    print("✅ Setup validation passed")
    return True

def run_training():
    """Run production training with fallback to test config"""
    print("\n🎯 Starting Production Training")
    print("=" * 50)
    
    # Try production config first
    command = [
        sys.executable, "scripts/train_production.py",
        "--config", "configs/production-config.yaml"
    ]
    
    success = run_command(command, "Production training", check=False)
    
    if not success:
        print("\n⚠️  Production training failed. Trying with test configuration...")
        print("   (Using smaller model for compatibility)")
        
        # Fallback to test config
        command_test = [
            sys.executable, "scripts/train_production.py",
            "--config", "configs/test-config.yaml",
            "--output", "models/production-model"  # Use same output path
        ]
        
        success = run_command(command_test, "Fallback training (test config)", check=False)
        
        if success:
            print("✅ Training completed successfully with test configuration!")
            print("💡 The model is smaller but fully functional for benchmarking.")
    
    return success

def run_benchmark(model_path):
    """Run comprehensive benchmarking"""
    print("\n📊 Starting Comprehensive Benchmarking")
    print("=" * 50)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    results_dir = f"results/benchmark_{timestamp}"
    
    command = [
        sys.executable, "scripts/benchmark.py",
        "--model", model_path,
        "--test-data", "data/test_data.jsonl",
        "--output", results_dir
    ]
    
    success = run_command(command, "Model benchmarking", check=False)
    
    if success:
        print(f"📁 Results saved to: {results_dir}")
        return results_dir
    
    return None

def show_results(results_dir):
    """Display benchmark results"""
    if not results_dir or not Path(results_dir).exists():
        print("❌ No results to display")
        return
    
    results_file = Path(results_dir) / "detailed_results.json"
    if results_file.exists():
        with open(results_file, 'r') as f:
            results = json.load(f)
        
        print("\n📊 BENCHMARK RESULTS SUMMARY")
        print("=" * 50)
        print(f"🎯 Perplexity: {results.get('perplexity', 'N/A'):.2f}")
        print(f"🔤 BLEU-4: {results.get('bleu_4', 'N/A'):.2f}")
        print(f"🌹 ROUGE-L: {results.get('rouge_l', 'N/A'):.3f}")
        print(f"🧠 Semantic Similarity: {results.get('semantic_similarity', 'N/A'):.3f}")
        print(f"🎯 Exact Match: {results.get('exact_match', 'N/A'):.3f}")
        print(f"⚡ Avg Inference Time: {results.get('avg_inference_time_ms', 'N/A'):.2f} ms")
        print("=" * 50)
        
        # Show file locations
        print(f"📄 Detailed Report: {results_dir}/evaluation_report.md")
        print(f"📊 Visualizations: {results_dir}/evaluation_results.png")
        print(f"📋 Predictions: {results_dir}/predictions.json")

def main():
    """Main function"""
    print("🚀 QLORAX Complete Fine-Tuning & Benchmarking Pipeline")
    print("=" * 60)
    print("This script will:")
    print("1. Validate your setup")
    print("2. Run production training")
    print("3. Benchmark the trained model")
    print("4. Generate comprehensive results")
    print("=" * 60)
    
    # Validate setup
    if not validate_setup():
        print("\n❌ Setup validation failed. Please fix the issues above.")
        return 1
    
    # Get user confirmation
    response = input("\n🤔 Do you want to proceed with training and benchmarking? (y/N): ")
    if response.lower() not in ['y', 'yes']:
        print("👋 Goodbye!")
        return 0
    
    # Run training
    training_success = run_training()
    
    if not training_success:
        print("\n❌ Training failed. Check the logs above.")
        return 1
    
    # Check if model was created
    model_path = "models/production-model"
    if not Path(model_path).exists():
        print(f"❌ Model not found at {model_path}")
        return 1
    
    # Run benchmarking
    results_dir = run_benchmark(model_path)
    
    if not results_dir:
        print("\n❌ Benchmarking failed.")
        return 1
    
    # Show results
    show_results(results_dir)
    
    print("\n🎉 Complete pipeline finished successfully!")
    print("🎯 Your model is trained and benchmarked!")
    print("\n📋 Next steps:")
    print("1. Review the evaluation report")
    print("2. Deploy your model using scripts/api_server.py or scripts/gradio_app.py")
    print("3. Try fine-tuning with your own data")
    
    return 0

if __name__ == "__main__":
    exit(main())