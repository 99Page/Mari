

// V1: (기존 유지 - 레거시 호환용)
export interface PostSummary {
  id: string;
  title: string;
  imageUrl: string;
  creatorID: string;
  location: FirebaseFirestore.GeoPoint;
}

// 포스트 내용 조회에 대한 간단한 정보. 
// 지도 표시에 이용. 
// 카메라로 찍은 사진 정보와, 마커 분리 
export interface PostSummaryV2 {
  id: string;
  title: string;
  imageUrl: string; // 기존 기능을 위해서 유지
  markerUrl: string | null; // 레거시는 마커 없을 수 있음
  creatorID: string;
  location: FirebaseFirestore.GeoPoint;
}