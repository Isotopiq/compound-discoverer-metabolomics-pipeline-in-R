FROM rocker/shiny:latest

# -----------------------------
# System dependencies
# -----------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    ca-certificates \
    build-essential \
    gfortran \
    make \
    cmake \
    pkg-config \
    pandoc \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libglpk-dev \
    libgmp3-dev \
    libudunits2-dev \
    libgeos-dev \
    libproj-dev \
    libgdal-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# App location
# -----------------------------
WORKDIR /srv/shiny-server/compound-discoverer

# Copy repository contents
COPY . /srv/shiny-server/compound-discoverer

# -----------------------------
# Create local config if missing
# -----------------------------
RUN if [ ! -f pipeline/config/settings.R ] && [ -f pipeline/config/settings.example.R ]; then \
      cp pipeline/config/settings.example.R pipeline/config/settings.R; \
    fi

# -----------------------------
# Install core R helpers
# -----------------------------
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); \
install.packages(c('BiocManager', 'remotes', 'pak'), dependencies = TRUE)"

# -----------------------------
# Install Shiny/app dependencies explicitly
# -----------------------------
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); \
install.packages(c( \
  'shiny', \
  'shinyjs', \
  'shinyWidgets', \
  'waiter', \
  'bslib', \
  'DT', \
  'plotly', \
  'htmltools', \
  'htmlwidgets', \
  'markdown', \
  'rmarkdown', \
  'knitr', \
  'tidyverse', \
  'dplyr', \
  'tidyr', \
  'tibble', \
  'readr', \
  'stringr', \
  'forcats', \
  'purrr', \
  'ggplot2', \
  'ggrepel', \
  'scales', \
  'RColorBrewer', \
  'viridis', \
  'pheatmap', \
  'ComplexHeatmap', \
  'circlize', \
  'readxl', \
  'openxlsx', \
  'writexl', \
  'janitor', \
  'data.table', \
  'lubridate', \
  'tools', \
  'fs', \
  'here', \
  'glue', \
  'rlang', \
  'vctrs', \
  'cli', \
  'stringi', \
  'matrixStats', \
  'factoextra', \
  'FactoMineR', \
  'vegan', \
  'ggpubr', \
  'rstatix', \
  'car', \
  'multcomp', \
  'broom', \
  'cowplot', \
  'patchwork', \
  'gridExtra', \
  'ggfortify', \
  'ggdendro', \
  'reshape2', \
  'jsonlite', \
  'config', \
  'yaml' \
), dependencies = TRUE)"

# -----------------------------
# Install Bioconductor packages separately
# Some packages like ComplexHeatmap are Bioconductor-native.
# This block is tolerant if packages are already installed.
# -----------------------------
RUN R -e "BiocManager::install(c( \
  'ComplexHeatmap', \
  'limma', \
  'impute' \
), ask = FALSE, update = FALSE)"

# -----------------------------
# Try the repo dependency script if present
# Do not fail the build if the script has interactive or optional packages.
# -----------------------------
RUN R -e "if (file.exists('pipeline/R/00_packages.R')) { \
  tryCatch(source('pipeline/R/00_packages.R'), error = function(e) message('Repo dependency script skipped/error: ', e$message)); \
}"

# -----------------------------
# Output/upload folders and permissions
# -----------------------------
RUN mkdir -p \
    /srv/shiny-server/compound-discoverer/output \
    /srv/shiny-server/compound-discoverer/uploads \
    /srv/shiny-server/compound-discoverer/data \
    && chown -R shiny:shiny /srv/shiny-server/compound-discoverer

USER shiny

EXPOSE 3838

# -----------------------------
# Start Shiny app
# -----------------------------
CMD ["R", "-e", "options(shiny.host='0.0.0.0', shiny.port=3838); shiny::runApp('/srv/shiny-server/compound-discoverer', host='0.0.0.0', port=3838)"]
