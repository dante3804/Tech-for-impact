# Tech-for-impact




# NetChain — 폐어망 적치장 AI 모니터링 플랫폼 (iOS)



---



## 📌 프로젝트 개요
 
현장 사진 한 장으로 폐어망 적치 위험도를 자동 수치화하고 수거 우선순위를 최적화하는 AI 모니터링 SaaS 플랫폼의 iOS 클라이언트입니다.
 
> 지자체 요청 없이는 수거되지 않는 폐어망 적치장이 방치되어 인근 주민의 호흡기 건강을 위협하고 있다.
 
전국 연안 폐어망 적치장의 방치 문제를 **YOLOv11 이미지 분석 + HRI(호흡기 위험지수) 산출**로 해결합니다.


 
---


 
## 🏗 시스템 아키텍처
 
```
iOS 앱 (Swift / SwiftUI)
        ↓  HTTP API 호출
FastAPI 백엔드 서버
        ↓
YOLOv11 Instance Segmentation  ←  TensorRT INT8 최적화 (NVIDIA)
        ↓  봉투 개수 카운팅
HRI 수식 계산
  HRI = (BagCount × 25kg × 0.985) × TimeDays × WeatherScore × ProximityScore
        ↓
PostgreSQL + PostGIS
        ↓
Kakao Map 기반 위험도 시각화
 
[현장 자동화 - 예정]
CCTV → Jetson Orin Nano Super → DeepStream → MQTT → FastAPI
```


 
---


 
## 📱 주요 기능
 
### 대시보드
- 거점별 HRI 점수 실시간 조회
- 수거 우선순위 1~5위 표시
- 위험/경계/양호 3단계 색상 분류
  - 🔴 위험 (HRI 80 이상)
  - 🟠 경계 (HRI 50~79)
  - 🟢 양호 (HRI 49 이하)
### AI 이미지 분석
- 카메라 직접 촬영 또는 갤러리 업로드
- YOLOv11 기반 봉투 자동 카운팅
- 분석 결과 → HRI 자동 계산 → 거점 데이터 반영
### 거점 관리
- 전국 적치장 거점 목록 조회
- 위치(위도/경도) 기반 지도 연동
- 봉투 수 / 방치 일수 / 풍속 / 주거지 거리 관리
### 수거 일정
- HRI 기반 자동 수거 일정 생성
- 주간 캘린더 뷰
- 수거 완료 처리 → HRI 자동 초기화
---

 
## 🛠 기술 스택

 
### iOS 클라이언트
| 구분 | 기술 |
|------|------|
| 언어 | Swift 5.9 |
| UI 프레임워크 | SwiftUI |
| 지도 | KakaoMapsSDK |
| 차트 | Swift Charts |
| 네트워크 | URLSession async/await |
| 최소 지원 버전 | iOS 16.0+ |


 
### 백엔드 (별도 레포)
| 구분 | 기술 |
|------|------|
| API 서버 | FastAPI (Python) |
| AI 모델 | YOLOv11s Instance Segmentation |
| 학습 환경 | Google Colab (Tesla T4 / A100) |
| 모델 정확도 | mAP@50 66.7% |
| 데이터베이스 | PostgreSQL + PostGIS |
| 기상 API | 기상청 단기예보 API |
| 대기질 API | 한국환경공단 에어코리아 API |

 
---

 
## 📂 프로젝트 구조
 
```
ESPA-iOS/
├── App/
│   ├── ESPAApp.swift              # 앱 진입점
│   └── ContentView.swift
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift    # 메인 대시보드
│   │   └── HRICardView.swift      # HRI 점수 카드
│   ├── Stockpile/
│   │   ├── StockpileListView.swift # 거점 목록
│   │   ├── StockpileDetailView.swift
│   │   └── ImageAnalysisView.swift # 사진 분석
│   ├── Schedule/
│   │   └── ScheduleView.swift     # 수거 일정
│   └── Map/
│       └── KakaoMapView.swift     # 지도 컴포넌트
├── Models/
│   ├── Stockpile.swift            # 거점 데이터 모델
│   ├── HRIResult.swift            # HRI 결과 모델
│   └── AnalysisResult.swift       # AI 분석 결과
├── Services/
│   ├── APIService.swift           # FastAPI 통신
│   ├── HRICalculator.swift        # HRI 계산 로직
│   └── LocationService.swift      # 위치 서비스
├── Utils/
│   └── Constants.swift            # API 엔드포인트 등
└── Resources/
    └── Info.plist
```

 
---

 
## 🚀 시작하기

 
### 요구사항
- Xcode 15.0+
- iOS 16.0+
- Kakao Developers 계정 (지도 API 키 필요)
- ESPA 백엔드 서버 실행 중


  
### 설치 및 실행
 
```bash
# 레포지토리 클론
git clone https://github.com/dante3804/espa-ios.git
cd espa-ios
```
 
```
1. Xcode에서 ESPA.xcodeproj 열기
2. Bundle ID 설정: com.espa.ESPA
3. Kakao Developers에서 앱 등록 후 API 키 발급
4. Info.plist에 카카오 앱 키 입력:
   KAKAO_NATIVE_APP_KEY = 발급받은_키
5. Constants.swift에서 API 서버 주소 설정:
   static let baseURL = "http://백엔드_서버_주소:8000"
6. 빌드 및 실행 (⌘R)
```
 
#### 백엔드 서버 연동
 
```bash
# ESPA 백엔드 레포 클론 후
cd espa-dashboard/backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```
 
---
 
## 📊 HRI 수식
 
```
HRI = (BagCount × W_avg × correction) × TimeDays × WeatherScore × ProximityScore
 
변수 설명:
  BagCount      : YOLOv11이 탐지한 봉투 개수
  W_avg         : 봉투 평균 무게 25.0 kg (현장 실측값)
  correction    : 충전율 보정계수 0.985 (실측 기반)
  TimeDays      : 방치 일수
  WeatherScore  : 1 + min(풍속/10, 1.5) + (100-습도)/100
  ProximityScore: 1 + (1/주거지거리km)
```
 
---
 
## 🔬 AI 모델 학습 상세
 
### 모델 기본 정보
 
| 항목 | 내용 |
|------|------|
| 모델 아키텍처 | YOLOv11s Instance Segmentation |
| 탐지 클래스 | `bag` (폐어망 마대 봉투 단일 클래스) |
| 최종 mAP@50 | 66.7% |
| Precision | 75.3% |
| Recall | 62.8% |
| 학습 환경 | Google Colab (Tesla T4 / A100) |
| 라벨링 플랫폼 | Roboflow (Auto Label + 수동 검수) |
 
### 데이터셋 구성
 
| 구분 | 내용 |
|------|------|
| 원본 이미지 | 48장 (부산 다대포항, 울산 정자항, 인천 연평도 등) |
| Augmentation | Flip / Rotation ±20° / Brightness ±30% / Blur / Noise |
| Augmentation 배율 | 5배 적용 → 약 240장 |
| Train / Valid / Test | 70 / 20 / 10 |
| 총 어노테이션 수 | 2,429개 |
| 라벨링 방식 | Polygon Segmentation (Smart Polygon 활용) |
 
### 학습 버전 히스토리
 
| 버전 | 변경사항 | mAP@50 |
|------|------|------|
| v1 | 초기 학습 (3클래스: bag_full / bag_half / net_loose) | 42.0% |
| v2 | 클래스 단순화 (bag 단일) + 데이터 추가 | 45.7% |
| v3 | Augmentation 강화 + YOLOv11s 업그레이드 | 60.1% |
| v4 | Auto Label 데이터 14장 추가 (총 48장) | 61.0% |
| v5 | patience=50, epoch 83 조기 종료 | 66.5% |
| **v6** | **patience=0, 300 epoch 완전 학습** | **66.7%** |
 
### 클래스 설계 배경
 
초기에는 `bag_full` / `bag_half` / `net_loose` 3개 클래스로 설계했으나, 현장 실측 결과 봉투의 95%가 꽉 찬 상태(full)임을 확인하여 클래스 불균형 문제를 해소하기 위해 `bag` 단일 클래스로 통합했습니다. 밀도 차이는 실측 보정계수(correction = 0.985)로 수식에 흡수하였습니다.
 
```python
# 현장 실측 기반 상수값
W_avg      = 25.0   # kg (봉투 평균 무게)
sigma      = 5.0    # kg (표준편차 ±5kg)
full_ratio = 0.95   # 95% 꽉 찬 봉투
correction = (0.95 × 1.0) + (0.05 × 0.7) = 0.985
```
 
---
 
## ⚡ 기술 고도화 로드맵 WITH NVIDIA
 
현재 CPU 기반 추론(1~3초/장)을 NVIDIA 기술 스택으로 전면 고도화하여 실시간 현장 자동화를 목표로 합니다.
 
### 1. TensorRT — 모델 추론 최적화
 
| 항목 | 내용 |
|------|------|
| 목적 | PyTorch 모델을 TensorRT 엔진으로 변환해 추론 속도 향상 |
| 변환 방식 | best.pt → ONNX → TensorRT Engine (.engine) |
| 최적화 | INT8 양자화 적용 (모델 크기 75% 감소) |
| 기대 효과 | CPU 1~3초 → Jetson GPU 0.05~0.1초 (20~30배 향상) |
| 적용 위치 | Jetson Orin Nano Super (현장 엣지 디바이스) |
| 상태 | 적용 완료 |
 
```python
# TensorRT 변환 코드
from ultralytics import YOLO
model = YOLO("best.pt")
model.export(format="engine", device=0, int8=True)
# → best.engine 생성 (Jetson 전용)
```
 
### 2. DeepStream SDK — 실시간 영상 파이프라인
 
| 항목 | 내용 |
|------|------|
| 목적 | CCTV 스트림을 실시간으로 분석하는 자동화 파이프라인 구축 |
| 처리 방식 | RTSP 스트림 → GStreamer → YOLOv11 TRT 추론 → 카운팅 |
| 핵심 기능 | Object Tracker (중복 카운팅 방지), 다중 카메라 동시 처리 |
| 전송 | MQTT 프로토콜로 FastAPI 서버에 분석 결과 전송 |
| 기대 효과 | 수동 사진 업로드 → 24시간 완전 무인 자동화 |
| 상태 | 적용 예정 |
 
```
[현장 파이프라인]
CCTV (RTSP)
    ↓ GStreamer 디코딩
DeepStream on Jetson
    ↓ YOLOv11-TRT 추론 (30fps)
봉투 카운팅 + 위치 추적
    ↓ MQTT
FastAPI 서버 → HRI 계산 → DB 저장
```
 
### 3. TAO Toolkit — 도메인 특화 재학습
 
| 항목 | 내용 |
|------|------|
| 목적 | NVIDIA 사전학습 모델 기반으로 폐어망 봉투 특화 파인튜닝 |
| 방식 | NGC 사전학습 모델 (DetectNet_v2) → Transfer Learning |
| 학습 환경 | Google Colab Pro (A100 GPU) |
| 기대 효과 | 현재 mAP 66.7% → 75~80% 이상 달성 |
| 출력 | TensorRT 최적화 모델 자동 생성 |
| 상태 | 적용 예정 |
 
```bash
# TAO Toolkit 학습 명령어
tao model yolo_v4 train \
  -e /workspace/specs/yolo_v4_train.txt \
  -r /workspace/output \
  -k YOUR_NGC_KEY \
  --gpus 1
```
 
### 4. Omniverse Replicator — 합성 데이터 생성
 
| 항목 | 내용 |
|------|------|
| 목적 | 데이터 부족 문제 해결을 위한 가상 적치장 합성 데이터 생성 |
| 생성 대상 | net_loose (산적 어망) 클래스 위주 1,000장 이상 |
| 환경 구성 | 3D 가상 항구 적치장 (다양한 날씨 / 조명 / 각도 자동 변환) |
| 자동 라벨링 | 합성 데이터에 폴리곤 어노테이션 자동 생성 |
| 기대 효과 | 실제 데이터 48장 + 합성 1,000장 → mAP 80%+ 달성 |
| 상태 | 🔄 적용중 |
 
```python
# Omniverse Replicator 합성 데이터 생성 스크립트 예시
import omni.replicator.core as rep
 
with rep.new_layer():
    # 가상 적치장 환경 구성
    ground = rep.create.plane(scale=10)
    bags = rep.create.from_usd("omniverse://bag_asset.usd")
 
    with rep.trigger.on_frame(num_frames=1000):
        with bags:
            rep.modify.pose(
                position=rep.distribution.uniform((-5,-5,0),(5,5,0)),
                rotation=rep.distribution.uniform((0,0,0),(0,0,360))
            )
        rep.modify.light(
            intensity=rep.distribution.uniform(500, 2000)
        )
```
 
### NVIDIA 기술 적용 단계별 성능 예측
 
```
현재 (CPU 기반)
  추론 속도: 1~3초/장
  mAP@50:   66.7%
  운영 방식: 수동 사진 업로드
 
TensorRT 적용 후
  추론 속도: 0.05~0.1초/장  (20~30배 향상)
  mAP@50:   66.7% 유지
 
TAO Toolkit 재학습 후
  추론 속도: 0.05~0.1초/장
  mAP@50:   75~80% (예상)
 
Omniverse 합성 데이터 + TAO 재학습 후
  추론 속도: 0.05~0.1초/장
  mAP@50:   80%+ (목표)
 
DeepStream 파이프라인 완성 후
  운영 방식: CCTV 24시간 자동 분석
  처리량:   30fps, 다중 카메라 동시 처리
  인력 필요: 0 (완전 무인 자동화)
```
 
---
 
## 🗺 로드맵
 
- [x] Next.js 웹 대시보드 MVP 구현
- [x] YOLOv11 모델 학습 (mAP 66.7%)
- [x] FastAPI 백엔드 + HRI 계산 엔진
- [x] Kakao Map 거점 시각화
- [x] 수거 일정 자동화 페이지
- [x] iOS 앱 개발 (진행 중)
- [ ] NVIDIA TensorRT INT8 최적화
- [ ] NVIDIA TAO Toolkit 재학습 (mAP 80% 목표)
- [x] NVIDIA Omniverse Replicator 합성 데이터 생성
- [ ] NVIDIA DeepStream 실시간 파이프라인
- [ ] Jetson Orin Nano Super 현장 배포
- [ ] AWS 프로덕션 배포
---
 
## 👥 팀 ESPA
 
| 이름 | 역할 |
|------|------|
| 이유나 | 팀장 / 기획 |
| 김현서 | 기획 / 데이터 분석 |
| 엄현경 | UI/UX 디자인 |
| 전용태 | AI 모델링 / 백엔드 개발 |
 
**지도교수:**
정효정 교수님, 이호준 교수님
 
**기업 멘토:**
정택수 대표 (넷스파)
 
**카카오 멘토:**
Roki
 
 
**프로그램:** 테크포임팩트리빙랩 With COSS 바이오헬스
 
---
 
 
## 🔗 관련 링크
 
- [ESPA 웹 대시보드 레포](https://github.com/dante3804/espa-ios)
- [넷스파 (기업 파트너)](https://netspa.co.kr)
- [Kakaoimpact 테크포임팩트](https://techforimpact.io)
- [NVIDIA NGC](https://ngc.nvidia.com)
- [Roboflow 데이터셋](https://roboflow.com)
---
 
<p align="center">
  <i>"알고리즘 한 줄이 누군가의 생활환경을 바꿀 수 있다"</i><br>
  <b>Team ESPA, 2026</b>
</p>
