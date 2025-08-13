export type ErrorResponse = {
  code: string;
  message: string;
};

// errorResponse.ts
export const errors = {
  // 일반
  METHOD_NOT_ALLOWED: {
    code: "method-not-allowed",
    message: "허용되지 않은 요청 메서드입니다.",
  },
  MISSING_REQUIRED_FIELDS: {
    code: "missing-required-fields",
    message: "필요한 정보가 누락됐어요.",
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
  INTERNAL_ERROR: {
    code: "internal-error",
    message: "서버 오류가 발생했어요",
  },
  

  // 게시글
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

  // UserRelatinoships
  CANNOT_BLOCK_SELF: {
    code: "cannot-block-self",
    message: "자기 자신을 차단할 수 없습니다.",
  },
  ALREADY_BLOCKED_USER: {
    code: "already-blocked-user",
    message: "사용자를 이미 차단했어요",
  },
  NOT_BLOCKED_USER: {
    code: "not-blocked-user",
    message: "차단하지 않은 사용자입니다.",
  },
} as const;