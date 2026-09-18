FROM nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

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

# 创建并激活虚拟环境
RUN python3.10 -m venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# 安装支持 P100 (sm_60) 的 PyTorch 2.1.0
RUN pip install --upgrade pip setuptools wheel \
    && pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121

COPY . .

# 关键：显式把 gradio, pandas 等 WebUI 必须包一次性装全
RUN pip install --no-build-isolation -e . \
    && pip install pandas gradio \
    && pip uninstall -y flash-attn || true

EXPOSE 7860

# 明确启动端口为 7860
CMD ["python", "webui.py", "--host", "0.0.0.0", "--port", "7860"]
