import type { Handler, HandlerParams } from "./types.ts";
import { isValidKey } from "./helpers.ts";
import { messages } from "./constants.ts";

export function validKey(handler: Handler): Handler {
  return async (params: HandlerParams) => {
    if (isValidKey(params.key)) {
      return handler(params);
    } else {
      await params.conn.write(messages.notFound);
    }
  };
}

export function checkValidValue(handler: Handler): Handler {
  return async (params: HandlerParams) => {
    if (isValidKey(params.val)) {
      return handler(params);
    } else {
      await params.conn.write(messages.notFound);
    }
  };
}

export function checkNoValue(handler: Handler): Handler {
  return async (params: HandlerParams) => {
    if (params.val) {
      await params.conn.write(messages.invalidCommand);
    } else {
      return handler(params);
    }
  };
}

export function checkNoKey(handler: Handler): Handler {
  return async (params: HandlerParams) => {
    if (params.key) {
      await params.conn.write(messages.invalidCommand);
    } else {
      return handler(params);
    }
  };
}

export function validKeyNoValue(handler: Handler): Handler {
  return validKey(checkNoValue(handler));
}

export function validKeyAndValue(handler: Handler): Handler {
  return validKey(checkValidValue(handler));
}
