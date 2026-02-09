// src/app.ts
import express from "express";
import * as admin from "firebase-admin";
import v2PostsRouter from "@/posts/router/postsRouterV2";
import v3PostsRouter from "@/posts/router/postsRouterV3";
import errorsRouterV3 from "@/errors/router/errorsRouterV3";
import { Router } from "express";

if (!admin.apps.length) {
  admin.initializeApp();
}

const app = express();
app.use(express.json());

const v3Router = Router();
v3Router.use("/posts", v3PostsRouter);
v3Router.use("/errors", errorsRouterV3);

app.use("/v3", v3Router);
app.use("/v2/posts", v2PostsRouter); // markerUrl 추가


export default app;