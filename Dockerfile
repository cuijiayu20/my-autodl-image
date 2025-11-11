# ------------------------------------------------------------------
# 【最终版 v3.1】完整的 PyTorch + Conda + Jupyter + TensorBoard 镜像
# (基于您的v3版本，添加了 TensorBoard)
# ------------------------------------------------------------------

# 1. 从 NVIDIA 官方 CUDA 11.3 + cuDNN 8 开发镜像开始
# (已包含完整的 nvcc 编译器)
FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

# 2. 设置非交互式安装，并安装基础依赖
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

# 3. 更完善的 SSH 配置 (允许root登录, 禁用严格主机密钥检查)
RUN mkdir -p /var/run/sshd && \
    sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config

# 4. 设置中国时区和UTF-8语言环境
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# 5. 安装 Miniconda (Python 3.8 版本)
RUN cd /root && wget -q https://repo.anaconda.com/miniconda/Miniconda3-py38_4.10.3-Linux-x86_64.sh \
    && bash ./Miniconda3-py38_4.10.3-Linux-x86_64.sh -b -f -p /root/miniconda3 \
    && rm -f ./Miniconda3-py38_4.10.3-Linux-x86_64.sh \
    && echo "PATH=/root/miniconda3/bin:/usr/local/bin:$PATH" >> /etc/profile \
    && echo "source /etc/profile" >> /root/.bashrc \
    && echo "source /etc/autodl-motd" >> /root/.bashrc

# 6. 【关键】使用 Conda 里的 pip 来安装所有 Python 包
# (已添加 tensorboard，并使用阿里云镜像源加速)
RUN /root/miniconda3/bin/pip install --no-cache-dir --upgrade \
    pip \
    jupyterlab>=3.0.0 \
    ipywidgets \
    matplotlib \
    jupyterlab_language_pack_zh_CN \
    tensorboard \
    torch==1.10.1+cu113 torchvision==0.11.2 torchaudio==0.10.1 \
    --extra-index-url https://download.pytorch.org/whl/cu113 \
    pandas \
    tqdm \
    -i https://mirrors.aliyun.com/pypi/simple

# 7. 设置工作目录 (适用于 AutoDL)
WORKDIR /root/autodl-tmp

# 8. 设置默认启动命令 (启动 sshd 服务)
CMD ["/usr/sbin/sshd", "-D"]
