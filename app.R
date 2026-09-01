library(shiny)
library(bslib)
library(readxl)
library(jsonlite)
library(httr)
library(markdown)
library(shinycssloaders)

# 1. Carregamento e tratamento da planilha
# Lê o arquivo enviado ao repositório
dados_excel <- read_excel("Problemas e soluções para IA.xlsx")

# Limpa linhas inteiramente vazias ou com campos ausentes
dados_excel <- na.omit(dados_excel)

# Monta a estrutura de dados garantindo o mesmo número de linhas
df_perguntas <- data.frame(
  `Problema relatado` = as.character(dados_excel$`Problema relatado`),
  `Solução` = as.character(dados_excel$`Solução`),
  stringsAsFactors = FALSE
)

# 2. Interface do Usuário (UI)
ui <- page_fluid(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  
  titlePanel("Consulta de Problemas e Soluções"),
  
  sidebarLayout(
    sidebarPanel(
      textInput("busca", "Buscar por palavra-chave:", value = ""),
      helpText("Digite um termo para filtrar os problemas e soluções cadastrados."),
      hr(),
      textOutput("total_registros")
    ),
    
    mainPanel(
      withSpinner(tableOutput("tabela_resultados"), type = 6)
    )
  )
)

# 3. Regras de Negócio / Servidor (Server)
server <- function(input, output, session) {
  
  # Filtro reativo baseado na busca do usuário
  dados_filtrados <- reactive({
    req(df_perguntas)
    
    if (input$busca == "") {
      return(df_perguntas)
    } else {
      termo <- tolower(input$busca)
      
      # Procura o termo nas colunas de Problema ou Solução
      linhas_validas <- grepl(termo, tolower(df_perguntas$`Problema.relatado`)) | 
                        grepl(termo, tolower(df_perguntas$`Solução`))
      
      return(df_perguntas[linhas_validas, ])
    }
  })
  
  # Exibe a quantidade de registros encontrados
  output$total_registros <- renderText({
    n <- nrow(dados_filtrados())
    paste("Registros encontrados:", n)
  })
  
  # Renderiza a tabela na tela
  output$tabela_resultados <- renderTable({
    dados_filtrados()
  }, striped = TRUE, hover = TRUE, bordered = TRUE)
}

# 4. Execução da aplicação
shinyApp(ui = ui, server = server)
