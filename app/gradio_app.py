"""
QLORAX Gradio Interface
User-friendly web interface for the QLORAX platform
"""

import os
import sys
import time
from pathlib import Path

# Add project root to Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

try:
    import gradio as gr
    import requests
except ImportError:
    print("Installing Gradio...")
    os.system("pip install gradio")
    import gradio as gr
    import requests

# Configuration
API_BASE_URL = "http://localhost:8000"

def chat_with_model(message, history, max_length, temperature, top_p):
    """Chat interface function"""
    if not message.strip():
        return history, ""
    
    try:
        # Add user message to history
        history.append([message, None])
        
        # Call API
        response = requests.post(
            f"{API_BASE_URL}/chat",
            json={
                "message": message,
                "max_length": int(max_length),
                "temperature": float(temperature),
                "top_p": float(top_p)
            },
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            bot_response = result["response"]
            processing_time = result["processing_time"]
            
            # Add bot response to history
            history[-1][1] = f"{bot_response}\n\n*Processing time: {processing_time:.2f}s*"
        else:
            history[-1][1] = f"Error: {response.status_code} - {response.text}"
            
    except requests.exceptions.RequestException as e:
        history[-1][1] = f"Connection error: {str(e)}"
    except Exception as e:
        history[-1][1] = f"Error: {str(e)}"
    
    return history, ""

def get_model_status():
    """Get current model status"""
    try:
        response = requests.get(f"{API_BASE_URL}/model_status", timeout=5)
        if response.status_code == 200:
            status = response.json()
            return f"Model: {status.get('model_name', 'Unknown')}\nLoaded: {status.get('is_loaded', False)}"
        else:
            return f"Error getting status: {response.status_code}"
    except Exception as e:
        return f"Connection error: {str(e)}"

def get_health_status():
    """Get health status"""
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=5)
        if response.status_code == 200:
            health = response.json()
            return f"Status: {health['status']}\nVersion: {health['version']}\nEnvironment: {health['environment']}"
        else:
            return f"Error: {response.status_code}"
    except Exception as e:
        return f"Connection error: {str(e)}"

def load_model(model_path):
    """Load model"""
    try:
        data = {"model_path": model_path} if model_path.strip() else {}
        response = requests.post(f"{API_BASE_URL}/load_model", json=data, timeout=60)
        
        if response.status_code == 200:
            result = response.json()
            return f"Success: {result['message']}"
        else:
            return f"Error: {response.status_code} - {response.text}"
    except Exception as e:
        return f"Error: {str(e)}"

def start_training(config_path):
    """Start training"""
    try:
        data = {"config_path": config_path} if config_path.strip() else {}
        response = requests.post(f"{API_BASE_URL}/train", json=data, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            return f"Training started: {result['message']}"
        else:
            return f"Error: {response.status_code} - {response.text}"
    except Exception as e:
        return f"Error: {str(e)}"

def get_training_status():
    """Get training status"""
    try:
        response = requests.get(f"{API_BASE_URL}/train/status", timeout=5)
        if response.status_code == 200:
            status = response.json()
            return f"Status: {status['status']}\nMessage: {status['message']}"
        else:
            return f"Error: {response.status_code}"
    except Exception as e:
        return f"Connection error: {str(e)}"

def list_available_models():
    """List available models"""
    try:
        response = requests.get(f"{API_BASE_URL}/models", timeout=10)
        if response.status_code == 200:
            models = response.json()["models"]
            model_list = []
            for model in models:
                model_list.append(f"• {model['name']} ({model['type']}) - {model['path']}")
            return "\n".join(model_list)
        else:
            return f"Error: {response.status_code}"
    except Exception as e:
        return f"Error: {str(e)}"

# Create Gradio interface
def create_interface():
    """Create the main Gradio interface"""
    
    with gr.Blocks(title="QLORAX MLOps Platform", theme=gr.themes.Soft()) as interface:
        gr.Markdown("# 🚀 QLORAX MLOps Platform")
        gr.Markdown("Production-ready QLoRA fine-tuning and inference platform")
        
        with gr.Tabs():
            # Chat Tab
            with gr.TabItem("💬 Chat"):
                gr.Markdown("## Chat with Fine-tuned Model")
                
                with gr.Row():
                    with gr.Column(scale=3):
                        chatbot = gr.Chatbot(height=400, label="Conversation")
                        msg = gr.Textbox(label="Your message", placeholder="Type your message here...")
                        
                        with gr.Row():
                            send_btn = gr.Button("Send", variant="primary")
                            clear_btn = gr.Button("Clear")
                    
                    with gr.Column(scale=1):
                        gr.Markdown("### Settings")
                        max_length = gr.Slider(10, 200, value=100, label="Max Length")
                        temperature = gr.Slider(0.1, 2.0, value=0.7, label="Temperature")
                        top_p = gr.Slider(0.1, 1.0, value=0.9, label="Top-p")
                        
                        gr.Markdown("### Model Status")
                        status_display = gr.Textbox(label="Status", interactive=False)
                        refresh_status_btn = gr.Button("Refresh Status")
                
                # Chat functionality
                send_btn.click(
                    chat_with_model,
                    inputs=[msg, chatbot, max_length, temperature, top_p],
                    outputs=[chatbot, msg]
                )
                msg.submit(
                    chat_with_model,
                    inputs=[msg, chatbot, max_length, temperature, top_p],
                    outputs=[chatbot, msg]
                )
                clear_btn.click(lambda: ([], ""), outputs=[chatbot, msg])
                refresh_status_btn.click(get_model_status, outputs=status_display)
            
            # Model Management Tab
            with gr.TabItem("🤖 Model Management"):
                gr.Markdown("## Model Management")
                
                with gr.Row():
                    with gr.Column():
                        gr.Markdown("### Load Model")
                        model_path_input = gr.Textbox(
                            label="Model Path",
                            placeholder="Leave empty for auto-detection or enter custom path",
                            value=""
                        )
                        load_model_btn = gr.Button("Load Model", variant="primary")
                        load_result = gr.Textbox(label="Load Result", interactive=False)
                    
                    with gr.Column():
                        gr.Markdown("### Available Models")
                        models_display = gr.Textbox(label="Models", interactive=False, lines=10)
                        list_models_btn = gr.Button("Refresh Model List")
                
                load_model_btn.click(load_model, inputs=model_path_input, outputs=load_result)
                list_models_btn.click(list_available_models, outputs=models_display)
            
            # Training Tab
            with gr.TabItem("🏋️ Training"):
                gr.Markdown("## Model Training")
                
                with gr.Row():
                    with gr.Column():
                        gr.Markdown("### Start Training")
                        config_path_input = gr.Textbox(
                            label="Config Path",
                            value="configs/production-config.yaml",
                            placeholder="Path to training configuration"
                        )
                        start_training_btn = gr.Button("Start Training", variant="primary")
                        training_result = gr.Textbox(label="Training Result", interactive=False)
                    
                    with gr.Column():
                        gr.Markdown("### Training Status")
                        training_status_display = gr.Textbox(label="Status", interactive=False, lines=5)
                        refresh_training_btn = gr.Button("Refresh Status")
                
                start_training_btn.click(start_training, inputs=config_path_input, outputs=training_result)
                refresh_training_btn.click(get_training_status, outputs=training_status_display)
            
            # System Tab
            with gr.TabItem("⚙️ System"):
                gr.Markdown("## System Information")
                
                with gr.Row():
                    with gr.Column():
                        gr.Markdown("### Health Status")
                        health_display = gr.Textbox(label="Health", interactive=False, lines=5)
                        refresh_health_btn = gr.Button("Refresh Health")
                    
                    with gr.Column():
                        gr.Markdown("### API Endpoints")
                        gr.Markdown(f"""
                        - **API Base**: {API_BASE_URL}
                        - **Documentation**: {API_BASE_URL}/docs
                        - **Health Check**: {API_BASE_URL}/health
                        - **Chat API**: {API_BASE_URL}/chat
                        """)
                
                refresh_health_btn.click(get_health_status, outputs=health_display)
        
        # Auto-refresh status on load
        interface.load(get_model_status, outputs=status_display)
        interface.load(get_health_status, outputs=health_display)
    
    return interface

if __name__ == "__main__":
    # Wait for API to be ready
    print("Waiting for API to be ready...")
    for i in range(30):  # Wait up to 30 seconds
        try:
            response = requests.get(f"{API_BASE_URL}/health", timeout=2)
            if response.status_code == 200:
                print("API is ready!")
                break
        except:
            pass
        time.sleep(1)
    else:
        print("Warning: API might not be ready, but starting Gradio anyway...")
    
    # Create and launch interface
    interface = create_interface()
    interface.launch(
        server_name="0.0.0.0",
        server_port=7860,
        share=False,
        debug=True
    )