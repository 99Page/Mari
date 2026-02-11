export interface PostSummary {
  id: string;
  title: string;
  imageUrl: string;
  creatorID: string;
  location: FirebaseFirestore.GeoPoint;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface PostSummaryV3 {
  id: string;
  title: string;
  imageUrl: string;
  thumbnail240Url: string;
  thumbnail540Url: string;
  creatorID: string;
  location: FirebaseFirestore.GeoPoint;
  createdAt: FirebaseFirestore.Timestamp;  
}