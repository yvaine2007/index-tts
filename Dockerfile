FROM nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3-pip \
    git \
    ffmpeg \
    libsndfile1 \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# 1. 安装适配 P100 (sm_60) 的 PyTorch 2.1.0
RUN python3 -m pip install --upgrade pip setuptools wheel \
    && python3 -m pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121

COPY . .

# 2. 补齐 WebUI 运行及模型自动下载所需的依赖 (加入 modelscope, huggingface_hub, omegaconf, sentencepiece 等)
RUN python3 -m pip install "numpy<2.0.0" pandas gradio librosa accelerate einops transformers soundfile cn2an pypinyin WeTextProcessing modelscope huggingface_hub omegaconf sentencepiece \
    && python3 -m pip install --no-build-isolation --no-deps -e . \
    && python3 -m pip uninstall -y flash-attn || true

EXPOSE 7860

CMD ["/usr/bin/python3", "webui.py", "--host", "0.0.0.0", "--port", "7860"]
