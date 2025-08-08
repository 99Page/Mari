// 인증 토큰 검증 유틸
// - 성공: 검증된 idToken 문자열 반환
// - 실패: 401 응답 반환 후 null

import { Request, Response } from "express";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions";
import { errors } from "../resopnse/errorResponse";

export async function verifyAuthAndGetUid(req: Request, res: Response): Promise<string | null> {
  // Authorization 헤더 추출 (대소문자 구분 없이) & 문자열/배열 대응
  const raw = req.headers["authorization"]; // Express는 헤더 키를 소문자로 normalize
  const authHeader = Array.isArray(raw) ? raw[0] : raw; // 첫 값 사용

  // "Bearer <token>" 형태 파싱
  let idToken: string | null = null;
  if (typeof authHeader === "string") {
    const [scheme, token] = authHeader.trim().split(/\s+/);
    if (/^Bearer$/i.test(scheme) && token) {
      idToken = token.trim();
    }
  }

  if (!idToken) {
    res.status(401).json(errors.INVALID_AUTH_HEADER);
    return null;
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken.uid
  } catch (error) {
    logger.error("Token verification failed", { error });
    res.status(401).json(errors.UNAUTHORIZED);
    return null;
  }
}