import { Request, Response } from "express";
import * as logger from "firebase-functions/logger";
import { db, adminInstance as admin } from "@/utils/firebase";
import { QuadKey } from "@/utils/QuadKey";
import { convertToPostDetailV3, PostDetailV3 } from "@/posts/models/postDetail"; // 모델은 V3(수정본) 재사용
import { PostSummary } from "@/posts/models/postSummary";
import { ErrorResponse } from "@/response/errorResponse";
import { logErrorToFirestore } from "@/utils/errorLogger";

export const fetchPostsForMapV3 = async (req: Request, res: Response) => {
  const lat = parseFloat(req.query.latitude as string);
  const lng = parseFloat(req.query.longitude as string);
  const zoom = parseInt(req.query.zoom as string, 10);

  // 1. 유효성 검사
  if (isNaN(lat) || isNaN(lng)) {
    const errorResponse: ErrorResponse = {
      code: "invalid-location-query",
      message: "Missing or invalid 'latitude' or 'longitude'"
    };
    res.status(400).json(errorResponse);
    return;
  }

  if (isNaN(zoom) || zoom < 0 || zoom > 23) {
    res.status(400).json({
      code: "invalid-zoom-query",
      message: "'zoom' query parameter must be an integer between 0 and 23"
    });
    return;
  }

  // 2. 토큰 확인 (선택적)
  let userID = "";
  try {
    const authHeader = req.headers.authorization || "";
    if (authHeader.startsWith("Bearer ")) {
      const idToken = authHeader.split("Bearer ")[1];
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      userID = decodedToken.uid;
    }
  } catch (error) {
    logger.warn("Failed to verify ID token:", error);
  }

  try {
    // 3. QuadKey 계산
    const targetPrecision = Math.min(zoom + 2, 22);
    const centerKey = QuadKey.fromGeo(lat, lng, targetPrecision);

    // 주변 타일 포함 9개(또는 설정에 따라) 키 생성
    const searchKeys = [
      centerKey.toString(),
      ...centerKey.neighbors(1, 3)
    ];

    // 4. [핵심] V4 쿼리 로직 실행
    const posts = await fetchPostsByQuadKeyArray(searchKeys, userID);

    // 5. 결과 가공
    const postSummaries: PostSummary[] = posts.map(post => ({
      id: post.id,
      title: post.title,
      imageUrl: post.imageUrl,
      creatorID: post.creatorID,
      location: post.location,
      createdAt: post.createdAt
    }));

    // (선택) 전체 결과에서 다시 한 번 시간순 정렬 (타일 간 순서 보정)
    postSummaries.sort((a, b) => b.createdAt.toMillis() - a.createdAt.toMillis());

    res.status(200).json({
      status: "SUCCESS",
      message: "Successfully fetched posts (V4 Compound Key)",
      result: {
        zoomLevel: zoom,
        appliedPrecision: targetPrecision, 
        posts: postSummaries,
        postCount: posts.length
      }
    });

  } catch (error) {
    logger.error("Error fetching posts V4:", error);
    await logErrorToFirestore(error, { handler: "fetchPostsForMapV3", userId: userID || undefined, req });
    res.status(500).json({
      code: "fetch-failed",
      message: "Failed to fetch posts"
    });
  }
};

async function fetchPostsByQuadKeyArray(keys: string[], userID: string): Promise<PostDetailV3[]> {
  const queries = keys.map(async (targetKey) => {
    // 쿼리 설명:
    const snapshot = await db.collection("posts")
      .where("quadKeys", "array-contains", targetKey) 
      .orderBy("createdAt", "desc") 
      .limit(3) 
      .get();

    if (!snapshot.empty) {
      return snapshot.docs.map(doc => convertToPostDetailV3(doc, userID));
    }
    return [];
  });

  const results = await Promise.all(queries);
  return results.flat();
}