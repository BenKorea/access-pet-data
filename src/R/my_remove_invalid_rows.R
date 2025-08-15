my_remove_invalid_rows <- function(dt) {
  # 필수 컬럼 존재 여부 확인
  required_cols <- c("PtID", "PtName", "ExamDate")
  stopifnot(all(required_cols %in% names(dt)))
  
  # 조건 1: PtID, PtName, ExamDate 모두 NA인 행
  all_na_rows <- is.na(dt$PtID) & is.na(dt$PtName) & is.na(dt$ExamDate)
  
  # 조건 2: PtID에 이상한 값이 포함되어 있고, 나머지 2항목이 NA인 경우
  invalid_ptid_pattern <- grepl("\\\\|^0$|^0\\.$|12:", dt$PtID)
  two_na_others <- (is.na(dt$PtName) & is.na(dt$ExamDate))
  invalid_ptid_rows <- invalid_ptid_pattern & two_na_others
  
  # 두 조건에 해당하지 않는 행만 남김
  cleaned_dt <- dt[!(all_na_rows | invalid_ptid_rows)]
  
  return(cleaned_dt)
}
