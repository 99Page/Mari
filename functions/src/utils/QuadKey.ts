export class QuadKey {
  public readonly tileX: number;
  public readonly tileY: number;
  public readonly level: number;

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

  // 2. [진입점] 문자열로 생성
  static fromString(quadKey: string): QuadKey {
    const { x, y, level } = QuadKey.quadKeyToTileXY(quadKey);
    return new QuadKey(x, y, level);
  }

  /**
   * [수정됨] 현재 타일을 기준으로 주변 이웃 QuadKey 문자열들을 반환합니다.
   * 이미 tileX, tileY를 가지고 있으므로 this.key 변환 과정이 필요 없습니다.
   * @param range 범위 (1 = 3x3, 2 = 5x5...)
   */
  neighbors(range: number = 1): string[] {
    // ★ 수정: this.key 대신 저장된 좌표를 바로 사용
    const x = this.tileX;
    const y = this.tileY;
    const level = this.level;
    
    const mapSize = 1 << level; // 2^level
    const maxXY = mapSize - 1;

    const neighborsList: string[] = [];

    for (let dx = -range; dx <= range; dx++) {
      for (let dy = -range; dy <= range; dy++) {
        
        // 중심(나 자신) 제외
        if (dx === 0 && dy === 0) continue;

        let nx = x + dx;
        let ny = y + dy;

        // 1. X축(경도) Wrap-around 처리 (지구는 둥그니까)
        if (nx < 0) {
          nx = mapSize + nx;
        } else if (nx >= mapSize) {
          nx = nx - mapSize;
        }

        // 2. Y축(위도) 범위 체크 (범위 밖이면 무시)
        if (ny < 0 || ny > maxXY) {
          continue;
        }

        // 좌표 -> 문자열 변환 후 리스트 추가
        neighborsList.push(QuadKey.tileXYToQuadKey(nx, ny, level));
      }
    }

    return neighborsList;
  }

  // 3. 단일 이웃 찾기 (객체 반환)
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

    // 간단한 Clamp 처리 (실제 프로덕션에서는 Wrap/Clamp 정책 결정 필요)
    const mapSize = 1 << this.level;
    let newX = this.tileX + dx;
    let newY = this.tileY + dy;

    // X축 Wrap
    if (newX < 0) newX = mapSize + newX;
    else if (newX >= mapSize) newX = newX - mapSize;

    // Y축 Clamp (범위 밖이면 그대로 두거나 에러 처리, 여기선 Clamp)
    newY = Math.max(0, Math.min(newY, mapSize - 1));

    return new QuadKey(newX, newY, this.level);
  }

  // 4. 문자열 변환 (Encoding)
  toString(): string {
    return QuadKey.tileXYToQuadKey(this.tileX, this.tileY, this.level);
  }

  // ==========================================
  // Private Static Helpers
  // ==========================================

  private static quadKeyToTileXY(quadKey: string): { x: number; y: number; level: number } {
    let tileX = 0;
    let tileY = 0;
    const level = quadKey.length;

    for (let i = level; i > 0; i--) {
      const mask = 1 << (i - 1);
      const digit = quadKey[level - i];

      switch (digit) {
        case '0': break;
        case '1': tileX |= mask; break;
        case '2': tileY |= mask; break;
        case '3': tileX |= mask; tileY |= mask; break;
      }
    }
    return { x: tileX, y: tileY, level };
  }

  private static tileXYToQuadKey(tileX: number, tileY: number, level: number): string {
    let quadKey = "";
    for (let i = level; i > 0; i--) {
      let digit = 0;
      const mask = 1 << (i - 1);
      if ((tileX & mask) !== 0) digit += 1;
      if ((tileY & mask) !== 0) digit += 2;
      quadKey += digit.toString();
    }
    return quadKey;
  }
}

export enum Direction {
  N = "North", S = "South", W = "West", E = "East",
  NW = "NorthWest", NE = "NorthEast", SW = "SouthWest", SE = "SouthEast"
}