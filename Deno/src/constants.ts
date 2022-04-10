export const encoder = new TextEncoder();
export const decoder = new TextDecoder();

export const messages = {
  notFound: encoder.encode("not found\n"),
  invalidCommand: encoder.encode("invalid command\n"),
  ready: encoder.encode("READY\n"),
  error: encoder.encode("ERROR\n"),
  ok: encoder.encode("OK\n"),
};
