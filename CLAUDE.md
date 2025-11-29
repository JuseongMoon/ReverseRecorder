# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ReverseRecorder는 SwiftUI 기반의 iOS 애플리케이션으로, 사용자가 음성을 녹음하고 자동으로 역재생하여 들을 수 있는 간단한 앱입니다.

### 주요 기능
- **Press & Hold 녹음**: 버튼을 누르고 있는 동안 녹음, 떼면 자동 종료
- **실시간 녹음 파형**: 녹음 중 오디오 레벨을 실시간으로 파형으로 시각화
- **역재생 진행률 표시**: 역재생 변환 중 진행률과 파형 애니메이션 표시
- **자동 역재생**: 녹음 종료 후 오디오를 역재생 변환하여 자동 재생
- **재생 컨트롤**: 재생/정지/삭제 버튼
- **드래그 가능한 프로그레스 바**: 재생 위치를 자유롭게 이동, 파형 시각화 포함
- **다크모드 토글**: 좌측 상단에서 라이트/다크 모드 전환 (원형 트랜지션 애니메이션)
- **파일 공유**: 역재생된 오디오 파일을 다른 앱으로 공유
- **파일 영구 저장**: Documents 디렉토리에 녹음본 저장

## Build and Run

### Xcode에서 빌드 및 실행
```bash
# Xcode에서 프로젝트 열기
open ReverseRecorder.xcodeproj

# 커맨드 라인에서 빌드 (iOS 시뮬레이터용)
xcodebuild -project ReverseRecorder.xcodeproj -scheme ReverseRecorder -destination 'platform=iOS Simulator,name=iPhone 15' build

# 커맨드 라인에서 실행
xcodebuild -project ReverseRecorder.xcodeproj -scheme ReverseRecorder -destination 'platform=iOS Simulator,name=iPhone 15' run
```

### 테스트 실행
```bash
# 모든 테스트 실행
xcodebuild test -project ReverseRecorder.xcodeproj -scheme ReverseRecorder -destination 'platform=iOS Simulator,name=iPhone 15'

# 특정 테스트만 실행
xcodebuild test -project ReverseRecorder.xcodeproj -scheme ReverseRecorder -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ReverseRecorderTests/TestClassName/testMethodName
```

## Code Architecture

이 프로젝트는 **MVVM (Model-View-ViewModel)** 아키텍처 패턴과 **Services 레이어**를 사용합니다.

### 프로젝트 구조
```
ReverseRecorder/
├── Models/
│   └── AudioRecording.swift          # 녹음 데이터 모델 (Codable, Identifiable)
├── ViewModels/
│   └── RecorderViewModel.swift       # 상태 관리 및 비즈니스 로직 (ObservableObject)
├── Views/
│   ├── RecordButton.swift            # Press & Hold 녹음 버튼
│   ├── ProgressSlider.swift          # 드래그 가능한 프로그레스 슬라이더 (파형 포함)
│   ├── PlaybackControls.swift        # 재생/정지/삭제 컨트롤
│   ├── WaveformView.swift            # 재생용 파형 시각화 뷰
│   ├── RecordingWaveformView.swift   # 녹음 중 실시간 파형 표시
│   ├── ProcessingWaveformView.swift  # 역재생 처리 중 파형 표시
│   ├── ShareButton.swift             # 파일 공유 버튼 (UIActivityViewController)
│   ├── ToastView.swift               # 토스트 메시지 (에러/알림)
│   └── DarkModeToggle.swift          # 다크모드 토글 버튼
├── Services/
│   ├── AudioRecorderService.swift    # AVAudioRecorder 기반 녹음 서비스
│   ├── AudioPlayerService.swift      # AVAudioPlayer 기반 재생 서비스
│   ├── AudioReverseService.swift     # 오디오 역재생 변환 서비스 (진행률 포함)
│   ├── AudioWaveformService.swift    # 오디오 파일 파형 추출 서비스
│   ├── FileManagerService.swift      # 파일 저장/로드 서비스
│   └── ThemeSnapshotService.swift    # 테마 전환 스냅샷 서비스
├── ContentView.swift                 # 메인 뷰 (모든 컴포넌트 통합)
├── ReverseRecorderApp.swift          # 앱 진입점 (@main)
├── Info.plist                        # 마이크 권한 설정
└── Assets.xcassets/                  # 이미지 및 색상 에셋
```

### MVVM 패턴
- **Model** (`AudioRecording`): 녹음 데이터 구조 (URL, duration, createdAt 등)
- **View** (SwiftUI Views): UI 컴포넌트, 사용자 인터랙션 처리
- **ViewModel** (`RecorderViewModel`):
  - `@Published` 프로퍼티로 UI 상태 관리
  - Services 레이어와 통신
  - Combine을 사용한 reactive binding
  - 스냅샷 업데이트 콜백 (`onSnapshotUpdateNeeded`)

### Services 레이어
각 Service는 단일 책임 원칙(SRP)에 따라 특정 기능만 담당합니다:

1. **AudioRecorderService**:
   - AVAudioRecorder를 사용한 녹음
   - 마이크 권한 요청
   - 녹음 파일 생성
   - 실시간 오디오 레벨 미터링 (`@Published audioLevel`)
   - 녹음 시간 추적 (`@Published recordingTime`)

2. **AudioReverseService** (싱글톤):
   - AVAudioFile로 오디오 샘플 읽기
   - Float 배열 reverse 처리
   - 역재생 파일 생성 및 저장
   - 청크 단위 처리로 진행률 발행 (`progressPublisher`)
   - Combine PassthroughSubject로 ReverseProgress 구조체 발행

3. **AudioPlayerService**:
   - AVAudioPlayer를 사용한 재생
   - Timer 기반 실시간 프로그레스 업데이트
   - Seek, Play, Pause, Stop 기능

4. **AudioWaveformService** (싱글톤):
   - 오디오 파일에서 파형 데이터 추출
   - 다운샘플링 및 정규화 처리
   - 비동기 처리 (백그라운드 스레드)

5. **FileManagerService** (싱글톤):
   - Documents/Recordings 디렉토리 관리
   - 녹음 파일 저장/로드 (JSON)
   - 파일 삭제

6. **ThemeSnapshotService** (싱글톤):
   - 다크/라이트 테마 UI 스냅샷 캡처
   - 원형 reveal 트랜지션 효과 지원
   - 화면 크기 변경 시 스냅샷 재생성

### AVFoundation 사용법

#### 녹음 설정
```swift
let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
    AVSampleRateKey: 44100.0,
    AVNumberOfChannelsKey: 1,
    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
]
```

#### 오디오 레벨 미터링
```swift
// 50ms 간격으로 오디오 레벨 측정
recorder.updateMeters()
let averagePower = recorder.averagePower(forChannel: 0)
// -50dB ~ 0dB 범위를 0~1로 정규화
let normalizedLevel = max(0, min(1, (averagePower + 50) / 50))
```

#### 오디오 역재생 알고리즘 (청크 단위)
1. AVAudioFile로 원본 파일 읽기
2. AVAudioPCMBuffer에 전체 샘플 로드
3. 청크 단위로 나누어 처리 (100개 청크)
4. 각 청크 내에서 샘플 순서 reverse
5. 원본 파일의 뒤에서부터 앞으로 처리하여 출력
6. 각 청크마다 진행률과 파형 데이터 발행

### SwiftUI 주요 패턴

#### State Management
- `@StateObject`: ViewModel 및 서비스 인스턴스 (ContentView)
- `@ObservedObject`: ViewModel 참조 (하위 View)
- `@Published`: reactive 데이터 바인딩
- `@AppStorage`: UserDefaults 기반 다크모드 설정 저장 (`isDarkModeOverride`)
- `@State`: 로컬 뷰 상태 (트랜지션 관련)

#### Gesture Handling
- **Press & Hold 녹음**: `DragGesture(minimumDistance: 0)`를 사용하여 onChanged/onEnded로 press/release 감지
- **프로그레스 드래그**: GeometryReader와 DragGesture를 조합하여 커스텀 슬라이더 구현

#### Custom Modifiers
- `ToastModifier`: View extension으로 토스트 메시지 기능 제공
- `.toast(isShowing:message:)` modifier 사용

#### 테마 전환 애니메이션
- `ThemeSnapshotService`로 다크/라이트 테마 스냅샷 미리 캡처
- 토글 버튼 중심에서 원형으로 확장되는 mask 애니메이션
- timing curve 기반 부드러운 가속 효과

### Combine 사용
- `AnyCancellable`로 구독 관리
- `PassthroughSubject`로 역재생 진행률 발행
- `assign(to:)` 및 `sink`로 상태 바인딩

### 권한 처리
Info.plist에 마이크 권한 설정 필수:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>녹음 기능을 사용하기 위해 마이크 권한이 필요합니다.</string>
```

### UI/UX 디자인
- **모던 스타일**: 그라데이션, 그림자 효과
- **SF Symbols**: 시스템 아이콘 사용
- **애니메이션**: spring animation, scale effect, timing curve
- **반응형**: GeometryReader를 사용한 동적 레이아웃
- **원형 트랜지션**: 다크모드 전환 시 circular reveal 효과
- **파형 시각화**: 녹음/처리/재생 각 상태별 다른 색상의 파형

### 파일 저장 위치
- 원본 녹음: `Documents/Recordings/original_<timestamp>.m4a`
- 역재생 파일: `Documents/Recordings/reversed_<timestamp>.m4a`
- 메타데이터: `Documents/recordings.json`

### 공유 기능
- `UIActivityViewController` 래핑한 `ShareSheet` 사용
- 임시 파일로 복사 후 공유 (파일명: `Reversed_<날짜>.m4a`)
- 공유 완료 후 임시 파일 자동 삭제

### 지역화 (Localization)
- `String(localized:)` 사용하여 문자열 지역화 지원
- 에러 메시지 및 권한 요청 메시지 지역화
