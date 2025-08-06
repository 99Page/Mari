// 사용자 게시글 응답에 필요한 최소 정보 구조체
export interface PostSummary {
  id: string;
  title: string;
  imageUrl: string;
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