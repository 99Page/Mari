import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import Geohash from "latlon-geohash";
import { fetchPostById } from "./fetchPostById";
import { db, adminInstance as admin } from "../utils/firebase";
import { PostSummary } from "./post";
import { ErrorResponse } from "../errorResponse/errorResponse";

const REGION = "asia-northeast3";

export const getPosts = onRequest({ region: REGION }, async (req, res) => {
  const lat = parseFloat(req.query.latitude as string);
  const lng = parseFloat(req.query.longitude as string);
  const precision = parseInt(req.query.precision as string, 10); // 10진법으로 변환

  // Add type parsing after parsing precision
  const type = (req.query.type as string || "latest").toLowerCase();
  logger.info("Requested post type:", type);

  if (isNaN(lat) || isNaN(lng)) {
    const errorResponse: ErrorResponse = {
      code: "invalid-location-query",
      message: "Missing or invalid 'latitude' or 'longitude' query parameters"
    };
    res.status(400).json(errorResponse);
    return;
  }

  if (isNaN(precision) || precision < 1 || precision > 10) {
    const errorResponse: ErrorResponse = {
      code: "invalid-precision-query",
      message: "'precision' query parameter must be a number between 1 and 10"
    };
    res.status(400).json(errorResponse);
    return;
  }

  // Extract userID from Authorization header
  let userID = "";
  try {
    const authHeader = req.headers.authorization || "";
    if (authHeader.startsWith("Bearer ")) {
      const idToken = authHeader.split("Bearer ")[1];
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      userID = decodedToken.uid;
    }
  } catch (error) {
    logger.warn("Failed to verify ID token:", error);
    // userID remains empty string if verification fails
  }

  logger.info("Query Params", { latitude: lat, longitude: lng, precision, userID });

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
        status: "SUCCESS",
        message: "Successfully fetched latest posts",
        result: {
          type: "latest",
          posts,
          geohashBlocks,
        }
      });
    } catch (error) {
      logger.error("Error fetching latest posts:", error);
      // 최신 게시글 조회 실패 에러 상수
      const FETCH_LATEST_FAILED: ErrorResponse = {
        code: "latest-fetch-failed",
        message: "Failed to fetch latest posts"
      };
      res.status(500).send(FETCH_LATEST_FAILED);
    }
  } else if (type === "popular") {
    try {
      const posts = await fetchPopularPosts(geohashBlocks, userID);
      res.status(200).json({
        status: "SUCCESS",
        message: "Successfully fetched popular posts",
        result: {
          type: "popular",
          posts,
          geohashBlocks,
        }
      });
    } catch (error) {
      logger.error("Error fetching popular posts:", error);
      // 인기 게시글 조회 실패 에러 상수
      const FETCH_POPULAR_FAILED: ErrorResponse = {
        code: "popular-fetch-failed",
        message: "Failed to fetch popular posts"
      };
      res.status(500).json(FETCH_POPULAR_FAILED);
    }
    return;
  }
});

// geohash 블록별로 최신 게시글을 가져옴 (각 블록당 최대 1개, createdAt 기준 내림차순 정렬)
async function fetchLatestPosts(geohashBlocks: string[], geohashField: string): Promise<PostSummary[]> {
  const posts: PostSummary[] = [];

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
      const data = doc.data();
      posts.push({
        id: doc.id,
        title: data.title,
        imageUrl: data.imageUrl,
        location: data.location
      });
    }
  }

  return posts;
}

// 인기순 포스트 조회 (6시간 내 인기 포스트, post_ranking_cache 사용)
async function fetchPopularPosts(geohashBlocks: string[], userID: string): Promise<PostSummary[]> {
  const now = new Date();
  const currentHour = now.getUTCHours();
  const snappedHour = Math.floor(currentHour / 3) * 3; // 현재 시간이 05시면 03시 조회
  const hourStr = snappedHour.toString().padStart(2, '0');
  const yyyyMMdd = now.toISOString().slice(0, 10);
  const basePath = `post_ranking_cache/${yyyyMMdd}/last6hours/hour${hourStr}/geohash`;

  const posts: PostSummary[] = [];

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
        const post = await fetchPostById(entry.postId, userID);
        posts.push({
          id: post.id,
          title: post.title,
          imageUrl: post.imageUrl,
          location: post.location
        });
      } catch (error) {
        logger.warn(`⚠️ postId ${entry.postId} 조회 실패:`, error);
      }
    }
  }

  return posts;
}
