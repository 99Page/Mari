import { Request, Response } from "express";
import * as logger from "firebase-functions/logger";
import { db, adminInstance as admin } from "@/utils/firebase";
import { QuadKey } from "@/utils/QuadKey";
import { convertToPostDetailV3 } from "@/posts/models/postDetail";
import { PostSummary } from "@/posts/models/postSummary";
import { ErrorResponse } from "@/resopnse/errorResponse";

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

  // 줌 레벨 유효성 체크 (일반적인 지도 API 범위: 0 ~ 22)
  if (isNaN(zoom) || zoom < 0 || zoom > 23) {
    const errorResponse: ErrorResponse = {
      code: "invalid-zoom-query",
      message: "'zoom' query parameter must be an integer between 0 and 23"
    };
    res.status(400).json(errorResponse);
    return;
  }

  // 2. User ID 추출
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
    const targetPrecision = Math.min(zoom + 1, 22);
    const centerKey = QuadKey.fromGeo(lat, lng, targetPrecision);

    // 4. 주변 타일(Neighbors) 포함 검색 키 생성 (3x3 Grid = 9개)
    const searchKeys = [
      centerKey.toString(),
      ...centerKey.neighbors() 
    ];

    // 5. DB 조회 실행
    const posts = await fetchPostsByQuadKeys(searchKeys, userID);

    // 6. 응답 데이터 변환
    const postSummaries: PostSummary[] = posts.map(post => ({
      id: post.id,
      title: post.title,
      imageUrl: post.imageUrl,
      creatorID: post.creatorID,
      location: post.location,
      createdAt: post.createdAt
    }));

    res.status(200).json({
      status: "SUCCESS",
      message: "Successfully fetched posts (V3)",
      result: {
        zoomLevel: zoom,
        appliedPrecision: targetPrecision, // "Zoom + 1" 적용 결과
        posts: postSummaries,
        postCount: posts.length
      }
    });

  } catch (error) {
    logger.error("Error fetching posts V3:", error);
    res.status(500).json({
      code: "fetch-failed",
      message: "Failed to fetch posts"
    });
  }
};

/**
 * QuadKey Prefix 리스트를 받아 병렬로 Firestore 조회
 */
async function fetchPostsByQuadKeys(keys: string[], userID: string) {
  const queries = keys.map(async (keyPrefix) => {
    // Prefix 검색 로직
    const snapshot = await db.collection("posts")
      .where("quadKeyL22", ">=", keyPrefix)
      .where("quadKeyL22", "<", keyPrefix + "\uf8ff")
      .orderBy("quadKeyL22")      
      .orderBy("createdAt", "desc") 
      .limit(5)
      .get();

    if (!snapshot.empty) {
      return snapshot.docs.map(doc => convertToPostDetailV3(doc, userID));
    }
    return [];
  });

  const results = await Promise.all(queries);
  return results.flat();
}