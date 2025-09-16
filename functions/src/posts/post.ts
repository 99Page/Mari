

// 사용자 게시글 응답에 필요한 최소 정보 구조체
export interface PostSummary {
  id: string;
  title: string;
  imageUrl: string;
  creatorID: string;
  location: FirebaseFirestore.GeoPoint;
}

export interface PostDetail {
  id: string;
  title: string;
  content: string;
  imageUrl: string;
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

// Firestore DocumentData → PostDetail 변환 함수
export function mapDataToPostDetail(
  data: FirebaseFirestore.DocumentData,
  uid: string
): PostDetail {
  return {
    id: data.id,
    title: data.title,
    content: data.content,
    imageUrl: data.imageUrl,
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
    geohash_9: data.geohash_9 ,
    geohash_10: data.geohash_10,
    isMine: uid == data.creatorID, // 기본값, 호출하는 쪽에서 로그인 사용자 ID 비교로 갱신
  };
}