import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { PostSummary } from "./post"
import { db, adminInstance as admin } from "../utils/firebase";
const REGION = "asia-northeast3";

// 사용자별 게시글 조회 (최대 20개, 최신순, 페이징 지원) - 인증 토큰 기반
export const getPostsByUser = onRequest({ region: REGION }, async (req, res) => {
  // 인증 토큰 추출
  const authHeader = req.headers.authorization;
  const idToken = authHeader?.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : null;

  if (!idToken) {
    res.status(401).json({
      code: "UNAUTHORIZED_MISSING_TOKEN",
      message: "Missing or invalid Authorization header"
    });
    return;
  }

  // 토큰에서 uid 디코딩
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

  // 커서 파라미터: nextCursor
  const nextCursor = req.query.nextCursor;

  let query = db.collection("posts")
    .where("creatorID", "==", uid)
    .orderBy("createdAt", "desc")
    .limit(20);

  // 페이징: nextCursor 이후의 게시글부터 조회 (startAfter)
  if (nextCursor && typeof nextCursor === "string") {
    const date = new Date(nextCursor);
    if (!isNaN(date.getTime())) {
      // Firestore에는 createdAt이 string(ISO)으로 저장되어 있으므로, toISOString() 사용
      query = query.startAfter(date.toISOString());
    }
  }

  try {
    const snapshot = await query.get();
    const posts: PostSummary[] = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        title: data.title,
        imageUrl: data.imageUrl,
        location: data.location
      };
    });

    // 다음 페이지 커서 (마지막 createdAt)
    const nextCursorRaw = snapshot.docs.length > 0
      ? snapshot.docs[snapshot.docs.length - 1].data().createdAt
      : null;
    const nextCursorValue = nextCursorRaw?.toDate?.() ?? null;

    res.status(200).json({
      status: "SUCCESS",
      message: "Posts fetched",
      result: {
        posts,
        nextCursor: nextCursorValue
      }
    });
  } catch (error) {
    logger.error("Error fetching posts by user:", error);
    res.status(500).json({
      code: "FIRESTORE_FETCH_FAILED",
      message: "Failed to fetch posts by user"
    });
  }
});
