// src/app.ts
import express from "express";
import * as admin from "firebase-admin";
import v2PostsRouter from "@/posts/router/postsRouterV2";
import v3Router from "@/posts/router/postsRouterV3";

if (!admin.apps.length) {
  admin.initializeApp();
}

const app = express();
app.use(express.json());

app.use("/v2/posts/", v2PostsRouter); // markerUrl 추가
app.use("/v3/posts/", v3Router); // quadKey 변경

export default app;