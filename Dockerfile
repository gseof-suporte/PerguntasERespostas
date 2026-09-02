FROM rocker/shiny:latest

# Instala dependências do sistema e Python
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Cria ambiente virtual Python
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Instala PyTorch CPU e Sentence-Transformers
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir sentence-transformers

# Instala os pacotes R necessários
RUN R -e "install.packages(c('shiny', 'bslib', 'readxl', 'shinycssloaders', 'reticulate'), repos='https://cloud.r-project.org/')"

# Configura diretório de trabalho
WORKDIR /app

# Copia todos os arquivos do projeto
COPY . /app

# Pré-baixa o modelo de IA na build do container para não travar o boot
RUN python3 -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2')"

# Expõe a porta e executa
EXPOSE 10000
CMD ["Rscript", "app.R"]
