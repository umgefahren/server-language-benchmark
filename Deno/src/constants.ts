export const encoder = new TextEncoder();
export const decoder = new TextDecoder();

export const notFound = encoder.encode("not found\n");
export const invalidCommand = encoder.encode("invalid command\n");
