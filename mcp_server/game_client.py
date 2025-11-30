"""
Game client for connecting to Cravetown TCP server.

This module provides an async TCP client that communicates with
the Lua game server using JSON-delimited messages.
"""

import asyncio
import json
import uuid
from typing import Any, Optional, Callable


class GameClient:
    """Async TCP client for communicating with the Cravetown game."""

    def __init__(self, host: str = "localhost", port: int = 9999):
        self.host = host
        self.port = port
        self.reader: Optional[asyncio.StreamReader] = None
        self.writer: Optional[asyncio.StreamWriter] = None
        self.connected = False
        self.pending_requests: dict[str, asyncio.Future] = {}
        self.event_handlers: list[Callable] = []
        self._read_task: Optional[asyncio.Task] = None

    async def connect(self) -> bool:
        """Connect to the game server."""
        try:
            self.reader, self.writer = await asyncio.open_connection(
                self.host, self.port
            )
            self.connected = True

            # Start background reader
            self._read_task = asyncio.create_task(self._read_loop())

            # Perform handshake
            await self._handshake()

            print(f"[GameClient] Connected to {self.host}:{self.port}")
            return True
        except Exception as e:
            print(f"[GameClient] Connection failed: {e}")
            self.connected = False
            return False

    async def _handshake(self):
        """Perform handshake with game server."""
        handshake = {
            "type": "handshake",
            "version": "1.0",
            "client": "mcp-server"
        }
        await self._send(handshake)
        # Handshake response handled in read loop

    async def _send(self, data: dict):
        """Send data to the game server."""
        if self.writer:
            message = json.dumps(data) + "\n"
            self.writer.write(message.encode())
            await self.writer.drain()

    async def _read_loop(self):
        """Background task to read responses from server."""
        buffer = ""
        try:
            while self.connected and self.reader:
                try:
                    data = await asyncio.wait_for(
                        self.reader.read(4096),
                        timeout=0.1
                    )
                    if not data:
                        break
                    buffer += data.decode()

                    # Process complete messages
                    while "\n" in buffer:
                        line, buffer = buffer.split("\n", 1)
                        if line.strip():
                            try:
                                message = json.loads(line)
                                await self._handle_message(message)
                            except json.JSONDecodeError as e:
                                print(f"[GameClient] JSON decode error: {e}")

                except asyncio.TimeoutError:
                    continue
                except Exception as e:
                    print(f"[GameClient] Read error: {e}")
                    break

        except Exception as e:
            print(f"[GameClient] Read loop error: {e}")
        finally:
            self.connected = False
            print("[GameClient] Disconnected")

    async def _handle_message(self, message: dict):
        """Handle incoming message from server."""
        msg_type = message.get("type")

        if msg_type == "handshake_ack":
            print(f"[GameClient] Handshake complete - game: {message.get('game')}, mode: {message.get('mode')}")
            return

        if msg_type == "response":
            request_id = message.get("id")
            if request_id and request_id in self.pending_requests:
                future = self.pending_requests.pop(request_id)
                if not future.done():
                    if message.get("success"):
                        future.set_result(message.get("data"))
                    else:
                        future.set_result({"error": message.get("error")})
            return

        if msg_type == "event":
            # Notify event handlers
            for handler in self.event_handlers:
                try:
                    await handler(message.get("event"), message.get("data"))
                except Exception as e:
                    print(f"[GameClient] Event handler error: {e}")

    def add_event_handler(self, handler: Callable):
        """Add a handler for game events."""
        self.event_handlers.append(handler)

    async def request(self, method: str, params: dict = None) -> Any:
        """Send a request and wait for response."""
        if not self.connected:
            success = await self.connect()
            if not success:
                return {"error": "Not connected to game"}

        request_id = str(uuid.uuid4())
        future: asyncio.Future = asyncio.get_event_loop().create_future()
        self.pending_requests[request_id] = future

        request = {
            "id": request_id,
            "type": "request",
            "method": method,
            "params": params or {}
        }

        await self._send(request)

        try:
            result = await asyncio.wait_for(future, timeout=10.0)
            return result
        except asyncio.TimeoutError:
            self.pending_requests.pop(request_id, None)
            return {"error": "Request timed out"}

    # Convenience methods for common operations

    async def get_state(self, include: list = None, depth: str = "summary") -> dict:
        """Get current game state."""
        params = {"depth": depth}
        if include:
            params["include"] = include
        return await self.request("get_state", params)

    async def send_key(self, key: str, action: str = "tap", duration: float = 0.1) -> dict:
        """Send a keyboard input."""
        return await self.request("send_input", {
            "type": "key",
            "action": action,
            "key": key,
            "duration": duration
        })

    async def send_click(self, x: int, y: int, button: int = 1) -> dict:
        """Send a mouse click."""
        return await self.request("send_input", {
            "type": "mouse",
            "action": "click",
            "x": x,
            "y": y,
            "button": button
        })

    async def execute_action(self, action: str, **params) -> dict:
        """Execute a high-level game action."""
        return await self.request("send_action", {"action": action, **params})

    async def control(self, command: str, value: Any = None) -> dict:
        """Send a control command."""
        params = {"command": command}
        if value is not None:
            params["value"] = value
        return await self.request("control", params)

    async def query(self, query_type: str, **params) -> dict:
        """Query game data."""
        return await self.request("query", {"query_type": query_type, **params})

    async def get_logs(self, since_frame: int = 0, event_types: list = None, limit: int = 50) -> dict:
        """Get game event logs."""
        params = {"since_frame": since_frame, "limit": limit}
        if event_types:
            params["event_types"] = event_types
        return await self.request("get_logs", params)

    async def close(self):
        """Close the connection."""
        self.connected = False
        if self._read_task:
            self._read_task.cancel()
            try:
                await self._read_task
            except asyncio.CancelledError:
                pass
        if self.writer:
            self.writer.close()
            await self.writer.wait_closed()
        print("[GameClient] Connection closed")


# Example usage
if __name__ == "__main__":
    async def main():
        client = GameClient()
        await client.connect()

        # Get game state
        state = await client.get_state()
        print(f"Game state: {json.dumps(state, indent=2)}")

        # Query available buildings
        buildings = await client.query("available_buildings")
        print(f"Available buildings: {json.dumps(buildings, indent=2)}")

        await client.close()

    asyncio.run(main())
