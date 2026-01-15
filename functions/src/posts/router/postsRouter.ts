import { Router } from "express";
import { createPost } from "@/posts/handlers/createPost"


const router = Router();

router.post("/", createPost);

export default router;