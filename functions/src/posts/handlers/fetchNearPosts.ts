import { onRequest } from "firebase-functions/v2/https";
import Geohash from "latlon-geohash";
import { db, adminInstance as admin } from "@/utils/firebase";
import { ErrorResponse, Errors } from "@/resopnse/errorResponse";
import { region } from "@/utils/firebase";
import type { SuccessResponse } from "@/resopnse/successResponse";
import { verifyAuthAndGetUid } from "@/auth/verifyToken";
import { PostDetail, convertToPostDetail } from "@/posts/models/postDetail";

export const nearPostsV1 = onRequest({ region: region }, async (req, res) => {
  const lat = parseFloat(req.query.latitude as string);
  const lng = parseFloat(req.query.longitude as string);
  const precision = parseInt(req.query.precision as string, 10); // 10진법
  const nextCursor = req.query.nextCursor as string;
  const limit = parseInt(req.query.limit as string, 10)

  const uid = await verifyAuthAndGetUid(req, res);
  if (uid == null) return; 

  const missing = hasParams(lat, lng, precision, limit);
  if (missing) {
    res.status(400).json(missing);
    return;
  }

  const geohash = Geohash.encode(lat, lng, precision);
  const geohashField = `geohash_${precision}`;

  try {
    let query = db.collection("posts")
        .where(geohashField, "==", geohash)
        .orderBy("createdAt", "desc")
        .limit(limit);

    if (nextCursor) {
        const date = new Date(nextCursor);
        const cursor = admin.firestore.Timestamp.fromDate(date);
        query = query.startAfter(cursor); 
    }

    const snapshot = await query.get();

    const posts: PostDetail[] = snapshot.docs.map(doc => 
      convertToPostDetail(doc, uid)
    );

    // 다음 페이지 커서 (마지막 createdAt)
    const nextCursorRaw = snapshot.docs.length > 0
      ? snapshot.docs[snapshot.docs.length - 1].data().createdAt
      : null;
    const nextCursorValue = nextCursorRaw?.toDate?.() ?? null;

    const successResponse: SuccessResponse<{
     posts: PostDetail[];
     nextCursor: Date | null;
   }> = {
     status: "success",
     message: "Posts fetched",
     result: {
       posts,
       nextCursor: nextCursorValue
     }
   };
   res.status(200).json(successResponse);

  } catch {
    res.status(500).json(Errors.NEAR_POST_FETCH_FAILED);
  }
});

function hasParams(
  lat: number,
  lng: number,
  precision: number,
  limit: number
): ErrorResponse | null {
  if (isNaN(lat) || isNaN(lng) || isNaN(precision) || isNaN(limit)) {
    return {
      code: "invalid-argument",
      message: "쿼리 파라미터(latitude, longitude, precision)가 모두 필요합니다."
    };
  }
  return null;
}