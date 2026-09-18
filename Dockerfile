# 使用 CUDA 12.1 开发版作为基础镜像
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

# 关键修复 1：安装原生支持 Tesla P100 (sm_60) 算力的 PyTorch 2.1.0
RUN pip install --upgrade pip setuptools wheel \
    && pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121

COPY requirements.txt .

# 关键修复 2：剔除不支持 P100 的 flash-attn，使用 PyTorch 原生 SDPA 算子
RUN grep -v "flash-attn" requirements.txt > requirements_p100.txt \
    && pip install -r requirements_p100.txt

COPY . .

EXPOSE 7870 8002

# 启动脚本
CMD ["python", "webui_enhanced.py"]
