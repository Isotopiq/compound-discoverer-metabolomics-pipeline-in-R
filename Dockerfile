FROM rocker/shiny:latest

# Install Linux system libraries commonly needed by R packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libgit2-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# App directory
WORKDIR /srv/shiny-server/compound-discoverer

# Copy app files
COPY . /srv/shiny-server/compound-discoverer

# Create settings.R if missing
RUN if [ ! -f pipeline/config/settings.R ]; then \
      cp pipeline/config/settings.example.R pipeline/config/settings.R; \
    fi

# Install required R helpers first
RUN R -e "install.packages(c('shiny', 'BiocManager', 'remotes'), repos='https://cloud.r-project.org')"

# Install repo dependencies if the package script works non-interactively
RUN R -e "source('pipeline/R/00_packages.R')" || true

# Permissions for uploads/outputs
RUN mkdir -p /srv/shiny-server/compound-discoverer/output && \
    chown -R shiny:shiny /srv/shiny-server/compound-discoverer

USER shiny

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/compound-discoverer', host='0.0.0.0', port=3838)"]
