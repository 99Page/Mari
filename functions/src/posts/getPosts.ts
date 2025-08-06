import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import Geohash from "latlon-geohash";
import { fetchPostById } from "./fetchPostById";
import { db, adminInstance as admin } from "../utils/firebase";
import { PostDetail, PostSummary } from "./post";
import { ErrorResponse } from "../resopnse/errorResponse";
import type { SuccessResponse } from "../resopnse/successResponse";

const REGION = "asia-northeast3";

export const getPosts = onRequest({ region: REGION }, async (req, res) => {
  const lat = parseFloat(req.query.latitude as string);
  const lng = parseFloat(req.query.longitude as string);
  const precision = parseInt(req.query.precision as string, 10); // 10진법으로 변환
  const groupSize = parseInt(req.query.groupSize as string, 10) || 1;

  // Add type parsing after parsing precision
  const type = (req.query.type as string || "latest").toLowerCase();

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

  // groupSize 파라미터 유효성 검사 (1~4)
  if (groupSize < 1 || groupSize > 4) {
    const errorResponse: ErrorResponse = {
      code: "invalid-group-size-query",
      message: "'groupSize' must be a number between 1 and 4"
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

  const geohash = Geohash.encode(lat, lng, precision);

  // 조회해야할 geohash 가져오기
  const geohashGroup = makeGeohashGroups(geohash, groupSize);
  const geohashBlocks = Object.keys(geohashGroup);
  const geohashField = `geohash_${precision}`;

  logger.info("geohash group", Object.entries(geohashGroup));

  if (type === "latest") {
    try {
      const posts = await fetchLatestPosts(geohashBlocks, geohashField, userID);
      const filteredPosts = filterLatestPostPerGroup(posts, geohashField, geohashGroup);
      res.status(200).json({
        status: "SUCCESS",
        message: "Successfully fetched latest posts",
        result: {
          type: "latest",
          posts: filteredPosts,
          geohashBlocks,
          postCount: filteredPosts.length
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
      const filteredPosts = filterLatestPostPerGroup(posts, geohashField, geohashGroup);
      const successResponse: SuccessResponse<{
        type: string;
        posts: PostSummary[];
        geohashBlocks: string[];
        postCount: number;
      }> = {
        status: "success",
        message: "Successfully fetched popular posts",
        result: {
          type: "popular",
          posts: filteredPosts,
          geohashBlocks,
          postCount: filteredPosts.length
        }
      };
      res.status(200).json(successResponse);
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
async function fetchLatestPosts(geohashBlocks: string[], geohashField: string, userID: string): Promise<PostDetail[]> {
  const posts: PostDetail[] = [];

  for (const hash of geohashBlocks) {
    const snapshot = await db
      .collectionGroup("posts")
      .where(geohashField, "==", hash)
      .orderBy("createdAt", "desc")
      .limit(1)
      .get();

    if (!snapshot.empty) {
      const doc = snapshot.docs[0];
      const data = doc.data();
      posts.push({
        id: doc.id,
        title: data?.title,
        content: data?.content,
        imageUrl: data?.imageUrl,
        location: data?.location,
        createdAt: data?.createdAt,
        creatorID: data?.creatorID,
        geohash_1: data?.geohash_1,
        geohash_2: data?.geohash_2,
        geohash_3: data?.geohash_3,
        geohash_4: data?.geohash_4,
        geohash_5: data?.geohash_5,
        geohash_6: data?.geohash_6,
        geohash_7: data?.geohash_7,
        geohash_8: data?.geohash_8,
        geohash_9: data?.geohash_9,
        geohash_10: data?.geohash_10,
        isMine: userID === data?.creatorID
      });
    }
  }

  return posts;
}

// 인기순 포스트 조회 (6시간 내 인기 포스트, post_ranking_cache 사용)
async function fetchPopularPosts(geohashBlocks: string[], userID: string): Promise<PostDetail[]> {
  const now = new Date();
  const currentHour = now.getUTCHours();
  const snappedHour = Math.floor(currentHour / 3) * 3; // 현재 시간이 05시면 03시 조회
  const hourStr = snappedHour.toString().padStart(2, '0');
  const yyyyMMdd = now.toISOString().slice(0, 10);
  const basePath = `post_ranking_cache/${yyyyMMdd}/last6hours/hour${hourStr}/geohash`;

  const posts: PostDetail[] = [];

  for (const hash of geohashBlocks) {
    const docRef = db.doc(`${basePath}/${hash}`);
    const snapshot = await docRef.get();

    if (!snapshot.exists) {
      continue;
    }

    const data = snapshot.data();
    const ranking = data?.ranking || [];

    for (const entry of ranking) {
      try {
        const post = await fetchPostById(entry.postId, userID);
        posts.push(post);
      } catch (error) {
        logger.warn(`⚠️ postId ${entry.postId} 조회 실패:`, error);
      }
    }
  }

  return posts;
}

function getTopLeftCornerGeohash(center: string, groupSize: number): string {
  const westCount = 2 * groupSize;
  const northCount = 2 * groupSize;
  let currentGeohash = center; 

  for (let i = 0; i < westCount; i++) {
    currentGeohash = Geohash.adjacent(center, "w");
  }

  for (let i = 0; i < northCount; i++) {
    currentGeohash = Geohash.adjacent(center, "n");
  }

  return currentGeohash;
}

function makeGeohashGroups(center: string, groupSize: number): Record<string, number> {
  const geohashGroups: Record<string, number> = {};

  let rowPosition = getTopLeftCornerGeohash(center, groupSize);
  let groupNumber = 0;

  for (let row = 0; row < 5; row++) {
    let groupStartPosition = rowPosition

    for (let col = 0; col < 5; col++) {
      const partialGroup = generateGeohashGroup(groupStartPosition, groupSize, groupNumber);
      Object.assign(geohashGroups, partialGroup);
      groupStartPosition = move(groupStartPosition, "E", groupSize);
      groupNumber += 1;
    }

    rowPosition = move(rowPosition, "S", groupSize);
  }

  return geohashGroups;
}

function move(geohash: string, direction: Geohash.Direction, count: number): string {
  let current = geohash;

  for (let i = 0; i < count; i++) {
    current = Geohash.adjacent(current, direction);
  }

  return current;
}

// topLeftGeohash: 해당 그룹 내의 좌측 상단 geo hash 값
// 이 값을 시작으로 주어진 그룹 사이즈만큼 좌측으로 탐색해가며 geo hash 추가
function generateGeohashGroup(topLeftGeohash: string, groupSize: number, groupNumber: number): Record<string, number> {
  const geohashGroups: Record<string, number> = {}; 

  let rowPosition = topLeftGeohash; 

  for (let row = 0; row < groupSize; row++) {
    let current = rowPosition;

    for (let col = 0; col < groupSize; col++) {
      geohashGroups[current] = groupNumber;
      current = Geohash.adjacent(current, "e");
    }
    
    rowPosition = Geohash.adjacent(rowPosition, "s");
  }

  return geohashGroups;
}

/**
 * 각 geohash 그룹별로 해당 그룹에 포함된 첫 번째 post만 추출
 */
function filterLatestPostPerGroup(
  posts: PostDetail[],
  geohashField: string,
  geohashGroups: Record<string, number>
): PostSummary[] {
  const result: PostSummary[] = [];
  const seenGroups = new Set<number>();

  for (const post of posts) {
    const fieldValue = (post as any)[geohashField];
    const groupIndex = geohashGroups[fieldValue];

    if (groupIndex !== undefined && !seenGroups.has(groupIndex)) {
      result.push({
        id: post.id,
        title: post.title,
        imageUrl: post.imageUrl,
        location: post.location
      });
      seenGroups.add(groupIndex);
    }
  }

  return result;
}