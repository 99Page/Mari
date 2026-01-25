# Firebase 

Firebase 설정에 대한 내용을 정리한 문서

## API 인증 

Firebase Functions를 사용해 Cloud Run에 API를 배포하여 사용하고 있습니다.

API 호출 시 필요한 인증 토큰 설정은 [공식 문서](https://cloud.google.com/run/docs/authenticating/end-users?hl=ko#internal)를 참고했습니다.

1. OAuth 또는 Firebase 인증을 통해 로그인한 후, 클라이언트에서 ID 토큰을 획득합니다.
2. API 요청 시 Authorization 헤더에 `Bearer {ID_TOKEN}` 형식으로 토큰을 포함합니다.
3. Cloud Run 함수 내부에서 `admin.auth().verifyIdToken()`을 사용해 토큰을 검증합니다.
4. 함수가 정상 동작하도록 IAM 설정에서 Cloud Run 서비스에 `allUsers` 권한을 부여합니다.

## 서버 배포 

개발(Dev) 환경과 운영(Prod) 환경을 분리하여 관리하며, `.env` 파일을 통해 환경 변수를 제어합니다.

### 1. 환경 설정 파일 (.env)
`functions` 폴더 내에 환경별 설정 파일을 생성하여 관리합니다.

* **`.env` (기본/개발용)**: 
  ```env
  # 개발 환경 변수
  DB_INSTANCE_NAME=
  ```
* **`.env.prod` (운영용)**: 
  ```env
  # 운영 환경 변수
  DB_INSTANCE_NAME=mari-db
  ```

### 2. 프로젝트 별칭(Alias) 등록 및 전환
CLI에서 매번 프로젝트 ID를 입력하는 대신, 별칭(default, prod)을 등록하여 환경을 전환합니다.

* **별칭 등록 방법 (최초 1회 설정)**
  1. 터미널에 명령어 입력:
     ```bash
     firebase use --add
     ```
  2. 나타나는 리스트에서 연결할 **운영용 프로젝트**를 선택(방향키) 후 Enter.
  3. 사용할 별칭 이름으로 **`prod`** 입력 후 Enter.

* **환경 전환 명령어**
  * **개발(Dev) 환경**으로 전환:
    ```bash
    firebase use dev
    ```
  * **운영(Prod) 환경**으로 전환:
    ```bash
    firebase use prod
    ```

* **현재 연결된 프로젝트 확인**
  ```bash
  firebase use
  # 결과 예시: Active Project: prod (mari-production)
  ```

### 3. 배포 명령어
반드시 `firebase use`로 현재 타겟 프로젝트를 확인한 후 배포합니다.

* **전체 함수 배포**
  ```bash
  firebase deploy --only functions
  ```

* **특정 함수만 배포** (추천)
  ```bash
  firebase deploy --only functions:createPost,functions:fetchPostById
  ```

## 필요한 패키지 다운로드

새로운 개발 환경 세팅 시 필요한 명령어입니다.

### 1. Firebase CLI 설치 (전역 도구)

터미널 어디서든 firebase 명령어를 사용하기 위해 필요합니다.

```bash
npm install -g firebase-tools
```

### 2. 프로젝트 라이브러리 설치 (의존성)

package.json에 정의된 라이브러리(firebase-admin, ngeohash, tsc-alias 등)를 설치합니다. 반드시 functions 폴더 내부에서 실행해야 합니다.

```Bash
cd functions
npm install
``` 