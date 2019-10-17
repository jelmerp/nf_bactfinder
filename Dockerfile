FROM continuumio/miniconda3
LABEL authors="Anthony Underwood, Varun Shamanna" \
      description="Docker image containing all requirements for the GHRU AMR prediction pipeline"
RUN apt update

## Install ariba via conda
COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/ghru-amr-prediction/bin:$PATH

## Get ariba database
RUN ariba getref resfinder resfinder && ariba prepareref -f resfinder.fa -m resfinder.tsv resfinder_database.17.10.2019

## Installing Git
RUN apt install -y git

## python modules for resfinder
RUN pip install tabulate biopython cgecore

## cloning into resfinder repository
RUN git clone -b 4.0 https://git@bitbucket.org/genomicepidemiology/resfinder.git

## installing dependencies for resfinder

#installing zlib for kma
RUN apt install -y zlib1g-dev make gcc

##installing kma
RUN cd resfinder && cd cge && git clone https://bitbucket.org/genomicepidemiology/kma.git && cd kma && make
ENV PATH /resfinder/cge/kma:$PATH

##downloading databases for resfinder
#resfinder_database
RUN cd resfinder && git clone https://git@bitbucket.org/genomicepidemiology/resfinder_db.git db_resfinder && cd db_resfinder && python3 INSTALL.py && mkdir kma_indexing && mv *.b *.name kma_indexing


#pointfinder_database
RUN cd resfinder && git clone https://git@bitbucket.org/genomicepidemiology/pointfinder_db.git db_pointfinder && cd db_pointfinder && python3 INSTALL.py

## copy script for parsing resfinder output
COPY scripts/parse_resfinder_4_output.py /scripts/

# install procps which is required by Nextflow trace
RUN apt install -y procps

ENV PATH /resfinder:$PATH