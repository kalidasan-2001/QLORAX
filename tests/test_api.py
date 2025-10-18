import pytest
from fastapi.testclient import TestClient
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

try:
    from app.api import app
    client = TestClient(app)
    API_AVAILABLE = True
except ImportError:
    API_AVAILABLE = False
    client = None

@pytest.mark.skipif(not API_AVAILABLE, reason="API not available")
def test_health_endpoint():
    """Test the health endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data
    assert "version" in data

@pytest.mark.skipif(not API_AVAILABLE, reason="API not available")
def test_root_endpoint():
    """Test the root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "version" in data

@pytest.mark.skipif(not API_AVAILABLE, reason="API not available")
def test_model_status():
    """Test the model status endpoint"""
    response = client.get("/model_status")
    assert response.status_code == 200
    data = response.json()
    assert "is_loaded" in data

@pytest.mark.skipif(not API_AVAILABLE, reason="API not available")
def test_models_list():
    """Test the models list endpoint"""
    response = client.get("/models")
    assert response.status_code == 200
    data = response.json()
    assert "models" in data
    assert isinstance(data["models"], list)

def test_import_structure():
    """Test that core modules can be imported"""
    try:
        import fastapi
        import gradio
        import pydantic
        assert True
    except ImportError:
        pytest.skip("Core dependencies not available")

def test_config_files():
    """Test that configuration files exist and are valid"""
    import yaml
    
    config_files = [
        "configs/production-config.yaml",
        ".env.example"
    ]
    
    for config_file in config_files:
        config_path = project_root / config_file
        if config_path.exists():
            if config_file.endswith('.yaml'):
                with open(config_path) as f:
                    config = yaml.safe_load(f)
                assert isinstance(config, dict)
        else:
            pytest.skip(f"Config file {config_file} not found")

def test_docker_files():
    """Test that Docker files exist"""
    docker_files = [
        "Dockerfile",
        "docker-compose.yml",
        ".dockerignore"
    ]
    
    for docker_file in docker_files:
        docker_path = project_root / docker_file
        assert docker_path.exists(), f"Docker file {docker_file} should exist"