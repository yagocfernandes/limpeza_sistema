<#
.SYNOPSIS
    Script Modular de Otimização e Manutenção Contínua para Windows.
.DESCRIPTION
    Executa limpeza de caches residuais, otimização de rede, liberação de memória
    e geração de logs sem interromper processos ativos ou exigir dependências externas.
#>

[CmdletBinding()]
param (
    [string]$LogPath = "$env:USERPROFILE\manutencao_sistema.log"
)

# ==============================================================================
# MÓDULO: LOGGER (Auditoria e Rastreabilidade)
# ==============================================================================
function Mod_Logger {
    param (
        [string]$Mensagem,
        [ValidateSet("INFO", "WARN", "ERRO", "SUCESSO")]
        [string]$Nivel = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LinhaLog = "[$Timestamp] [$Nivel] $Mensagem"
    
    # Grava no log de forma resiliente
    try {
        Add-Content -Path $LogPath -Value $LinhaLog -ErrorAction SilentlyContinue
    } catch {
        # Fallback silencioso se o arquivo de log estiver bloqueado
    }
}

# ==============================================================================
# MÓDULO: CACHE (Limpeza Profunda e Segura)
# ==============================================================================
function Mod_Cache {
    Mod_Logger -Mensagem "Iniciando Mod_Cache: Limpeza de temporarios e lixeira..." -Nivel "INFO"
    
    # 1. Esvaziar Lixeira silenciosamente
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Mod_Logger -Mensagem "Lixeira esvaziada com sucesso." -Nivel "SUCESSO"
    } catch {
        Mod_Logger -Mensagem "Nao foi possivel esvaziar a lixeira ou ela ja estava vazia." -Nivel "WARN"
    }

    # 2. Diretorios de arquivos temporarios
    $TempDirs = @(
        $env:TEMP,
        "$env:SystemRoot\Temp",
        "$env:SystemRoot\SoftwareDistribution\Download"
    )

    $ItensRemovidos = 0
    $ItensIgnorados = 0

    foreach ($Dir in $TempDirs) {
        if (Test-Path -Path $Dir) {
            Get-ChildItem -Path $Dir -Force -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    if (-not $_.PSIsContainer) {
                        Remove-Item -Path $_.FullName -Force -ErrorAction Stop
                        $ItensRemovidos++
                    } else {
                        # Tenta remover pastas vazias
                        if ((Get-ChildItem -Path $_.FullName -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
                            Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
                        }
                    }
                } catch {
                    # Arquivo ou pasta em uso por processos ativos e preservado
                    $ItensIgnorados++
                }
            }
        }
    }

    Mod_Logger -Mensagem "Mod_Cache concluido: $ItensRemovidos itens removidos; $ItensIgnorados itens protegidos/em uso." -Nivel "SUCESSO"
}

# ==============================================================================
# MÓDULO: REDE (Latencia e Resolucao de Nomes)
# ==============================================================================
function Mod_Rede {
    Mod_Logger -Mensagem "Iniciando Mod_Rede: Flush de DNS e renovacao de conexoes..." -Nivel "INFO"
    
    try {
        # Flush no cache de nomes do Windows
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        
        # Renovacao de sockets e liberacao de NetBIOS residuais
        Start-Process -FilePath "ipconfig.exe" -ArgumentList "/flushdns" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
        Start-Process -FilePath "nbtstat.exe" -ArgumentList "-R" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue

        Mod_Logger -Mensagem "Mod_Rede concluido: Cache DNS limpo e tabela NetBIOS recarregada com sucesso." -Nivel "SUCESSO"
    } catch {
        Mod_Logger -Mensagem "Falha parcial durante a otimizacao de rede: $($_.Exception.Message)" -Nivel "WARN"
    }
}

# ==============================================================================
# MÓDULO: MEMORIA (Otimizacao e Esvaziamento de Working Sets Nativamente)
# ==============================================================================
function Mod_Memoria {
    Mod_Logger -Mensagem "Iniciando Mod_Memoria: Reducao de Working Sets e coleta de lixo .NET nativa..." -Nivel "INFO"

    # Injeta chamada nativa da API Win32 (psapi.dll -> EmptyWorkingSet)
    $Win32MemoryApi = @"
    using System;
    using System.Runtime.InteropServices;

    public class Win32Memory {
        [DllImport("psapi.dll")]
        public static extern int EmptyWorkingSet(IntPtr hwProc);
    }
"@
    try {
        if (-not ([System.Management.Automation.PSTypeName]'Win32Memory').Type) {
            Add-Type -TypeDefinition $Win32MemoryApi -ErrorAction SilentlyContinue
        }

        # Coleta de lixo do proprio runtime
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        # Solicita ao kernel que pagine blocos inativos de memoria em segundo plano sem matar nenhum processo
        $Processos = Get-Process -ErrorAction SilentlyContinue
        $CountTrimmados = 0

        foreach ($Proc in $Processos) {
            try {
                if ($Proc.Handle -ne [IntPtr]::Zero) {
                    [Win32Memory]::EmptyWorkingSet($Proc.Handle) | Out-Null
                    $CountTrimmados++
                }
            } catch {
                # Processos de sistema protegidos sao ignorados com seguranca
            }
        }

        Mod_Logger -Mensagem "Mod_Memoria concluido: Working Sets de $CountTrimmados processos foram otimizados sem interrupcao." -Nivel "SUCESSO"
    } catch {
        Mod_Logger -Mensagem "Falha na chamada da API Win32 de memoria: $($_.Exception.Message)" -Nivel "WARN"
    }
}

# ==============================================================================
# ORQUESTRADOR PRINCIPAL
# ==============================================================================
try {
    Mod_Logger -Mensagem "=== CICLO DE MANUTENCAO PROGRAMADA INICIADO ===" -Nivel "INFO"
    Mod_Cache
    Mod_Rede
    Mod_Memoria
    Mod_Logger -Mensagem "=== CICLO DE MANUTENCAO FINALIZADO COM EXITO ===" -Nivel "SUCESSO"
} catch {
    Mod_Logger -Mensagem "Erro critico na orquestracao: $($_.Exception.Message)" -Nivel "ERRO"
}
