library(shiny)
library(bslib)
library(readxl)
library(shinycssloaders)
library(reticulate)

# Mapeia a pasta 'imagens' caso exista
if (dir.exists("imagens")) {
  addResourcePath("imagens", "imagens")
}

# ==============================================================================
# UI - INTERFACE DO USUÁRIO
# ==============================================================================

ui <- page_fluid(
  theme = bs_theme(version = 5, bootswatch = "zephyr"),
  div(class = "container py-4", style = "max-width: 800px;",
    
    div(class = "text-center mb-4",
      h2("🤖 Assistente de Suporte"),
      p(class = "text-muted", "Digite sua dúvida ou o problema que está enfrentando no sistema:")
    ),
    
    # Status de carregamento do modelo de IA
    uiOutput("status_modelo_ui"),
    
    card(
      card_body(
        class = "d-flex flex-column gap-2",
        textAreaInput(
          "pergunta_usuario", 
          label = NULL, 
          placeholder = "Ex: cadastro de usuário", 
          rows = 3, 
          width = "100%"
        ),
        actionButton(
          "btn_perguntar", 
          "Buscar Resposta", 
          class = "btn-primary w-100 fw-bold py-2"
        )
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

# ==============================================================================
# SERVER - LÓGICA DO SERVIDOR
# ==============================================================================

server <- function(input, output, session) {
  
  # Valores reativos para guardar o modelo e os embeddings carregados
  modelo_ia <- reactiveVal(NULL)
  embeddings_base <- reactiveVal(NULL)
  df_faq_data <- reactiveVal(NULL)
  mostrar_mais <- reactiveVal(FALSE)
  
  # Carregamento do modelo em background assim que o Shiny abre a porta
  observe({
    invalidateLater(100, session)
    if (is.null(modelo_ia())) {
      message(">>> Carregando Python e Modelo Semântico...")
      
      # Garante a utilização do virtualenv do Docker
      if (file.exists("/opt/venv/bin/python")) {
        use_virtualenv("/opt/venv", required = TRUE)
      }
      
      st <- import("sentence_transformers")
      model <- st$SentenceTransformer("sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")
      
      # Carrega planilha
      dados_excel <- read_excel("Problemas e soluções para IA.xlsx")
      if (!"Imagem" %in% colnames(dados_excel)) {
        dados_excel$Imagem <- NA
      }
      
      df_faq <- data.frame(
        Problema = as.character(dados_excel$`Problema relatado`),
        Solucao = as.character(dados_excel$`Solução`),
        Imagem = trimws(as.character(dados_excel$Imagem)),
        stringsAsFactors = FALSE
      )
      
      df_faq$TextoCompleto <- paste("Problema:", df_faq$Problema, "| Solução:", df_faq$Solucao)
      
      message(">>> Gerando embeddings da base de dados...")
      doc_embeds <- model$encode(df_faq$TextoCompleto, normalize_embeddings = TRUE)
      
      # Salva os dados nos estados reativos
      df_faq_data(df_faq)
      embeddings_base(doc_embeds)
      modelo_ia(model)
      
      message(">>> Modelo Semântico Pronto!")
    }
  })
  
  # UI do status do modelo
  output$status_modelo_ui <- renderUI({
    if (is.null(modelo_ia())) {
      div(
        class = "alert alert-info d-flex align-items-center mb-3",
        span(class = "spinner-border spinner-border-sm me-2", role = "status"),
        span("Inicializando motor de inteligência artificial... Aguarde alguns segundos.")
      )
    } else {
      NULL
    }
  })
  
  observeEvent(input$btn_perguntar, { mostrar_mais(FALSE) })
  observeEvent(input$btn_mostrar_mais, { mostrar_mais(TRUE) })
  
  # Função de similaridade
  cosine_similarity <- function(query_vec, doc_vecs) {
    as.numeric(doc_vecs %*% t(query_vec))
  }
  
  # Renderização do cartão
  criar_card <- function(res_row, i, titulo_prefixo = "Resultado Relevante") {
    imagem_nome <- res_row$Imagem
    tem_imagem <- !is.na(imagem_nome) && 
                  imagem_nome != "" && 
                  imagem_nome != "NA" && 
                  tolower(imagem_nome) != "nan"
    
    src_caminho <- NULL
    if (tem_imagem) {
      if (file.exists(file.path("imagens", imagem_nome))) {
        src_caminho <- file.path("imagens", imagem_nome)
      } else if (file.exists(file.path("www", imagem_nome))) {
        src_caminho <- imagem_nome
      } else {
        src_caminho <- file.path("imagens", imagem_nome)
      }
    }
    
    card(
      class = "mb-3 border-start border-primary border-4 shadow-sm",
      card_header(
        class = "d-flex justify-content-between align-items-center fw-bold text-primary",
        paste(titulo_prefixo, "#", i),
        span(class = "badge bg-light text-primary border", sprintf("Relevância: %.0f%%", res_row$Score * 100))
      ),
      card_body(
        p(tags$b("Problema: "), res_row$Problema),
        hr(),
        p(tags$b("💡 Solução Encontrada: "), res_row$Solucao, style = "font-size: 1.05rem;"),
        
        if (tem_imagem) {
          div(class = "text-center mt-3",
            tags$img(
              src = src_caminho, 
              alt = "Imagem da Solução",
              style = "max-width: 100%; height: auto; border: 1px solid #dee2e6; border-radius: 6px; padding: 4px;"
            )
          )
        }
      )
    )
  }
  
  # Ranqueamento dos resultados
  resultados_ranqueados <- eventReactive(input$btn_perguntar, {
    req(input$pergunta_usuario)
    
    if (is.null(modelo_ia())) {
      showNotification("O motor de IA ainda está inicializando. Tente em instantes.", type = "warning")
      return(NULL)
    }
    
    texto_raw <- trimws(input$pergunta_usuario)
    if (texto_raw == "") return(NULL)
    
    model <- modelo_ia()
    doc_embeds <- embeddings_base()
    df_faq <- df_faq_data()
    
    query_vec <- model$encode(list(texto_raw), normalize_embeddings = TRUE)
    scores <- cosine_similarity(query_vec, doc_embeds)
    indices_validos <- which(scores >= 0.25)
    
    if (length(indices_validos) == 0) return("NENHUMA")
    
    indices_ordenados <- indices_validos[order(scores[indices_validos], decreasing = TRUE)]
    df_res <- df_faq[indices_ordenados, ]
    df_res$Score <- scores[indices_ordenados]
    
    return(df_res)
  })
  
  # Renderização da Interface das Respostas
  output$respostas_container <- renderUI({
    res <- resultados_ranqueados()
    if (is.null(res)) return(NULL)
    
    if (is.character(res) && res == "NENHUMA") {
      return(
        div(class = "alert alert-warning text-center p-4",
          h5(class = "fw-bold", "Tópico não encontrado"),
          p("Desculpe, não encontrei nada semanticamente relacionado ao tópico em minha base de dados."),
          p(class = "mb-0", tags$b("Enviar e-mail para a GSEOF solicitando maiores informações."))
        )
      )
    }
    
    melhor_resposta <- criar_card(res[1, ], 1, "Principal Resposta Encontrada")
    if (nrow(res) == 1) return(tagList(h4(class = "mb-3", "Resultado da Busca:"), melhor_resposta))
    
    total_opcoes <- min(nrow(res), 10)
    cards_secundarios <- NULL
    if (mostrar_mais()) {
      cards_secundarios <- lapply(2:total_opcoes, function(i) {
        criar_card(res[i, ], i, "Outra Opção Relacionada")
      })
    }
    
    tagList(
      h4(class = "mb-3", "Resultado da Busca:"),
      melhor_resposta,
      if (!mostrar_mais()) {
        div(class = "text-center my-3",
          actionButton("btn_mostrar_mais", paste("Mostrar mais respostas (", total_opcoes - 1, "outras opções )"), class = "btn-outline-primary fw-bold px-4 py-2")
        )
      } else {
        tagList(hr(class = "my-4"), h5(class = "mb-3 text-muted", "Outras respostas possíveis:"), cards_secundarios)
      }
    )
  })
}

# ==============================================================================
# EXECUÇÃO DO SHINY COM BINDING IMEDIATO DE PORTA
# ==============================================================================

porta_app <- as.numeric(Sys.getenv("PORT", unset = "10000"))

shinyApp(
  ui = ui, 
  server = server,
  options = list(
    host = "0.0.0.0", 
    port = porta_app
  )
)
