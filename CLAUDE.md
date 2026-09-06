# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ReverseRecorder는 SwiftUI 기반의 iOS 애플리케이션으로, 사용자가 음성을 녹음하고 자동으로 역재생하여 들을 수 있는 간단한 앱입니다.

### 주요 기능
- **탭 토글 녹음**: 버튼을 탭하면 녹음 시작, 다시 탭하면 녹음 종료 (최대 60초)
- **실시간 녹음 파형**: 녹음 중 오디오 레벨을 실시간으로 파형으로 시각화 (펄스 효과 포함)
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
xcodebuild -project ReverseRecorder.xcodeproj -scheme ReverseRecorder -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### 테스트 실행
이 프로젝트에는 아직 테스트 타깃이 없습니다. `xcodebuild test`는 실패합니다.
테스트 타깃을 추가한 뒤에 아래 명령을 사용하세요.

```bash
# 테스트 타깃 추가 후 사용
# xcodebuild test -project ReverseRecorder.xcodeproj -scheme ReverseRecorder -destination 'platform=iOS Simulator,name=iPhone 16'
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
│   ├── RecordButton.swift            # 탭 토글 녹음 버튼 (펄스 효과 포함)
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
  - 녹음 상태: `isRecording`, `recordingTime`, `recordingWaveformData`
  - 처리 상태: `isProcessingReverse`, `reverseProgress`, `processingWaveformData`
  - 재생 상태: `isPlaying`, `currentTime`, `duration`, `waveformData`
  - 파형 샘플 수: 100개 고정 (`maxWaveformSamples`)

### Services 레이어
각 Service는 단일 책임 원칙(SRP)에 따라 특정 기능만 담당합니다:

1. **AudioRecorderService**:
   - AVAudioRecorder를 사용한 녹음
   - 마이크 권한 요청
   - 녹음 파일 생성
   - 실시간 오디오 레벨 미터링 (`@Published audioLevel`)
   - 녹음 시간 추적 (`@Published recordingTime`)
   - 최대 녹음 시간: 60초 (ViewModel에서 제한)

2. **AudioReverseService** (싱글톤):
   - AVAudioFile로 오디오 샘플 읽기
   - Float 배열 reverse 처리
   - 역재생 파일 생성 및 저장
   - 청크 단위 처리로 진행률 발행 (`progressPublisher`)
   - Combine PassthroughSubject로 ReverseProgress 구조체 발행

3. **AudioPlayerService**:
   - AVAudioPlayer를 사용한 재생
   - Timer 기반 실시간 프로그레스 업데이트 (10ms 간격)
   - Seek, Play, Pause, Stop, Unload 기능
   - `isLoaded(url:)` 메서드로 현재 로드된 오디오 확인

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
- **탭 토글 녹음**: `onTapGesture`를 사용하여 녹음 시작/종료 토글
- **프로그레스 드래그**: GeometryReader와 `DragGesture(minimumDistance: 0)`를 조합하여 커스텀 슬라이더 구현

#### Static Mode (스냅샷 캡처용)
- Views에 `isStatic` 파라미터를 추가하여 스냅샷 캡처 시 인터랙션 비활성화
- `RecordButton`, `ProgressSlider`, `PlaybackControls`, `DarkModeToggle` 등에서 지원
- 정적 모드에서는 애니메이션과 사용자 입력이 무시됨

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

### 권한 처리 및 프로젝트 설정
Xcode 프로젝트 설정에 포함된 주요 설정:
- **마이크 권한**: `NSMicrophoneUsageDescription` - "녹음 기능을 사용하기 위해 마이크 권한이 필요합니다."
- **iOS 최소 버전**: iOS 18.6
- **화면 방향**:
  - iPhone: 세로 방향만 지원 (`UIInterfaceOrientationPortrait`)
  - iPad: 모든 방향 지원
- **앱 표시 이름**: "Reverse Recorder"

### UI/UX 디자인
- **모던 스타일**: 그라데이션, 그림자 효과
- **SF Symbols**: 시스템 아이콘 사용
- **애니메이션**: spring animation, scale effect, timing curve
- **펄스 효과**: 녹음 중 `PulsingBorder` 컴포넌트로 테두리 펄스 애니메이션
- **반응형**: GeometryReader를 사용한 동적 레이아웃
- **원형 트랜지션**: 다크모드 전환 시 circular reveal 효과
- **파형 시각화**: 녹음/처리/재생 각 상태별 다른 색상의 파형
  - 녹음 중: 빨강/주황 그라데이션
  - 처리 중: 회색
  - 재생 중: 파랑/보라 그라데이션

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

## 공개 저장소 규칙

이 저장소는 공개되어 있다. 커밋한 것은 되돌려도 남는다.

- **시크릿 금지** — API 키·토큰·서명 키(`*.jks`/`*.p12`)·서비스 계정 키·실제 사용자 데이터를 커밋하지 않는다.
  값은 **`Secrets.xcconfig`** 에만 두고 저장소에는 `*.example`만 올린다.
  소스·plist·manifest·주석·커밋 메시지 어디에도 값을 쓰지 않는다.
  이미 올렸다면 되돌리는 것으로 끝내지 말고 **키를 폐기·재발급**한다.
  **예외** — Firebase 클라이언트 설정(`GoogleService-Info.plist`, `google-services.json`, `AIzaSy…`)과
  OAuth public client ID는 Google이 앱 바이너리 내장을 전제로 문서화한 **식별자**이며 비밀이 아니다.
  커밋해도 되고 재발급 대상이 아니다. 접근 통제는 Firestore 보안 규칙과 API 키의 `apiTargets`·앱 제한이 담당한다.
  **단 서비스 계정 키·Admin SDK 자격증명·서명 키는 이 예외에 해당하지 않는다.**
- **내부 정보 금지** — 로컬 절대경로(`/Users/…`), 저장소 밖 파일 참조, 관리자 URL,
  인프라 식별자(버킷·배포 ID·계정 번호), 개인 기기 식별자(UDID·시리얼),
  릴리스 진행 상태와 스토어 콘솔 절차는 문서에 남기지 않는다.
- **내부 문서 위치** — 가격 전략·미출시 기획·운영 절차·서버 계약은 저장소에 두지 않는다.
  로컬에 두고 gitignore 하되 **그 판단 근거를 이 문서에 적어** 다음 세션이 되돌리지 않게 한다.
  gitignore된 경로를 코드 주석이나 문서에서 참조하지 않는다 — 방문자에게는 끊어진 링크다.
- **문서 정확성** — 여기 적힌 버전·경로·명령·구조가 코드와 다르면 코드가 아니라 문서를 고친다.
  배포 타깃과 언어 버전은 프로젝트 기본값이 아니라 **앱 타깃의 실제 값**을 확인해 적는다.
- **브랜치** — 에이전트 작업 브랜치는 머지 후 지운다. 원격에 실험 브랜치를 남기지 않는다.
  **처음 push 하는 순간 그 브랜치의 문서·메모도 함께 공개된다.**
- **`main`에 force-push 하지 않는다.** 공개된 히스토리를 다시 쓰면 클론·포크한 쪽이 깨진다.
  (예외: 시크릿 제거 — 이때도 키 폐기가 먼저다.)
- **push 전 확인** — `git fetch origin && git status -sb`로 원격이 앞섰는지 보고, 앞섰으면 덮지 말고 rebase 한다.
  `git log origin/main..HEAD --stat`으로 올라갈 파일 전체를 확인해 무관한 파일을 분리하고,
  `git diff`에서 키·절대경로·기기 식별자가 없는지 본다. **`git add .` 금지.**
