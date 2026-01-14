import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { fetchPostById } from './handlers/fetchPostById';
import { db } from "../utils/firebase";
import { ErrorResponse, errors } from '../resopnse/errorResponse';

const REGION = "asia-northeast3";
// 5분 내 중복 조회 방지용 (선택)
const VIEW_DUPLICATION_LIMIT_MS = 5 * 60 * 1000 // 5분

const MISSING_POST_ID: ErrorResponse = {
  code: "missing-post-id",
  message: "Missing postId in request path"
};

export const increasePostViewCount = onRequest(
  { region: REGION },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send(errors.METHOD_NOT_ALLOWED);
      return;
    }

    // 🔒 Firebase ID 토큰 확인
    const authHeader = req.headers.authorization;
    const idToken = authHeader?.startsWith("Bearer ")
      ? authHeader.split("Bearer ")[1]
      : null;

    if (!idToken) {
      res.status(401).send(errors.INVALID_AUTH_HEADER);
      return;
    }

    let decodedToken: admin.auth.DecodedIdToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      logger.error("Token verification failed:", error);
      res.status(401).send(errors.UNAUTHORIZED);
      return;
    }

    const uid = decodedToken.uid;
    const postId = req.path.split('/')[2]; // e.g. /posts/{postId}/views

    if (!postId) {
      res.status(400).json(MISSING_POST_ID);
      return;
    }

    // ⏱️ UTC 기준 날짜 & 시각 블럭 계산
    const now = new Date();
    const yyyyMMdd = now.toISOString().slice(0, 10);
    const hour = now.getUTCHours().toString().padStart(2, '0');

    // 🔁 중복 조회 여부 체크
    const historyRef = db.collection('post_view_history').doc(`${uid}_${postId}`);
    const historySnap = await historyRef.get();

    const lastViewedAt = historySnap.exists
      ? historySnap.data()?.lastViewedAt?.toDate?.()
      : null;

  if (lastViewedAt && now.getTime() - lastViewedAt.getTime() < VIEW_DUPLICATION_LIMIT_MS) {
    res.status(200).json({
      status: 'IGNORED',
      message: 'View ignored (too recent)',
      result: {}
    });
    return;
  }

    // 📄 포스트에서 geohash 값들 조회
    const post = await fetchPostById(postId, uid);
    const geohashValues = [
      post.geohash_1,
      post.geohash_2,
      post.geohash_3,
      post.geohash_4,
      post.geohash_5,
      post.geohash_6,
      post.geohash_7,
      post.geohash_8,
      post.geohash_9,
      post.geohash_10
    ];

    // ⏫ 모든 geohash 블록에 대해 조회수 증가
    const incrementPromises = geohashValues.map((geohash) => {
      const geoRef = db
        .collection("post_view_stats")
        .doc(yyyyMMdd)
        .collection("hours")
        .doc(hour)
        .collection("geohash")
        .doc(geohash)
        .collection("posts")
        .doc(postId);

      return geoRef.set(
        { viewCount: admin.firestore.FieldValue.increment(1) },
        { merge: true }
      );
    });

    // 각 시간별 문서에 활성 geohash 목록 저장
    const geohashIndexRef = db
      .collection("post_view_stats")
      .doc(yyyyMMdd)
      .collection("hours")
      .doc(hour);

    await geohashIndexRef.set(
      { activeGeohashes: admin.firestore.FieldValue.arrayUnion(...geohashValues) },
      { merge: true }
    );

    // 병렬 실행
    await Promise.all(incrementPromises);

    // 🕓 조회 기록 저장
    await historyRef.set({ lastViewedAt: now }, { merge: true });

  res.status(200).json({
      status: 'SUCCESS',
      message: `View recorded at ${yyyyMMdd}/hours/${hour}`,
      result: {}
    });
  }
);