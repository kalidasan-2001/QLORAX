@echo off
REM QLORAX Docker Build and Push Script

echo Building QLORAX Docker image...
docker build -t qlorax:latest .

if %ERRORLEVEL% neq 0 (
    echo Error building Docker image
    exit /b 1
)

echo Testing Docker image...
docker run --rm --name qlorax-test -d -p 8000:8000 -p 7860:7860 qlorax:latest
timeout /t 30 /nobreak

REM Test health endpoint
curl -f http://localhost:8000/health
if %ERRORLEVEL% neq 0 (
    echo Health check failed
    docker stop qlorax-test
    exit /b 1
)

echo Stopping test container...
docker stop qlorax-test

echo Build and test successful!
echo To run the container:
echo docker run -d --name qlorax -p 8000:8000 -p 7860:7860 ^
echo            -v %cd%/data:/app/data ^
echo            -v %cd%/models:/app/models ^
echo            -v %cd%/outputs:/app/outputs ^
echo            qlorax:latest