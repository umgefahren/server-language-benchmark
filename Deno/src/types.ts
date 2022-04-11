export type HandlerParams = {
  conn: Deno.Conn;
  key: string;
  val: string;
  duration: string;
};

export type Handler = (params: HandlerParams) => Promise<void>;

export type MapValue = { text: string; date: Date };
