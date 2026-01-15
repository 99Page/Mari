// src/app.ts
import express from "express";
import * as admin from "firebase-admin";
import postsRouter from "@/posts/router/postsRouter";

if (!admin.apps.length) {
  admin.initializeApp();
}

const app = express();
app.use(express.json());

app.use("/v2/posts/", postsRouter); // markerUrl 추가

export default app;