import type { MapValue } from "./types.ts";
import { encoder } from "./constants.ts";

export class Lock {
  private promise?: Promise<void>;
  private resolve?: () => void;

  public async lock() {
    if (this.promise) {
      await this.promise;
    }
    this.promise = new Promise((resolve) => {
      this.resolve = resolve;
    });
  }

  public release() {
    this.resolve?.();
  }
}

export function isValidKey(key: string): boolean {
  for (const char of key) {
    const code = char.charCodeAt(0);
    if (
      !(code > 47 && code < 58) &&
      !(code > 64 && code < 91) &&
      !(code > 96 && code < 123)
    ) {
      return false;
    }
  }
  return true;
}

const opening = encoder.encode("[");
const closing = encoder.encode("]\n");
const comma = encoder.encode(",");

export async function streamDump(conn: Deno.Conn, map: Map<string, MapValue>) {
  let first = true;
  await conn.write(opening);
  for (const [key, { text, date }] of map) {
    if (first) {
      first = false;
    } else {
      await conn.write(comma);
    }

    await conn.write(
      encoder.encode(
        JSON.stringify({
          key,
          associated_value: { value: text, timestamp: date.toISOString() },
        })
      )
    );
  }
  await conn.write(closing);
}

export function parseDuration(text: string): {
  success: boolean;
  duration: number;
} {
  const digits: Array<number> = [];

  type Expecter = (char: string) => { valid: boolean; value?: number };

  function expectDigit(char: string) {
    const digit = parseInt(char, 10);
    if (digit > 9 || digit < 0) {
      return { valid: false };
    } else {
      return {
        valid: true,
        value: digit,
      };
    }
  }

  function expectChar(expected: string) {
    return (char: string) => {
      return { valid: char === expected };
    };
  }

  function expectEnd(char: string) {
    return { valid: char === undefined };
  }

  const chain: Array<Expecter> = [
    expectDigit,
    expectDigit,
    expectChar("h"),
    expectChar("-"),
    expectDigit,
    expectDigit,
    expectChar("m"),
    expectChar("-"),
    expectDigit,
    expectDigit,
    expectDigit,
    expectChar("s"),
    expectEnd,
  ];

  for (let i = 0; i < chain.length; i++) {
    const { valid, value } = chain[i](text[i]);
    if (!valid) {
      return { success: false, duration: 0 };
    } else if (value !== undefined) {
      digits.push(value);
    }
  }

  const hours = digits[0] * 10 + digits[1];
  const minutes = digits[2] * 10 + digits[3];
  const seconds = digits[4] * 100 + digits[5] * 10 + digits[6];

  return {
    success: true,
    duration: hours * 3600 + minutes * 60 + seconds,
  };
}
