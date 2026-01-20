import { Request, Response } from "express"; 
import * as logger from "firebase-functions/logger";
import Geohash from "latlon-geohash";
import { fetchPostById } from "@/posts/handlers/fetchPostById";
import { db, adminInstance as admin } from "@/utils/firebase";
import { convertToPostDetail, PostDetail } from "@/posts/models/postDetail";
import { PostSummary } from "@/posts/models/postSummary";
import { ErrorResponse } from "@/resopnse/errorResponse";


export const fetchPostsForMap = async (req: Request, res: Response) => {
  const lat = parseFloat(req.query.latitude as string);
  const lng = parseFloat(req.query.longitude as string);
  const precision = parseInt(req.query.precision as string, 10); // 10진법으로 변환
  const hRadius = parseInt(req.query.hRadius as string || "1", 10);
  const vRadius = parseInt(req.query.vRadius as string || "1", 10);

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
  const geohashBlocks = getRectangularGeohashes(geohash, hRadius, vRadius);
  const geohashField = `geohash_${precision}`;

  if (type === "latest") {
    try {
      const posts = await fetchLatestPosts(geohashBlocks, geohashField, userID);
      
      // PostDetail -> PostSummary 변환이 필요하다면 여기서 map을 사용 (선택사항)
      const postSummaries: PostSummary[] = posts.map(post => ({
        id: post.id,
        title: post.title,
        imageUrl: post.imageUrl,
        creatorID: post.creatorID,
        location: post.location,
        createdAt: post.createdAt
      }));

      res.status(200).json({
        status: "SUCCESS",
        message: "Successfully fetched latest posts",
        result: {
          type: "latest",
          posts: postSummaries, // 필터링된 posts 대신 전체 posts 반환
          geohashBlocks,
          postCount: posts.length
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
      
      const postSummaries: PostSummary[] = posts.map(post => ({
        id: post.id,
        title: post.title,
        imageUrl: post.imageUrl,
        creatorID: post.creatorID,
        location: post.location,
        createdAt: post.createdAt
      }));

      res.status(200).json({
        status: "success",
        message: "Successfully fetched popular posts",
        result: {
          type: "popular",
          posts: postSummaries,
          geohashBlocks,
          postCount: posts.length
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
};

// geohash 블록별로 최신 게시글을 가져옴 (각 블록당 최대 3개, createdAt 기준 내림차순 정렬)
async function fetchLatestPosts(geohashBlocks: string[], geohashField: string, userID: string): Promise<PostDetail[]> {
  const posts: PostDetail[] = [];

  for (const hash of geohashBlocks) {
    const snapshot = await db
      .collectionGroup("posts")
      .where(geohashField, "==", hash)
      .orderBy("createdAt", "desc")
      .limit(3)
      .get();

    if (!snapshot.empty) {
      const doc = snapshot.docs[0];
      const data = doc.data();
      const postDetail = convertToPostDetail(doc, data?.creatorID)
      posts.push(postDetail)
    }
  }

  return posts;
}


function move(startHash: string, direction: "n" | "s" | "e" | "w", steps: number): string {
  let current = startHash;
  for (let i = 0; i < steps; i++) {
    current = Geohash.adjacent(current, direction);
  }
  return current;
}

function getRectangularGeohashes(center: string, hRadius: number, vRadius: number): string[] {
  const geohashes: string[] = [];

  // 1. 격자의 좌측 상단(North-West) 시작점 찾기
  // 서쪽으로 hRadius만큼, 북쪽으로 vRadius만큼 이동
  let startRowHash = move(center, "w", hRadius);
  startRowHash = move(startRowHash, "n", vRadius);

  // 2. 전체 격자 크기 계산
  // 예: hRadius=1 (좌1+우1+본인) -> 가로 3칸
  // 예: vRadius=2 (위2+아래2+본인) -> 세로 5칸
  const width = hRadius * 2 + 1;
  const height = vRadius * 2 + 1;

  let rowHash = startRowHash;

  // 행(Row) 반복 (위 -> 아래)
  for (let row = 0; row < height; row++) {
    let colHash = rowHash;
    
    // 열(Col) 반복 (좌 -> 우)
    for (let col = 0; col < width; col++) {
      geohashes.push(colHash);
      colHash = Geohash.adjacent(colHash, "e"); // 오른쪽으로 이동
    }

    rowHash = Geohash.adjacent(rowHash, "s"); // 다음 줄(아래)로 이동
  }

  return geohashes;
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