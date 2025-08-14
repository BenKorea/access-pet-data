#!/usr/bin/env Rscript
# =====================================
# scripts/install_global.R
# 사용자 전역 라이브러리에 패키지 설치 스크립트
# =====================================

# 기본 설치 패키지
default_pkgs <- c(
  "devtools",       # 패키지 개발 도구
  "languageserver", # VS Code, LSP 지원
  "httpgd"          # 웹 기반 그래픽 디바이스
)

# 사용자 전역 라이브러리 경로 확인 및 생성
user_lib <- Sys.getenv("R_LIBS_USER")
if (user_lib == "") {
  stop("R_LIBS_USER 환경변수가 비어 있습니다. R 설정을 확인하세요.")
}
if (!dir.exists(user_lib)) {
  message("사용자 전역 라이브러리 생성: ", user_lib)
  dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
}

# 설치 함수
install_global <- function(pkgs) {
  install.packages(pkgs,
                   lib = user_lib,
                   dependencies = TRUE,
                   repos = "https://cloud.r-project.org")
}

# 설치 시작
message("사용자 전역 라이브러리: ", user_lib)
message("설치할 패키지: ", paste(default_pkgs, collapse = ", "))
install_global(default_pkgs)

# 설치 결과 출력
installed <- sapply(default_pkgs, function(p) {
  if (p %in% rownames(installed.packages(lib.loc = user_lib))) {
    paste(p, as.character(packageVersion(p, lib.loc = user_lib)))
  } else {
    paste(p, "설치 실패")
  }
})
message("설치 결과:\n", paste(installed, collapse = "\n"))
