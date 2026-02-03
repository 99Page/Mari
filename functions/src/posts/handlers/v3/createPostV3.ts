import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import * as logger from "firebase-functions/logger";
import { errors } from '@/response/errorResponse';
import { QuadKey } from '@/utils/QuadKey';
import { PostDetailV3 } from '@/posts/models/postDetail';
import { hasBannedWord } from '@/utils/bannedWords'
import { db } from '@/utils/firebase';

export const createPostV3 = async (req: Request, res: Response) => {
  try {
    const authHeader = req.headers.authorization;
    const idToken = authHeader?.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : null;

    if (!idToken) {
      res.status(401).json(errors.UNAUTHORIZED);
      return;
    }

    let userID: string;

    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      userID = decodedToken.uid; 
    } catch (error) {
      logger.error("Token verification failed:", error);
      res.status(401).json(errors.UNAUTHORIZED);
      return;
    }

    const body = req.body;
    if (!body || typeof body !== "object") {
      res.status(400).json({ code: "INVALID_BODY", message: "Invalid request body" });
      return;
    }

    const { title, content, latitude, longitude, imageUrl } = body;

    if (!title || latitude == null || longitude == null || !imageUrl) {
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

    const bannedInTitle = hasBannedWord(title);
    const bannedInContent = content ? hasBannedWord(content) : []; // content가 없을 경우 대비
    const allBannedWords = [...bannedInTitle, ...bannedInContent];

    if (allBannedWords.length > 0) {
      res.status(400).json(errors.BANNED_WORD_DETECTED(allBannedWords[0]));
      return;
    }

    const now = new Date();
    const createdAtTimestamp = admin.firestore.Timestamp.fromDate(now);
    let quadKeys: string[] = [];

    try {
      const fullQuadKey = QuadKey.fromGeo(latitude, longitude, 22).toString();
      
      for (let i = 1; i <= fullQuadKey.length; i++) {
        quadKeys.push(fullQuadKey.substring(0, i));
      }
    } catch (e) {
      logger.error("QuadKey encoding failed:", e);
      res.status(500).json({
        code: "QUADKEY_ENCODING_ERROR",
        message: "Failed to generate spatial index"
      });
      return;
    }

    const locationGeoPoint = new admin.firestore.GeoPoint(latitude, longitude);

    const newPost = {
      title,
      content: content || "", 
      location: locationGeoPoint,
      creatorID: userID,      
      imageUrl,
      createdAt: createdAtTimestamp,
      quadKeys: quadKeys      
    };

    const postRef = await db.collection("posts").add(newPost);

    const resultData: PostDetailV3 = {
      id: postRef.id,
      title,
      content: content || "",
      imageUrl,
      location: locationGeoPoint,
      createdAt: createdAtTimestamp,
      creatorID: userID,
      quadKeys: quadKeys,
      isMine: true
    };

    res.status(201).json({
      status: "SUCCESS",
      message: "Post created successfully!",
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