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
YOLOv11 Instance Segmentation
        ↓  봉투 개수 카운팅
HRI 수식 계산
 HRI = (BagCount × 25kg × 0.985) × TimeDays × WeatherScore × ProximityScore
        ↓
PostgreSQL + PostGIS
        ↓
Kakao Map 기반 위험도 시각화
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
git clone https://github.com/your-username/espa-ios.git
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

### 백엔드 서버 연동

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

## 🔬 AI 모델 정보

| 항목 | 내용 |
|------|------|
| 모델 | YOLOv11s Instance Segmentation |
| 학습 데이터 | 현장 실사진 48장 (부산 다대포항, 울산 정자항 등) |
| 탐지 클래스 | bag (폐어망 마대 봉투) |
| mAP@50 | 66.7% |
| 학습 환경 | Google Colab A100 / Tesla T4 |
| 라벨링 | Roboflow (Auto Label 활용) |
| 향후 계획 | TensorRT 최적화, Omniverse Replicator 합성데이터 재학습 |

---

## 🗺 로드맵

- [x] Next.js 웹 대시보드 MVP 구현
- [x] YOLOv11 모델 학습 (mAP 66.7%)
- [x] FastAPI 백엔드 + HRI 계산 엔진
- [x] Kakao Map 거점 시각화
- [ ] iOS 앱 개발 (진행 중)
- [ ] TensorRT 모델 최적화
- [ ] Jetson Orin Nano 현장 배포
- [ ] DeepStream 실시간 파이프라인
- [ ] AWS 프로덕션 배포

---

## 👥 팀 ESPA

| 이름 | 역할 |
|------|------|
| 이유나 | 팀장 / 기획 |
| 김현서 | 기획 / 개발 |
| 엄현경 | UI/UX 디자인 |
| 전용태 | AI 모델링 / 백엔드 개발 |

**지도교수:** 정효정, 이호준 교수님
**기업 멘토:** 정택수 대표 (넷스파)

---

## 🔗 관련 링크

- [ESPA 대시보드 레포](https://github.com/dante3804/espa-ios2)
- [넷스파 (기업 파트너)](https://netspa.co.kr)
- [Kakaoimpact 테크포임팩트](https://techforimpact.io)

---

<p align="center">
  <i>"알고리즘 한 줄이 누군가의 생활환경을 바꿀 수 있다"</i><br>
  <b>Team ESPA, 2026</b>
</p>
