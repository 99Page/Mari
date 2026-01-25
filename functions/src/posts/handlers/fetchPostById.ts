import type { SuccessResponse } from "../../resopnse/successResponse";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db, adminInstance as admin } from "../../utils/firebase";
import { ErrorResponse, errors } from "../../resopnse/errorResponse";
import { PostDetail, convertToPostDetail } from "../models/postDetail"

const REGION = "asia-northeast3";


export async function fetchPostById(postId: string, userID: string): Promise<PostDetail> {
  const docRef = db.collection("posts").doc(postId);
  const doc = await docRef.get();
  if (!doc.exists) {
    throw new Error("Post not found");
  }

  return convertToPostDetail(doc, userID);
}

export const getPostById = onRequest({ region: REGION }, async (req, res) => {
  const postId = req.query.id;

  if (!postId || typeof postId !== "string") {
    const errorResponse: ErrorResponse = {
      code: "INVALID_ID",
      message: "Missing or invalid 'id' query parameter"
    };
    res.status(400).json(errorResponse);
    return;
  }

  const authHeader = req.get("Authorization");
  const idToken = authHeader?.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : undefined;

  if (!idToken) {
    res.status(401).json(errors.UNAUTHORIZED);
    return;
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const userID = decodedToken.uid;

    const post = await fetchPostById(postId, userID);
    const successResponse: SuccessResponse<PostDetail> = {
      status: "success",
      message: "게시글 조회 성공",
      result: post
    };
    res.status(200).json(successResponse);
  } catch (error: any) {
    logger.error("Error fetching post by ID:", error);
    const errorResponse: ErrorResponse = {
      code: "POST_NOT_FOUND",
      message: "Failed to fetch post"
    };
    res.status(404).json(errorResponse);
  }
});