import { Request, Response } from "express";
import { SuccessResponse } from "@/response/successResponse";
import { db } from "@/utils/firebase";
import { QuadKey } from "@/utils/QuadKey";
import { convertToPostDetailV3 } from "@/posts/models/postDetail";
import { PostDetailV3 } from "@/posts/models/postDetail";
import { sendError, ErrorCase } from "@/response/errorResponse";
import * as logger from "firebase-functions/logger";

export const fetchNearbyPostsV3 = async (req: Request, res: Response) => {
  const lat = parseFloat(req.query.latitude as string);
  const lng = parseFloat(req.query.longitude as string);
  const clientZoom = parseInt(req.query.zoom as string, 10);
  const cursor = req.query.cursor as string | undefined;

  const targetCount = 20;
  const START_PRECISION = 21;

  if (isNaN(lat) || isNaN(lng) || isNaN(clientZoom)) {
    sendError(res, ErrorCase.INVALID_QUERY)
    return;
  }

  const userID = ""; 

  try {
    const collectedPosts: PostDetailV3[] = [];
    let minZoom = clientZoom - 1;
    if (minZoom < 5) minZoom = 5;

    // 커서가 있으면 그 값을 쓰고, 없으면 새로 생성
    let currentKeyString = cursor || QuadKey.fromGeo(lat, lng, START_PRECISION).toString();
    
    // [중요] 줌 레벨은 문자열 길이로 판단
    let currentZoom = currentKeyString.length;

    // 1. 첫 진입인 경우만 자식 노드 탐색
    if (!cursor) {
      const initialTargets = ['0', '1', '2', '3'].map(suffix => currentKeyString + suffix);
      await fetchAndCollect(initialTargets, collectedPosts, targetCount, userID);
    }

    // 2. 줌아웃 확장 탐색
    while (collectedPosts.length < targetCount && currentZoom > minZoom) {
      const parentKeyString = currentKeyString.slice(0, -1);
      if (!parentKeyString) break;

      const siblings = ['0', '1', '2', '3'].map(suffix => parentKeyString + suffix);
      const nextTargets = siblings.filter(key => key !== currentKeyString);
      
      await fetchAndCollect(nextTargets, collectedPosts, targetCount, userID);

      currentKeyString = parentKeyString;
      currentZoom = currentKeyString.length; // 길이 갱신
    }

    collectedPosts.sort((a, b) => b.createdAt.toMillis() - a.createdAt.toMillis());
    const finalPosts = collectedPosts.slice(0, targetCount);

    const response: SuccessResponse = {
      status: "SUCCESS",
      message: "Nearby posts fetched successfully", // message 필드 추가
      result: {
        posts: finalPosts,
        count: finalPosts.length,
        nextCursor: currentKeyString 
      }
    };

    res.status(200).json(response);
  } catch (error) {
    logger.error("Error fetching quadtree posts:", error);
    res.status(500).json({ code: "server-error", message: "Internal Error" });
  }
};

async function fetchAndCollect(
  keys: string[], 
  collection: PostDetailV3[], 
  limit: number, 
  userID: string
) {
  if (collection.length >= limit) return;

  const queries = keys.map(key => 
    db.collection("posts")
      .where("quadKeys", "array-contains", key)
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get()
  );

  const snapshots = await Promise.all(queries);

  for (const snap of snapshots) {
    if (!snap.empty) {
      const details = snap.docs.map(doc => convertToPostDetailV3(doc, userID));
      collection.push(...details);
    }
  }
}