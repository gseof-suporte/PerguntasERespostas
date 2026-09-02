FROM rocker/shiny:latest

# 1. Instala dependências do sistema Linux (incluindo libuv para o pacote R 'fs')
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    libuv1-dev \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Cria e ativa ambiente virtual Python
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 3. Instala PyTorch CPU e Sentence-Transformers
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir sentence-transformers

# 4. Reinstala/Garante o pacote 'fs' e instala as demais bibliotecas do R
RUN R -e "install.packages('fs', repos='https://cloud.r-project.org/')"
RUN R -e "install.packages(c('shiny', 'bslib', 'readxl', 'shinycssloaders', 'reticulate'), repos='https://cloud.r-project.org/')"

WORKDIR /app
COPY . /app

# 5. Pré-baixa o modelo HuggingFace na compilação da imagem
RUN python3 -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2')"

# 6. Configuração de porta do Render
EXPOSE 10000

CMD ["Rscript", "app.R"]
