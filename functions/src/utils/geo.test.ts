import { toBase4 } from "@/utils/geo";

describe('toBase4 (QuadKey Generator)', () => {

  describe('광화문 좌표로 검증', () => {
    // 광화문 좌표
    const spot = {
      lat: 37.572395, 
      lon: 126.976939
    };

    test('모든 정밀도(1~22)가 계층 구조(Prefix)를 완벽하게 유지해야 한다', () => {
    
      const MAX_PRECISION = 22;
      const fullHash = '1321103200022221122323';

      for (let p = 1; p <= MAX_PRECISION; p++) {
        const currentHash = toBase4(spot.lat, spot.lon, p);
        const expectedPrefix = fullHash.substring(0, p);
        expect(currentHash).toBe(expectedPrefix);
      }
    });
  });
});