export type ErrorResponse = {
  code: string;
  message: string;
};

// errorResponse.ts
export const errors = {
  METHOD_NOT_ALLOWED: {
    code: "method-not-allowed",
    message: "허용되지 않은 요청 메서드입니다.",
  },
  INVALID_AUTH_HEADER: {
    code: "invalid-auth-header",
    message: "Authorization 헤더가 없거나 형식이 잘못되었습니다.",
  },
  UNAUTHORIZED: {
    code: "unauthorized",
    message: "토큰이 유효하지 않습니다.",
  },
  WITHDRAW_FAILED: (message: string): ErrorResponse => ({
    code: "withdraw-failed",
    message,
  }),
  POST_NOT_FOUND: {
    code: "post-err-4827",
    message: "게시글을 찾을 수 없습니다.",
  },
  CANNOT_REPORT_OWN_POST: {
    code: "cannot-report-own-post",
    message: "자신의 게시글은 신고할 수 없습니다.",
  },
  ALREADY_REPORTED_POST: {
    code: "already-reported-post",
    message: "이미 신고한 게시글입니다.",
  },
  REPORT_POST_FAILED: {
    code: "report-post-failed",
    message: "게시글 신고에 실패했습니다.",
  },
  BANNED_WORD_DETECTED: (word: string): ErrorResponse => ({
    code: "banned-word-detected",
    message: `"${word}"를 포함할 수 없어요`,
  }),
} as const;