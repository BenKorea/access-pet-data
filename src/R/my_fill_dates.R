my_copy_examdate <- function(na_data, reference_data) {
  log_debug("ExamDate 복사 시작")
  
  # PtID, ReqDate로 매칭해서 ExamDate 채우기
  na_data[reference_data, 
          on = .(PtID, ReqDate), 
          ExamDate := i.ExamDate]
  
  log_info("ExamDate 복사 완료")
  return(na_data)
}
