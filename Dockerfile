FROM rocker/shiny:latest

RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('shiny', 'bslib', 'jsonlite', 'httr', 'markdown'), repos='https://cloud.r-project.org/')"

WORKDIR /app
COPY app.R /app/app.R

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/app/app.R', host = '0.0.0.0', port = 3838)"]
