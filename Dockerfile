FROM rocker/shiny:latest

RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('shiny', 'bslib', 'jsonlite', 'httr'), repos='https://cloud.r-project.org/')"

COPY app.R /srv/shiny-server/

EXPOSE 3838

ENV PORT=3838
CMD ["/usr/bin/shiny-server"]
