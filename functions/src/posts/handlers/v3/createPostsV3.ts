import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import * as logger from "firebase-functions/logger";
import { errors } from '@/resopnse/errorResponse';
import { QuadKey } from '@/utils/QuadKey'; // 아까 만든 QuadKey 클래스 경로
import { PostDetailV3 } from '@/posts/models/postDetail'; // 아까 정의한 인터페이스 경로
import { hasBannedWord } from '@/utils/bannedWords'
import { db } from '@/utils/firebase';

export const createPostV3 = async (req: Request, res: Response) => {
  try {
    // 1. 인증 토큰 확인
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

    // 2. 유효성 검사 (Body & Field)
    const body = req.body;

    if (!body || typeof body !== "object") {
      res.status(400).json({ code: "INVALID_BODY", message: "Invalid request body" });
      return;
    }

    const { title, content, latitude, longitude, creatorID, imageUrl } = body;

    if (!title || latitude == null || longitude == null || !creatorID || !imageUrl) {
      res.status(400).json({ code: "MISSING_REQUIRED_FIELDS", message: "Missing required fields" });
      return;
    }

    if (
      typeof latitude !== "number" || isNaN(latitude) ||
      typeof longitude !== "number" || isNaN(longitude)
    ) {
      res.status(400).json({ code: "INVALID_COORDINATES", message: "Invalid latitude or longitude" });
      return;
    }

    // 3. 금칙어 검사
    const bannedInTitle = hasBannedWord(title);
    const bannedInContent = hasBannedWord(content);
    const allBannedWords = [...bannedInTitle, ...bannedInContent];

    if (allBannedWords.length > 0) {
      res.status(400).json(errors.BANNED_WORD_DETECTED(allBannedWords[0]));
      return;
    }

    let quadKeyL22: string;
    
    try {
      quadKeyL22 = QuadKey.fromGeo(latitude, longitude, 22).toString();
    } catch (e) {
      logger.error("QuadKey encoding failed:", e);
      res.status(500).json({
        code: "QUADKEY_ENCODING_ERROR",
        message: "Failed to generate spatial index"
      });
      return;
    }

    const now = new Date();
    const createdAtTimestamp = admin.firestore.Timestamp.fromDate(now);
    const locationGeoPoint = new admin.firestore.GeoPoint(latitude, longitude);

    // 4. Firestore 저장 객체 구성
    // geohashFields 스프레드 연산자(...) 제거됨
    const newPost = {
      title,
      content,
      location: locationGeoPoint,
      creatorID,
      imageUrl,
      createdAt: createdAtTimestamp,
      
      // ★ 이거 하나만 저장합니다. (인덱싱 비용 절감)
      quadKeyL22: quadKeyL22 
    };

    // 5. DB 저장
    const postRef = await db.collection("posts").add(newPost);

    // 6. 응답 생성 (PostDetailV3 타입)
    const resultData: PostDetailV3 = {
      id: postRef.id,
      title,
      content,
      imageUrl,
      location: locationGeoPoint,
      createdAt: createdAtTimestamp,
      creatorID,
      quadKeyL22: quadKeyL22,
      isMine: true
    };

    res.status(201).json({
      status: "SUCCESS",
      message: "Post created successfully",
      result: resultData
    });

  } catch (error) {
    logger.error("Error creating post:", error);
    res.status(500).json({
      code: "FIRESTORE_WRITE_FAILED",
      message: "Failed to create post"
    });
  }
};