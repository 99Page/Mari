import { Request, Response } from "express"; 
import * as logger from "firebase-functions/logger";
import Geohash from "latlon-geohash";
import { db, adminInstance as admin } from "../../utils/firebase";
import { errors } from "../../resopnse/errorResponse";
import type { ErrorResponse } from "../../resopnse/errorResponse";
import { PostDetail } from "../models/postDetail";



export const createPost = async (req: Request, res: Response) => {
  try {
    // 클라이언트에서 전달된 Firebase 인증 토큰을 확인
    const authHeader = req.headers.authorization;
    const idToken = authHeader?.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : null;

    if (!idToken) {
      res.status(401).json(errors.UNAUTHORIZED);
      return;
    }

    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      logger.error("Token verification failed:", error);
      res.status(401).json(errors.UNAUTHORIZED);
      return;
    }

    // 요청 본문에서 필요한 필드 추출 및 유효성 검사
    const body = req.body;

    if (!body || typeof body !== "object") {
      const errorResponse: ErrorResponse = {
        code: "INVALID_BODY",
        message: "Invalid request body"
      };
      res.status(400).json(errorResponse);
      return;
    }

    const { title, content, latitude, longitude, creatorID, imageUrl } = body;

    if (!title || latitude == null || longitude == null || !creatorID || !imageUrl) {
      const errorResponse: ErrorResponse = {
        code: "MISSING_REQUIRED_FIELDS",
        message: "Missing required fields"
      };
      res.status(400).json(errorResponse);
      return;
    }

    if (
      typeof latitude !== "number" || isNaN(latitude) ||
      typeof longitude !== "number" || isNaN(longitude)
    ) {
      const errorResponse: ErrorResponse = {
        code: "INVALID_COORDINATES", 
        message: "Invalid latitude or longitude"
      };
      res.status(400).json(errorResponse);
      return;
    }

    const bannedInTitle = hasBannedWord(title);
    const bannedInContent = hasBannedWord(content);
    const allBannedWords = [...bannedInTitle, ...bannedInContent];

    if (allBannedWords.length > 0) {
      res.status(400).json(errors.BANNED_WORD_DETECTED(allBannedWords[0]));
      return;
    }

    // GeoHash는 위치 기반 검색 최적화를 위해 사용됨
    // precision 값이 작을수록 더 넓은 범위를 커버하고, 클수록 정밀도가 높아짐
    // 예) precision 1 → 약 수천 km / precision 10 → 약 1m 단위의 위치 구분 가능
    // precision 1~10까지의 다양한 정밀도로 인코딩된 값들을 생성하여 저장
    let geohashFields: Record<string, string> = {};
    const GEOHASH_ENCODING_ERROR: ErrorResponse = {
      code: "GEOHASH_ENCODING_ERROR",
      message: "GeoHash encoding error"
    };
    try {
      for (let p = 1; p <= 10; p++) {
        geohashFields[`geohash_${p}`] = Geohash.encode(latitude, longitude, p);
      }
    } catch (e) {
      logger.error("GeoHash encoding failed:", e);
      res.status(500).json(GEOHASH_ENCODING_ERROR);
      return;
    }

    const now = new Date();
    const createdAtTimestamp = admin.firestore.Timestamp.fromDate(now);
    const locationGeoPoint = new admin.firestore.GeoPoint(latitude, longitude);

    // Firestore에 저장할 새로운 포스트 객체 구성
    const newPost = {
      title,
      content,
      location: locationGeoPoint,
      creatorID,
      imageUrl,
      createdAt: createdAtTimestamp,
      ...geohashFields
    };

    // Firestore의 "posts" 컬렉션에 문서 추가
    const postRef = await db.collection("posts").add(newPost);

    const resultData: PostDetail = {
      id: postRef.id,
      title,
      content,
      imageUrl,
      location: locationGeoPoint,     // GeoPoint 타입
      createdAt: createdAtTimestamp,  // Timestamp 타입
      creatorID,
      geohash_1: geohashFields["geohash_1"],
      geohash_2: geohashFields["geohash_2"],
      geohash_3: geohashFields["geohash_3"],
      geohash_4: geohashFields["geohash_4"],
      geohash_5: geohashFields["geohash_5"],
      geohash_6: geohashFields["geohash_6"],
      geohash_7: geohashFields["geohash_7"],
      geohash_8: geohashFields["geohash_8"],
      geohash_9: geohashFields["geohash_9"],
      geohash_10: geohashFields["geohash_10"],
      isMine: true
    };

  res.status(201).json({
    status: "SUCCESS",
    message: "Post created successfully",
    result: resultData
  });
  } catch (error) {
    logger.error("Error creating post:", error);
    const errorResponse: ErrorResponse = {
      code: "FIRESTORE_WIRTE_FAILED",
      message: "Failed to create post"
    };
    res.status(500).json(errorResponse);
  }
};

function hasBannedWord(text: string): string[] {
  const normalizedText = text
    .toLowerCase()
    .replace(/[\s.,!?;:'"(){}\[\]<>@#$%^&*_+=~`|\\/\\-]/g, "");

  const matchedWords = bannedWords.filter(word => normalizedText.includes(word.toLowerCase()));
  return matchedWords;
}

const bannedWords: string[] = [
  // 성적인 표현
  "sex", "sexual", "porn", "porno", "pornography", "nude", "naked",
  "섹스", 
  
  // 욕설/비하 (한글 초성·완성 혼합)
  "fuck", "shit", "bitch", "bastard", "asshole", "jerk",
  "개새", "개새끼", "씨발", "ㅅㅂ", "ㅂㅅ", "멍청이",
];