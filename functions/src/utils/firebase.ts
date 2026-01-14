import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";

const app = admin.apps.length ? admin.app() : admin.initializeApp();
const dbName = process.env.DB_INSTANCE_NAME;

// dbName 값이 있으면(prod) 그 DB를, 없으면(dev) 기본 DB를 사용
export const db = dbName ? getFirestore(app, dbName) : getFirestore(app);

export const auth = admin.auth();
export const adminInstance = admin;
export const region = "asia-northeast3";