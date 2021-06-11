FROM ubuntu:focal
FROM opendatacube/geobase:wheels-3.0.4  as env_builder
ARG py_env_path=/env

# set rpy2 to ABI mode, since R is installed after rpy2
ENV RPY2_CFFI_MODE=ABI

# install python dependencies
RUN mkdir -p /conf
COPY requirements.txt /conf/
RUN env-build-tool new /conf/requirements.txt ${py_env_path} /wheels

FROM opendatacube/geobase:runner-3.0.4
ARG py_env_path=/env

COPY --chown=1000:100 --from=env_builder $py_env_path $py_env_path
COPY --from=env_builder /bin/tini /bin/tini

RUN export GDAL_DATA=$(gdal-config --datadir)
ENV LC_ALL=C.UTF-8 \
    PATH="/env/bin:$PATH"

RUN useradd -m -s /bin/bash -N jovyan -g 100 -u 1000 \
	&& chown jovyan /home/jovyan \
	&& addgroup jovyan staff

# install R dependencies
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		software-properties-common \
                dirmngr \
                ed \
		less \
		locales \
		vim-tiny \
		wget \
		ca-certificates \
        && add-apt-repository --enable-source --yes "ppa:marutter/rrutter4.0" \
        && add-apt-repository --enable-source --yes "ppa:c2d4u.team/c2d4u4.0+"

# configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

# set env variables for noninteractive
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV TZ UTC

# install R and littler, and create a link for littler in /usr/local/bin
# Default CRAN repo is now set by R itself, and littler knows about it too
# r-cran-docopt is not currently in c2d4u so we install from source
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
        && apt-get install -y --no-install-recommends \
                 littler \
 		 r-base \
 		 r-base-dev \
 		 r-recommended \
  	&& ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
 	&& ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
 	&& ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
 	&& ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
 	&& install.r docopt \
 	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
 	&& rm -rf /var/lib/apt/lists/*

# install system dependencies for suite of spatial R packages
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update&&apt-get install -y apt-utils pkg-config
RUN apt-get install -y libsqlite3-dev libudunits2-dev libssl-dev libmagick++-dev libcurl4-openssl-dev
RUN apt-get update&&apt-get install -y --no-install-recommends r-cran-reticulate

# install R packages
RUN R -e 'install.packages(c("IRkernel", "rgdal", "sp", "raster", "sf", "basemaps", "ggplot2", "mapview", "mapedit", "devtools", "usethis", "testthat", "roxygen2"))'

# initiliaze R kernel for Jupyter
RUN R -e "IRkernel::installspec(user = FALSE)"

# set user and working dir
USER jovyan
WORKDIR /notebooks

ENTRYPOINT ["/bin/tini", "--"]

CMD ["jupyter", "notebook", "--allow-root", "--ip='0.0.0.0'" "--NotebookApp.token='secretpassword'"]
