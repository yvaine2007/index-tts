# 使用 CUDA 12.1 开发版基础镜像
FROM nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# 安装系统基础依赖与 Python 3.10
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3-pip \
    python3.10-venv \
    git \
    ffmpeg \
    libsndfile1 \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 建立虚拟环境
RUN python3.10 -m venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# 1. 先安装适配 Tesla P100 (sm_60) 的 PyTorch 2.1.0 套件
RUN pip install --upgrade pip setuptools wheel \
    && pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121

COPY . .

# 2. 安装项目基础依赖，并补充 WebUI 所需的 pandas、gradio 等包
RUN pip install --no-build-isolation -e . \
    && pip install pandas gradio \
    && pip uninstall -y flash-attn || true

EXPOSE 7870 8002

CMD ["python", "webui.py"]
