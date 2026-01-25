/****
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { onRequest } from "firebase-functions/v2/https";
import app from "@/app"; 

export { deletePost } from './posts/deletePost';
export { getPostById } from './posts/handlers/fetchPostById'
export { increasePostViewCount } from './posts/increasePostViewCount'
export { getPostsByUser } from './posts/getPostsByUser'
export { getPosts } from '@/posts/handlers/getPosts'
export { createPost } from './posts/handlers/createPost'
export { scheduleAggregateLast6HoursRanking } from './posts/aggregateRanking'
export { testAggregateLast6HoursRanking } from './posts/aggregateRanking'
export { reportPost } from "./posts/reportPost"
export { nearPostsV1 } from "@/posts/handlers/fetchNearPosts"

export { debugFirestorePath } from './debug/debugFirstorePath'

// acount
export  { withdrawAccount} from './account/withdrawAccount'

// userRelationships
export { blocksUser } from './userRelationships/blocksUser'
export { fetchBlockedUserIds } from './userRelationships/fetchBlockedUserIds'
export { unblocksUser } from './userRelationships/unblocksUser'

// restful 적용
export const api = onRequest({ region: "asia-northeast3" }, app);