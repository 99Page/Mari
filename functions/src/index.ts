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
const {initializeApp} = require("firebase-admin/app");

export const helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", { structuredData: true });
  response.send("Hello from Firebase!");
});

initializeApp();

import * as admin from "firebase-admin";

const db = admin.firestore();

export const getPosts = onRequest(async (req, res) => {
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