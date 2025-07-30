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
} as const;