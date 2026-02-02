import { QuadKey, Direction } from "@/utils/QuadKey";

describe('QuadKey', () => {

  describe('Hashing with Precision 17', () => {

    const sinrimHome = {
      lat: 37.4837641826256, 
      lon: 126.93189792720779
    };
  
    const sinrimHash = "13211032012202132"

    test('신림', () => {
      const sinrimHash = QuadKey.fromGeo(sinrimHome.lat, sinrimHome.lon, 17).toString();

      expect(sinrimHash).toBe("13211032012202132")
    });

    test('양지 병원', () => {
      const hash = QuadKey.fromGeo(37.4841408, 126.9325573, 17).toString();

      expect(hash).toBe(sinrimHash)
    });

    test('카페 그날', () => {
      const hash = QuadKey.fromGeo(37.4840405, 126.9331012, 17).toString();

      expect(hash).toBe(sinrimHash)
    });

    test('GS25', () => {
      const hash = QuadKey.fromGeo(37.4841941, 126.9313648, 17).toString();

      expect(hash).toBe(sinrimHash)
    });
  });

   describe('Hashing with Precision 18', () => {
    // 광화문 좌표
    const sinrimHome = {
      lat: 37.4837641826256, 
      lon: 126.93189792720779
    };
  
    const sinrimHash = "132110320122021322"

    test('신림', () => {
      const sinrimHash = QuadKey.fromGeo(sinrimHome.lat, sinrimHome.lon, 18).toString();

      expect(sinrimHash).toBe("132110320122021322")
    });

    test('양지 병원', () => {
      const hash = QuadKey.fromGeo(37.4841408, 126.9325573, 18);

      expect(hash).not.toBe(sinrimHash)
    });

    test('카페 그날', () => {
      const hash = QuadKey.fromGeo(37.4840405, 126.9331012, 18).toString();

      expect(hash).not.toBe(sinrimHash)
    });

    test('GS25', () => {
      const hash = QuadKey.fromGeo(37.4841941, 126.9313648, 18).toString();

      expect(hash).toBe(sinrimHash)
    });
  });

  describe('Neighbors with Precision2 (Center Node: "03")', () => {
    // 기준점: "03" (Grid 좌표: x=1, y=1)
    // 위치: 좌상단 큰 박스(0)의 우하단 모서리에 위치함
    const startKey = "03";

    // 1. 상하좌우 (Cardinal Directions)
    test('N (North)', () => {
        // (1, 1) -> (1, 0) : 위로 한 칸
        expect(QuadKey.fromString(startKey).neighbor(Direction.N).toString()).toBe("01");
    });

    test('S (South)', () => {
        // (1, 1) -> (1, 2) : 아래로 한 칸 (큰 격자 경계 넘어감 0->2)
        expect(QuadKey.fromString(startKey).neighbor(Direction.S).toString()).toBe("21");
    });

    test('W (West)', () => {
        // (1, 1) -> (0, 1) : 왼쪽으로 한 칸
        expect(QuadKey.fromString(startKey).neighbor(Direction.W).toString()).toBe("02");
    });

    test('E (East)', () => {
        // (1, 1) -> (2, 1) : 오른쪽으로 한 칸 (큰 격자 경계 넘어감 0->1)
        expect(QuadKey.fromString(startKey).neighbor(Direction.E).toString()).toBe("12");
    });

    // 2. 대각선 (Ordinal Directions)
    test('NW (NorthWest)', () => {
        // (1, 1) -> (0, 0) : 왼쪽 위 대각선 (지도의 원점)
        expect(QuadKey.fromString(startKey).neighbor(Direction.NW).toString()).toBe("00");
    });

    test('NE (NorthEast)', () => {
        // (1, 1) -> (2, 0) : 오른쪽 위 대각선
        expect(QuadKey.fromString(startKey).neighbor(Direction.NE).toString()).toBe("10");
    });

    test('SW (SouthWest)', () => {
        // (1, 1) -> (0, 2) : 왼쪽 아래 대각선
        expect(QuadKey.fromString(startKey).neighbor(Direction.SW).toString()).toBe("20");
    });

    test('SE (SouthEast)', () => {
        // (1, 1) -> (2, 2) : 오른쪽 아래 대각선 (완전히 다른 큰 격자로 이동)
        expect(QuadKey.fromString(startKey).neighbor(Direction.SE).toString()).toBe("30");
    });

    // 1. 목표: "11" (x:3, y:0) - 우측 상단 끝
    // 이동: 오른쪽 2칸(E, E) + 위로 1칸(N)
    test('Chain to "11" (East -> East -> North)', () => {
        const dest = QuadKey.fromString(startKey)
            .neighbor(Direction.E) // -> "12" (2,1)
            .neighbor(Direction.E) // -> "13" (3,1)
            .neighbor(Direction.N) // -> "11" (3,0)
            .toString();

        expect(dest).toBe("11");
    });

    // 2. 목표: "13" (x:3, y:1) - 우측 벽
    // 이동: 오른쪽 2칸(E, E)
    test('Chain to "13" (East -> East)', () => {
        const dest = QuadKey.fromString(startKey)
            .neighbor(Direction.E) // -> "12" (2,1)
            .neighbor(Direction.E) // -> "13" (3,1)
            .toString();

        expect(dest).toBe("13");
    });

    // 3. 목표: "31" (x:3, y:2) - 우측 하단 벽
    // 이동: 오른쪽 2칸(E, E) + 아래로 1칸(S)
    test('Chain to "31" (East -> East -> South)', () => {
        const dest = QuadKey.fromString(startKey)
            .neighbor(Direction.E) // -> "12" (2,1)
            .neighbor(Direction.E) // -> "13" (3,1)
            .neighbor(Direction.S) // -> "31" (3,2)
            .toString();

        expect(dest).toBe("31");
    });

    // 4. 목표: "33" (x:3, y:3) - 우측 하단 끝 (가장 먼 곳)
    // 이동: 대각선(SE) + 대각선(SE)
    test('Chain to "33" (SouthEast -> SouthEast)', () => {
        const dest = QuadKey.fromString(startKey)
            .neighbor(Direction.SE) // -> "30" (2,2)
            .neighbor(Direction.SE) // -> "33" (3,3)
            .toString();

        expect(dest).toBe("33");
    });
  });

  describe('Bulk Neighbors (neighbors method)', () => {
    // Level 2 (4x4 Grid)
    // [00][01][10][11] (y=0)
    // [02][03][12][13] (y=1)
    // [20][21][30][31] (y=2)
    // [22][23][32][33] (y=3)

    test('Center Node "03"', () => {
      // (1, 1) 위치 -> 주변 8개 모두 유효 범위 내에 있음
      const centerKey = "03"; 
      const neighbors = QuadKey.fromString(centerKey).neighbors(1);

      // 정렬하여 비교 (순서는 보장되지 않을 수 있으므로)
      const expected = ["00", "01", "10", "02", "12", "20", "21", "30"].sort();
      const result = neighbors.sort();

      expect(result).toEqual(expected);
      expect(result.length).toBe(8);
    });

    test('Corner Node "00"', () => {
      const key = "00";
      const neighbors = QuadKey.fromString(key).neighbors(1);
      
      const expected = ["01", "02", "03", "11", "13"].sort() // 지도는 연결되어 있으니 00-11, 00-13은 이웃
      const result = neighbors.sort();

      expect(result).toEqual(expected);
      expect(result.length).toBe(5); 
    });
  });
});