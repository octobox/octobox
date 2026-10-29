# Octobox MCP server

Octobox is available as a hosted [Model Context Protocol](https://modelcontextprotocol.io) (MCP)
server, so AI agents such as Claude, ChatGPT, Cursor and VS Code can call it as tools.

| | |
| --- | --- |
| Server URL | `https://app.getelva.ai/mcp/elvademo/octobox` |
| Tools | 18, one per operation in [`openapi.yaml`](openapi.yaml) |
| Calls | `https://octobox.io` |
| Authentication | Your own API token, sent as a bearer token. Your MCP client asks for it when you connect. |

## Install

[![Install in Cursor](https://cursor.com/deeplink/mcp-install-dark.svg)](https://cursor.com/en/install-mcp?name=Octobox&config=eyJ1cmwiOiJodHRwczovL2FwcC5nZXRlbHZhLmFpL21jcC8zMjc2NTA0Ni9vY3RvYm94In0%3D)
[![Install in VS Code](https://img.shields.io/badge/VS_Code-Install_MCP-0098FF?logo=visualstudiocode&logoColor=white)](https://insiders.vscode.dev/redirect/mcp/install?name=octobox&config=%7B%22type%22%3A%22http%22%2C%22url%22%3A%22https%3A%2F%2Fapp.getelva.ai%2Fmcp%2F32765046%2Foctobox%22%7D)

### Claude Code

```bash
claude mcp add --transport http octobox https://app.getelva.ai/mcp/elvademo/octobox
```

### Claude (claude.ai and Claude Desktop)

Settings → Connectors → **Add custom connector**, then paste the server URL.

### ChatGPT

Settings → Apps & Connectors → Advanced settings → turn on **Developer mode**, then
**Create** a connector and paste the server URL.

### Any other MCP client

```json
{
  "mcpServers": {
    "octobox": {
      "url": "https://app.getelva.ai/mcp/elvademo/octobox"
    }
  }
}
```

---

Generated from this repository's OpenAPI spec and hosted by [Elva](https://getelva.ai/).
