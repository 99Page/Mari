import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";

const app = admin.apps.length ? admin.app() : admin.initializeApp();

// release
// export const db = getFirestore(app, "mari-db"); 

// dev
export const db = getFirestore(app); 
export const auth = admin.auth();
export const adminInstance = admin;
export const region = "asia-northeast3";