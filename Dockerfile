FROM osgeo/gdal:ubuntu-small-3.3.1

ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    TINI_VERSION=v0.19.0 \
    TZ=UTC \
    RPY2_CFFI_MODE=ABI
# set rpy2 to ABI mode, since R is installed after rpy2

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN apt-get update && \
    apt-get install -y \
      build-essential \
      git \
      # For Psycopg2
      libpq-dev python3-dev \
      python3-pip \
      wget \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/{apt,dpkg,cache,log}

COPY requirements.txt /conf/
#COPY products.csv /conf/
RUN pip3 install --no-cache-dir --requirement /conf/requirements.txt

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
RUN add-apt-repository --yes "ppa:ubuntugis/ppa" \
        && apt-get update \
        && apt-get install -y apt-utils pkg-config \
        && apt-get install -y libsqlite3-dev libssl-dev \
                              libmagick++-dev libcurl4-openssl-dev \
                              libprotobuf-dev protobuf-compiler libv8-dev libjq-dev \
                              libudunits2-dev libgdal-dev libgeos-dev libproj-dev \
        && apt-get install -y --no-install-recommends r-cran-reticulate

# install R packages
RUN R -e 'install.packages(c("IRkernel", "rgdal", "sp", "raster", "sf", "basemaps", "ggplot2", "mapview", "mapedit", "devtools", "usethis", "testthat", "roxygen2", "geojsonio", "gdalUtils"))'
RUN R -e 'devtools::install_github("eo2cube/odcr")'
RUN R -e 'install.packages(c("IRkernel"))'

# initiliaze R kernel for Jupyter
RUN R -e "IRkernel::installspec(user = FALSE)"

## automatically link a shared volume for kitematic users
#VOLUME /home/rstudio/kitematic

# set user and working dir
USER jovyan
WORKDIR /notebooks

#CMD bash -c " && rstudio-server start"
#RUN "/init"

ENTRYPOINT ["/tini", "--"]
CMD ["jupyter", "notebook", "--allow-root", "--ip='0.0.0.0'", "--NotebookApp.token='secretpassword'"]
#CMD ["rstudio-server start"]
