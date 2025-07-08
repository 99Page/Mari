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

  // Add type parsing after parsing precision
  const type = (req.query.type as string || "latest").toLowerCase();
  logger.info("Requested post type:", type);

  if (isNaN(lat) || isNaN(lng)) {
    res.status(400).send("Missing or invalid 'latitude' or 'longitude' query parameters");
    return;
  }

  if (isNaN(precision) || precision < 1 || precision > 10) {
    res.status(400).send("Missing or invalid 'precision' query parameter. Must be between 1 and 10.");
    return;
  }

  logger.info("Query Params", { latitude: lat, longitude: lng, precision });

  // Shared geohash calculation
  const geohash = Geohash.encode(lat, lng, precision);
  logger.info(`GeoHash(${precision}): ${geohash}`);

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

  if (type === "latest") {
    try {
      const posts = await fetchLatestPosts(geohashBlocks, geohashField);

      res.status(200).json({
        type: "latest",
        posts,
        geohashBlocks,
      });
    } catch (error) {
      logger.error("Error fetching latest posts:", error);
      res.status(500).send("Failed to fetch latest posts");
    }
  } else if (type === "popular") {
    try {
      const posts = await fetchPopularPosts(geohashBlocks);
      res.status(200).json({
        type: "popular",
        posts,
        geohashBlocks,
      });
    } catch (error) {
      logger.error("Error fetching popular posts:", error);
      res.status(500).send("Failed to fetch popular posts");
    }
    return;
  }
});

// geohash 블록별로 최신 게시글을 가져옴 (각 블록당 최대 1개, createdAt 기준 내림차순 정렬)
async function fetchLatestPosts(geohashBlocks: string[], geohashField: string): Promise<any[]> {
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

  return posts;
}

// 인기순 포스트 조회 (6시간 내 인기 포스트, post_ranking_cache 사용)
async function fetchPopularPosts(geohashBlocks: string[]): Promise<any[]> {
  const now = new Date();
  const currentHour = now.getUTCHours();
  const snappedHour = Math.floor(currentHour / 3) * 3; // 현재 시간이 05시면 03시 조회
  const hourStr = snappedHour.toString().padStart(2, '0');
  const yyyyMMdd = now.toISOString().slice(0, 10);
  const basePath = `post_ranking_cache/${yyyyMMdd}/last6hours/hour${hourStr}/geohash`;

  const posts: any[] = [];

  for (const hash of geohashBlocks) {
    const docRef = db.doc(`${basePath}/${hash}`);
    const snapshot = await docRef.get();

    if (!snapshot.exists) {
      logger.info(`⚠️ 랭킹 데이터 없음: ${basePath}/${hash}`);
      continue;
    }

    const data = snapshot.data();
    const ranking = data?.ranking || [];

    for (const entry of ranking) {
      try {
        const post = await fetchPostById(entry.postId);
        posts.push(post);
      } catch (error) {
        logger.warn(`⚠️ postId ${entry.postId} 조회 실패:`, error);
      }
    }
  }

  return posts;
}

async function fetchPostById(postId: string): Promise<Record<string, any>> {
  const docRef = db.collection("posts").doc(postId);
  const doc = await docRef.get();
  if (!doc.exists) {
    throw new Error("Post not found");
  }
  return { id: doc.id, ...doc.data() };
}

export const getPostById = onRequest({ region: REGION }, async (req, res) => {
  const postId = req.query.id;

  if (!postId || typeof postId !== "string") {
    res.status(400).send("Missing or invalid 'id' query parameter");
    return;
  }

  try {
    const post = await fetchPostById(postId);
    res.status(200).json(post);
  } catch (error: any) {
    logger.error("Error fetching post by ID:", error);
    res.status(404).send(error.message || "Failed to fetch post");
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
      res.status(200).json({ message: 'View ignored (too recent)' });
      return;
    }

    // 📄 포스트에서 geohash 값들 조회
    const post = await fetchPostById(postId);
    const geohashKeys = Object.keys(post).filter((key) => key.startsWith('geohash_'));
    const geohashValues = geohashKeys.map((key) => post[key]);

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

    res.status(200).json({ message: 'View recorded', block: `${yyyyMMdd}/hours/${hour}` });
  }
);

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




// Firestore document/collection inspection via HTTPS POST
export const debugFirestorePath = onRequest({ region: REGION }, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const { path } = req.body;

  if (!path || typeof path !== 'string') {
    res.status(400).send("Missing or invalid 'path' in request body");
    return;
  }

  try {
    const segments = path.split('/').filter(Boolean);

    if (segments.length % 2 === 0) {
      // Document path
      const doc = await db.doc(path).get();
      if (!doc.exists) {
        res.status(404).send(`Document not found at path: ${path}`);
      } else {
        res.status(200).json({ type: 'document', path, data: doc.data() });
      }
    } else {
      // Collection path
      const snapshot = await db.collection(path).get();
      const result: Record<string, any> = {};
      snapshot.forEach(doc => {
        result[doc.id] = doc.data();
      });
      res.status(200).json({ type: 'collection', path, documents: result });
    }
  } catch (error) {
    logger.error(`❌ Error fetching path ${path}`, error);
    res.status(500).send('Internal Server Error');
  }
});