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

export const helloWorld = onRequest({ region: "asia-northeast3" }, (request, response) => {
  logger.info("Hello logs!", { structuredData: true });
  response.send("Hello from Firebase!");
});

export const getPosts = onRequest({ region: "asia-northeast3" }, async (req, res) => {
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