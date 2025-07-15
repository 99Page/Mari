import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import Geohash from "latlon-geohash";
import { db, adminInstance as admin } from "../utils/firebase";

const REGION = "asia-northeast3";


export const createPost = onRequest({ region: REGION }, async (req, res) => {
  try {
    // 클라이언트에서 전달된 Firebase 인증 토큰을 확인
    const authHeader = req.headers.authorization;
    const idToken = authHeader?.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : null;

    if (!idToken) {
      res.status(401).json({
        code: "UNAUTHORIZED_MISSING_TOKEN",
        message: "Missing or invalid Authorization header"
      });
      return;
    }

    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      logger.error("Token verification failed:", error);
      res.status(401).json({
        code: "UNAUTHORIZED_INVALID_TOKEN",
        message: "Token verification failed"
      });
      return;
    }

    // 요청 본문에서 필요한 필드 추출 및 유효성 검사
    const body = req.body;

    if (!body || typeof body !== "object") {
      res.status(400).json({
        code: "INVALID_BODY",
        message: "Invalid request body"
      });
      return;
    }

    const { title, content, latitude, longitude, creatorID, imageUrl } = body;

    if (!title || latitude == null || longitude == null || !creatorID || !imageUrl) {
      res.status(400).json({
        code: "MISSING_REQUIRED_FIELDS",
        message: "Missing required fields"
      });
      return;
    }

    if (
      typeof latitude !== "number" || isNaN(latitude) ||
      typeof longitude !== "number" || isNaN(longitude)
    ) {
      res.status(400).json({
        code: "INVALID_COORDINATES",
        message: "Invalid latitude or longitude"
      });
      return;
    }

    // GeoHash는 위치 기반 검색 최적화를 위해 사용됨
    // precision 값이 작을수록 더 넓은 범위를 커버하고, 클수록 정밀도가 높아짐
    // 예) precision 1 → 약 수천 km / precision 10 → 약 1m 단위의 위치 구분 가능
    // precision 1~10까지의 다양한 정밀도로 인코딩된 값들을 생성하여 저장
    let geohashFields: Record<string, string> = {};
    try {
      for (let p = 1; p <= 10; p++) {
        geohashFields[`geohash_${p}`] = Geohash.encode(latitude, longitude, p);
      }
    } catch (e) {
      logger.error("GeoHash encoding failed:", e);
      res.status(500).json({
        code: "GEOHASH_ENCODING_ERROR",
        message: "GeoHash encoding error"
      });
      return;
    }

    // Firestore에 저장할 새로운 포스트 객체 구성
    const newPost = {
      title,
      content,
      location: new admin.firestore.GeoPoint(latitude, longitude),
      creatorID,
      imageUrl,
      dailyScore: 0,
      weeklyScore: 0,
      monthlyScore: 0,
      viewCount: 0,
      createdAt: new Date(),
      ...geohashFields
    };

    // Firestore의 "posts" 컬렉션에 문서 추가
    const postRef = await db.collection("posts").add(newPost);

    res.status(201).json({ id: postRef.id, ...newPost });
  } catch (error) {
    logger.error("Error creating post:", error);
    res.status(500).json({
      code: "FIRESTORE_WRITE_FAILED",
      message: "Failed to create post"
    });
  }
});