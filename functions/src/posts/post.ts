

// 사용자 게시글 응답에 필요한 최소 정보 구조체
export interface PostSummary {
  id: string;
  title: string;
  imageUrl: string;
  creatorID: string;
  location: FirebaseFirestore.GeoPoint;
}