import { Router } from "express";
import { createPostV3 } from "@/posts/handlers/v3/createPostsV3"
import { fetchPostsForMap } from "../handlers/v2/fetchPostsForMap";


const v3Router = Router();

v3Router.post("/", createPostV3);
v3Router.get("/", fetchPostsForMap);

export default v3Router;