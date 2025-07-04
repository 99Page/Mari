# Firebase 

Firebase 설정에 대한 내용을 정리한 문서

## API 인증 

Firebase Functions를 사용해 Cloud Run에 API를 배포하여 사용하고 있습니다.

API 호출 시 필요한 인증 토큰 설정은 [공식 문서](https://cloud.google.com/run/docs/authenticating/end-users?hl=ko#internal)를 참고했습니다.

1. OAuth 또는 Firebase 인증을 통해 로그인한 후, 클라이언트에서 ID 토큰을 획득합니다.
2. API 요청 시 Authorization 헤더에 `Bearer {ID_TOKEN}` 형식으로 토큰을 포함합니다.
3. Cloud Run 함수 내부에서 `admin.auth().verifyIdToken()`을 사용해 토큰을 검증합니다.
4. 함수가 정상 동작하도록 IAM 설정에서 Cloud Run 서비스에 `allUsers` 권한을 부여합니다.