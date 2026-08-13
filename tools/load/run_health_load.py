"""Small deterministic health/readiness load probe for staging or local API."""

from __future__ import annotations

import argparse
import asyncio
import statistics
import time

import httpx


async def _request(client: httpx.AsyncClient, url: str) -> float:
    started = time.perf_counter()
    response = await client.get(url)
    response.raise_for_status()
    return (time.perf_counter() - started) * 1000


async def run(url: str, users: int, rounds: int, p95_limit_ms: float) -> None:
    async with httpx.AsyncClient(timeout=10) as client:
        durations: list[float] = []
        for _ in range(rounds):
            durations.extend(await asyncio.gather(*(_request(client, url) for _ in range(users))))
    ordered = sorted(durations)
    p95 = ordered[min(len(ordered) - 1, int(len(ordered) * 0.95))]
    print(f"requests={len(durations)} p50_ms={statistics.median(durations):.2f} p95_ms={p95:.2f}")
    if p95 > p95_limit_ms:
        raise SystemExit(f"p95 {p95:.2f}ms exceeds {p95_limit_ms:.2f}ms")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("--users", type=int, default=100)
    parser.add_argument("--rounds", type=int, default=2)
    parser.add_argument("--p95-limit-ms", type=float, default=500)
    args = parser.parse_args()
    asyncio.run(run(args.url, args.users, args.rounds, args.p95_limit_ms))


if __name__ == "__main__":
    main()
