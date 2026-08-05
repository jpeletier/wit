import { sanitizeIrcText } from "../core/format.js";

const MAX_ERROR_LENGTH = 200;

export function runQuestionMaintenance(
  ageQuestions: () => void,
  log: (message: string) => void = console.error,
): void {
  try {
    ageQuestions();
  } catch (error) {
    let detail: string;
    try {
      detail = String(error instanceof Error ? error.message : error);
    } catch {
      detail = "unknown failure";
    }
    detail = sanitizeIrcText(detail);
    const concise =
      detail.length > MAX_ERROR_LENGTH
        ? `${detail.slice(0, MAX_ERROR_LENGTH - 3)}...`
        : detail;
    log(`Question maintenance failed: ${concise}`);
  }
}
