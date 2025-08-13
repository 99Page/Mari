import { onRequest } from "firebase-functions/v2/https";
import { db, region } from "../utils/firebase";
import { errors } from "../resopnse/errorResponse";
import { SuccessResponse } from "../resopnse/successResponse";
import { verifyAuthAndGetUid } from "../auth/verifyToken";

export const fetchBlockedUserIds = onRequest({ region }, async (req, res) => {
  try {
    if (req.method !== "GET") {
      res.status(405).json(errors.METHOD_NOT_ALLOWED);
      return;
    }

    const uid = await verifyAuthAndGetUid(req, res);
    if (uid == null) return;

    const snapshot = await db
      .collection("relation")
      .doc(uid)
      .collection("blocks")
      .get();

    const blockedUserIds = snapshot.docs.map(doc => doc.id);

    const successResponse: SuccessResponse<{ blockedUserIds: string[] }> = {
      status: "success",
      message: "차단한 사용자 목록을 성공적으로 가져왔습니다.",
      result: { blockedUserIds },
    };

    res.status(200).json(successResponse);
    return;
  } catch (error) {
    console.error("❌ fetchBlockedUserIds error:", error);
    res.status(500).json(errors.INTERNAL_ERROR);
    return;
  }
});