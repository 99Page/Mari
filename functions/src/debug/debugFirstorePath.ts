import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { db } from "../utils/firebase";

const REGION = "asia-northeast3";


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