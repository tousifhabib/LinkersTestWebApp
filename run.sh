#!/usr/bin/env bash

# コマンドが非ゼロステータスで終了した場合、すぐにスクリプトを終了する
set -e

# 未定義の変数を置換時にエラーとして扱う
set -u

# ログ用のスクリプト名
SCRIPT_NAME=$(basename "$0")

# ログファイル
LOG_FILE="setup_and_run.log"

# メッセージをログに記録する関数
log() {
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# エラーを処理する関数
handle_error() {
    log "エラー: $1"
    exit 1
}

# コマンドが存在するか確認する関数
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 必要なコマンドが存在するか確認
for cmd in ruby npm; do
    command_exists "$cmd" || handle_error "$cmd が必要ですが、インストールされていません。"
done

# ディレクトリパス
BACKEND_DIR="LinkersTestBackend"
FRONTEND_DIR="linkers-test-frontend"

# 親ディレクトリに移動
cd "$(dirname "$0")" || handle_error "親ディレクトリに移動できませんでした"

log "RailsとReactプロジェクトのセットアップと実行スクリプトを開始します"

# Railsプロジェクトのセットアップと実行
log "Railsプロジェクトのセットアップ"
cd "$BACKEND_DIR" || handle_error "$BACKEND_DIR ディレクトリに移動できませんでした"

log "Rubyの依存関係をインストール中"
bundle install || handle_error "Rubyの依存関係のインストールに失敗しました"

log "ポート3000でRailsサーバーを起動中"
rails server -p 3000 &
RAILS_PID=$!
log "RailsサーバーがPID $RAILS_PID で起動しました"

# 親ディレクトリに戻る
cd ..

# Reactプロジェクトのセットアップと実行
log "Reactプロジェクトのセットアップ"
cd "$FRONTEND_DIR" || handle_error "$FRONTEND_DIR ディレクトリに移動できませんでした"

log "Nodeの依存関係をインストール中"
npm install || handle_error "Nodeの依存関係のインストールに失敗しました"

log "ポート3001でReact開発サーバーを起動中"
PORT=3001 npm start &
REACT_PID=$!
log "ReactサーバーがPID $REACT_PID で起動しました"

# スクリプト終了時の処理をトラップ
trap 'log "サーバーを停止中"; kill $RAILS_PID $REACT_PID; exit' INT TERM EXIT

log "両方のサーバーが稼働中です。停止するにはCtrl+Cを押してください。"

# 両方のプロセスを待つ
wait
