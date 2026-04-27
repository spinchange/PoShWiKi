# Handoff

## Project State

PoShWiKi is fully functional as a "smallest honest version." All core CRUD operations (get, set, find, rm, stats) are operational and verified in PowerShell 7.

## Completed

- Core SQLite module with dependency management (working cross-platform runtimes).
- CLI entry point (`wiki.ps1`) for basic management.
- Fixed a critical PowerShell unrolling bug in `Invoke-WikiSql`.
- Verified and initialized the database with test data.

## Claude Session — 2026-04-27 (3 sessions)

**Session 1 — Synthesis (claude-synthesis-handoff):**
- 5 Literature notes: `lit-typescript-handbook`, `lit-rust-programming-language`, `lit-mcp-architecture`, `lit-python-standard-library`, `lit-skills-agent-behavior`
- Community Report Generator spec (`community-report-generator.md`): full algorithm — hybrid edge weights (α=0.6), k-means L1 / Leiden L2, agent prompt schema, registration workflow, regeneration triggers
- 7 Multi-Agent Pattern Language notes (permanent): `pattern-dynamic-delegation`, `pattern-state-transfer`, `pattern-capability-gating`, `pattern-parallel-fan-out`, `pattern-agent-as-tool`, `pattern-progressive-handoff`, `pattern-human-in-the-loop` — synthesizing ADK + Swarm + A2A into model-agnostic standards

**Session 2 — Blueprint (claude-blueprint-handoff):**
- `spec-memory-mcp.md`: Full SQLite-backed Memory MCP Server — two scopes (session volatile / vault persistent), FTS5 + cosine hybrid search, `commit_memory` / `search_memories` / `prune_memory` tools with complete C# and Python implementations
- `rust-tier-0-patterns.md`: Rust safe-core patterns — serializable `Capability` enum, `CapabilitySet` with `meet()`/`join()`/`authorize()`, `StateTransfer` serde validation, `gate_delegation()`/`gate_handoff()` with unit tests, `GuardrailProof` HMAC bridge for cross-process token verification

**Session 3 — Gardening & Sources (claude-gardening-visuals-handoff + research):**
- `spec-knowledge-gardening.md`: Five failure modes (thin node, orphan, concept drift, blob, shadow duplicate), SQL/Python detection queries, five remediation actions, four-phase session protocol with verification queries, cadence triggers
- `spec-visual-vault-language.md`: Mermaid.js standards — shared classDef palette, four diagram patterns with rendered examples (flowchart LR/TB, stateDiagram-v2, lattice TB, sequenceDiagram)
- `spec-firecrawl-pgvector-pipeline.md`: Research-grounded external source ingestion — Firecrawl v2 API shapes, two-table Postgres schema with full provenance, HNSW cosine index, heading-aware hybrid chunking, two-level dedup (ETag + SHA-256), `match_documents()` RPC, Python ingestion skeleton

Total: **17 new notes** across 3 sessions. All committed to `main`.

## In Progress

- Stub notes flagged as missing: `workflow-agents.md`, `adk-session-service.md`, `multi-agent-patterns-moc.md`

## Blocked

- None.

## Known Risks

- Dependency on PowerShell 7 (`pwsh`): The project cannot run in Windows PowerShell 5.1 due to `.NET Core` requirements.

## Important Context

- **PowerShell 7 Requirement:** You MUST use `pwsh` to run the wiki. Windows PowerShell 5.1 will fail to load the assemblies.
- **Unrolling Fix:** The `Invoke-WikiSql` function uses `return ,$table` to prevent PowerShell from unrolling its results.

## Next Recommended Step

Begin using the wiki for your knowledge base. Run `./wiki.ps1 stats` to confirm readiness. Consider adding a `list` command for easier discovery of existing pages.

## Verification

- `stats`: Success.
- `save`: Success.
- `get`: Success.
- `find`: Success.
- `rm`: Success.

## Key Artifacts

- `./wiki.ps1`: Primary entry point.
- `./PoShWiKi.psm1`: Core module.
- `./wiki.db`: The SQLite database.
