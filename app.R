library(shiny)
library(bslib)
library(readxl)
library(shinycssloaders)

# Mapeia a pasta 'imagens' caso ela exista
if (dir.exists("imagens")) {
  addResourcePath("imagens", "imagens")
}

# 1. Carregamento e Preparação dos Dados
dados_excel <- read_excel("Problemas e soluções para IA.xlsx")

if (!"Imagem" %in% colnames(dados_excel)) {
  dados_excel$Imagem <- NA
}

df_faq <- data.frame(
  Problema = as.character(dados_excel$`Problema relatado`),
  Solucao = as.character(dados_excel$`Solução`),
  Imagem = as.character(dados_excel$Imagem),
  stringsAsFactors = FALSE
)

# Lista de stopwords em português
stopwords_pt <- c(
  "o", "a", "os", "as", "um", "uma", "uns", "umas", "de", "do", "da", "dos", "das",
  "em", "no", "na", "nos", "nas", "ao", "aos", "à", "às", "por", "pelo", "pela",
  "que", "fazer", "para", "como", "qual", "quais", "onde", "quando", "quem", "porquê",
  "porque", "com", "sem", "sobre", "entre", "até", "mais", "menos", "muito", "meu",
  "minha", "seu", "sua", "não", "sim", "está", "estou", "estamos", "estão", "ocorreu",
  "ocorrendo", "erro", "problema", "ajuda", "saber", "gostaria", "preciso", "posso",
  "ter", "tem", "tenho", "ser", "são", "foi", "fui", "vai", "vou", "pode", "podem"
)

# Função auxiliar para criar card de resposta
criar_card <- function(res_row, i, titulo_prefixo = "Resultado Relevante") {
  imagem_nome <- res_row$Imagem
  tem_imagem <- !is.na(imagem_nome) && imagem_nome != "" && imagem_nome != "NA"
  
  card(
    class = "mb-3 border-start border-primary border-4 shadow-sm",
    card_header(class = "fw-bold text-primary", paste(titulo_prefixo, "#", i)),
    card_body(
      p(tags$b("Problema: "), res_row$Problema),
      hr(),
      p(tags$b("💡 Solução Encontrada: "), res_row$Solucao, style = "font-size: 1.05rem;"),
      
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
}

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
        class = "d-flex flex-column gap-2",
        textAreaInput(
          "pergunta_usuario", 
          label = NULL, 
          placeholder = "Ex: permissão a uo 2100", 
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

# 3. Servidor (Logic)
server <- function(input, output, session) {
  
  # Estado reativo para controlar a exibição das respostas adicionais
  mostrar_mais <- reactiveVal(FALSE)
  
  # Reseta o botão de "mostrar mais" sempre que fizer uma nova busca
  observeEvent(input$btn_perguntar, {
    mostrar_mais(FALSE)
  })
  
  # Evento do clique em "Mostrar mais respostas"
  observeEvent(input$btn_mostrar_mais, {
    mostrar_mais(TRUE)
  })
  
  # Busca e hierarquização dos resultados
  resultados_ranqueados <- eventReactive(input$btn_perguntar, {
    req(input$pergunta_usuario)
    
    texto_raw <- trimws(tolower(input$pergunta_usuario))
    if (texto_raw == "") return(NULL)
    
    texto_limpo <- gsub("[[:punct:]]", " ", texto_raw)
    palavras <- unlist(strsplit(texto_limpo, "\\s+"))
    
    palavras_chave <- palavras[!palavras %in% stopwords_pt & nchar(palavras) >= 2]
    
    if (length(palavras_chave) == 0) return("NENHUMA")
    
    # Pontuação por número de palavras correspondentes + peso para termos no Problema
    pontuacao <- sapply(1:nrow(df_faq), function(i) {
      prob_text <- tolower(df_faq$Problema[i])
      sol_text  <- tolower(df_faq$Solucao[i])
      
      score <- 0
      for (p in palavras_chave) {
        pattern <- paste0("\\b", p, "\\b")
        if (grepl(pattern, prob_text)) {
          score <- score + 2  # Termo encontrado no Problema tem peso 2
        } else if (grepl(pattern, sol_text)) {
          score <- score + 1  # Termo encontrado na Solução tem peso 1
        }
      }
      return(score)
    })
    
    max_pontos <- max(pontuacao)
    if (max_pontos == 0) return("NENHUMA")
    
    # Ordena todos com pontuação > 0 do maior para o menor
    indices <- which(pontuacao > 0)
    indices <- indices[order(pontuacao[indices], decreasing = TRUE)]
    
    return(df_faq[indices, ])
  })
  
  # Renderização da Interface das Respostas
  output$respostas_container <- renderUI({
    res <- resultados_ranqueados()
    
    if (is.null(res)) return(NULL)
    
    if (is.character(res) && res == "NENHUMA") {
      return(
        div(class = "alert alert-warning text-center p-4",
          h5(class = "fw-bold", "Tópico não encontrado"),
          p("Desculpe, não encontrei nada relacionado ao tópico em minha base de dados."),
          p(class = "mb-0", tags$b("Enviar e-mail para a GSEOF solicitando maiores informações."))
        )
      )
    }
    
    # 1. Primeira resposta (melhor pontuada)
    melhor_resposta <- criar_card(res[1, ], 1, "Principal Resposta Encontrada")
    
    # Se houver apenas 1 resultado relevante na base
    if (nrow(res) == 1) {
      return(tagList(
        h4(class = "mb-3", "Resultado da Busca:"),
        melhor_resposta
      ))
    }
    
    # 2. Respostas secundárias (da 2ª em diante)
    cards_secundarios <- NULL
    if (mostrar_mais()) {
      cards_secundarios <- lapply(2:nrow(res), function(i) {
        criar_card(res[i, ], i, "Outra Opção Relacionada")
      })
    }
    
    # Interface combinada com o botão "Mostrar mais respostas"
    tagList(
      h4(class = "mb-3", "Resultado da Busca:"),
      melhor_resposta,
      
      if (!mostrar_mais()) {
        div(class = "text-center my-3",
          actionButton(
            "btn_mostrar_mais", 
            paste("Mostrar mais respostas (", nrow(res) - 1, "outras opções )"), 
            class = "btn-outline-primary fw-bold px-4 py-2"
          )
        )
      } else {
        tagList(
          hr(class = "my-4"),
          h5(class = "mb-3 text-muted", "Outras respostas possíveis:"),
          cards_secundarios
        )
      }
    )
  })
}

shinyApp(ui = ui, server = server)
