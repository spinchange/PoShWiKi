# Project Brief: PoShWiKi

## Problem

Agents and humans need a lightweight, cross-platform, CLI-driven wiki system that is easy for agents to write to and query. Existing solutions often require complex setups, web servers, or are not easily scriptable for LLM-driven automation.

## Users / Operators

- **Chris Duffy (Spinchange):** Primary human operator and maintainer.
- **Agents (LLMs):** Automated users that need to read, write, and query knowledge.
- **PowerShell 7 Users:** Developers who want a quick, cross-platform wiki.

## Outcome

A functional, "smallest honest version" of a PowerShell 7 Wiki that uses SQLite as its backend. It will provide a CLI for page management and search, ensuring cross-platform compatibility and ease of use for both humans and agents.

## In Scope

- PowerShell 7 core logic (cross-platform).
- SQLite database for storing wiki pages (Markdown content).
- CLI commands for:
  - `Initialize-Wiki`: Set up the database.
  - `Get-WikiPage`: Retrieve a page by title.
  - `Set-WikiPage`: Create or update a page.
  - `Find-WikiPage`: Search for pages by title or content.
  - `Remove-WikiPage`: Delete a page.
- Simple, agent-friendly schema.

## Out Of Scope

- Web UI (Server-side rendering or React/Tauri/etc.).
- User authentication/authorization (local use focus).
- Complex revision history (for now, just basic last-modified).
- Rich text editing (Markdown is the standard).

## Constraints

- **Technical:** Must run on PowerShell 7 (Windows/Linux/macOS).
- **Technical:** Must use SQLite.
- **Budget:** "Smallest honest version" (Minimalist).

## Risks / Unknowns

- **SQLite Dependency:** Ensuring a cross-platform SQLite driver/client is easily available for PS7 without complex installs.
- **Agent Integration:** Ensuring the CLI output is easily parsed by LLMs.

## Success Signals

- Database is successfully initialized in a single command.
- A human or agent can save a page and retrieve it by name.
- Search returns relevant results.
- Code runs unmodified on both Windows and Linux (if tested).

## First Slice

The "Real" version: A single script (or module) that can initialize a SQLite DB and perform basic CRUD operations on a `Pages` table containing `Title` and `Content` (Markdown).
