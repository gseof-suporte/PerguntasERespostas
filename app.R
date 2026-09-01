library(shiny)
library(bslib)
library(readxl)
library(shinycssloaders)

# 1. Carregamento e tratamento dos dados do Excel
dados_excel <- read_excel("Problemas e soluções para IA.xlsx")
dados_excel <- na.omit(dados_excel)

df_faq <- data.frame(
  Problema = as.character(dados_excel$`Problema relatado`),
  Solucao = as.character(dados_excel$`Solução`),
  stringsAsFactors = FALSE
)

# 2. Interface do Usuário (Estilo Chat / Assistente)
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
          placeholder = "Ex: O que fazer quando ocorre erro ORA20000 ao anular restos a pagar?", 
          rows = 3
        ),
        actionButton("btn_perguntar", "Buscar Resposta", class = "btn-primary w-100 fw-bold")
      )
    ),
    
    br(),
    
    # Adicionado 'withSpinner' para exibir a animação de carregamento
    withSpinner(
      uiOutput("respostas_container"),
      type = 6,          # Estilo da animação (ícone circular suave)
      color = "#0d6efd", # Cor azul primaria
      size = 1
    )
  )
)

# 3. Lógica da IA / Busca Semántica
server <- function(input, output, session) {
  
  # Dispara a busca apenas ao clicar no botão
  resultado <- eventReactive(input$btn_perguntar, {
    req(input$pergunta_usuario)
    
    # Simula um pequeno delay se necessário (opcional)
    # Sys.sleep(0.5)
    
    texto <- trimws(tolower(input$pergunta_usuario))
    if (texto == "") return(NULL)
    
    # Quebra a frase em palavras-chave importantes
    palavras <- unlist(strsplit(texto, "\\s+"))
    palavras <- palavras[nchar(palavras) > 2] # Ignora palavras muito curtas
    
    if (length(palavras) == 0) palavras <- texto
    
    # Pontua as linhas do Excel que possuem o maior número de correspondências
    pontuacao <- sapply(1:nrow(df_faq), function(i) {
      texto_linha <- tolower(paste(df_faq$Problema[i], df_faq$Solucao[i]))
      sum(sapply(palavras, function(p) grepl(p, texto_linha, fixed = TRUE)))
    })
    
    # Filtra as melhores respostas
    indices <- which(pontuacao > 0)
    if (length(indices) == 0) return("NENHUMA")
    
    # Ordena pelas opções com mais acertos
    indices <- indices[order(pontuacao[indices], decreasing = TRUE)]
    
    return(df_faq[head(indices, 3), ]) # Retorna até as 3 respostas mais relevantes
  })
  
  output$respostas_container <- renderUI({
    res <- resultado()
    
    if (is.null(res)) return(NULL)
    
    if (is.character(res) && res == "NENHUMA") {
      return(
        div(class = "alert alert-warning text-center",
          h5("Nenhum resultado encontrado"),
          p("Tente reescrever sua pergunta com outros termos ou palavras-chave.")
        )
      )
    }
    
    # Renderiza os cards de respostas encontradas
    card_list <- lapply(1:nrow(res), function(i) {
      card(
        class = "mb-3 border-start border-primary border-4",
        card_header(class = "fw-bold text-primary", paste("Problema Relacionado #", i)),
        card_body(
          p(tags$b("Problema: "), res$Problema[i]),
          hr(),
          p(tags$b("💡 Solução Encontrada: "), res$Solucao[i], style = "font-size: 1.05rem;")
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
