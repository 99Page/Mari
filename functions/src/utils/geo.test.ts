import { toBase4 } from "@/utils/geo";

describe('toBase4 (QuadKey Generator)', () => {

  describe('Precision 17', () => {
    // 광화문 좌표
    const sinrimHome = {
      lat: 37.4837641826256, 
      lon: 126.93189792720779
    };
  
    const sinrimHash = "13211032012202132"

    test('신림', () => {
      const sinrimHash = toBase4(sinrimHome.lat, sinrimHome.lon, 17);

      expect(sinrimHash).toBe("13211032012202132")
    });

    test('양지 병원', () => {
      const hash = toBase4(37.4841408, 126.9325573, 17);

      expect(hash).toBe(sinrimHash)
    });

    test('카페 그날', () => {
      const hash = toBase4(37.4840405, 126.9331012, 17);

      expect(hash).toBe(sinrimHash)
    });

    test('GS25', () => {
      const hash = toBase4(37.4841941, 126.9313648, 17);

      expect(hash).toBe(sinrimHash)
    });
  });

   describe('Precision 18', () => {
    // 광화문 좌표
    const sinrimHome = {
      lat: 37.4837641826256, 
      lon: 126.93189792720779
    };
  
    const sinrimHash = "132110320122021322"

    test('신림', () => {
      const sinrimHash = toBase4(sinrimHome.lat, sinrimHome.lon, 18);

      expect(sinrimHash).toBe("132110320122021322")
    });

    test('양지 병원', () => {
      const hash = toBase4(37.4841408, 126.9325573, 18);

      expect(hash).not.toBe(sinrimHash)
    });

    test('카페 그날', () => {
      const hash = toBase4(37.4840405, 126.9331012, 18);

      expect(hash).not.toBe(sinrimHash)
    });

    test('GS25', () => {
      const hash = toBase4(37.4841941, 126.9313648, 18);

      expect(hash).toBe(sinrimHash)
    });
  });
});