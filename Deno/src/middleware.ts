import type { Handler, HandlerParams } from "./types.ts";
import { isValidKey } from "./helpers.ts";
import { notFound, invalidCommand } from "./constants.ts";

export function checkValidKey(handler: Handler): Handler {
  return async (params: HandlerParams) => {
    if (isValidKey(params.key)) {
      return handler(params);
    } else {
      params.conn.write(notFound);
    }
  };
}

export function checkValidValue(handler: Handler): Handler {
  return async (params: HandlerParams) => {
    if (isValidKey(params.val)) {
      return handler(params);
    } else {
      params.conn.write(notFound);
    }
  };
}

export function checkNoValue(handler: Handler): Handler {
  return async (params: HandlerParams) => {
    if (params.val) {
      params.conn.write(invalidCommand);
    } else {
      return handler(params);
    }
  };
}

export function checkNoKey(handler: Handler): Handler {
  return async (params: HandlerParams) => {
    if (params.key) {
      params.conn.write(invalidCommand);
    } else {
      return handler(params);
    }
  };
}

export function validKeyNoValue(handler: Handler): Handler {
  return checkValidKey(checkNoValue(handler));
}

export function validKeyAndValue(handler: Handler): Handler {
  return checkValidKey(checkValidValue(handler));
}
