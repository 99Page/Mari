import * as admin from 'firebase-admin';
import { QuadKey } from './src/utils/QuadKey';

const serviceAccount = require('./serviceAccountKey.json'); 

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migratePostsToQuadKey() {
  console.log("🚀 마이그레이션 시작...");

  const postsRef = db.collection('posts'); // 혹은 컬렉션 그룹이 필요하면 수정
  const snapshot = await postsRef.get(); // 문서가 너무 많으면 stream() 권장

  if (snapshot.empty) {
    console.log("데이터가 없습니다.");
    return;
  }

  const bulkWriter = db.bulkWriter();
  let count = 0;
  let skipped = 0;

  console.log(`총 ${snapshot.size}개의 문서를 처리합니다.`);

  snapshot.docs.forEach((doc) => {
    const data = doc.data();

    // 1. 좌표 데이터 가져오기 (필드명 확인 필수: location 혹은 latitude/longitude)
    let lat: number | undefined;
    let lng: number | undefined;

    if (data.location && data.location.latitude) {
      // GeoPoint 타입인 경우
      lat = data.location.latitude;
      lng = data.location.longitude;
    } else if (data.latitude && data.longitude) {
      // 숫자 필드로 따로 저장된 경우
      lat = data.latitude;
      lng = data.longitude;
    }


    if (lat !== undefined && lng !== undefined) {
      const quadKey = QuadKey.fromGeo(lat, lng, 22).toString();
      if (data.quadKeyL22 === quadKey) {
        skipped++;
        return;
      }

      bulkWriter.update(doc.ref, { 
        quadKeyL22: quadKey 
      });
      
      count++;
    } else {
      console.warn(`[SKIP] 문서 ID ${doc.id}: 좌표 정보 없음`);
      skipped++;
    }
  });

  await bulkWriter.close();
  console.log(`✅ 마이그레이션 완료!`);
  console.log(`- 업데이트됨: ${count}`);
  console.log(`- 스킵됨: ${skipped}`);
}

migratePostsToQuadKey().catch(console.error);