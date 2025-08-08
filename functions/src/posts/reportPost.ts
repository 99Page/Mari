import { verifyAuthAndGetUid } from '../auth/verifyToken';
import { onRequest } from "firebase-functions/v2/https";
import { errors } from "../resopnse/errorResponse"
import { db, adminInstance as admin } from "../utils/firebase";
import type { SuccessResponse } from '../resopnse/successResponse';


const REGION = "asia-northeast3";

export const reportPost = onRequest({ region: REGION }, async (req, res) => {

   // 메서드 제한
  if (req.method !== "POST") {
    res.status(405).json(errors.METHOD_NOT_ALLOWED);
    return;
  }

  const uid = await verifyAuthAndGetUid(req, res);
  if (uid == null) return; 

  const postId = req.body.postId as string;

  try {
    const postRef = db.collection("posts").doc(postId);
    const postSnap = await postRef.get(); 

    if (!postSnap.exists) {
      res.status(404).json(errors.POST_NOT_FOUND);
      return;
    }

    const postData = postSnap.data() 
    const authorId = postData?.creatorID

    if (authorId == uid) {
      res.status(403).json(errors.CANNOT_REPORT_OWN_POST);
      return;
    }

    const reportRef = db
      .collection("report")
      .doc("posts")
      .collection(postId)
      .doc(uid);

    const report = await reportRef.get();
    if (report.exists) {
      res.status(400).json(errors.ALREADY_REPORTED_POST);
      return;
    }

    const newReport = {
      reporterId: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };
  
    await reportRef.set(newReport);

    const successResponse: SuccessResponse<{ reportId: string }> = {
      status: "success",
      message: "신고가 접수되었습니다",
      result: {
        reportId: reportRef.id
      }
    }
    res.status(200).json(successResponse);
  } catch {
    res.status(500).json(errors.REPORT_POST_FAILED);
  }
})