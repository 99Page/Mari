import { Router } from "express";
import { createPost } from "@/posts/handlers/v2/createPost"
import { fetchPostsForMap } from "../handlers/v2/fetchPostsForMap";


const v2Router = Router();

v2Router.post("/", createPost);
v2Router.get("/", fetchPostsForMap);

export default v2Router;