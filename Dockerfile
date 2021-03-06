FROM tensorflow/tensorflow:1.12.0-gpu
#FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

# Install the basics
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git \
    bzip2 \
    libx11-6 \
    wget \
    libxml-parser-perl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory
RUN mkdir /workspace
WORKDIR /workspace

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos '' --shell /bin/bash user \
    && chown -R user:user /workspace
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER user

# All users can use /home/user as their home directory
ENV HOME=/home/user
RUN chmod 777 /home/user

# Install Miniconda
RUN curl -so ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda2-4.5.11-Linux-x86_64.sh \
    && chmod +x ~/miniconda.sh \
    && ~/miniconda.sh -b -p ~/miniconda \
    && rm ~/miniconda.sh
ENV PATH=/home/user/miniconda/bin:$PATH
ENV CONDA_AUTO_UPDATE_CONDA=false

# Create a Python 2.7 environment
RUN /home/user/miniconda/bin/conda install conda-build \
    && /home/user/miniconda/bin/conda create -y --name py27 python=2.7 \
    && /home/user/miniconda/bin/conda clean -ya
ENV CONDA_DEFAULT_ENV=py27
ENV CONDA_PREFIX=/home/user/miniconda/envs/$CONDA_DEFAULT_ENV
ENV PATH=$CONDA_PREFIX/bin:$PATH

# Install jupyter and additional packages
RUN conda install -y keras jupyter matplotlib scikit-learn natsort tqdm pandas

# Copy data to container
COPY ./ /workspace/

# Ensure python requirements met
RUN pip install -r /workspace/RLSeq2Seq/python_requirements.txt
RUN pip install pyrouge unidecode
RUN pyrouge_set_rouge_path /workspace/pyrouge/tools/ROUGE-1.5.5


# Set the default command to python2
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--allow-root", "--NotebookApp.token=''", "--port=8888"]
