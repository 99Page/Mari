import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { errors  } from "../errorResponse/errorResponse";

const REGION = "asia-northeast3";

// 회원 탈퇴 API
export const withdrawAccount = onRequest({ region: REGION }, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json(errors.METHOD_NOT_ALLOWED);
    return;
  }

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json(errors.INVALID_AUTH_HEADER);
    return;
  }

  const idToken = authHeader.split("Bearer ")[1];
  let decodedToken: admin.auth.DecodedIdToken;

  try {
    decodedToken = await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    logger.error("❌ Token verification failed", error);
    res.status(401).json(errors.UNAUTHORIZED);
    return;
  }

  const uid = decodedToken.uid;

  try {
    // Firebase Authentication에서 사용자 삭제
    await admin.auth().deleteUser(uid);

    res.status(200).json({ status: "success", message: "회원 탈퇴가 완료되었습니다.", result: null });
  } catch (error) {
    logger.error("❌ 회원 탈퇴 실패", error);
    res.status(500).json({ code: "withdraw-failed", message: (error as Error).message });
  }
});