/****
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
// import * as geohash from "ngeohash";

// The Firebase Admin SDK to access Firestore.
import { getFirestore } from "firebase-admin/firestore";
import { initializeApp } from "firebase-admin/app";

const app = initializeApp();
const db = getFirestore(app, "mari-db");

const REGION = "asia-northeast3";

export const helloWorld = onRequest({ region: REGION }, (request, response) => {
  logger.info("Hello logs!", { structuredData: true });
  response.send("Hello from Firebase!");
});

export const getPosts = onRequest({ region: REGION }, async (req, res) => {
  try {
    const snapshot = await db.collectionGroup("posts").get();
    const posts = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.status(200).json(posts);
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

    // let geohashFields: Record<string, string> = {};
    // try {
    //   for (let p = 1; p <= 10; p++) {
    //     geohashFields[`geohash_${p}`] = geohash.encode(latitude, longitude, p);
    //   }
    // } catch (e) {
    //   logger.error("GeoHash encoding failed:", e);
    //   res.status(500).send("GeoHash encoding error");
    //   return;
    // }

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
      createdAt: new Date().toISOString()
      // ...geohashFields
    };

    const postRef = await db.collection("posts").add(newPost);

    res.status(201).json({ id: postRef.id, ...newPost });
  } catch (error) {
    logger.error("Error creating post:", error);
    res.status(500).send("Failed to create post");
  }
});