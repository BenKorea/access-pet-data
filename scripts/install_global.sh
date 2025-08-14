#!/usr/bin/env bash
# ==============================================
# scripts/install_global.sh
# R 사용자 전역 라이브러리 설치 스크립트
# ==============================================

set -e

# 1. 필요한 시스템 패키지 설치
echo "[INFO] Installing required system libraries..."
sudo apt update
sudo apt install -y \
    libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
    libharfbuzz-dev libfribidi-dev libcairo2-dev libfontconfig1-dev \
    zlib1g-dev libglib2.0-dev \
    pkg-config git

# 2. 사용자 전역 라이브러리 경로 확인
R_LIB_USER=$(Rscript -e 'cat(Sys.getenv("R_LIBS_USER"))')
if [ -z "$R_LIB_USER" ]; then
    echo "[ERROR] R_LIBS_USER is not set. Please check your R configuration."
    exit 1
fi

echo "[INFO] R user global library: $R_LIB_USER"

# 디렉토리 없으면 생성
if [ ! -d "$R_LIB_USER" ]; then
    echo "[INFO] Creating R user library directory..."
    mkdir -p "$R_LIB_USER"
fi

# 3. CRAN 패키지 설치 (httpgd 제외)
CRAN_PKGS=("devtools" "languageserver")
PKG_STR=$(printf '"%s",' "${CRAN_PKGS[@]}")
PKG_STR="c(${PKG_STR%,})"

echo "[INFO] Installing CRAN packages: ${CRAN_PKGS[*]}"
Rscript -e "install.packages(${PKG_STR}, lib = Sys.getenv('R_LIBS_USER'), dependencies = TRUE, repos = 'https://cloud.r-project.org')"

# 4. GitHub에서 httpgd 설치
echo "[INFO] Installing httpgd from GitHub..."
Rscript -e "if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes', lib = Sys.getenv('R_LIBS_USER'), repos = 'https://cloud.r-project.org'); remotes::install_github('nx10/httpgd', lib = Sys.getenv('R_LIBS_USER'))"

# 5. 설치 결과 확인
echo "[INFO] Installed package versions:"
Rscript -e "pkgs <- c(${PKG_STR}, 'httpgd'); lib <- Sys.getenv('R_LIBS_USER'); versions <- sapply(pkgs, function(p) if (p %in% rownames(installed.packages(lib.loc = lib))) as.character(packageVersion(p, lib.loc = lib)) else 'NOT INSTALLED'); print(versions)"

echo "[INFO] Installation completed."
