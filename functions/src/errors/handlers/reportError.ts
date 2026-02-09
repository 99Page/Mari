import { Request, Response } from "express";
import * as admin from "firebase-admin";
import { logErrorFromClient, type ClientErrorPayload } from "@/utils/errorLogger";

/**
 * POST /v3/errors
 * Body: { context: string, message: string, code?: string }
 * Authorization: Bearer <idToken> (optional)
 * Writes to Firestore errorLogs with source "ios".
 */
export async function reportError(req: Request, res: Response): Promise<void> {
  if (req.method !== "POST") {
    res.status(405).json({ code: "method-not-allowed", message: "Method Not Allowed" });
    return;
  }

  const body = req.body;
  if (!body || typeof body !== "object" || typeof body.context !== "string" || typeof body.message !== "string") {
    res.status(400).json({ code: "invalid-body", message: "context and message (strings) are required" });
    return;
  }

  const payload: ClientErrorPayload = {
    context: body.context,
    message: body.message,
  };
  if (typeof body.code === "string") payload.code = body.code;

  let userId: string | undefined;
  const authHeader = req.headers.authorization;
  const idToken = authHeader?.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : undefined;
  if (idToken) {
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      userId = decoded.uid;
    } catch {
      // ignore invalid token; still record error without userId
    }
  }

  await logErrorFromClient(payload, userId);
  res.status(200).json({ status: "ok" });
}
