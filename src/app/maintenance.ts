import { sanitizeIrcText } from "../core/format.js";
import { createLogger } from "../logging.js";

const MAX_ERROR_LENGTH = 200;
const log = createLogger().child({ module: "maintenance.questions" });

export function runQuestionMaintenance(
  ageQuestions: () => void,
  report: (message: string) => void = (message) => log.error({}, message)
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
      detail.length > MAX_ERROR_LENGTH ? `${detail.slice(0, MAX_ERROR_LENGTH - 3)}...` : detail;
    report(`Question maintenance failed: ${concise}`);
  }
}
