/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

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
    const snapshot = await db.collectionGroup("posts")
      .where("__name__", "==", postId)
      .get();

    if (snapshot.empty) {
      res.status(404).send("Post not found");
      return;
    }

    const doc = snapshot.docs[0];
    res.status(200).json({
      id: doc.id,
      ...doc.data(),
    });
  } catch (error) {
    logger.error("Error fetching post by ID:", error);
    res.status(500).send("Failed to fetch post");
  }
});