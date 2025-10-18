@echo off
REM Windows batch script to run QLORAX training
echo Starting QLORAX QLoRA Fine-tuning...
echo =====================================

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Run training
python -m axolotl.cli.train configs\default-qlora-config.yml

echo Training completed!
pause