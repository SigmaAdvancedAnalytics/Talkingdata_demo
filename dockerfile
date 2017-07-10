FROM debian:jessie-slim
MAINTAINER Joshua Barber "j.barber501@gmail.com"

USER root

# Install basic system packages and add /bin/bash as default shell
RUN apt-get update  && \
    apt-get install -yq --no-install-recommends \
        python3-pip \
        python3-dev \
        python3-wheel \
        ssh \
        git \
        wget \
        bzip2 \
        ca-certificates \
        sudo && \
    rm /bin/sh && ln -s /bin/bash /bin/sh

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini && \
    echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Set environment variables
ENV CONDA_DIR=/opt/conda
ENV PATH=/$CONDA_DIR/bin:${PATH}
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DEV_USER jeb
ENV NB_UID 1000
ENV HOME /home
ENV ENV_NAME docker-env
ENV STARTSCRIPT /home/start.sh
ENV APP_ACTIVATE "python dashboard.py"

# Create jeb user
RUN useradd -m -s /bin/bash -N -u $NB_UID $DEV_USER && \
    mkdir -p $CONDA_DIR && \
    chown -R $DEV_USER:users $CONDA_DIR

# Setup jeb home directory
RUN mkdir /home/config && \
    mkdir /home/config/.jupyter && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/config/.curlrc

# Miniconda installation
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Linux-x86_64.sh && \
    /bin/bash Miniconda3-4.2.12-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-4.2.12-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    conda clean -tipsy
 
# Install Jupyter Notebook and Hub
RUN conda install -c conda-forge --quiet --yes \
    'notebook=4.3*' \
    'jupyterhub=0.7.2' \
    && conda clean -tipsy
 
# Upgrade pip
RUN pip install --upgrade pip

WORKDIR /home
    
# Install Python 3 packages
RUN chown -R $DEV_USER:users /home
COPY environment.yml ./
RUN conda env create -f environment.yml -n $ENV_NAME

# Script: Activate conda env and launch application
COPY . ./
RUN echo "#!/bin/bash" >> $STARTSCRIPT && \
    echo "source activate $ENV_NAME" >> $STARTSCRIPT && \
    echo "$APP_ACTIVATE" >> $STARTSCRIPT && \
    chmod +x $STARTSCRIPT

# Configure container startup
ENTRYPOINT ["/usr/local/bin/tini", "--"]
CMD ["/bin/sh","start.sh"]

USER $DEV_USER


