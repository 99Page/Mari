import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { PostDetail } from './post'
import { db, adminInstance as admin } from "../utils/firebase";

const REGION = "asia-northeast3";


export async function fetchPostById(postId: string, userID: string): Promise<PostDetail> {
  const docRef = db.collection("posts").doc(postId);
  const doc = await docRef.get();
  if (!doc.exists) {
    throw new Error("Post not found");
  }
  const data = doc.data();
  return {
    id: doc.id,
    title: data?.title,
    content: data?.content,
    imageUrl: data?.imageUrl,
    location: data?.location,
    createdAt: data?.createdAt,
    creatorID: data?.creatorID,
    geohash_1: data?.geohash_1,
    geohash_2: data?.geohash_2,
    geohash_3: data?.geohash_3,
    geohash_4: data?.geohash_4,
    geohash_5: data?.geohash_5,
    geohash_6: data?.geohash_6,
    geohash_7: data?.geohash_7,
    geohash_8: data?.geohash_8,
    geohash_9: data?.geohash_9,
    geohash_10: data?.geohash_10,
    isMine: userID === data?.creatorID
  };
}

export const getPostById = onRequest({ region: REGION }, async (req, res) => {
  const postId = req.query.id;

  if (!postId || typeof postId !== "string") {
    res.status(400).json({ code: "INVALID_ID", message: "Missing or invalid 'id' query parameter" });
    return;
  }

  const authHeader = req.get("Authorization");
  const idToken = authHeader?.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : undefined;

  if (!idToken) {
    res.status(401).json({ code: "UNAUTHORIZED", message: "Missing Authorization header" });
    return;
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const userID = decodedToken.uid;

    const post = await fetchPostById(postId, userID);
    res.status(200).json(post);
  } catch (error: any) {
    logger.error("Error fetching post by ID:", error);
    res.status(404).json({ code: "POST_NOT_FOUND", message: error.message || "Failed to fetch post" });
  }
});