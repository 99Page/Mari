/****
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as functions from 'firebase-functions'
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import Geohash from "latlon-geohash";

// The Firebase Admin SDK to access Firestore.
import { getFirestore } from "firebase-admin/firestore";
import { initializeApp } from "firebase-admin/app";
import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";


const app = initializeApp();
const db = getFirestore(app, "mari-db");

const REGION = "asia-northeast3";

export const helloWorld = onRequest({ region: REGION }, (request, response) => {
  logger.info("Hello logs!", { structuredData: true });
  response.send("Hello from Firebase!");
});

export const getPosts = onRequest({ region: REGION }, async (req, res) => {
  const lat = parseFloat(req.query.latitude as string);
  const lng = parseFloat(req.query.longitude as string);
  const precision = parseInt(req.query.precision as string, 10); // 10진법으로 변환

  if (isNaN(lat) || isNaN(lng)) {
    res.status(400).send("Missing or invalid 'latitude' or 'longitude' query parameters");
    return;
  }

  if (isNaN(precision) || precision < 1 || precision > 10) {
    res.status(400).send("Missing or invalid 'precision' query parameter. Must be between 1 and 10.");
    return;
  }

  logger.info("Query Params", { latitude: lat, longitude: lng, precision });

  // 현재 위치 값 해싱 (정확한 geohash만 쿼리)
  const geohash = Geohash.encode(lat, lng, precision);
  logger.info(`GeoHash(${precision}): ${geohash}`);

  try {

    // 5x3 총 15개 구역에서 조회
    const geohashBlocks = [
      Geohash.adjacent(Geohash.adjacent(Geohash.adjacent(geohash, "N"), "N"), "W"), // NNW
      Geohash.adjacent(Geohash.adjacent(geohash, "N"), "N"), // NN
      Geohash.adjacent(Geohash.adjacent(Geohash.adjacent(geohash, "N"), "N"), "E"), // NNE

      Geohash.adjacent(Geohash.adjacent(geohash, "N"), "W"), // NW
      Geohash.adjacent(geohash, "N"),                       // N
      Geohash.adjacent(Geohash.adjacent(geohash, "N"), "E"), // NE

      Geohash.adjacent(geohash, "W"),                       // W
      geohash,                                              // 현재위치
      Geohash.adjacent(geohash, "E"),                       // E

      Geohash.adjacent(Geohash.adjacent(geohash, "S"), "W"), // SW
      Geohash.adjacent(geohash, "S"),                       // S
      Geohash.adjacent(Geohash.adjacent(geohash, "S"), "E"), // SE
      
      Geohash.adjacent(Geohash.adjacent(Geohash.adjacent(geohash, "S"), "S"), "W"), // SSW
      Geohash.adjacent(Geohash.adjacent(geohash, "S"), "S"), // SE
      Geohash.adjacent(Geohash.adjacent(Geohash.adjacent(geohash, "S"), "S"), "E"), // SSE
    ];

    const geohashField = `geohash_${precision}`;
    logger.info("Fetching posts with geohash:", geohash, "Field:", geohashField, "block:", geohashBlocks);

    // 각 geohash 블록별로 최대 1개씩만 반환
    const posts: any[] = [];

    for (const hash of geohashBlocks) {
      const snapshot = await db
        .collectionGroup("posts")
        .where(geohashField, "==", hash)
        .orderBy("createdAt", "desc")
        .limit(1)
        .get();

      logger.info(`Fetched ${snapshot.size} posts for hash ${hash}`);

      if (!snapshot.empty) {
        const doc = snapshot.docs[0];
        posts.push({ id: doc.id, ...doc.data() });
      }
    }

    res.status(200).json({
      posts,
      geohashBlocks,
    });
    
  } catch (error) {
    logger.error("Error fetching posts:", error);
    res.status(500).send("Failed to fetch posts");
  }
});


export const getPostById = onRequest({ region: REGION }, async (req, res) => {
  const postId = req.query.id;

  if (!postId || typeof postId !== "string") {
    res.status(400).send("Missing or invalid 'id' query parameter");
    return;
  }

  try {
    const docRef = db.collection("posts").doc(postId);
    const doc = await docRef.get();

    if (!doc.exists) {
      res.status(404).send("Post not found");
      return;
    }

    res.status(200).json({ id: doc.id, ...doc.data() });
  } catch (error) {
    logger.error("Error fetching post by ID:", error);
    res.status(500).send("Failed to fetch post");
  }
});

export const createPost = onRequest({ region: REGION }, async (req, res) => {
  try {
    // 클라이언트에서 전달된 Firebase 인증 토큰을 확인
    const authHeader = req.headers.authorization;
    const idToken = authHeader?.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : null;

    if (!idToken) {
      res.status(401).send("Missing or invalid Authorization header");
      return;
    }

    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      logger.error("Token verification failed:", error);
      res.status(401).send("Unauthorized");
      return;
    }

    // 요청 본문에서 필요한 필드 추출 및 유효성 검사
    const body = req.body;

    if (!body || typeof body !== "object") {
      res.status(400).send("Invalid request body");
      return;
    }

    const { title, content, latitude, longitude, creatorID, imageUrl } = body;

    if (!title || !content || latitude == null || longitude == null || !creatorID || !imageUrl) {
      res.status(400).send("Missing required fields");
      return;
    }

    if (
      typeof latitude !== "number" || isNaN(latitude) ||
      typeof longitude !== "number" || isNaN(longitude)
    ) {
      res.status(400).send("Invalid latitude or longitude");
      return;
    }

    // GeoHash는 위치 기반 검색 최적화를 위해 사용됨
    // precision 값이 작을수록 더 넓은 범위를 커버하고, 클수록 정밀도가 높아짐
    // 예) precision 1 → 약 수천 km / precision 10 → 약 1m 단위의 위치 구분 가능
    // precision 1~10까지의 다양한 정밀도로 인코딩된 값들을 생성하여 저장
    let geohashFields: Record<string, string> = {};
    try {
      for (let p = 1; p <= 10; p++) {
        geohashFields[`geohash_${p}`] = Geohash.encode(latitude, longitude, p);
      }
    } catch (e) {
      logger.error("GeoHash encoding failed:", e);
      res.status(500).send("GeoHash encoding error");
      return;
    }

    // Firestore에 저장할 새로운 포스트 객체 구성
    const newPost = {
      title,
      content,
      latitude,
      longitude,
      location: new admin.firestore.GeoPoint(latitude, longitude),
      creatorID,
      imageUrl,
      dailyScore: 0,
      weeklyScore: 0,
      monthlyScore: 0,
      viewCount: 0,
      createdAt: new Date().toISOString(),
      ...geohashFields
    };

    // Firestore의 "posts" 컬렉션에 문서 추가
    const postRef = await db.collection("posts").add(newPost);

    res.status(201).json({ id: postRef.id, ...newPost });
  } catch (error) {
    logger.error("Error creating post:", error);
    res.status(500).send("Failed to create post");
  }
});

// 5분 내 중복 조회 방지용 (선택)
const VIEW_DUPLICATION_LIMIT_MS = 5 * 60 * 1000 // 5분

export const increasePostViewCount = functions.https.onRequest(
  { region: REGION },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    // 🔒 Firebase ID 토큰 확인
    const authHeader = req.headers.authorization;
    const idToken = authHeader?.startsWith("Bearer ")
      ? authHeader.split("Bearer ")[1]
      : null;

    if (!idToken) {
      res.status(401).send("Missing or invalid Authorization header");
      return;
    }

    let decodedToken: admin.auth.DecodedIdToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      logger.error("Token verification failed:", error);
      res.status(401).send("Unauthorized");
      return;
    }

    const uid = decodedToken.uid;
    const postId = req.path.split('/')[2]; // e.g. /posts/{postId}/views

    if (!postId) {
      res.status(400).json({ error: 'Missing postId' });
      return;
    }

    // 현재 시간 기준 날짜 & 시각 블럭 계산
    const now = new Date();
    const koreaOffset = 9 * 60 * 60 * 1000;
    const kst = new Date(now.getTime() + koreaOffset);
    const yyyyMMdd = kst.toISOString().slice(0, 10); // "2025-07-04"
    const hour = kst.getUTCHours().toString().padStart(2, '0'); // "14"

    // 🔁 중복 조회 여부 체크
    const historyRef = db.collection('post_view_history').doc(`${uid}_${postId}`);
    const historySnap = await historyRef.get();

    const lastViewedAt = historySnap.exists
      ? historySnap.data()?.lastViewedAt?.toDate?.()
      : null;

    if (lastViewedAt && now.getTime() - lastViewedAt.getTime() < VIEW_DUPLICATION_LIMIT_MS) {
      res.status(200).json({ message: 'View ignored (too recent)' });
      return;
    }

    // 📈 시간 단위 조회수 증가
    const hourlyRef = db
      .collection("post_view_stats")
      .doc(yyyyMMdd)
      .collection("hours")
      .doc(hour)
      .collection("posts")
      .doc(postId);

    await hourlyRef.set(
      { viewCount: admin.firestore.FieldValue.increment(1) },
      { merge: true }
    );

    // 🕓 조회 기록 저장
    await historyRef.set({ lastViewedAt: now }, { merge: true });

    res.status(200).json({ message: 'View recorded', block: `${yyyyMMdd}/hours/${hour}` });
  }
);

// 랭킹 집계 자동화
export const scheduleAggregateLast6HoursRanking = onSchedule(
  {
    region: REGION,
    schedule: "every 180 minutes",
    timeZone: "Asia/Seoul",
  },
  async () => {
    const now = new Date();
    const kstNow = new Date(now.getTime() + 9 * 60 * 60 * 1000);
    const yyyyMMdd = kstNow.toISOString().slice(0, 10);
    const currentHour = kstNow.getUTCHours(); // 0~23 숫자

    const postViews: Record<string, number> = {};

    for (let i = 6; i >= 1; i--) {
      const hour = (currentHour - i + 24) % 24;
      const hourStr = hour.toString().padStart(2, "0");

      const path = `post_view_stats/${yyyyMMdd}/hours/${hourStr}/posts`;
      const snapshot = await db.collection(path).get();

      snapshot.forEach((doc) => {
        const postId = doc.id;
        const count = doc.data()?.viewCount || 0;
        if (postViews[postId]) {
          postViews[postId] += count;
        } else {
          postViews[postId] = count;
        }
      });
    }

    // postId + 누적 조회수로 배열 변환 및 정렬
    const topRanking = Object.entries(postViews)
      .map(([postId, viewCount]) => ({ postId, viewCount }))
      .sort((a, b) => b.viewCount - a.viewCount)
      .slice(0, 50);

    const cachePath = `post_ranking_cache/${yyyyMMdd}_last6hours_hour${currentHour.toString().padStart(2, "0")}`;
    await db.doc(cachePath).set({
      ranking: topRanking,
      fromHour: currentHour - 6 < 0 ? currentHour + 18 : currentHour - 6,
      toHour: currentHour - 1,
      updatedAt: new Date().toISOString(),
    });

    logger.info(`✅ Aggregated 6-hour ranking at hour ${currentHour}`);
  }
);

// 랭킹 집계
async function aggregateLast6HoursRanking() {
  const now = new Date();
  const kstNow = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  const yyyyMMdd = kstNow.toISOString().slice(0, 10);
  const currentHour = kstNow.getUTCHours(); // 0~23 숫자

  const postViews: Record<string, number> = {};

  for (let i = 6; i >= 1; i--) {
    const hour = (currentHour - i + 24) % 24;
    const hourStr = hour.toString().padStart(2, "0");

    const path = `post_view_stats/${yyyyMMdd}/hours/${hourStr}/posts`;
    const snapshot = await db.collection(path).get();

    snapshot.forEach((doc) => {
      const postId = doc.id;
      const count = doc.data()?.viewCount || 0;
      postViews[postId] = (postViews[postId] || 0) + count;
    });
  }

  const topRanking = Object.entries(postViews)
    .map(([postId, viewCount]) => ({ postId, viewCount }))
    .sort((a, b) => b.viewCount - a.viewCount)
    .slice(0, 50);

  const cachePath = `post_ranking_cache/${yyyyMMdd}_last6hours_hour${currentHour.toString().padStart(2, "0")}`;
  await db.doc(cachePath).set({
    ranking: topRanking,
    fromHour: currentHour - 6 < 0 ? currentHour + 18 : currentHour - 6,
    toHour: currentHour - 1,
    updatedAt: new Date().toISOString(),
  });

  logger.info(`✅ Aggregated 6-hour ranking at hour ${currentHour}`);
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
      res.status(401).send("Missing or invalid Authorization header");
      return;
    }

    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      logger.error("Token verification failed:", error);
      res.status(401).send("Unauthorized");
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