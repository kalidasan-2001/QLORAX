@echo off
REM QLORAX Docker Management Script for Windows
REM This script provides easy management of the QLORAX Docker environment

setlocal enabledelayedexpansion

REM Configuration
set PROJECT_NAME=qlorax
set DOCKER_COMPOSE_FILE=docker-compose.yml

REM Functions
:print_header
echo ============================================
echo            QLORAX Docker Manager           
echo ============================================
goto :eof

:print_success
echo [SUCCESS] %~1
goto :eof

:print_warning
echo [WARNING] %~1
goto :eof

:print_error
echo [ERROR] %~1
goto :eof

:print_info
echo [INFO] %~1
goto :eof

:check_requirements
call :print_info "Checking requirements..."

docker --version >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker is not installed. Please install Docker Desktop first."
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker Compose is not available. Please ensure Docker Desktop is running."
    exit /b 1
)

if not exist "%DOCKER_COMPOSE_FILE%" (
    call :print_error "docker-compose.yml not found in current directory."
    exit /b 1
)

call :print_success "All requirements met"
goto :eof

:prepare_directories
call :print_info "Preparing directories..."

if not exist "data" mkdir data
if not exist "models" mkdir models
if not exist "outputs" mkdir outputs
if not exist "logs" mkdir logs
if not exist "docker\grafana" mkdir docker\grafana
if not exist "docker\prometheus" mkdir docker\prometheus

call :print_success "Directories prepared"
goto :eof

:build_images
call :print_info "Building Docker images..."
docker-compose build --no-cache
if errorlevel 1 (
    call :print_error "Failed to build images"
    exit /b 1
)
call :print_success "Images built successfully"
goto :eof

:start_services
set profile=%~1
call :print_info "Starting QLORAX services..."

if "%profile%"=="" (
    docker-compose up -d
) else (
    docker-compose --profile %profile% up -d
)

if errorlevel 1 (
    call :print_error "Failed to start services"
    exit /b 1
)

call :print_success "Services started"
call :print_info "FastAPI: http://localhost:8000"
call :print_info "Gradio: http://localhost:7860"

if "%profile%"=="monitoring" (
    call :print_info "Grafana: http://localhost:3000 (admin/admin)"
    call :print_info "Prometheus: http://localhost:9090"
)

if "%profile%"=="full" (
    call :print_info "Grafana: http://localhost:3000 (admin/admin)"
    call :print_info "Prometheus: http://localhost:9090"
    call :print_info "Redis: localhost:6379"
)

goto :eof

:stop_services
call :print_info "Stopping QLORAX services..."
docker-compose down
if errorlevel 1 (
    call :print_error "Failed to stop services"
    exit /b 1
)
call :print_success "Services stopped"
goto :eof

:restart_services
call :print_info "Restarting QLORAX services..."
docker-compose restart
if errorlevel 1 (
    call :print_error "Failed to restart services"
    exit /b 1
)
call :print_success "Services restarted"
goto :eof

:show_logs
set service=%~1
if "%service%"=="" set service=qlorax
call :print_info "Showing logs for %service%..."
docker-compose logs -f %service%
goto :eof

:show_status
call :print_info "Service status:"
docker-compose ps

call :print_info ""
call :print_info "Health checks:"
docker-compose exec qlorax curl -f http://localhost:8000/health >nul 2>&1
if errorlevel 1 (
    call :print_warning "Health check failed"
) else (
    call :print_success "Health check passed"
)
goto :eof

:cleanup
call :print_info "Cleaning up Docker resources..."
docker-compose down -v --remove-orphans
docker system prune -f
call :print_success "Cleanup completed"
goto :eof

:backup_data
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "backup_dir=backups\%YYYY%%MM%%DD%_%HH%%Min%%Sec%"

call :print_info "Creating backup in %backup_dir%..."

if not exist backups mkdir backups
mkdir "%backup_dir%"

if exist "data" xcopy /E /I data "%backup_dir%\data" >nul
if exist "models" xcopy /E /I models "%backup_dir%\models" >nul
if exist "outputs" xcopy /E /I outputs "%backup_dir%\outputs" >nul
if exist "configs" xcopy /E /I configs "%backup_dir%\configs" >nul

call :print_success "Backup created at %backup_dir%"
goto :eof

:restore_data
set backup_dir=%~1

if "%backup_dir%"=="" (
    call :print_error "Please specify backup directory"
    exit /b 1
)

if not exist "%backup_dir%" (
    call :print_error "Backup directory %backup_dir% not found"
    exit /b 1
)

call :print_info "Restoring from %backup_dir%..."

REM Stop services first
docker-compose down

REM Restore data
if exist "%backup_dir%\data" (
    if exist "data" rmdir /S /Q data
    xcopy /E /I "%backup_dir%\data" data >nul
)

if exist "%backup_dir%\models" (
    if exist "models" rmdir /S /Q models
    xcopy /E /I "%backup_dir%\models" models >nul
)

if exist "%backup_dir%\outputs" (
    if exist "outputs" rmdir /S /Q outputs
    xcopy /E /I "%backup_dir%\outputs" outputs >nul
)

call :print_success "Data restored from %backup_dir%"
goto :eof

:run_training
call :print_info "Starting training in container..."
docker-compose exec qlorax python scripts/train_production.py
goto :eof

:run_demo
call :print_info "Starting interactive demo..."
docker-compose exec qlorax python complete_demo.py
goto :eof

:enter_container
call :print_info "Entering QLORAX container..."
docker-compose exec qlorax cmd
goto :eof

:show_help
call :print_header
echo Usage: %~nx0 [COMMAND] [OPTIONS]
echo.
echo Commands:
echo   setup                  Setup and start QLORAX (first time)
echo   start [profile]        Start services (profiles: dev, full, monitoring)
echo   stop                   Stop all services
echo   restart                Restart all services
echo   status                 Show service status
echo   logs [service]         Show logs (default: qlorax)
echo   build                  Build Docker images
echo   train                  Run training in container
echo   demo                   Run interactive demo
echo   shell                  Enter container shell
echo   backup                 Backup data and models
echo   restore ^<backup_dir^>   Restore from backup
echo   cleanup                Clean up Docker resources
echo   help                   Show this help
echo.
echo Profiles:
echo   default               Basic QLORAX services
echo   dev                   Development environment
echo   full                  Include Redis caching
echo   monitoring            Include Prometheus + Grafana
echo.
echo Examples:
echo   %~nx0 setup                    # First time setup
echo   %~nx0 start                    # Start basic services
echo   %~nx0 start monitoring         # Start with monitoring
echo   %~nx0 logs qlorax              # Show main service logs
echo   %~nx0 backup                   # Create backup
goto :eof

REM Main script logic
set command=%~1
if "%command%"=="" set command=help

if "%command%"=="setup" (
    call :print_header
    call :check_requirements
    if errorlevel 1 exit /b 1
    call :prepare_directories
    call :build_images
    if errorlevel 1 exit /b 1
    call :start_services
) else if "%command%"=="start" (
    call :check_requirements
    if errorlevel 1 exit /b 1
    call :start_services %~2
) else if "%command%"=="stop" (
    call :stop_services
) else if "%command%"=="restart" (
    call :restart_services
) else if "%command%"=="status" (
    call :show_status
) else if "%command%"=="logs" (
    call :show_logs %~2
) else if "%command%"=="build" (
    call :check_requirements
    if errorlevel 1 exit /b 1
    call :build_images
) else if "%command%"=="train" (
    call :run_training
) else if "%command%"=="demo" (
    call :run_demo
) else if "%command%"=="shell" (
    call :enter_container
) else if "%command%"=="backup" (
    call :backup_data
) else if "%command%"=="restore" (
    call :restore_data %~2
) else if "%command%"=="cleanup" (
    call :cleanup
) else if "%command%"=="help" (
    call :show_help
) else (
    call :print_error "Unknown command: %command%"
    call :show_help
    exit /b 1
)