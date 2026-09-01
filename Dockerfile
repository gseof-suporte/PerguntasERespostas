FROM rocker/shiny:latest

# 1. Instala as dependências de sistema necessárias do Linux
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    libuv1-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Instala TODOS os pacotes R utilizados no app.R
RUN R -e "install.packages(c('shiny', 'bslib', 'jsonlite', 'httr', 'markdown', 'shinycssloaders'), repos='https://cloud.r-project.org/')"

# 3. Copia a aplicação
WORKDIR /app
COPY app.R /app/app.R

# 4. Expõe a porta e define o comando de inicialização
EXPOSE 3838
CMD ["R", "-e", "shiny::runApp('/app/app.R', host = '0.0.0.0', port = 3838)"]
