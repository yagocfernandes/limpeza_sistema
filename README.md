# Limpeza de Sistema | Windows Native Maintenance & RAM Optimizer

[![Repository](https://img.shields.io/badge/GitHub-limpeza__sistema-181717?style=for-the-badge&logo=github)](https://github.com/HighestCoder/limpeza_sistema)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows)](https://github.com/HighestCoder/limpeza_sistema)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE?style=for-the-badge&logo=powershell)](https://github.com/HighestCoder/limpeza_sistema)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](https://github.com/HighestCoder/limpeza_sistema)

> **Repositório Oficial:** [https://github.com/HighestCoder/limpeza_sistema](https://github.com/HighestCoder/limpeza_sistema)

Uma solução modular, resiliente e 100% nativa para purga de caches residuais, otimização de rede e liberação de memória RAM no Windows — desenvolvida sob a filosofia **Vibe Coding** com rigor de infraestrutura corporativa: **zero dependências externas e zero impacto nos processos ativos do desenvolvedor.**

---

##  O Problema (Contexto)

Para desenvolvedores, engenheiros de dados e profissionais que operam ambientes locais pesados (VS Code, containers Docker, bancos de dados locais, instâncias de LLM e navegadores com dezenas de abas), a manutenção periódica do Windows costuma ser um dilema:

- **Softwares de terceiros invasivos:** Otimizadores comerciais frequentemente instalam bloatware, injetam telemetria desnecessária ou aplicam heurísticas agressivas.
- **Interrupção destrutiva (*Kill-Switches*):** Scripts comuns utilizam `taskkill` indiscriminado, encerrando IDEs, sessões ativas e pipelines em andamento.
- **Acúmulo invisível de arquivos:** Caches de atualizações do sistema (`SoftwareDistribution\Download`) e gigabytes de `%TEMP%` travam a performance de I/O do disco.
- **RAM represada:** O Windows nem sempre devolve prontamente as páginas de memória de processos inativos (Working Sets inflados), causando gargalos sem que nenhum processo esteja efetivamente em pico de CPU.

---

##  A Solução (A Abordagem Vibe Coder)

Construído a partir de uma sólida bagagem de **Suporte de TI & Infraestrutura**, orquestrando **Engenharia de Prompt e Modelos de Linguagem Avançados**, este projeto demonstra o ápice do movimento *Vibe Coding*: unir visão arquitetural e requisitos estritos de segurança a implementações elegantes, seguras e reproduzíveis.

### Pilares Arquiteturais:
- **Zero Dependências:** 100% construído com ferramentas nativas do ecossistema Windows (PowerShell + Batch).
- **Sem Interrupções (Zero Kill-Switch):** Em vez de matar processos, o script utiliza a API nativa do Windows (`psapi.dll` via P/Invoke) invocando `EmptyWorkingSet`, solicitando ao kernel o esvaziamento gracioso de páginas de memória inativas para o standby.
- **Tratamento Silencioso de Concorrência:** Arquivos com handles abertos por processos ativos em desenvolvimento são ignorados silenciosamente sem travar o script.
- **Arquitetura Plug-and-Play:** Dividido em submódulos desacoplados (`Mod_Cache`, `Mod_Rede`, `Mod_Memoria`, `Mod_Logger`).

---

##  Estrutura do Projeto

```text
limpeza_sistema/
│
├── Manutencao-Sistema.ps1   # Núcleo de automação modular e chamadas da API Win32
├── Executar-Otimizacao.bat   # Gatilho invisível (Bypass de ExecutionPolicy sem console)
└── README.md                # Documentação técnica e guia de orquestração
```

---

##  Módulos e Funcionamento Técnico

| Módulo | Ação Executada | Mecanismo |
| :--- | :--- | :--- |
| **`Mod_Cache`** | Purga de `%TEMP%`, `Windows\Temp`, Lixeira e cache do Windows Update (`SoftwareDistribution\Download`). | `Clear-RecycleBin` e remoção com skip de concorrência (`-ErrorAction SilentlyContinue`). |
| **`Mod_Rede`** | Flush de cache DNS e revalidação de tabelas de nomes NetBIOS. | `Clear-DnsClientCache`, `ipconfig /flushdns` e `nbtstat -R`. |
| **`Mod_Memoria`** | Trimming de Working Sets e coleta de lixo no heap .NET. | `[System.GC]::Collect()` e chamada P/Invoke para `psapi.dll -> EmptyWorkingSet`. |
| **`Mod_Logger`** | Registro auditável de cada etapa em arquivo texto. | Gravação contínua com timestamp em `$env:USERPROFILE\manutencao_sistema.log`. |

---

##  Instalação e Uso

### 1. Execução Rápida (1-Click)
1. Clone ou baixe este repositório:
   ```powershell
   git clone https://github.com/HighestCoder/limpeza_sistema.git
   ```
2. Dê um duplo clique no arquivo **`Executar-Otimizacao.bat`**.
3. O script executará em segundo plano (janela oculta) e criará o arquivo de log detalhado em seu diretório de usuário (`%USERPROFILE%\manutencao_sistema.log`).

### 2. Integração com Microsoft Power Automate Desktop (PAD)
Para automatizar a execução de forma programada:
1. Abra seu fluxo no **Power Automate Desktop**.
2. Adicione a ação **"Executar aplicativo"** ou **"Executar script do PowerShell"**.
3. Em linha de comando, defina:
   ```cmd
   powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Caminho\Ate\limpeza_sistema\Manutencao-Sistema.ps1"
   ```
4. Salve e atribua um gatilho diário/semanal pelo Agendador de Tarefas ou pelo próprio PAD.

---

##  Auditoria e Logs

Após cada execução, consulte o arquivo gerado em:
```text
%USERPROFILE%\manutencao_sistema.log
```
Exemplo de saída:
```text
[2026-11-26 08:40:35] [INFO] === CICLO DE MANUTENCAO PROGRAMADA INICIADO ===
[2026-11-26 08:40:35] [INFO] Iniciando Mod_Cache: Limpeza de temporarios e lixeira...
[2026-11-26 08:40:36] [SUCESSO] Lixeira esvaziada com sucesso.
[2026-11-26 08:40:38] [SUCESSO] Mod_Cache concluido: 142 itens removidos; 18 itens protegidos/em uso.
[2026-11-26 08:40:38] [INFO] Iniciando Mod_Rede: Flush de DNS e renovacao de tabela NetBIOS...
[2026-11-26 08:40:39] [SUCESSO] Mod_Rede concluido: DNS limpo e sockets revalidados com sucesso.
[2026-11-26 08:40:39] [INFO] Iniciando Mod_Memoria: Coleta de lixo e trim de Working Sets via psapi.dll...
[2026-11-26 08:40:40] [SUCESSO] Mod_Memoria concluido: Working Sets de 94 processos foram otimizados sem encerramento.
[2026-11-26 08:40:40] [SUCESSO] === CICLO DE MANUTENCAO FINALIZADO COM EXITO ===
```

---

##  Licença

Distribuído sob a licença MIT. Consulte `LICENSE` para mais informações.
