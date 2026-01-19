export interface PostSummary {
  id: string;
  title: string;
  imageUrl: string;
  creatorID: string;
  location: FirebaseFirestore.GeoPoint;
}