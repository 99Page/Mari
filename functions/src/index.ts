/****
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

export { deletePost } from './posts/deletePost';
export { getPostById } from './posts/fetchPostById'
export { increasePostViewCount } from './posts/increasePostViewCount'
export { getPostsByUser } from './posts/getPostsByUser'
export { getPosts } from './posts/getPosts'
export { createPost } from './posts/createPost'
export { scheduleAggregateLast6HoursRanking } from './posts/aggregateRanking'
export { testAggregateLast6HoursRanking } from './posts/aggregateRanking'

export { debugFirestorePath } from './debug/debugFirstorePath'

export  { withdrawAccount} from './account/withdrawAccount'
