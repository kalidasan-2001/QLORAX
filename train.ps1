# PowerShell script to run QLORAX training
Write-Host "Starting QLORAX QLoRA Fine-tuning..." -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Activate virtual environment
& ".\venv\Scripts\Activate.ps1"

# Run training
python -m axolotl.cli.train configs\default-qlora-config.yml

Write-Host "Training completed!" -ForegroundColor Green