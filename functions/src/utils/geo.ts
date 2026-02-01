/**
 * Web Mercator 투영법을 사용하여 위도/경도를 Base4(QuadKey)로 변환합니다.
 * 이 방식은 전 세계를 정사각형 타일로 관리하며, 구글/네이버 지도와 호환됩니다.
 * * @param lat 위도 (-85.05 ~ 85.05) *Mercator는 극지방 표현 불가
 * @param lon 경도 (-180 ~ 180)
 * @param precision 정밀도 (Zoom Level). 
 * - 1: 세계지도 4등분
 * - 5: 대륙/국가 단위
 * - 10: 도시 단위
 * - 20~22: 건물/집 한 채 단위 
 */

export const toBase4 = (lat: number, lon: number, precision: number): string => {
  // Web Mercator의 위도 제한 
  const MIN_LAT = -85.05112878;
  const MAX_LAT = 85.05112878;
  const MIN_LON = -180;
  const MAX_LON = 180;

  const clippedLat = Math.max(MIN_LAT, Math.min(lat, MAX_LAT));
  const clippedLon = Math.max(MIN_LON, Math.min(lon, MAX_LON));

  // 3. [핵심] 투영 변환 (위도/경도 -> 0.0 ~ 1.0 사이의 정규 좌표값)
  // 경도(x): -180~180을 0~1로 선형 변환
  const x = (clippedLon + 180) / 360;

  // 위도(y): Mercator 공식을 통해 0~1로 변환 (로그와 사인 함수 사용)
  // 이 공식이 지도를 '정사각형'으로 펴주는 마법입니다.
  const sinLat = Math.sin(clippedLat * Math.PI / 180);
  const y = 0.5 - Math.log((1 + sinLat) / (1 - sinLat)) / (4 * Math.PI);

  // 4. 정수 좌표로 변환 및 QuadKey 생성
  // mapSize: 해당 정밀도에서의 전체 격자 개수 (예: precision 3이면 8x8 격자)
  const mapSize = Math.pow(2, precision);
  
  // 현재 위치가 몇 번째 격자에 있는지 계산 (정수형 좌표)
  // Math.floor를 써서 0부터 시작하는 인덱스로 만듭니다.
  // 예: x가 0.7이고 mapSize가 8이면 -> 5.6 -> 5번째 칸
  let pixelX = Math.floor(x * mapSize);
  let pixelY = Math.floor(y * mapSize);

  // 5. 비트 인터리빙 (Bit Interleaving)
  // X와 Y 좌표의 비트를 하나씩 꺼내서 합칩니다.
  let result = "";

  for (let i = precision; i > 0; i--) {
    let digit = 0;
    
    // 검사할 비트의 위치 마스크 (왼쪽부터 검사)
    const mask = 1 << (i - 1);

    // X 좌표의 해당 비트가 1이면? -> 오른쪽(East) -> 1 더함
    if ((pixelX & mask) !== 0) {
      digit += 1;
    }

    // Y 좌표의 해당 비트가 1이면? -> 아래쪽(South) -> 2 더함
    // (Mercator 좌표계는 위에서 아래로 갈수록 Y가 커집니다)
    if ((pixelY & mask) !== 0) {
      digit += 2;
    }

    // 결과: 0(NW), 1(NE), 2(SW), 3(SE)
    result += digit.toString();
  }

  return result;
};