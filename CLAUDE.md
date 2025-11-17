# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ReverseRecorder는 SwiftUI 기반의 iOS 애플리케이션으로, 사용자가 음성을 녹음하고 자동으로 역재생하여 들을 수 있는 간단한 앱입니다.

### 주요 기능
- **Press & Hold 녹음**: 버튼을 누르고 있는 동안 녹음, 떼면 자동 종료
- **자동 역재생**: 녹음 종료 후 1초 뒤 오디오를 역재생하여 자동 재생
- **재생 컨트롤**: 재생/정지/삭제 버튼
- **드래그 가능한 프로그레스 바**: 재생 위치를 자유롭게 이동
- **다크모드 토글**: 우측 하단에서 라이트/다크 모드 전환
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
│   ├── ContentView.swift             # 메인 뷰 (모든 컴포넌트 통합)
│   ├── RecordButton.swift            # Press & Hold 녹음 버튼
│   ├── ProgressSlider.swift          # 드래그 가능한 프로그레스 슬라이더
│   ├── PlaybackControls.swift        # 재생/정지/삭제 컨트롤
│   ├── ToastView.swift               # 토스트 메시지 (에러/알림)
│   └── DarkModeToggle.swift          # 다크모드 토글 버튼
├── Services/
│   ├── AudioRecorderService.swift    # AVAudioRecorder 기반 녹음 서비스
│   ├── AudioPlayerService.swift      # AVAudioPlayer 기반 재생 서비스
│   ├── AudioReverseService.swift     # 오디오 역재생 변환 서비스
│   └── FileManagerService.swift      # 파일 저장/로드 서비스
├── ReverseRecorderApp.swift          # 앱 진입점 (@main)
├── Info.plist                        # 마이크 권한 설정
└── Assets.xcassets/                  # 이미지 및 색상 에셋
```

### MVVM 패턴
- **Model** (`AudioRecording`): 녹음 데이터 구조 (URL, duration 등)
- **View** (SwiftUI Views): UI 컴포넌트, 사용자 인터랙션 처리
- **ViewModel** (`RecorderViewModel`):
  - `@Published` 프로퍼티로 UI 상태 관리
  - Services 레이어와 통신
  - Combine을 사용한 reactive binding

### Services 레이어
각 Service는 단일 책임 원칙(SRP)에 따라 특정 기능만 담당합니다:

1. **AudioRecorderService**:
   - AVAudioRecorder를 사용한 녹음
   - 마이크 권한 요청
   - 녹음 파일 생성

2. **AudioReverseService**:
   - AVAudioFile로 오디오 샘플 읽기
   - Float 배열 reverse 처리
   - 역재생 파일 생성 및 저장

3. **AudioPlayerService**:
   - AVAudioPlayer를 사용한 재생
   - Timer 기반 실시간 프로그레스 업데이트
   - Seek, Play, Pause, Stop 기능

4. **FileManagerService**:
   - Documents/Recordings 디렉토리 관리
   - 녹음 파일 저장/로드 (JSON)
   - 파일 삭제

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

#### 오디오 역재생 알고리즘
1. AVAudioFile로 원본 파일 읽기
2. AVAudioPCMBuffer에 샘플 로드
3. floatChannelData를 Array로 변환
4. 배열 reverse() 메서드 호출
5. 새 AVAudioFile에 쓰기

### SwiftUI 주요 패턴

#### State Management
- `@StateObject`: ViewModel 인스턴스 (ContentView)
- `@ObservedObject`: ViewModel 참조 (하위 View)
- `@Published`: reactive 데이터 바인딩
- `@AppStorage`: UserDefaults 기반 다크모드 설정 저장

#### Gesture Handling
- **Press & Hold 녹음**: `DragGesture(minimumDistance: 0)`를 사용하여 onChanged/onEnded로 press/release 감지
- **프로그레스 드래그**: GeometryReader와 DragGesture를 조합하여 커스텀 슬라이더 구현

#### Custom Modifiers
- `ToastModifier`: View extension으로 토스트 메시지 기능 제공
- `.toast(isShowing:message:)` modifier 사용

### 권한 처리
Info.plist에 마이크 권한 설정 필수:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>녹음 기능을 사용하기 위해 마이크 권한이 필요합니다.</string>
```

### UI/UX 디자인
- **모던 스타일**: 그라데이션, 그림자 효과
- **SF Symbols**: 시스템 아이콘 사용
- **애니메이션**: spring animation, scale effect
- **반응형**: GeometryReader를 사용한 동적 레이아웃

### 파일 저장 위치
- 원본 녹음: `Documents/Recordings/original_<timestamp>.m4a`
- 역재생 파일: `Documents/Recordings/reversed_<timestamp>.m4a`
- 메타데이터: `Documents/recordings.json`
