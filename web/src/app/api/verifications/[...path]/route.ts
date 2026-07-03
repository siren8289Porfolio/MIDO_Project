import { NextRequest, NextResponse } from "next/server";

/** nginx가 /mido/api 를 mido-web 으로내도 Spring 으로 전달 */
const apiUrl = () => process.env.API_URL ?? "http://localhost:8080";

async function proxy(req: NextRequest, path: string[]) {
  const target = `${apiUrl()}/api/verifications/${path.join("/")}${req.nextUrl.search}`;

  const headers = new Headers(req.headers);
  headers.delete("host");
  headers.delete("connection");

  const init: RequestInit = {
    method: req.method,
    headers,
    redirect: "manual",
  };

  if (req.method !== "GET" && req.method !== "HEAD") {
    init.body = await req.arrayBuffer();
  }

  try {
    const upstream = await fetch(target, init);
    const body = await upstream.arrayBuffer();
    const resHeaders = new Headers(upstream.headers);
    resHeaders.delete("transfer-encoding");

    return new NextResponse(body, {
      status: upstream.status,
      statusText: upstream.statusText,
      headers: resHeaders,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Upstream request failed";
    return NextResponse.json({ error: message, target }, { status: 502 });
  }
}

type Ctx = { params: Promise<{ path: string[] }> };

export async function GET(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return proxy(req, path);
}

export async function POST(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return proxy(req, path);
}

export async function PUT(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return proxy(req, path);
}

export async function PATCH(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return proxy(req, path);
}

export async function DELETE(req: NextRequest, ctx: Ctx) {
  const { path } = await ctx.params;
  return proxy(req, path);
}
