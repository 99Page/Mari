import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db, adminInstance as admin } from "../utils/firebase";

const REGION = "asia-northeast3";


// 사용자 게시글 삭제 API
export const deletePost = onRequest({ region: REGION }, async (req, res) => {
  if (req.method !== 'DELETE') {
    res.status(405).json({
      code: "METHOD_NOT_ALLOWED",
      message: "Only DELETE method is allowed"
    });
    return;
  }

  const authHeader = req.headers.authorization;
  const idToken = authHeader?.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : null;

  if (!idToken) {
    res.status(401).json({
      code: "UNAUTHORIZED_MISSING_TOKEN",
      message: "Missing or invalid Authorization header"
    });
    return;
  }

  let uid: string;
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    uid = decoded.uid;
  } catch (error) {
    logger.error("Token verification failed:", error);
    res.status(401).json({
      code: "UNAUTHORIZED_INVALID_TOKEN",
      message: "Token verification failed"
    });
    return;
  }

  const postId = req.query.id;
  if (!postId || typeof postId !== "string") {
    res.status(400).json({
      code: "INVALID_POST_ID",
      message: "Missing or invalid 'id' query parameter"
    });
    return;
  }

  const postRef = db.collection("posts").doc(postId);
  const snapshot = await postRef.get();

  if (!snapshot.exists) {
    res.status(404).json({
      code: "POST_NOT_FOUND",
      message: "Post not found"
    });
    return;
  }

  // 요청한 사용자의 포스트인지 검증
  const post = snapshot.data();
  if (post?.creatorID !== uid) {
    res.status(403).json({
      code: "FORBIDDEN_NOT_CREATOR",
      message: "You are not the creator of this post"
    });
    return;
  }

  try {
    await postRef.delete();
    res.status(200).json({
      status: "SUCCESS",
      message: "Post deleted",
      result: {
        id: postId
      }
    });
  } catch (error) {
    logger.error("Error deleting post:", error);
    res.status(500).json({
      code: "FIRESTORE_DELETE_FAILED",
      message: "Failed to delete post"
    });
  }
});

