"""
QLORAX FastAPI Application
Production-ready API for the QLORAX MLOps platform
"""

import os
import sys
import time
import logging
from pathlib import Path
from typing import Dict, List, Optional, Any
import traceback

# Add project root to Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

try:
    from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import JSONResponse
    from pydantic import BaseModel
    import uvicorn
except ImportError as e:
    print(f"Error importing FastAPI dependencies: {e}")
    print("Installing required packages...")
    os.system("pip install fastapi uvicorn[standard] pydantic")
    from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import JSONResponse
    from pydantic import BaseModel
    import uvicorn

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# FastAPI app
app = FastAPI(
    title="QLORAX MLOps Platform",
    description="Production-ready API for QLoRA fine-tuning and inference",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables for model management
model_manager = None
training_status = {"status": "idle", "message": "No training in progress"}

# Pydantic models
class HealthResponse(BaseModel):
    status: str
    timestamp: float
    version: str
    environment: str
    python_version: str
    dependencies: Dict[str, str]

class ChatRequest(BaseModel):
    message: str
    max_length: Optional[int] = 100
    temperature: Optional[float] = 0.7
    top_p: Optional[float] = 0.9

class ChatResponse(BaseModel):
    response: str
    processing_time: float
    model_name: str

class TrainingRequest(BaseModel):
    config_path: Optional[str] = "configs/production-config.yaml"
    dataset_path: Optional[str] = None
    output_dir: Optional[str] = "outputs/production_training"

class TrainingStatus(BaseModel):
    status: str
    message: str
    progress: Optional[float] = None
    logs: Optional[List[str]] = None

# Model Manager Class
class ModelManager:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.model_name = None
        self.is_loaded = False
        
    def load_model(self, model_path: str = None):
        """Load the trained model for inference"""
        try:
            import torch
            from transformers import AutoTokenizer, AutoModelForCausalLM
            from peft import PeftModel
            
            # Determine model path
            if model_path is None:
                # Look for trained model
                possible_paths = [
                    "outputs/production_training/final_model",
                    "models/fine_tuned_model",
                    "microsoft/DialoGPT-medium"  # fallback to base model
                ]
                
                for path in possible_paths:
                    if os.path.exists(path) or path.startswith("microsoft/"):
                        model_path = path
                        break
            
            logger.info(f"Loading model from: {model_path}")
            
            # Load tokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(model_path)
            if self.tokenizer.pad_token is None:
                self.tokenizer.pad_token = self.tokenizer.eos_token
            
            # Load model
            if os.path.exists(model_path) and "adapter_config.json" in os.listdir(model_path):
                # Load PEFT model
                base_model = AutoModelForCausalLM.from_pretrained(
                    "microsoft/DialoGPT-medium",
                    torch_dtype=torch.float32,
                    device_map="cpu"
                )
                self.model = PeftModel.from_pretrained(base_model, model_path)
            else:
                # Load regular model
                self.model = AutoModelForCausalLM.from_pretrained(
                    model_path,
                    torch_dtype=torch.float32,
                    device_map="cpu"
                )
            
            self.model_name = model_path
            self.is_loaded = True
            logger.info("Model loaded successfully")
            
        except Exception as e:
            logger.error(f"Error loading model: {e}")
            self.is_loaded = False
            raise
    
    def generate_response(self, message: str, max_length: int = 100, 
                         temperature: float = 0.7, top_p: float = 0.9) -> str:
        """Generate response using the loaded model"""
        if not self.is_loaded:
            raise HTTPException(status_code=503, detail="Model not loaded")
        
        try:
            import torch
            
            # Tokenize input
            inputs = self.tokenizer.encode(message + self.tokenizer.eos_token, 
                                         return_tensors="pt")
            
            # Generate response
            with torch.no_grad():
                outputs = self.model.generate(
                    inputs,
                    max_length=inputs.shape[1] + max_length,
                    temperature=temperature,
                    top_p=top_p,
                    do_sample=True,
                    pad_token_id=self.tokenizer.eos_token_id
                )
            
            # Decode response
            response = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
            
            # Extract only the generated part
            response = response[len(message):].strip()
            
            return response
            
        except Exception as e:
            logger.error(f"Error generating response: {e}")
            raise HTTPException(status_code=500, detail=f"Generation error: {str(e)}")

# Initialize model manager
def get_model_manager():
    global model_manager
    if model_manager is None:
        model_manager = ModelManager()
        try:
            model_manager.load_model()
        except Exception as e:
            logger.warning(f"Could not load model on startup: {e}")
    return model_manager

# API Endpoints
@app.get("/", response_model=Dict[str, str])
async def root():
    """Root endpoint"""
    return {
        "message": "QLORAX MLOps Platform API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    try:
        import torch
        import transformers
        import peft
        
        dependencies = {
            "torch": torch.__version__,
            "transformers": transformers.__version__,
            "peft": peft.__version__
        }
    except ImportError:
        dependencies = {"error": "Some dependencies not available"}
    
    return HealthResponse(
        status="healthy",
        timestamp=time.time(),
        version="1.0.0",
        environment=os.getenv("QLORAX_ENV", "production"),
        python_version=sys.version,
        dependencies=dependencies
    )

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest, manager: ModelManager = Depends(get_model_manager)):
    """Chat with the fine-tuned model"""
    start_time = time.time()
    
    try:
        response = manager.generate_response(
            request.message,
            request.max_length,
            request.temperature,
            request.top_p
        )
        
        processing_time = time.time() - start_time
        
        return ChatResponse(
            response=response,
            processing_time=processing_time,
            model_name=manager.model_name or "unknown"
        )
        
    except Exception as e:
        logger.error(f"Chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/load_model")
async def load_model(model_path: Optional[str] = None, 
                    manager: ModelManager = Depends(get_model_manager)):
    """Load or reload the model"""
    try:
        manager.load_model(model_path)
        return {"status": "success", "message": f"Model loaded from {manager.model_name}"}
    except Exception as e:
        logger.error(f"Model loading error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/model_status")
async def model_status(manager: ModelManager = Depends(get_model_manager)):
    """Get current model status"""
    return {
        "is_loaded": manager.is_loaded,
        "model_name": manager.model_name,
        "model_type": type(manager.model).__name__ if manager.model else None
    }

@app.post("/train")
async def start_training(request: TrainingRequest, background_tasks: BackgroundTasks):
    """Start model training in background"""
    global training_status
    
    if training_status["status"] == "training":
        raise HTTPException(status_code=409, detail="Training already in progress")
    
    def run_training():
        global training_status
        try:
            training_status = {"status": "training", "message": "Training started"}
            
            # Import and run training
            sys.path.append(str(project_root))
            from scripts.train_production import main as train_main
            
            # Run training
            config_path = request.config_path or "configs/production-config.yaml"
            train_main(config_path)
            
            training_status = {"status": "completed", "message": "Training completed successfully"}
            
        except Exception as e:
            training_status = {"status": "error", "message": f"Training failed: {str(e)}"}
            logger.error(f"Training error: {e}")
    
    background_tasks.add_task(run_training)
    training_status = {"status": "starting", "message": "Training task queued"}
    
    return {"status": "success", "message": "Training started in background"}

@app.get("/train/status", response_model=TrainingStatus)
async def training_status_endpoint():
    """Get current training status"""
    global training_status
    return TrainingStatus(**training_status)

@app.get("/models")
async def list_models():
    """List available models"""
    models = []
    
    # Check for trained models
    model_dirs = [
        "outputs/production_training",
        "models",
        "checkpoints"
    ]
    
    for model_dir in model_dirs:
        if os.path.exists(model_dir):
            for item in os.listdir(model_dir):
                item_path = os.path.join(model_dir, item)
                if os.path.isdir(item_path):
                    models.append({
                        "name": item,
                        "path": item_path,
                        "type": "local"
                    })
    
    # Add base models
    base_models = [
        "microsoft/DialoGPT-medium",
        "microsoft/DialoGPT-small",
        "microsoft/DialoGPT-large"
    ]
    
    for model in base_models:
        models.append({
            "name": model,
            "path": model,
            "type": "huggingface"
        })
    
    return {"models": models}

@app.get("/metrics")
async def get_metrics():
    """Get system metrics"""
    try:
        import psutil
        
        return {
            "cpu_percent": psutil.cpu_percent(),
            "memory_percent": psutil.virtual_memory().percent,
            "disk_usage": psutil.disk_usage('/').percent,
            "timestamp": time.time()
        }
    except ImportError:
        return {"error": "psutil not available"}

# Error handlers
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Global exception: {exc}")
    logger.error(traceback.format_exc())
    return JSONResponse(
        status_code=500,
        content={"detail": f"Internal server error: {str(exc)}"}
    )

# Main execution
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="QLORAX FastAPI Server")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8000, help="Port to bind to")
    parser.add_argument("--workers", type=int, default=1, help="Number of workers")
    parser.add_argument("--dev", action="store_true", help="Development mode")
    parser.add_argument("--reload", action="store_true", help="Auto-reload on changes")
    
    args = parser.parse_args()
    
    # Configure for development or production
    if args.dev or args.reload:
        logger.info("Starting in development mode")
        uvicorn.run(
            "app.api:app",
            host=args.host,
            port=args.port,
            reload=True,
            log_level="debug"
        )
    else:
        logger.info("Starting in production mode")
        uvicorn.run(
            app,
            host=args.host,
            port=args.port,
            workers=args.workers,
            log_level="info"
        )