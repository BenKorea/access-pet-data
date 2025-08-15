my_plot_monthly_counts <- function(dt, date_col, title) {
  # 변수 이름(표현식)을 가져옴
  date_sym <- substitute(date_col)
  
  # 날짜 컬럼 값을 가져와 연-월 변환
  year_month <- as.Date(format(eval(date_sym, dt, parent.frame()), "%Y-%m-01"))
  
  # 월별 빈도 계산
  monthly_counts <- data.table(YearMonth = year_month)[, .N, by = YearMonth][order(YearMonth)]
  
  # 그래프 생성
  ggplot(monthly_counts, aes(x = YearMonth, y = N)) +
    geom_col(fill = "steelblue") +
    theme_minimal() +
    labs(title = title, x = "연도", y = "월별건수") +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}
