library(shiny)
library(bslib)
library(readxl)
library(shinycssloaders)

# Libera o acesso à pasta 'imagens' no Shiny
if (dir.exists("imagens")) {
  addResourcePath("imagens", "imagens")
}

# 1. Carregamento e Preparação dos Dados
dados_excel <- read_excel("Problemas e soluções para IA.xlsx")

# Garante que a coluna Imagem exista no dataframe
if (!"Imagem" %in% colnames(dados_excel)) {
  dados_excel$Imagem <- NA
}

df_faq <- data.frame(
  Problema = as.character(dados_excel$`Problema relatado`),
  Solucao = as.character(dados_excel$`Solução`),
  Imagem = as.character(dados_excel$Imagem),
  stringsAsFactors = FALSE
)

# Lista expandida de stopwords em português
stopwords_pt <- c(
  "o", "a", "os", "as", "um", "uma", "uns", "umas", "de", "do", "da", "dos", "das",
  "em", "no", "na", "nos", "nas", "ao", "aos", "à", "às", "por", "pelo", "pela",
  "que", "fazer", "para", "como", "qual", "quais", "onde", "quando", "quem", "porquê",
  "porque", "com", "sem", "sobre", "entre", "até", "mais", "menos", "muito", "meu",
  "minha", "seu", "sua", "não", "sim", "está", "estou", "estamos", "estão", "ocorreu",
  "ocorrendo", "erro", "problema", "ajuda", "saber", "gostaria", "preciso", "posso",
  "ter", "tem", "tenho", "ser", "são", "foi", "fui", "vai", "vou", "pode", "podem"
)

# 2. Interface do Usuário (UI)
ui <- page_fluid(
  theme = bs_theme(version = 5, bootswatch = "zephyr"),
  
  div(class = "container py-4", style = "max-width: 800px;",
    
    div(class = "text-center mb-4",
      h2("🤖 Assistente de Suporte"),
      p(class = "text-muted", "Digite sua dúvida ou o problema que está enfrentando no sistema:")
    ),
    
    card(
      card_body(
        textAreaInput(
          "pergunta_usuario", 
          label = NULL, 
          placeholder = "Ex: O que fazer para desdobrar o título?", 
          rows = 3
        ),
        actionButton("btn_perguntar", "Buscar Resposta", class = "btn-primary w-100 fw-bold")
      )
    ),
    
    br(),
    
    withSpinner(
      uiOutput("respostas_container"),
      type = 6,
      color = "#0d6efd",
      size = 1
    )
  )
)

# 3. Servidor (Logic)
server <- function(input, output, session) {
  
  resultado <- eventReactive(input$btn_perguntar, {
    req(input$pergunta_usuario)
    
    # Normalização e limpeza do texto
    texto_raw <- trimws(tolower(input$pergunta_usuario))
    if (texto_raw == "") return(NULL)
    
    texto_limpo <- gsub("[[:punct:]]", " ", texto_raw)
    palavras <- unlist(strsplit(texto_limpo, "\\s+"))
    
    # 1. Filtragem rigorosa de Stopwords
    palavras_chave <- palavras[!palavras %in% stopwords_pt & nchar(palavras) > 2]
    
    # Se todas as palavras forem stopwords/curtas, invalida a busca
    if (length(palavras_chave) == 0) return("NENHUMA")
    
    # 2. Cálculo da pontuação por relevância
    pontuacao <- sapply(1:nrow(df_faq), function(i) {
      texto_linha <- tolower(paste(df_faq$Problema[i], df_faq$Solucao[i]))
      # Conta quantas palavras-chave aparecem na linha
      sum(sapply(palavras_chave, function(p) grepl(p, texto_linha, fixed = TRUE)))
    })
    
    max_pontos <- max(pontuacao)
    
    # Exige pontuação mínima (pelo menos 1 palavra-chave principal deve existir na base)
    if (max_pontos == 0) return("NENHUMA")
    
    # Filtra e ordena apenas os resultados com correspondência válida
    indices <- which(pontuacao > 0)
    indices <- indices[order(pontuacao[indices], decreasing = TRUE)]
    
    return(df_faq[head(indices, 3), ])
  })
  
  output$respostas_container <- renderUI({
    res <- resultado()
    
    if (is.null(res)) return(NULL)
    
    # Exibição da mensagem padronizada de falha (evita falsos positivos)
    if (is.character(res) && res == "NENHUMA") {
      return(
        div(class = "alert alert-warning text-center p-4",
          h5(class = "fw-bold", "Tópico não encontrado"),
          p("Desculpe, não encontrei nada relacionado ao tópico em minha base de dados."),
          p(class = "mb-0", tags$b("Enviar e-mail para a GSEOF solicitando maiores informações."))
        )
      )
    }
    
    # Renderização das soluções encontradas
    card_list <- lapply(1:nrow(res), function(i) {
      
      imagem_nome <- res$Imagem[i]
      tem_imagem <- !is.na(imagem_nome) && imagem_nome != "" && imagem_nome != "NA"
      
      card(
        class = "mb-3 border-start border-primary border-4",
        card_header(class = "fw-bold text-primary", paste("Problema Relacionado #", i)),
        card_body(
          p(tags$b("Problema: "), res$Problema[i]),
          hr(),
          p(tags$b("💡 Solução Encontrada: "), res$Solucao[i], style = "font-size: 1.05rem;"),
          
          if (tem_imagem) {
            div(class = "text-center mt-3",
              tags$img(
                src = file.path("imagens", imagem_nome), 
                style = "max-width: 100%; height: auto; border: 1px solid #dee2e6; border-radius: 6px; padding: 4px;"
              )
            )
          }
        )
      )
    })
    
    tagList(
      h4(class = "mb-3", "Resultados da Busca:"),
      card_list
    )
  })
}

shinyApp(ui = ui, server = server)
