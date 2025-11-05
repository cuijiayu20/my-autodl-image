# ------------------------------------------------------------------
# 【最终版 v3】完整的 PyTorch + Conda + Jupyter 镜像
# (修复了 locale 和 tzdata 问题)
# ------------------------------------------------------------------

# 1. 从 NVIDIA 官方 CUDA 11.3 + cuDNN 8 镜像开始
FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

# 2. 设置非交互式安装，并安装基础依赖
# 【【已修改：添加了 'tzdata' 用于设置时区】】
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    python3 \
    python3-pip \
    git \
    vim \
    wget \
    curl \
    ca-certificates \
    locales \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. 【来自您】更完善的 SSH 配置
RUN mkdir -p /var/run/sshd && \
    sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config

# 4. 【【已修改：精简版】】设置语言和时区
# (不再运行脆弱的 locale-gen，只设置环境变量和时区)
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# 5. 【来自您】安装 Miniconda
RUN cd /root && wget -q https://repo.anaconda.com/miniconda/Miniconda3-py38_4.10.3-Linux-x86_64.sh \
    && bash ./Miniconda3-py38_4.10.3-Linux-x86_64.sh -b -f -p /root/miniconda3 \
    && rm -f ./Miniconda3-py38_4.10.3-Linux-x86_64.sh \
    && echo "PATH=/root/miniconda3/bin:/usr/local/bin:$PATH" >> /etc/profile \
    && echo "source /etc/profile" >> /root/.bashrc \
    && echo "source /etc/autodl-motd" >> /root/.bashrc

# 6. 【关键】使用 Conda 里的 pip 来安装所有 Python 包
RUN /root/miniconda3/bin/pip install --no-cache-dir --upgrade \
    pip \
    jupyterlab>=3.0.0 \
    ipywidgets \
    matplotlib \
    jupyterlab_language_pack_zh_CN \
    torch==1.10.1+cu113 torchvision==0.11.2 torchaudio==0.10.1 \
    --extra-index-url https://download.pytorch.org/whl/cu113 \
    pandas \
    tqdm \
    -i https://mirrors.aliyun.com/pypi/simple

# 7. 设置工作目录
WORKDIR /root/autodl-tmp

# 8. 设置启动命令 (必须，启动 sshd)
CMD ["/usr/sbin/sshd", "-D"]