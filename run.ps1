# 厳格モードを有効化
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ログ用のスクリプト名
$SCRIPT_NAME = $MyInvocation.MyCommand.Name

# ログファイル
$LOG_FILE = "setup_and_run.log"

# メッセージをログに記録する関数
function Log-Message {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $message"
    Write-Host $logMessage
    Add-Content -Path $LOG_FILE -Value $logMessage
}

# エラーを処理する関数
function Handle-Error {
    param([string]$message)
    Log-Message "エラー: $message"
    exit 1
}

# コマンドが存在するか確認する関数
function Test-Command {
    param([string]$command)
    return [bool](Get-Command -Name $command -ErrorAction SilentlyContinue)
}

# 必要なコマンドが存在するか確認
$requiredCommands = @("ruby", "npm")
foreach ($cmd in $requiredCommands) {
    if (-not (Test-Command $cmd)) {
        Handle-Error "$cmd が必要ですが、インストールされていません。"
    }
}

# ディレクトリパス
$BACKEND_DIR = "LinkersTestBackend"
$FRONTEND_DIR = "linkers-test-frontend"

# 親ディレクトリに移動
Set-Location -Path $PSScriptRoot

Log-Message "RailsとReactプロジェクトのセットアップと実行スクリプトを開始します"

# Railsプロジェクトのセットアップと実行
Log-Message "Railsプロジェクトのセットアップ"
Set-Location -Path $BACKEND_DIR -ErrorAction Stop

Log-Message "Rubyの依存関係をインストール中"
bundle install
if ($LASTEXITCODE -ne 0) { Handle-Error "Rubyの依存関係のインストールに失敗しました" }

Log-Message "ポート3000でRailsサーバーを起動中"
$railsJob = Start-Job -ScriptBlock {
    Set-Location $using:BACKEND_DIR
    rails server -p 3000
}
Log-Message "Railsサーバーがバックグラウンドジョブとして起動しました"

# 親ディレクトリに戻る
Set-Location ..

# Reactプロジェクトのセットアップと実行
Log-Message "Reactプロジェクトのセットアップ"
Set-Location -Path $FRONTEND_DIR -ErrorAction Stop

Log-Message "Nodeの依存関係をインストール中"
npm install
if ($LASTEXITCODE -ne 0) { Handle-Error "Nodeの依存関係のインストールに失敗しました" }

Log-Message "ポート3001でReact開発サーバーを起動中"
$reactJob = Start-Job -ScriptBlock {
    Set-Location $using:FRONTEND_DIR
    $env:PORT = "3001"
    npm start
}
Log-Message "ReactサーバーがバックグラウンドジョブとしPIで起動しました"

# サーバーを停止する関数
function Stop-Servers {
    Log-Message "サーバーを停止中"
    Stop-Job -Job $railsJob, $reactJob
    Remove-Job -Job $railsJob, $reactJob
}

# クリーンアップアクションを登録
$exitHandler = {
    Stop-Servers
    exit
}
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action $exitHandler

Log-Message "両方のサーバーが稼働中です。停止するにはCtrl+Cを押してください。"

# ジョブが完了するまで待機（手動で中断されるまで実行）
try {
    Wait-Job -Job $railsJob, $reactJob
} finally {
    Stop-Servers
}