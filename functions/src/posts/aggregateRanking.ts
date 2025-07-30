import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db, adminInstance as admin } from "../utils/firebase";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { errors } from "../errorResponse/errorResponse";

const REGION = "asia-northeast3";

// 랭킹 집계 자동화
export const scheduleAggregateLast6HoursRanking = onSchedule(
  {
    region: REGION,
    schedule: "0 */3 * * *",
    timeZone: "Asia/Seoul",
  },
  async () => {
    await aggregateLast6HoursRanking();
  }
);

// 랭킹 집계 (지오해시별)
async function aggregateLast6HoursRanking() {
  const now = new Date();
  const yyyyMMdd = now.toISOString().slice(0, 10);
  const currentHour = now.getUTCHours().toString().padStart(2, "0"); // "00"~"23" 문자열

  const geoPostViews: Record<string, Record<string, number>> = {}; // geohash -> { postId -> count }

  for (let i = 6; i >= 1; i--) {
    const target = new Date(now.getTime() - i * 60 * 60 * 1000); // i시간 전
    const yyyyMMdd = target.toISOString().slice(0, 10);
    const hour = target.getUTCHours().toString().padStart(2, '0');

    const hourDocRef = db.doc(`post_view_stats/${yyyyMMdd}/hours/${hour}`);
    const hourDocSnap = await hourDocRef.get();
    const activeGeohashes: string[] = hourDocSnap.exists ? hourDocSnap.data()?.activeGeohashes || [] : [];

    if (activeGeohashes.length === 0) {
      logger.info(`⚠️ No active geohashes found at ${yyyyMMdd} ${hour}`);
      continue;
    }

    for (const geoId of activeGeohashes) {
      const postsRef = db
        .collection(`post_view_stats/${yyyyMMdd}/hours/${hour}/geohash`)
        .doc(geoId)
        .collection("posts");
      logger.debug(`📁 조회 경로: post_view_stats/${yyyyMMdd}/hours/${hour}/geohash/${geoId}/posts`);
      const postsSnapshot = await postsRef.get();

      if (!geoPostViews[geoId]) {
        geoPostViews[geoId] = {};
      }

      postsSnapshot.forEach((doc) => {
        logger.debug(`📊 [${yyyyMMdd} ${hour}] GeoHash: ${geoId}, PostID: ${doc.id}, ViewCount: ${doc.data()?.viewCount}`);
        const postId = doc.id;
        const count = doc.data()?.viewCount || 0;
        geoPostViews[geoId][postId] = (geoPostViews[geoId][postId] || 0) + count;
      });
    }
  }

  // Log the final aggregated result before committing the batch
  logger.info("📊 최종 지역별 집계 결과:", geoPostViews);

  const cacheBatch = db.batch();

  for (const [geoId, postMap] of Object.entries(geoPostViews)) {
    const ranking = Object.entries(postMap)
      .map(([postId, viewCount]) => ({ postId, viewCount }))
      .sort((a, b) => b.viewCount - a.viewCount)
      .slice(0, 10); 

    // 예시: 기준 시각이 15시인 경우 → 09시~14시 데이터를 기준으로 랭킹 집계
    // 저장 경로 예: post_ranking_cache/2025-07-07/last6hours/hour15/geohash/wyd6
    const cachePath = `post_ranking_cache/${yyyyMMdd}/last6hours/hour${currentHour}/geohash/${geoId}`;

    const docRef = db.doc(cachePath);
    cacheBatch.set(docRef, {
      ranking,
      fromHour: parseInt(currentHour) - 6 < 0 ? parseInt(currentHour) + 18 : parseInt(currentHour) - 6,
      toHour: parseInt(currentHour) - 1,
      updatedAt: new Date().toISOString(),
    });
  }

  await cacheBatch.commit();
  logger.info(`✅ 지역별 6시간 랭킹 집계 완료 at hour ${currentHour}`);
}

// 수동 랭킹 집계
export const testAggregateLast6HoursRanking = onRequest(
  { region: REGION },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    // 🔒 Firebase ID 토큰 확인
    const authHeader = req.headers.authorization;
    const idToken = authHeader?.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : null;

    if (!idToken) {
      res.status(401).send(errors.INVALID_AUTH_HEADER);
      return;
    }

    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      logger.error("Token verification failed:", error);
      res.status(401).send(errors.UNAUTHORIZED);
      return;
    }

    try {
      await aggregateLast6HoursRanking();
      res.status(200).send("✅ 테스트용 랭킹 집계 완료");
    } catch (error) {
      logger.error("랭킹 집계 실패", error);
      res.status(500).send("❌ 랭킹 집계 실패");
    }
  }
);