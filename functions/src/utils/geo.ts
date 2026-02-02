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

export class QuadKey {
  public readonly tileX: number;
  public readonly tileY: number;
  public readonly level: number;

  // 생성자: 외부에서 직접 호출하기보다 static 메서드를 통해 생성하는 것을 권장
  constructor(tileX: number, tileY: number, level: number) {
    this.tileX = tileX;
    this.tileY = tileY;
    this.level = level;
  }

  // 1. [진입점] 위경도로 생성
  static fromGeo(lat: number, lon: number, level: number): QuadKey {
    const MIN_LAT = -85.05112878;
    const MAX_LAT = 85.05112878;
    const clippedLat = Math.max(MIN_LAT, Math.min(lat, MAX_LAT));
    const clippedLon = Math.max(-180, Math.min(lon, 180));

    const x = (clippedLon + 180) / 360;
    const sinLat = Math.sin(clippedLat * Math.PI / 180);
    const y = 0.5 - Math.log((1 + sinLat) / (1 - sinLat)) / (4 * Math.PI);

    const mapSize = Math.pow(2, level);
    const tileX = Math.floor(x * mapSize);
    const tileY = Math.floor(y * mapSize);

    return new QuadKey(tileX, tileY, level);
  }

  // 2. [진입점] 기존 QuadKey 문자열로 생성 (Decoding)
  // "132" 문자열을 받아서 -> x=6, y=3 좌표로 복원하는 역연산
  static fromString(quadKey: string): QuadKey {
    let tileX = 0;
    let tileY = 0;
    const level = quadKey.length;

    for (let i = 0; i < level; i++) {
      // 비트 위치: level이 3이면 -> i=0일 때 mask는 100(2) 즉 4
      const mask = 1 << (level - i - 1);
      const char = quadKey[i];

      // 문자열의 숫자에 따라 X, Y 좌표에 값을 더함
      if (char === '1') {
        tileX |= mask;
      } else if (char === '2') {
        tileY |= mask;
      } else if (char === '3') {
        tileX |= mask;
        tileY |= mask;
      }
    }

    return new QuadKey(tileX, tileY, level);
  }

  // 3. [핵심] 이웃 찾기 (체이닝 지원)
  // 값을 변경한 '새로운 QuadKey'를 반환 (Immutability)
  neighbor(dir: Direction): QuadKey {
    let dx = 0;
    let dy = 0;

    switch (dir) {
      case Direction.N:  dy = -1; break;
      case Direction.S:  dy = 1;  break;
      case Direction.W:  dx = -1; break;
      case Direction.E:  dx = 1;  break;
      case Direction.NW: dx = -1; dy = -1; break;
      case Direction.NE: dx = 1;  dy = -1; break;
      case Direction.SW: dx = -1; dy = 1;  break;
      case Direction.SE: dx = 1;  dy = 1;  break;
    }

    // 지도 경계(Map Boundary) 체크 (세계지도를 벗어나면 순환하거나 에러 처리)
    // 여기서는 단순히 계산만 하고, 경계 처리는 필요 시 추가 (보통 모듈로 연산 사용)
    // const maxIndex = Math.pow(2, this.level) - 1;
    
    // Wrapping (지구는 둥그니까 오른쪽 끝으로 가면 왼쪽 끝이 나옴 - 경도만)
    // 위도(Y)는 보통 -1이 되면 존재하지 않는 영역이지만 여기선 단순 Clamp 처리 예시
    let newX = this.tileX + dx;
    let newY = this.tileY + dy;

    // (선택사항) 범위 밖으로 나가면 반대편으로? 아니면 막기?
    // 여기서는 안전하게 0 ~ maxIndex 범위 내로 제한(Clamp)하거나 
    // newX = (newX + mapSize) % mapSize; // 순환 로직
    
    return new QuadKey(newX, newY, this.level);
  }

  // 4. 문자열로 반환 (Encoding)
  toString(): string {
    let result = "";
    for (let i = this.level; i > 0; i--) {
      let digit = 0;
      const mask = 1 << (i - 1);

      if ((this.tileX & mask) !== 0) digit += 1;
      if ((this.tileY & mask) !== 0) digit += 2;

      result += digit.toString();
    }
    return result;
  }
}

export enum Direction {
  N = "North",
  S = "South",
  W = "West",
  E = "East",
  NW = "NorthWest",
  NE = "NorthEast",
  SW = "SouthWest",
  SE = "SouthEast"
}