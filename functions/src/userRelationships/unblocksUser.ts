import { onRequest } from "firebase-functions/v2/https";
import { db, region } from "../utils/firebase";
import { errors } from "../response/errorResponse";
import { SuccessResponse } from "../response/successResponse";
import { verifyAuthAndGetUid } from "../auth/verifyToken";
import { logErrorToFirestore } from "../utils/errorLogger";

export const unblocksUser = onRequest({ region }, async (req, res) => {
  try {
    if (req.method !== "DELETE") {
      res.status(405).json(errors.METHOD_NOT_ALLOWED);
      return;
    }

    const uid = await verifyAuthAndGetUid(req, res);
    if (uid == null) return;

    const targetUserId = req.body?.targetUserId;
    if (!targetUserId) {
      res.status(400).json(errors.MISSING_REQUIRED_FIELDS);
      return;
    }

    if (uid === targetUserId) {
      res.status(400).json(errors.CANNOT_BLOCK_SELF);
      return;
    }

    const docRef = db.collection("relation").doc(uid).collection("blocks").doc(targetUserId);
    const docSnap = await docRef.get();
    if (!docSnap.exists) {
      res.status(400).json(errors.NOT_BLOCKED_USER);
      return;
    }

    await docRef.delete();

    const successResponse: SuccessResponse<{ blocked: boolean; relationshipId: string }> = {
      status: "success",
      message: "User successfully unblocked",
      result: {
        blocked: false,
        relationshipId: targetUserId,
      },
    };
    res.status(200).json(successResponse);
    return;
  } catch (error) {
    await logErrorToFirestore(error, { handler: "unblocksUser", req });
    res.status(500).json(errors.INTERNAL_ERROR);
    return;
  }
});
