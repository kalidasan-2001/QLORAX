@echo off
REM QLORAX Quick Start Script for Windows
REM One-command setup for QLORAX Docker deployment

setlocal enabledelayedexpansion

REM Functions
:print_header
echo ============================================
echo         QLORAX Quick Start Setup          
echo ============================================
goto :eof

:print_success
echo [SUCCESS] %~1
goto :eof

:print_info
echo [INFO] %~1
goto :eof

:print_warning
echo [WARNING] %~1
goto :eof

:print_error
echo [ERROR] %~1
goto :eof

:check_docker
call :print_info "Checking Docker installation..."

docker --version >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker is not installed"
    echo Please install Docker Desktop from: https://docker.com/get-started
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker is not running"
    echo Please start Docker Desktop
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker Compose is not available"
    echo Please ensure Docker Desktop includes Docker Compose
    exit /b 1
)

call :print_success "Docker is ready"
goto :eof

:setup_environment
call :print_info "Setting up environment..."

if not exist ".env" (
    copy .env.example .env >nul
    call :print_success "Created .env file from template"
) else (
    call :print_info ".env file already exists"
)

if not exist "data" mkdir data
if not exist "models" mkdir models
if not exist "outputs" mkdir outputs
if not exist "logs" mkdir logs

call :print_success "Created necessary directories"
goto :eof

:build_and_start
call :print_info "Building and starting QLORAX..."

docker-compose build
if errorlevel 1 (
    call :print_error "Failed to build Docker images"
    exit /b 1
)

docker-compose up -d
if errorlevel 1 (
    call :print_error "Failed to start services"
    exit /b 1
)

call :print_success "QLORAX services started"
goto :eof

:wait_for_services
call :print_info "Waiting for services to be ready..."

REM Wait for API (up to 2 minutes)
set /a counter=0
:wait_api
set /a counter+=1
curl -s -f http://localhost:8000/health >nul 2>&1
if not errorlevel 1 (
    call :print_success "FastAPI is ready"
    goto wait_gradio
)

if %counter% geq 60 (
    call :print_warning "API took longer than expected to start"
    goto wait_gradio
)

timeout /t 2 /nobreak >nul
goto wait_api

:wait_gradio
REM Wait for Gradio (up to 1 minute)
set /a counter=0
:wait_gradio_loop
set /a counter+=1
curl -s -f http://localhost:7860 >nul 2>&1
if not errorlevel 1 (
    call :print_success "Gradio interface is ready"
    goto :eof
)

if %counter% geq 30 (
    call :print_warning "Gradio took longer than expected to start"
    goto :eof
)

timeout /t 2 /nobreak >nul
goto wait_gradio_loop

:show_status
call :print_info "Service status:"
docker-compose ps

echo.
call :print_info "Health check:"
curl -s -f http://localhost:8000/health >nul 2>&1
if not errorlevel 1 (
    call :print_success "API health check passed"
) else (
    call :print_warning "API health check failed"
)
goto :eof

:show_access_info
echo.
echo ============================================
echo          QLORAX is Ready! 🚀              
echo ============================================
echo.
echo Access your QLORAX platform:
echo   • Web Interface: http://localhost:7860
echo   • API Docs:      http://localhost:8000/docs
echo   • Health Check:  http://localhost:8000/health
echo.
echo Management commands:
echo   • View logs:     docker\manage.bat logs
echo   • Stop services: docker\manage.bat stop
echo   • Restart:       docker\manage.bat restart
echo   • Enter shell:   docker\manage.bat shell
echo.
echo Training commands:
echo   • Start training: docker\manage.bat train
echo   • Run demo:       docker\manage.bat demo
echo.
echo ============================================
goto :eof

:main
call :print_header

REM Check requirements
call :check_docker
if errorlevel 1 exit /b 1

REM Setup environment
call :setup_environment

REM Build and start
call :build_and_start
if errorlevel 1 exit /b 1

REM Wait for services
call :wait_for_services

REM Show status
call :show_status

REM Show access information
call :show_access_info
goto :eof

REM Handle script arguments
set command=%~1
if "%command%"=="" set command=setup

if "%command%"=="setup" (
    call :main
) else if "%command%"=="start" (
    call :main
) else if "%command%"=="status" (
    call :show_status
) else if "%command%"=="info" (
    call :show_access_info
) else if "%command%"=="help" (
    echo QLORAX Quick Start Script
    echo.
    echo Usage: %~nx0 [COMMAND]
    echo.
    echo Commands:
    echo   setup    Complete setup and start (default)
    echo   start    Same as setup
    echo   status   Show current status
    echo   info     Show access information
    echo   help     Show this help
) else (
    call :print_error "Unknown command: %command%"
    echo Use '%~nx0 help' for usage information
    exit /b 1
)