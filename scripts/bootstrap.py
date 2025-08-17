#!/usr/bin/env python3
import sys, sysconfig
from pathlib import Path

# 1. 현재 파이썬 site-packages 위치

site_packages = Path(sysconfig.get_paths()["purelib"])

# 2. 프로젝트 루트와 src 경로
project_root = Path(__file__).resolve().parent.parent
src_path = project_root / "src"

# 3. src 경로 검증
if not src_path.is_dir():
    sys.exit(f"[ERROR] src 경로 없음: {src_path}")

# 4. .pth 파일 생성
pth_file = site_packages / "project_paths.pth"
pth_file.write_text(str(src_path) + "\n", encoding="utf-8")

# 5. 확인 메시지
print(f"[OK] .pth 생성: {pth_file}")
print(f"[OK] 추가 경로: {src_path}")



# 8. check_syspath.py 실행 (모든 변수 정의 이후, 맨 마지막에 위치)
import subprocess
check_syspath = project_root / "scripts" / "check_syspath.py"
if check_syspath.is_file():
    print(f"[INFO] check_syspath.py 실행...")
    result = subprocess.run([sys.executable, str(check_syspath)], capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(f"[WARN] check_syspath.py stderr: {result.stderr}")
else:
    print(f"[WARN] check_syspath.py 파일 없음: {check_syspath}")
