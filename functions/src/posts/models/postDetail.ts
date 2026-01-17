import * as admin from 'firebase-admin';

// 1. PostDetail 인터페이스 정의 (공용 사용)
export interface PostDetail {
  id: string;
  title: string;
  content: string;
  imageUrl: string;
  markerUrl: string;
  location: FirebaseFirestore.GeoPoint;
  createdAt: FirebaseFirestore.Timestamp;
  creatorID: string;
  geohash_1: string;
  geohash_2: string;
  geohash_3: string;
  geohash_4: string;
  geohash_5: string;
  geohash_6: string;
  geohash_7: string;
  geohash_8: string;
  geohash_9: string;
  geohash_10: string;
  isMine: boolean; // 요청한 사용자가 생성했는지 판단
}

// 2. 변환 헬퍼 함수 (재사용 가능)
// Firestore 스냅샷과 userID를 받아 PostDetail 객체로 반환
export function convertToPostDetail(doc: admin.firestore.DocumentSnapshot, userID: string): PostDetail {
  const data = doc.data() || {};
  
  return {
    id: doc.id,
    title: data.title,
    content: data.content,
    imageUrl: data.imageUrl,
    markerUrl: data.markerUrl ?? null,
    location: data.location,
    createdAt: data.createdAt,
    creatorID: data.creatorID,
    geohash_1: data.geohash_1,
    geohash_2: data.geohash_2,
    geohash_3: data.geohash_3,
    geohash_4: data.geohash_4,
    geohash_5: data.geohash_5,
    geohash_6: data.geohash_6,
    geohash_7: data.geohash_7,
    geohash_8: data.geohash_8,
    geohash_9: data.geohash_9,
    geohash_10: data.geohash_10,
    isMine: userID === data.creatorID
  };
}