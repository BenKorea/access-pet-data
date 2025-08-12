import logging
from common.logger import get_logger

def test_logger_yaml():
    logger = get_logger()
    logger.info("logging.yml 테스트 로그")
    print("테스트 로그를 남겼습니다.")
    assert True

if __name__ == "__main__":
    test_logger_yaml()
    print("테스트 완료")
