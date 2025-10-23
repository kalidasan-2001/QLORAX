from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel
import torch
import os
import argparse

def merge_lora(base_model_name, lora_model_path, output_dir):
    print(f"Loading base model: {base_model_name}")
    base_model = AutoModelForCausalLM.from_pretrained(
        base_model_name,
        torch_dtype=torch.float32,
        device_map="cpu",
        trust_remote_code=False
    )
    tokenizer = AutoTokenizer.from_pretrained(base_model_name)

    print(f"Loading LoRA model from: {lora_model_path}")
    model = PeftModel.from_pretrained(base_model, lora_model_path)
    print("Merging LoRA weights with base model...")
    model = model.merge_and_unload()

    print(f"Saving merged model to: {output_dir}")
    model.save_pretrained(output_dir)
    tokenizer.save_pretrained(output_dir)
    print("Done!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Merge LoRA weights with base model")
    parser.add_argument("--base-model", required=True, help="Base model name or path")
    parser.add_argument("--lora-model", required=True, help="LoRA model path")
    parser.add_argument("--output-dir", required=True, help="Output directory for merged model")
    
    args = parser.parse_args()
    merge_lora(args.base_model, args.lora_model, args.output_dir)