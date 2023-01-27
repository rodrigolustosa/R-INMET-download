# R-INMET-download
[![en](https://img.shields.io/badge/lang-en-red)](https://github.com/rodrigolustosa/R-INMET-download/blob/main/README-en.md)
[![pt-br](https://img.shields.io/badge/lang-pt--br-blue)](https://github.com/rodrigolustosa/R-INMET-download/blob/main/README.md)

Baixa dados meteorológicos do Instituto Nacional de Meteorologia (INMET) em linguagem R.

## Descrição Geral

Esse repositório consegue baixar dados do INMET de duas formas diferentes (com os scripts [`inmet_download_1.R`](https://github.com/rodrigolustosa/R-INMET-download/blob/main/inmet_download_1.R) e [`inmet_download_2.R`](https://github.com/rodrigolustosa/R-INMET-download/blob/main/inmet_download_2.R)) utilizando o [portal do INMET](https://portal.inmet.gov.br/). No geral, `inmet_download_1.R` é **mais fácil de usar** mas não consegue acessar certos dados e deve baixar muitos dados que não são de seu interesse, já o `inmet_download_2.R` tem **acesso a mais dados** (como os do CIIAGRO) mas não irá funcionar no Windows sem modificar o código e a velocidade de download será mais baixa. Abaixo há um resumo das principais condições.

|    |  script 1 |  script 2 |
|----------|:------:|:------:|
| **Sistema Operacional**                  | Linux e Windows :heavy_check_mark:            | Linux |
| **Estações acessadas**                  | Somente estações INMET automáticas | estações INMET automáticas e convencionais e de outros gestores (todas que estão disponíveis em https://mapas.inmet.gov.br/) :heavy_check_mark: |
| **Configuração**                  | Apenas bibliotecas do R :heavy_check_mark:            | Docker e bibliotecas do R |
| **Tempo para que os dados estejam disponíveis**       | Pode demorar vários dias         | Normalmente no mesmo dia :heavy_check_mark:|
| **Menor quantidade de dados possível por arquivo baixado** (Obs.: No final ambos retornam um único arquivo com somente os dados requisitados)  | Todas as estações automáticas do INMET, por ano, em um mesmo aquivo ZIP (~100 MB por arquivo) | Arquivo CSV para cada estação e dia (~3.7 KB) :heavy_check_mark: |
| **Velocidade de Download**                   | Rádipo :heavy_check_mark:                         | Mediano |

No geral, `inmet_download_1.R` é recomendável para Windows, caso serão utilizadas muitas estações ou se não pretende-se instalar o Docker.

## Como configurar e usar

Instale R e RStudio. As bibliotecas utilizadas podem ser baixadas executando-se o seguinte código no R:
```
install.packages("tidyverse")
install.packages("stringr")
install.packages("stringi")
install.packages("lubridate")
install.packages("RCurl")     # only for script 1
install.packages("RSelenium") # only for script 2
```
Se estiver utilizando Linux, é necessário antes instalar algumas dependências no terminal (como mostrado [aqui](https://blog.zenggyu.com/en/post/2018-01-29/installing-r-r-packages-e-g-tidyverse-and-rstudio-on-ubuntu-linux/)).

Baixe a última versão do repositório [aqui](https://github.com/rodrigolustosa/R-INMET-download/releases) (`Assets` -> `Source Code (zip)`) e descompacte onde preferir.


### Script 1

Abra `inmet_download_1.R`, preencha as datas e horas de início e fim e os códigos das estações (você pode procurar mais estações usando o portal do INMET) e então execute o script. Seus arquivos serão baixados no seu diretório de trabalho. 

### Script 2

Antes de executar o `inmet_download_2.R`, é necessário instalar o docker. Siga as instruções dadas na [página do docker](https://docs.docker.com/engine/install/ubuntu/) (programa separado do R). Após instalado, agora você pode executar `inmet_download_2.R`. Nesse código há duas funções que enviam comandos ao terminal do Linux, a `open_docker` e a `close_docker`. Elas enviam ao terminal, respectivamente:
```
sudo docker run --name rselenium_inmet -d -p 4445:4444 -v dir_path:/home/seluser/Downloads:rw -d selenium/standalone-firefox:2.53.1
```
para iniciar um docker (onde `dir_path` precisa ser substituído pelo endereço absoluto onde os dados serão baixados) e
```
sudo docker stop rselenium_inmet; sudo docker rm rselenium_inmet
```
para parar e remover o docker anteriormente criado. Se qualquer problema ocorrer com essas funções no R, você pode executar esses comandos no terminal ao invés de executar a função no R. Como no script 1, preencha as datas e horas de início e fim e os códigos das estações e então execute o script. Seus arquivos serão baixados no seu diretório de trabalho. 

[![version](https://img.shields.io/badge/version-0.3.0-green)](https://github.com/rodrigolustosa/R-INMET-download/releases/tag/v0.3.0)

