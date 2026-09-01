library(shiny)
library(bslib)
library(jsonlite)
library(httr)

# ==============================================================================
# 1. BASE DE DADOS ATUALIZADA (78 REGISTROS DA NOVA PLANILHA)
# ==============================================================================
base_problemas_solucoes <- data.frame(
  "Problema relatado" = c(
    "Ao tentar realizar anulação de restos a pagar (emitidos antes da integração ao GRP) ou de empenho parcial de anos anteriores, ocorre um erro (ERRO ORA20000). O erro pode ser tanto quanto à \"Contratos Migrados do SUCC\" quanto à \"Reestabelecimento_Saldo_Migrado_IJ_GRP\". Erro na importação do restabelecimento do IJ para o GRP.",
    "Querem processar o processar o título e a liquidaçãoda Claro, mas o sistema retorna o CNPJ diferente do que o usuário deseja.",
    "Código de barra difere do fornecedor correto. Ao capturar o código de barras da fatura referente à despesa com telefonia móvel, há dois fornecedores diferentes, sendo que a pessoa necessita de um específico que não é o que retorna pelo SOF. ",
    "Emissão de empenho de um contrato cuja vigência já encontra-se expirada. Não é mais possível emitir empenho para este contrato via pedido de empenho no GRP, visto que este sistema não permite a emissão de pedido de empenho para contrato vencido",
    "Empenho para credores com restrições funcionais. Se há uma restrição associada a um credor, não é possível efetuar a liquidação de um título. Ex.: Servidor já aposentado ou exonerado que precisa receber precatórios.",
    "Ao vincular uma nota de empenho de uma UO diferente, consta um erro de UO. Também pode haver um erro na liquidação complementar de encargos. ",
    "Ao processar a despesa de Convênio,  competência e NE do exercício anterior, aparece a seguinte mensagem \"Tipo Espécie desse título somente aceita empenhos cuja origem seja de congêneres\".",
    "Se há mais de um cadastro do mesmo CNPJ ou CPF como credor, fornecedor, funcionário, o SOF apresenta uma mensagem de erro \"Mais de um credor ativo associado a esse CPF\". ",
    "Matrícula do funcionário não está disponível para utilização no SOF. Verifique o cadastro do servidor/endereço junto ao órgão de RH.. Ao cadastrar uma nota de empenho para um funcionário, o SOF mostra a mensagem. ",
    "Regularização dos rendimentos da conta judicial. Liberação para emissão de NE e NPD sem título com data retroativa,",
    "Retenção não cadastrada ou bloqueada. Atividade de cadastro de títulos apresenta mensagem de \"Retenção não cadastrada ou bloqueada\", o que impede a liquidação da folha de pensionistas do RPPS",
    "Ao se efetuar a liquidação referente a compensação da Unimed, é solicitado que se retire a exigência de exclusividade na NPD para algum Tipo Espécie. Retirada da exigência de exclusividade na NPD.",
    "Ao criar uma nota de pagamento (NPD), o usuário não está habilitado para o módulo de títulos. Mensagem: usuário sem permissão de emitir documentos que utilizem a estrutura do módulo de títulos",
    "Para efetuar liquidações retroativas, o SOF barra essa opção e aparece a mensagem: \"Usuário sem permissão para emitir NPD sem cadastro de título\"",
    "Usuário sem permissão no Projeto/Empreendimento. Ao tentar informar o projeto empreendimento 484 no cadastro do título do SOF aparece a informação de usuário sem permissão.",
    "Não é permitida a utilização de empenhos de projetos/empreendimentos diferentes do informado no Título",
    "Empenho não possui permissão para outro credor . Ao processar a despesa no SOF, referente ao consultor individual RPA, na etapa de fazer a alteração da despesa para incluir o empenho patronal do INSS, constatou o mesmo erro das liquidações passadas.  Aparece uma mensagem de erro que diz que \"para utilização de empenho com credor diferente do credor do título, contacte a GEIF\"",
    "Usuário esqueceu a senha do SOF",
    "Recolher um ISSQN para o município de Lagoa Santa",
    "Não é possível anulação do empenho de data anterior, pois já existe movimentação no dia de hoje",
    "Ao cadastrar um título, quando  a chave de acesso é informada, aparece uma mensagem: \"  O valor informado na primeira e segunda posição deve corresponder ao UF do fornecedor.\"\nA chave estadual é digitada corretamente.  O valor informado na primeira e segunda posição deve corresponder ao UF do fornecedor",
    "A mensagem de erro reporta \"Informe somente o INSS ou o PIS/PASEP\". Ao realizar o cadastro de uma categoria por credor no sof, está pedindo para informar inss ou pis.",
    "Frequentemente ao emitir NEs e NPDs, algumas delas não são enviadas para assinatura e é necessário reenviar para a assinatura digital.",
    "Usuário tenta cancelar a liberação do Titulo para alterar uma informação e deseja voltar o saldo. No entanto, aparece a mensagem: \"empenho não possui saldo disponível para efetuar estorno do desconto na entrada da nota\"",
    "É necessário atualizar no SOF um cadastro de credor efetuado no GRP. Entretanto, a tela não está habilitando a função \"salvar\" para que possamos fazer o procedimento.",
    "",
    "servidor informou que perdeu a senha do SOF e gostaria de resetar",
    "Qual Código Natureza Rendimento- REINF utilizar para aquisição de sabonetes líquidos para a nota de pagamento?",
    "Ao processar a despesa, cadastro de título 58/1, aparece a seguinte mensagem de erro \"Competência já informada para o Credor no título de Número Provisório XXXX do Exercício de...\" . ",
    "Anulação de nota de empenho sem pedido (anulação parcial de NE - nota de empenho). Aparece a seguinte mensagem: \"O valor de anulação está maior que o saldo do empenho até Mês/ano. Saldo a reservar do empenho 0,00.",
    "Ao informar a chave de acesso da NFS-e o SOF retorna a mensagem: \"Código IBGE do Município do Credor diferente do Código IBGE do Município da chave de acesso - Posição 1 a 7\"",
    "O SOF não permite lançar valor de retenção do ISSQN ao inserir no campo Natureza de despesa a opção \" 1- Desobrigado Legalmente\". Retenção do ISSQN no campo Natureza de Despesa",
    "A categoria P2 - REQUISITÓRIOS E ACOES JUDICIAIS SEM DIRF E EFD-REINF não pode ser utilizada, pois o tipo pessoa desta categoria difere do tipo pessoa do credor da Liquidação. Ao tentar gerar a NPD de regularização de bloqueios/sequestros judiciais, com a categoria P2, constou a mensagem de erro anterior",
    "Mensagem: \"Não encontrada NOTA FISCAL / FATURA DE CONSUMO Pendente de Acumulação para os critérios informados. Acumulação de título da Cemig",
    "Ao tentar realizar a prévia da apropriação da despesa Copasa referente ao mês de dezembro/2025 em DEA, consta a seguinte mensagem: \"O mês da data do documento deve ser igual ao mês de referência.\"",
    " Ao cadastrar o título, não aparece a natureza ",
    "Houve uma solicitação de criação de conta contábil. Criação De Nova Conta Contábil SOF",
    "No SOF aparece a mensagem \"Competência já informada para o credor no título de número ...\". Usuária relatou que não estava conseguindo lançar um título referente a parte extra-orçamentária de abatimento feito na npd de decisão judicial.\nO sistema alerta que o título já foi feito, o que não é verdade.\nAparece o título 15.800, como já lançado, mas que ela não tem acesso.",
    "SOF informa \"o valor da retenção deve ser informado para retenção de IRRF\". Sistema apresenta um erro ao salvar, solicitando que seja informado o valor da retenção. Despesa é extraorçamentária e não é possível cadastrar retenção em extraorçamentária",
    "A Espécie Título: Tributos Federais sequência:    está vencida e não permite pagamento.  Inconsistência CASP (IRRF TERCEIROS)",
    "Estamos com uma fatura da CEMIG - contrato vigente, com incidência de multa, gostaríamos de uma orientação a respeito de como fazer a nota de empenho em relação ao \"vínculo de despesa\" no SOF, pois conforme orientação, o empenho para encargos deve ser feito sem pedido. VÍNCULO DE DESPESA / PAGAMENTO CEMIG - ACUMULAÇÃO DE FATURAS",
    "Necessita de autorização para emissão de empenho de indenização sem IJ. Empenho de Indenização sem IJ",
    "Mensagem: \"Competência já informada para o Credor no título de Número Provisório ...\" Problema ao executar o título (cadastro de título)",
    "Foi emitido solicitação de empenho e posteriormente CANCELADO no GRP, porém usuário não consegue ANULAR/CANCELAR no mesmo valor no SOF. Pediu orientações de como proceder para ANULAÇÃO/CANCELAMENTO do mesmo. Exclusão de empenho provisório (cancelar empenho que ainda não foi liberado)",
    "Cadastro da alíquota diferente de 2, 2,5, 3 e 5% no ISSQN dentro do SOF.",
    "Ao iniciar o cadastro do título no SOF, o sistema não está puxando o projeto/empreendimento contido na NE, o que está impossibilitando de prosseguir com o processamento. Dúvida em relação ao processamento de convênio",
    "A nota fiscal o valor de INSS tem um centavo a mais. O cálculo do SOF dá um centavo a menos e o sistema não permite alterar o valor. Ajuste na retenção de INSS",
    "Uma nota não está concluindo no SOF, pois aparece a crítica de que não está no GRP, entretanto a mesma foi lançada. A mensagem de erro que aparece é \"A nota fiscal não foi encontrada no GRP-BH\". Erro ao buscar nota fiscal no GRP",
    "A espécie título/tipo espécie título judicial não pode ser liquidada pela forma de pagamento indicada na liquidação",
    "Ao cadastrar um título com a espécie 63 - tipo espécie 0, aparece uma mensagem de que o \"tipo espécie\" deve ser informado",
    "Ao tentar gerar um título referente a um convênio com parcelas, a informação não consta no SOF. PARCELA CONGÊNERE / GRP - SOF",
    "ACESSO AO SOFWEB. Usuário digita login e senha corretos, mas SOF WEB não reconhece. Aparece a mensagem: \"Credenciais LDAP inválidas do usuário\"",
    "Ao lançar a chave de acesso no cadastro do título, aparece a  mensagem: \"número do título diferente do número NFS-e na Chave de acesso -  Posição 24 a 36\". O processo foi lançado no GRP também.",
    "Notas de Empenho para devolução de rendimento de garantia de proposta. O único vínculo que localizei no SOF é o \"Garantia contratual - correção monetária\", o que difere do objeto da despesa, que é \"garantia de proposta\".",
    "Notas de prestadores de serviços de outros municípios que não estão no formato nacional, apesar de constar na nota a chave de acesso e ao verificar que estão corretas",
    "Problema no Sof para cadastrar título. Erro ao autenticar o usuário! Código 500",
    "Devolução de valor que foi depositado indevidamente em nossa conta. Já foi criada a conta contábil para que o referido valor seja devolvido através de NPD extra-orçamentária. A dúvida foi se seria necessário o cadastro de títulos ou se era possível devolver sem o cadastro de título após a autorização.",
    "Como devemos fazer o preenchimento nos casos de pagamentos em que é destinado a Pessoa Física e não haverá retenção de IR por se tratar de RRA, ou verba indenizatória?",
    "Em decorrência de arredondamento, o valor do DARF de INSS a pagar sobre folha de pagamento de pessoal foi inferior em alguns centavos se comparado ao somatório das NPDs realizadas para este fim.\n",
    " Retirada da exigência de exclusividade na NPD",
    "Dúvidas preenchimento do SOF - Valor Isenção IRRF da Retenção de IRRF - Terceiros deve ser maior que zero",
    "Ao realizar um pagamento de RPV, onde a CATEGORIA DE CREDOR é \"P\", quando se busca cadastrar esta categoria no SOF aparece a mensagem solicitando o preenchimento do número do INSS ou PIS/PASEP, porém esta informação não se encontra no processo. Mensagem do SOF: \"informe o número do INSS ou do PIS/PASEP\"",
    "O valor informado na primeira e segunda posição deve corresponder ao UF do fornecedor",
    "Problemas ao tentar autorizar a movimentação eletrônica (17756), o parâmetro de forma de lançamento não foi encontrado (...)",
    "Liberação para cadastrar título com numeração repetida",
    "Usuário deseja bloquear o cadastro de um Projeto Empreendimento no SOF",
    "SOF não permitiu cancelar o título devido a erro na integração com o GRP-BH. Solicitação de cancelamento de títulos cadastrados em exercício anterior",
    "Precisam desvincular o empenho de títulos desdobrados que tiveram a liquidação anulada",
    "Como cadastrar usuário?",
    "Como acumular faturas?",
    "Como cadastrar título acompanhado por boleto ou outro documento com código de barras para pagamento",
    "Como alterar a despesa do título?",
    "Como é a execução da despesa de intermediação e serviços de terceiros?",
    "Como posso desagrupar as liquidações (NPDs)?",
    "A data de vencimento foi alterada (ou atualizada) pelo fornecedor (ou credor). Como fazer?",
    "Como excluir um título de juros/multa (juros ou multa) do INSS e como fazer a liquidação dos juros e da multa do INSS?",
    "Acumulação de DARF/INSS",
    "Para acumulação e informação do código de barras do INSS"
  ),
  "Solução" = c(
    "Encaminhar e-mail para mclara@pbh.gov.br e dinha@pbh.gov.br solicitando uma avaliação",
    "Solicitar à GSEOF que desabilite um CNPJ e habilite outro",
    "É necessário bloquear o cadastro de um deles para deixar somente um ativo. Solicitar à GSEOF o bloqueio de um deles, deixando somente um ativo. ",
    "Empenhar a despesa diretamente no SOF, utilizando o vínculo de \"Despesa indenizada de IJ\" e referenciando o IJ em questão.",
    "É necessário criar uma exceção à restrição, de forma pontual. Solicitar à GSEOF. ",
    "É necessário criar uma exceção à regra, deixando-se que a liquidação ocorra diferente da U.O de origem. Isso acontece quando a UO que gerou o empenho é diferente da UO que irá liquidar o título. Já a questão da NPD complementar refere-se à parte complementar (encargos) da atividade de Nota de Pagamento. Nesse caso, tb é necessário criar uma autorização pontual. Solicitar à GSEOF a autorização. ",
    "É necessário cancelar o empenho e emitir outro, com integração ao GRP.",
    "É necessário bloquear os demais credores do cadastro, deixando somente aquele que será efetuada a liquidação. Atenção: não é possível manter duas matrículas desbloqueadas para o mesmo cpf. Solicitar à GSEOF o bloqueio. ",
    "Há duas situações em que ocorrem esse erro: quando o usuário realmente ainda não está cadastrado no SOF ou quando o cadastro está errado. Se ele não estiver cadastrado, é necessário que, primeiramente, faça o cadastro no ART. O ART envia os dados para o SOF em dois horários: 14h e final do dia. Caso a atualização tenha sido realizada após o almoço, orientar aguardar até o dia seguinte. Se o cadastro estiver errado, pode ser a matrícula que contém X e a pessoa digitou x minúsculo (SOF só aceita maiúsculo) ou pode ser a matrícula errada ou até mesmo a Empresa cadastrada (ex.: cadastrou como PBH e no SOF está como SUDECAP). Se não for nada disso, solicitar à GSEOF que abrar um SDM com os prints da tela.  ",
    "É necessário autorizar a matrícula para gerar empenho ou nota de pagamento sem título com data retroativa. Essa autorização deve ser pontual e deve ser concedida somente para o dia da requisição. Enviar solicitação à GSEOF. ",
    "O cadastro para o \"Tipo Administração\" pode não estar liberado. Enviar o código de retenção desejado para a GSEOF. ",
    "O SOF tem um parâmetro para impedir que os usuários misturem tipos espécies na NPD.\nQuando é necessário processar dois títulos na mesma NPD, para que a NPD não fique zerada (o que não é permitido), é necessário alterar pontualmente o parâmetro dos tipo espécies 50/4 e 50/8 para que consigam liquidar. Enviar solicitação à GSEOF. ",
    "É necessário solicitar à GSEOF que habilite o usuário para o módulo de títulos.",
    "Solicitar à GSEOF a liberação.",
    "O cadastro de usuários no projeto empreendimento é realizado pela Simone Galinari ( sgsoares@pbh.gov.br). Caso seja urgente, solicitar à GSEOF.",
    "Se forem das secretarias, não precisa informar o projeto empreendimento para pagamento no tesouro, mas se forem de UOs dos fundos  e indiretas, terão que refazer os empenhos incluindo nestes o projeto empreendimento para conseguir incluir nos títulos e possibilitar o pagamento pela DIAF de despesas destes órgãos.",
    "Solicitar a permissão para utilização do empenho para outro credor à GSEOF",
    "Enviar email para sergioe@pbh.gov.br, com cópia para celula-orcamentario@pbh.gov.br, informando o usuário e que esqueceu a senha.",
    "Solicitar à GSEOF o desbloqueio do credor para o tipo espécie 54/3. ",
    "A anulação só é possível com data de hoje, não pode ter anulação com empenho de data anterior quando, no dia, já houver movimentação.",
    "É necessário atualizar o endereço do credor no GRP e posteriormente carregar a informação no SOF. Quando o endereço está desatualizado, a validação da chave estadual apresenta o erro. ",
    "Essa informação era utilizada antigamente para informar o GIFP, mas não é mais utilizada. Então, deve-se limpar os campos de INSS e de PIS/PASEP do cadastro a ser realizado. ",
    "Verificar se o erro ocorre somente com você ou com outros colegas. Caso seja somente com você, faça  um teste logando em outra máquina para ver se irá gerar o PDF. Se der certo, é necessário abrir um chamado para a Prodabel configurar o seu computador. Se não der certo, informar à GSEOF. ",
    "Para que você consiga fazer o cancelamento da liberação, é necessário cancelar o pagamento que foi emitido hoje (se for possível) , cancelar toda a movimentação realizada no SOF referente a este pagamento (NPD, Título), cancelar a OF correspondente deste pagamento no GRP. Posteriormente, você conseguiria fazer o cancelamento da liberação do título com o restabelecimento do saldo para a OF.\n\nDepois que consertar o que precisa no título no SOF e fazer nova liberação de título, é possível novamente cancelar parcialmente o saldo da OF e emitir nova OF para refazer o pagamento que foi cancelado para este movimento.  Caso não seja cancelado no dia, tem que abrir um SDM. Enviar e-mail à GSEOF. ",
    "Quando o credor já foi atualizado uma vez no SOF (veja que já possui número de credor), só irá habilitar para salvar, se houver algum dado alterado, que virá marked com um asterisco (veja que no print que encaminhou não há nenhum campo com asterisco). Se não houver nenhuma informação para ser atualizada, não tem que ser feito. ",
    "",
    "Favor  enviar email para sergioe@pbh.gov.br, com cópia para celula-orcamentario@pbh.gov.br, informando o usuário que perdeu a senha.",
    "Utilizar código 17008. Para confirmação, enviar e-mail à GSEOF. ",
    "É necessário informar \"sim\" no campo Pagamento Complementar/Honorário nos Dados Complementares. ",
    "É necessário desdobrar o título em questão no valor que precisa anular e, após o desdobramento, informar à GSEOF para que seja desvinculado o saldo. Quem faz o desdobramento do título é o próprio usuário, mas a exclusão é feita pela GSEOF. Enviar solicitação por e-mail. ",
    "Consultar CNPJ da empresa no site da Receita. Se o endereço da empresa for de BH, é necessário atualizar o cadastro do credor no GRP e no SOF.",
    "Sempre que um título possui mais de um empenho, a retenções e valores lançados na aba \"Retenções\" do cadastro do título deverão ser lançados também na subaba \"Dados retenções\" da aba Dados despesa Casp, para cada um dos empenhos, sendo que os valores normalmente são distribuidos proporcionalmente ao valor de cada empenho na despesa e o somatório de cada retenção lançado nesta última aba deverá corresponder ao total lançado na aba \"Retenções\". Mesmo que a retenção tenha sido lançada com o valor 0,00, ela deverá ser inserida na aba \"Dados Retenções\" para todos os empenhos relacionados. \n\nCaso se tenha lançado todo o valor da retenção do IR para um único empenho, é necessário, na aba \"Dados retenções\" do outro empenho, lançar a retenção de ISSQN com o valor 0,00 e também um valor para a retenção de IR (diminua o valor lançado para o primeiro empenho de forma que a soma dos valores lançados para os dois empenhos seja o mesmo valor lançado na aba \"Retenções\" para o IR).",
    "Considerando se tratar de regularização de bloqueios/sequestros judiciais, queira, por gentileza, utilizar a categoria P5 - Bloqueio Judicial de Pagamento. ",
    "Para acumulação, você precisa digitar a data de vencimento e mês de referência do Título. \nA data de vencimento e o mês de referência devem ser os mesmos do título (há uma validação). ",
    "Como se trata de DEA, devem selecionar no campo mês de referencia o mês atual e colocar a data atual.",
    "Olhar no módulo \"Prestação de Contas\" e verificar o código Pagamento IRRF associado à natureza questionada. Pode ser que tenha sido extinta e alterada. Caminho no SOF Prestação de Contas > Cadastros > EFD - REINF > Natureza de Rendimentos",
    "Olhar no módulo Execução Orçamentária se já não há uma retenção associada (Manutenções > Retenção > Tipos Retenções/Abatimentos/Outros Tributos (verificar se há a retenção cadastrada). Caso haja, verificar se pode utilizá-la. Caso negativo, é necessário cadastrar uma nova retenção. Solicitar à GSEOF.",
    "Caso realmente o título não esteja duplicado (é necessário sempre se certificar de que não está gerando um cadastro duplicado), para prosseguir, informe SIM no campo Pagamento complementar/honorários.",
    "Tendo em vista que a despesa será extra orçamentária, e que não é possível informar retenções em títulos extra orçamentários, será necessário:\n-  cancelar o título\n- anular o saldo do empenho\n- cadastrar a despesa na NPD Versão Sem Cadastro de Títulos, informando o IRRF como retido não.",
    "Quando é necessário efetuar o pagamento sem a informação do encargo, solicitar à GSEOF que altere pontualmente o parâmetro do tipo espécie para permitir  pagamento após o vencimento.",
    "Para verificar quais os vínculos existentes, utilizar o relatório \"Despesa por Vínculo\". Outra forma é criar um empenho provisório para ver a listagem dos vínculos existentes (caminho: Atividades > Execução > Empenho> Nota de Empenho Sem Pedido. Há uma opção de preenchimento de vínculo da despesa que mostra todas as opções existentes). Dependendo do caso, deve-se utilizar \"despesa indireta de IJ\" pois trata-se de multa que está associada a um contrato. vínculo 28 - DESPESA INDIRETA DE IJ. Verificar informação com GSEOF. ",
    "A emissão de empenho de indenização de IJ só deve ser usada em casos que não tem outro jeito. Se for oriundo de uma despesa que nasce no módulo de compras (não tem contrato, mas teve processo licitatório), deve ser feito no GRP e não no SOF. Se não tem contrato e não teve processo licitatório, deve ser solicitada a permissão para a GSEOF. ",
    "Na tela de \"Atividade de Cadastro de Título\", deve ser informado \"SIM\" no campo \"Pagamento Complementar\". Módulo Execução: Atividades > Execução > Títulos > Cadastro de Títulos. Na aba \"Dados Complementares\", opção \"Pagamento Complementar/Honorários\":SIM",
    "Como o empenho consta cancelado no GRP, para liberar o saldo, o empenho provisório pode ser excluído do SOF. Módulo Execução: Atividades > Execução> Empenho via pedido. Digite o numero do empenho provisório no campo próprio e clique na lixeira para excluir o empenho provisório.",
    "Em BH, há as alíquotas 2% 2,5% 3% e 5%. Optante simples que tem recolhimento em BH não deve ser cadastrado, pois há grande variação. Se for optante pelo Simples Nacional, deve fazer o cadastro da retenção 108 (ISSQN Optante Simples). Se não for optante simples, verificar a nota fiscal para verificação de alíquota. ",
    "É necessário solicitar autorização no projeto empreendimento à Simone Galinari Soares de Oliveira ",
    "O usuário pode informar esse 0,01 na retenção do irrf, pra fechar o valor líquido com o da nota fiscal",
    "Verificar se a data do documento está incorreta no GRP, pois este é um dos campos que o SOF verifica para carregar o documento a partir daquele sistema. Para que o SOF localize a NF cadastrada no GRP é necessário que os dois cadastros possuam as mesmas informações no GRP e no SOF para os campos abaixo:\nCódigo Fornecedor:\nNúmero do documento:\nData de Emissão do documento:\nValor total:",
    "Deve selecionar a instrução de pagamento 8-deposito em juizo e marcar o campo pagamento complementar igual a SIM.",
    "O cadastro de título de Adiantamento segue um rito diferente, pois o título é gerado concomitantemente ao cadastro da solicitação de adiantamento. Para maiores detalhes, é recomendada a leitura do documento Execução da despesa de adiantamento financeiro - SOF, disponível no EAD da PBH no link: https://ead.pbh.gov.br/course/view.php?id=3887 (também o envio em anexo o arquivo lá disponível, de título POP - SOF Concessão de Adiantamento Financeiro)",
    "Para a parcela aparecer no SOF, é necessário autorizar a parcela no GRP. Para verificar, entrar no GRP> Gestão de Congênere > Cadastro de congênere > clicando com o botão direito em cima do ícone com três barras e depois em parcela, verificar situação",
    "A senha informada deve ser a do e-mail institucional. Caso esteja digitando a senha corretamente, solicitar avaliação da GSEOF. ",
    "O usuário deve informar, no campo Número Título da aba inicial, o número conforme consta na chave de acesso. O intervalo da posição 24 à posição 36 na Chave de Acesso da NFS-e corresponde ao número da Nota Fiscal. ",
    "Foi alterado o nome do Vínculo para Garantia - Correção Monetária. Deve ser utilizado este. ",
    "Se a verificação no Portal Nacional foi realizada com sucesso, a Nota Fiscal mencionada pode ser aceita, sendo Espécie Título / Tipo Espécie: 50/4 para notas fiscais de serviços \nEspécie Título / Tipo Espécie:  50/10 para notas fiscais de serviços do tipo DANFSE",
    "Sair do sistema, entrar novamente forçando a atualização e tentar novamente.",
    "Devem cadastrar o título , espécie título /tipo espécie 57/13 regularização. Para isso, solicitar autorização da GSEOF. ",
    " A informação de retido NÃO será apenas para os casos em que o contribuinte tenha um processo judicial ou administrativo junto à Receita Federal, no qual foi determinado que não haverá retenção de IR.\nPara os casos de IRRF Isento, deverão informar IRRF Retido SIM, e SIM no campo Indicativo Isenção, preenchendo as demais informações exigidas.\nLembramos que quando o valor for tributável, mas não houver retenção por ser valor inferior ao valor da tabela da Receita Federal, não deverá ser informada a retenção do imposto de renda. Caso haja um processo de suspensão de exigibilidade, este precisará ser cadastrado no módulo prestação de contas para ser vinculado no cadastro de título.  \nCaso seja algum outro tipo de isenção, você deverá informar SIM no campo \"Indicativo Isenção\" e preencher os demais campos que serão solicitados para prosseguir com o cadastro: Valor isenção, Tipo isenção e Data moléstia grave e/ou descrição, se for o caso. O preenchimento deverá ser de acordo com os dados do processo para o qual você está cadastrando a despesa.  ",
    "É necessário que seja feito o ajuste para emissão de borderô e posterior anulação do saldo dos centavos da NPD. Após feito isso, solicitar à GSEOF que seja realizada a desvinculação do empenho do título para a emissão de NAE do valor residual. ",
    "Solicitar à GSEOF \n",
    "se não há retenção de IR, não deve informar valor de base de cálculo e nem de Valor retenção. Deverá informar o valor no campo Valor Isenção. O valor isenção é o valor que está isento do imposto, ou seja, se o valor total do título for isento, este valor deverá ser informado. Neste caso, o valor da base de cálculo do IRRF deverá ser 0,00, já que não haverá valor retido e todo o valor é isento. \nSe houver valor tributável, informe o valor da base de cálculo e o valor do IR.\nPode ocorrer de parte do valor ser tributável e parte isenta, neste caso, preencha os campos com os respectivos valores.",
    "O SOF exige o PIS devido à categoria cadastrada anteriormente Jeton Individual. Será necessário cadastrar essa informação para prosseguir com o cadastro.",
    "É necessário atualizar o endereço do credor no GRP e posteriormente carregar a informação no SOF.",
    "O problema ocorreu porque não foi cadastrado o DAE no sistema.\nSerá necessário anular a liquidação e o cancelar o título. Ao cadastrar o novo Título, deverá informar SIM no campo Título Acompanhado. \nEm seguida, cadastrar o DAE informando SIM no campo Este Título Acompanha Outro e informando o número do título cadastrado no passo anterior.",
    "Solicitar à GSEOF\n",
    "Bloquear os parâmetros do projeto empreendimento para que ele não seja exigido quando do lançamento do empenho. Módulo Prestação de Contas: Cadastros > Projeto Empreendimento > Despesas. Clica na pastinha amarela (a pastinha verde é para criar um novo) e pesquisa pelo Projeto Empreendimento desejado. Clicar em pesquisar, rolar até o fim e clicar em \"Ok\". Digitar a data de hoje para \"Data Expiração\" e salvar. ",
    "Para o cancelamento deste título, você precisará primeiro fazer uma substituição de despesa no GRP, pelo valor bruto da NF, incluindo o valor do desconto lei 9145/06. Neste caso, precisará ter saldo de empenho para acobertar este valor do desconto lançado no título SOF, além do saldo já existente. Caso haja empenho com saldo, proceder com os seguintes passos:  1) alterar a despesa no SOF para \"A empenhar\"; 2) fazer a substituição do empenho no GRP, incluindo o empenho que possui o saldo total (valor bruto da despesa, incluindo o valor do desconto lei); 3) fazer a alteração da despesa novamente no SOF, incluindo novamente o empenho conforme consta do GRP; 4) cancelar a liberação do título no SOF (atenção: esta etapa só poderá ser realizada após a reinserção do empenho, não poderá cancelar o título sem o empenho vinculado); 5) cancelar o título no SOF. \nCaso não tenha saldo, avaliar a entrada do documento no GRP para ver se consta o registro do desconto lei.Se constar, é necessário: 1) alterar a despesa no SOF para \"A empenhar\"; 2) fazer a substituição do empenho no GRP, incluindo o  saldo do empenho 383 no GRP; 3) fazer a alteração da despesa novamente no SOF, incluindo novamente o empenho conforme consta do GRP; \nSó depois disso solicitar à GSEOF cancelar o titulo e desvincular o saldo. ",
    "Só dá para excluir o empenho quando a liquidação foi anulada. Solicitar verificação à GSEOF. ",
    "Verificar POP publicado no link: https://ead.pbh.gov.br/enrol/index.php?id=4009 ",
    "Verificar POP publicado no link: https://ead.pbh.gov.br/course/view.php?id=4115",
    "Verificar POP publicado no link: https://ead.pbh.gov.br/enrol/index.php?id=3854",
    "Verificar POP publicado no link: https://ead.pbh.gov.br/enrol/index.php?id=3817",
    "Verificar POP publicado no link: https://ead.pbh.gov.br/enrol/index.php?id=3889",
    "Para desagrupar as NPDs, é necessário informar o número do título acumulador na tela de acumulação, marcar todas, retorná-las para o lado esquerdo e salvar -  isso vai cancelar o título acumulador.",
    "É necessário anular as NPDs, cancelar a liberação dos títulos, alterar as datas de vencimento dos títulos, liberá-los novamente e emitir novas NPDs com a nova data de vencimento. Após isso, gerar novo acumulador e incluir o novo código de barras por meio da captura.",
    "Sobre este assunto, cumpre esclarecer que  a multa pode ser inserida tanto no título prinicipal quanto no acumulador. Para a exclusão do valor da multa, é necessário anular a liquidação e solicitar à equipe GSEOF a exclusão do empenho da multa do título, somente após a exclusão do empenho é possível retirar o valor da multa do título. Feito isso, é possível fazer a acumulação dos títulos e a inclusão da multa no acumulador, posteriormente, faz-se a inclusão do empenho da multa por meio da alteração da despesa e é possível liquidar o valor da multa e incluir o código de barras no título via captura de código de barras. ",
    "1) Ao gerar títulos com retenção de INSS, sempre devem enviar o email solicitando a geração do DARF.\n2) A acumulação de DARF INSS só é possível quando a despesa é processada no módulo de títulos.\n3) Sempre que houver um título no mês, mais outro título com valor menor que R$10,00, devem acumular os dois títulos, pois não é possível pagar DARF INSS com valor inferior a 10,00. Como acumular: salve o título acumulador com o título em questão. Abra o título acumulador gerado na funcionalidade de acumulação, informe sim no campo DARF INSS menor que 10,00, informe a competência inicial e final para que o SOF busque os títulos com valores inferiores a 10,00 e inclua-os no título acumulador gerado.\n4) Como acumular os títulos (regra geral): Informe os dados da NPD prinicpal nos filtros correspondentes da funcionalidade \"Atividade de Acumulação de DARF-INSS\". Ao carregar os títulos e NPDs de INSS, marque aqueles que serão pagos em um mesmo DARF para acumular, clique na seta para direita. Após clicar na seta, o sistema carregará os dados para o lado direito da tela, aí você clica em Salvar. O sistema vai retornar um número provisório de Título acumulador (anote este número para fazer a captura do código de barras). Na atividade \"Captura de Código de Barras\", no campo \"Pesquisar título por: NÚMERO PROVISÓRIO\" Informe o número do título acumulador. Após carregar os dados, o sistema abrirá um campo com o nome \"Capturar código barra\", clique nele e informe informe SIM no campo \"Via código barra\". Clique na aba Dados complementares e informe o código de barras do DARF e salve no disquete",
    "Informe os dados da NPD prinicpal nos filtros correspondentes. Ao carregar os títulos e NPDs de INSS, marque aqueles que serão pagos em um mesmo DARF para acumular, clique na seta para direita:"
  ),
  check.names = FALSE
)

dados_json <- toJSON(base_problemas_solucoes, pretty = TRUE)

system_prompt_restrito <- paste(
  "Você é um assistente virtual especialista de suporte focado em problemas e soluções do sistema SOF/GRP.",
  "Sua função é responder às dúvidas dos usuários usando EXCLUSIVAMENTE a base de dados fornecida a seguir.",
  "",
  "REGRAS ESTRITAS DE RESPOSTA:",
  "1. Responda APENAS com base nos dados fornecidos abaixo.",
  "2. NÃO utilize conhecimentos externos nem invente soluções.",
  "3. Se a dúvida do usuário não puder ser respondida com as informações da base de dados, responda exatamente: 'Desculpe, não encontrei essa informação na base de dados.'",
  "",
  "--- BASE DE DADOS (PROBLEMAS E SOLUÇÕES) ---",
  dados_json
)

# ==============================================================================
# 2. INTERFACE DO USUÁRIO (UI)
# ==============================================================================
ui <- page_fluid(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  
  tags$head(
    tags$style(HTML("
      .main-container {
        max-width: 900px;
        margin: 0 auto;
        padding-top: 30px;
        padding-bottom: 50px;
      }
      .card-resposta {
        background-color: #ffffff;
        border: 1px solid #e3e6f0;
        border-radius: 8px;
        padding: 20px;
        margin-top: 20px;
        box-shadow: 0 0.15rem 1.75rem 0 rgba(58, 59, 69, 0.05);
      }
      .card-resposta p, .card-resposta li {
        font-size: 1.05rem;
        line-height: 1.6;
        color: #2c3e50;
      }
    "))
  ),
  
  div(
    class = "main-container",
    h2("Assistente de Suporte SOF - Inteligência Artificial", class = "mb-1 text-primary"),
    p("Agente virtual de consultas rápidas à base de dados interna.", class = "text-muted mb-4"),
    
    card(
      card_body(
        textAreaInput(
          "pergunta", 
          "Digite a sua dúvida:", 
          rows = 3, 
          width = "100%",
          placeholder = "Ex: Como proceder para acumular DARF?"
        ),
        actionButton(
          "btn_enviar", 
          "Enviar Pergunta", 
          class = "btn-primary w-100 mt-2"
        )
      )
    ),
    
    uiOutput("area_resposta")
  )
)

# ==============================================================================
# 3. LÓGICA DO SERVIDOR (SERVER)
# ==============================================================================
server <- function(input, output, session) {
  
  chave_api <- Sys.getenv("GEMINI_API_KEY")
  
  resposta_val <- eventReactive(input$btn_enviar, {
    req(input$pergunta)
    
    url_api <- paste0(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=", 
      chave_api
    )
    
    corpo_requisicao <- list(
      system_instruction = list(
        parts = list(list(text = system_prompt_restrito))
      ),
      contents = list(
        list(
          role = "user",
          parts = list(list(text = input$pergunta))
        )
      )
    )
    
    max_tentativas <- 3
    tentativa <- 1
    sucesso <- FALSE
    resultado <- NULL
    
    while (tentativa <= max_tentativas && !sucesso) {
      res <- tryCatch({
        POST(
          url_api,
          body = corpo_requisicao,
          encode = "json",
          content_type_json()
        )
      }, error = function(e) {
        return(NULL)
      })
      
      if (!is.null(res)) {
        status <- status_code(res)
        conteudo <- content(res, as = "parsed")
        
        if (status == 200 && is.null(conteudo$error)) {
          sucesso <- TRUE
          resultado <- conteudo$candidates[[1]]$content$parts[[1]]$text
        } else {
          msg_erro <- if (!is.null(conteudo$error$message)) conteudo$error$message else ""
          
          if (status %in% c(429, 503) || grepl("demand|quota|limit", msg_erro, ignore.case = TRUE)) {
            Sys.sleep(2 * tentativa)
            tentativa <- tentativa + 1
          } else {
            return(paste("Erro da API Gemini:", msg_erro))
          }
        }
      } else {
        Sys.sleep(2 * tentativa)
        tentativa <- tentativa + 1
      }
    }
    
    if (sucesso) {
      return(resultado)
    } else {
      return("A API do Gemini está com alta demanda no momento. Aguarde alguns segundos e clique em 'Enviar Pergunta' novamente.")
    }
  })
  
  output$area_resposta <- renderUI({
    res <- resposta_val()
    req(res)
    
    div(
      class = "card-resposta",
      h5("Resposta do Agente:", class = "mb-3 text-secondary"),
      markdown(res)
    )
  })
}

# ==============================================================================
# 4. EXECUÇÃO DO APLICATIVO
# ==============================================================================
shinyApp(ui = ui, server = server)