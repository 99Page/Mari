import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";

const app = admin.apps.length ? admin.app() : admin.initializeApp();

export const db = getFirestore(app, "mari-db");
export const auth = admin.auth();
export const adminInstance = admin;
export const region = "asia-northeast3";