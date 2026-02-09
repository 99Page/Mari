import { Router } from "express";
import { createPostV3 } from "@/posts/handlers/v3/createPostV3"
import { fetchPostsForMapV3 } from "@/posts/handlers/v3/fetchPostsForMapV3";


const v3PostRouter = Router();

v3PostRouter.post("/", createPostV3);
v3PostRouter.get("/", fetchPostsForMapV3);

export default v3PostRouter;