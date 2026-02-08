import type { Request } from "express";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { db } from "@/utils/firebase";

const ERROR_LOGS_COLLECTION = "errorLogs";
const SOURCE_FUNCTIONS = "functions";
const SOURCE_IOS = "ios";

export type ClientErrorPayload = {
  context: string;
  message: string;
  code?: string;
};

export type ErrorLogContext = {
  handler: string;
  userId?: string;
  req?: Request;
};

function getMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  if (typeof error === "string") return error;
  return String(error);
}

function getStack(error: unknown): string | undefined {
  if (error instanceof Error && error.stack) return error.stack;
  return undefined;
}

function getCode(error: unknown): string | undefined {
  if (error && typeof error === "object" && "code" in error && typeof (error as { code: unknown }).code === "string") {
    return (error as { code: string }).code;
  }
  return undefined;
}

/**
 * Logs an error to Cloud Logging and writes to Firestore `errorLogs` for tracking.
 * Firestore write failures are logged only and do not throw, so they do not affect the main flow.
 */
export async function logErrorToFirestore(
  error: unknown,
  context: ErrorLogContext
): Promise<void> {
  const message = getMessage(error);
  const stack = getStack(error);
  const code = getCode(error);

  logger.error(`[${context.handler}]`, message, error);

  try {
    const doc: Record<string, unknown> = {
      source: SOURCE_FUNCTIONS,
      context: context.handler,
      message,
      timestamp: admin.firestore.Timestamp.now(),
    };
    if (code) doc.code = code;
    if (stack) doc.stack = stack;
    if (context.userId) doc.userId = context.userId;

    await db.collection(ERROR_LOGS_COLLECTION).add(doc);
  } catch (writeError) {
    logger.error("Failed to write error to Firestore:", writeError);
    // Do not rethrow; keep existing handler behavior unchanged.
  }
}

/**
 * Writes a client-reported error to Firestore `errorLogs` with source "ios".
 * Used by the POST /v3/errors endpoint. Does not throw on Firestore failure.
 */
export async function logErrorFromClient(
  payload: ClientErrorPayload,
  userId?: string
): Promise<void> {
  try {
    const doc: Record<string, unknown> = {
      source: SOURCE_IOS,
      context: payload.context,
      message: payload.message,
      timestamp: admin.firestore.Timestamp.now(),
    };
    if (payload.code) doc.code = payload.code;
    if (userId) doc.userId = userId;

    await db.collection(ERROR_LOGS_COLLECTION).add(doc);
  } catch (writeError) {
    logger.error("Failed to write client error to Firestore:", writeError);
  }
}
