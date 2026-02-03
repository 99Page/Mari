export function hasBannedWord(text: string): string[] {
  const normalizedText = text
    .toLowerCase()
    .replace(/[\s.,!?;:'"(){}\[\]<>@#$%^&*_+=~`|\\/\\-]/g, "");

  const matchedWords = bannedWords.filter(word => normalizedText.includes(word.toLowerCase()));
  return matchedWords;
}

const bannedWords: string[] = [
  // 성적인 표현
  "sex", "sexual", "porn", "porno", "pornography", "nude", "naked",
  "섹스", 
  
  // 욕설/비하 (한글 초성·완성 혼합)
  "fuck", "shit", "bitch", "bastard", "asshole", "jerk",
  "개새", "개새끼", "씨발", "ㅅㅂ", "ㅂㅅ", "멍청이",
];