
export type SuccessResponse<T = any> = {
  status: string;
  message: string;
  result: T;
};
