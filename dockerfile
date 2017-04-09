FROM debian@sha256:32a225e412babcd54c0ea777846183c61003d125278882873fb2bc97f9057c51
MAINTAINER Joshua Barber "j.barber501@gmail.com"

USER root

# Install basic system packages and add /bin/bash as default shell
RUN apt-get update  && \
	apt-get install -y python3-pip python-dev build-essential wget && \
	rm /bin/sh && ln -s /bin/bash /bin/sh

# Set environment variables
ENV APP_ACTIVATE "python ./dashboard.py"
ENV ENV_NAME "app-env"
ENV CONDA_DIR /opt/conda
ENV STARTSCRIPT /opt/start.sh
ENV PATH=/$CONDA_DIR/bin:${PATH}

# Miniconda installation
RUN cd /tmp && \
	mkdir -p $CONDA_DIR && \
	wget --quiet http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
	/bin/bash Miniconda3-latest-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
	rm Miniconda3-latest-Linux-x86_64.sh && \
	conda update -y conda && \
	conda clean -tipsy

# Install yaml to enable the parsing of YAML environment files
RUN conda install pyyaml

#Application setup
COPY . /code
WORKDIR /code

RUN conda env create -f environment.yml -n $ENV_NAME

# Script: Activate condaenv and launch application
RUN echo "#!/bin/bash" > $STARTSCRIPT && \
	echo "source activate $ENV_NAME" >> $STARTSCRIPT && \
	echo "$APP_ACTIVATE" >> $STARTSCRIPT
RUN chmod +x $STARTSCRIPT

#Expose required port
EXPOSE 5000
