# Board

Use these statuses consistently:

- `Now` - active work being executed
- `Next` - the next ready work to pull after `Now`
- `Blocked` - work that cannot proceed until an external dependency or decision is resolved
- `Later` - known work that is intentionally not active yet
- `Risks` - delivery threats, not tasks

Move work to `Done` only in status updates or milestone summaries after the code or doc exists and the claimed validation has been run.

## Now

- 

## Next — Gemini (Ingester)

- [ ] **Embedding run:** Re-run the semantic embedding pipeline over the 17 new notes from today's Claude sessions. Target notes: all `pattern-*`, `lit-*`, `spec-*` created 2026-04-27. Verify they appear in `NoteEmbeddings` table and auto-link pass produces new edges.
- [ ] **Cluster & summarize:** Execute Phase 1 of `community-report-generator` (k-means clustering on current `NoteEmbeddings`). Produce cluster membership lists in `01_Wiki/community-reports/`. Target: ≥ 6 Level-1 clusters. Output is input for next Claude summarization session.
- [ ] **Stub notes:** Create the three stubs flagged as missing wikilink targets — `workflow-agents.md` (ADK SequentialAgent/ParallelAgent/LoopAgent), `adk-session-service.md` (Session & State management), `multi-agent-patterns-moc.md` (MOC for the 7 pattern notes). All need full YANP frontmatter, `type: permanent`, and at minimum an outline + References section.
- [ ] **Firecrawl bootstrap:** Run the ingestion pipeline from `spec-firecrawl-pgvector-pipeline` against 2–3 priority doc sites. Suggested targets: Firecrawl docs (`docs.firecrawl.dev`), MCP spec (`modelcontextprotocol.io`), ADK docs (`adk.dev`). Store results in Supabase `source_pages` + `source_chunks`.

## Next — Codex (Auditor / Implementer)

- [ ] **Rust Tier-0 scaffold:** Scaffold the binary project from `rust-tier-0-patterns`. Create `Cargo.toml` with dependencies: `tokio` (full), `serde`/`serde_json`, `thiserror`, `hmac`, `sha2`, `hex`, `chrono`. Implement `Capability` enum, `CapabilitySet`, `StateTransfer`, and `gate_delegation()` from the spec verbatim. Run the included unit tests.
- [ ] **Memory MCP scaffold:** Implement the Python Memory MCP Server from `spec-memory-mcp` §6. The blueprint is ~150 lines using `mcp` SDK + `sqlite3`. Wire the FTS5 schema init, the three tool handlers (`commit_memory`, `search_memories`, `prune_memory`), and session cleanup on disconnect. Verify all three tools return valid MCP `TextContent` responses.
- [ ] **Chunker implementation:** Implement the `chunk_markdown()` and `split_by_heading()` functions from `spec-firecrawl-pgvector-pipeline` §3.1. Add pytest coverage for edge cases: no headings (preamble only), heading with empty body, chunk smaller than min (50 words), overlap correctness.
- [ ] **Gardening audit run:** Execute the Thin Node and Orphan SQL queries from `spec-knowledge-gardening` §2.1–2.2 against the current vault DB. Produce a Triage List in `02_System/log.md` with candidates and suggested actions. Do not execute remediation — list only for human/Claude review.

## Blocked

- 

## Later

- [ ] Add basic Markdown rendering to PoShWiKi (console or external viewer).
- [ ] `match_documents()` RPC as MCP Tool `search_sources` — expose Firecrawl pipeline via MCP so any agent can query external source chunks.

## Blocked

- 

## Later

- [ ] Revise `Get-WikiPage` to handle multiple versions (if out-of-scope for now).

## Risks

- 

## Done

- [x] Phase 1: Dependency Management (SQLite DLLs).
- [x] Phase 2: Core Module Development (CRUD).
- [x] Phase 3: CLI Implementation (`wiki.ps1`).
- [x] Phase 4: Verification (Integrated tests pass in PowerShell 7).
- [x] Repo hardening: local git repo on `main`, `.gitignore`, manifest, README, and smoke test.
- [x] Added `list` command and plain object JSON output.

## Release / Pause State

- Current seam: Basic CRUD, search, list, docs, and smoke verification are functional.
- Minimum next step: Use it for actual notes or add Markdown-friendly display/rendering.
