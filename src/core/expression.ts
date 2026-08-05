export interface ExpressionOptions {
  dice?: boolean;
  maxLength?: number;
  random?: () => number;
  maxTerms?: number;
  maxDepth?: number;
}

type Token =
  | { type: "number"; value: number }
  | { type: "operator"; value: string }
  | { type: "eof" };

export function calculate(
  expression: string,
  options: ExpressionOptions = {},
): number {
  if (expression.length > (options.maxLength ?? 200))
    throw new Error("Expression is too long");
  const tokens = tokenize(
    expression,
    options.dice ?? true,
    options.random ?? Math.random,
    options.maxTerms ?? 20,
  );
  let position = 0;
  let depth = 0;
  const current = (): Token => tokens[position] ?? { type: "eof" };
  const consume = (): Token => tokens[position++] ?? { type: "eof" };

  const primary = (): number => {
    const token = consume();
    if (token.type === "number") return token.value;
    if (token.type === "operator" && token.value === "(") {
      depth++;
      if (depth > (options.maxDepth ?? 10))
        throw new Error("Expression is too deeply nested");
      const value = addSubtract();
      const close = consume();
      if (close.type !== "operator" || close.value !== ")")
        throw new Error("Missing closing parenthesis");
      depth--;
      return value;
    }
    if (token.type === "operator" && ["+", "-"].includes(token.value))
      return token.value === "-" ? -primary() : primary();
    throw new Error("Expected a number");
  };
  const power = (): number => {
    let value = primary();
    while (
      current().type === "operator" &&
      (current() as { value: string }).value === "^"
    ) {
      consume();
      value **= primary();
    }
    return value;
  };
  const multiplyDivide = (): number => {
    let value = power();
    while (
      current().type === "operator" &&
      ["*", "/"].includes((current() as { value: string }).value)
    ) {
      const operator = (consume() as { value: string }).value;
      const right = power();
      value = operator === "*" ? value * right : value / right;
    }
    return value;
  };
  const addSubtract = (): number => {
    let value = multiplyDivide();
    while (
      current().type === "operator" &&
      ["+", "-"].includes((current() as { value: string }).value)
    ) {
      const operator = (consume() as { value: string }).value;
      const right = multiplyDivide();
      value = operator === "+" ? value + right : value - right;
    }
    return value;
  };

  const result = addSubtract();
  if (current().type !== "eof" || !Number.isFinite(result))
    throw new Error("Invalid expression");
  return result;
}

function tokenize(
  input: string,
  dice: boolean,
  random: () => number,
  maxTerms: number,
): Token[] {
  const tokens: Token[] = [];
  let index = 0;
  while (index < input.length) {
    const character = input[index]!;
    if (/\s/u.test(character)) {
      index++;
      continue;
    }
    const number = input
      .slice(index)
      .match(/^(?:\d+(?:[.,]\d*)?|[.,]\d+)/u)?.[0];
    if (number !== undefined) {
      index += number.length;
      let value = Number(number.replace(",", "."));
      const diceMatch = input.slice(index).match(/^[dD](\d+)/u);
      if (diceMatch !== null) {
        if (!dice) throw new Error("Dice are not allowed");
        const sides = Number(diceMatch[1]);
        if (!Number.isInteger(value) || value < 1 || sides < 1)
          throw new Error("Invalid dice");
        if (value > 100 || sides > 1_000_000) throw new Error("Invalid dice");
        let rolled = 0;
        for (let roll = 0; roll < value; roll++)
          rolled += Math.floor(random() * sides) + 1;
        value = rolled;
        index += diceMatch[0].length;
      }
      tokens.push({ type: "number", value });
      if (tokens.filter((token) => token.type === "number").length > maxTerms)
        throw new Error("Expression has too many terms");
      continue;
    }
    if ("+-*/^()".includes(character)) {
      tokens.push({ type: "operator", value: character });
      index++;
      continue;
    }
    throw new Error(`Unexpected character at ${index + 1}`);
  }
  tokens.push({ type: "eof" });
  return tokens;
}
