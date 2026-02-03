import * as admin from 'firebase-admin';
import { QuadKey } from './src/utils/QuadKey'; 

const serviceAccount = require('./serviceAccountKey.json'); 

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function migratePostsToQuadKeyArray() {
  console.log("🚀 마이그레이션(Array 방식 전환) 시작...");

  const postsRef = db.collection('posts'); 
  const snapshot = await postsRef.get();

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

    // 1. 좌표 데이터 추출
    let lat: number | undefined;
    let lng: number | undefined;

    // GeoPoint 객체 우선 확인
    if (data.location && typeof data.location.latitude === 'number') {
      lat = data.location.latitude;
      lng = data.location.longitude;
    } 
    // 평문 필드(latitude, longitude) 확인
    else if (typeof data.latitude === 'number' && typeof data.longitude === 'number') {
      lat = data.latitude;
      lng = data.longitude;
    }

    if (lat !== undefined && lng !== undefined) {
      try {
        const fullQuadKey = QuadKey.fromGeo(lat, lng, 22).toString();

        const quadKeys: string[] = [];
        for (let i = 1; i <= fullQuadKey.length; i++) {
          quadKeys.push(fullQuadKey.substring(0, i));
        }

        const isAlreadyMigrated = 
          data.quadKeys && 
          data.quadKeys.length === quadKeys.length &&
          data.quadKeys[quadKeys.length - 1] === fullQuadKey &&
          data.quadKeyL22 === undefined &&     
          data.quadKeyTimeL22 === undefined;   

        if (isAlreadyMigrated) {
          skipped++;
          return;
        }

        bulkWriter.update(doc.ref, { 
          quadKeys: quadKeys,
          quadKeyL22: admin.firestore.FieldValue.delete(),     
          quadKeyTimeL22: admin.firestore.FieldValue.delete()  
        });
        
        count++;
      } catch (e) {
        console.error(`[ERROR] 문서 ID ${doc.id} 처리 중 오류:`, e);
      }
    } else {
      console.warn(`[SKIP] 문서 ID ${doc.id}: 필수 좌표 정보 부족`);
      skipped++;
    }
  });

  await bulkWriter.close();
  console.log(`✅ 마이그레이션 완료!`);
  console.log(`- 업데이트됨: ${count}`);
  console.log(`- 스킵됨(이미 완료): ${skipped}`);
}

migratePostsToQuadKeyArray().catch(console.error);