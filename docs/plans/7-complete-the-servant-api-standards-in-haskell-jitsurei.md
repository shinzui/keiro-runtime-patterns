---
id: 7
slug: complete-the-servant-api-standards-in-haskell-jitsurei
title: "Complete the servant API standards in haskell-jitsurei"
kind: exec-plan
created_at: 2026-07-22T14:55:29Z
intention: intention_01ky5agv9gehqa8dbw03cdcpwv
master_plan: "docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md"
---

# Complete the servant API standards in haskell-jitsurei

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ (in the
repository being edited, if it keeps ADRs) in the same change.


## Purpose / Big Picture

The repository `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei` is the fleet's curated
corpus of Haskell implementation standards. Its `api/` directory currently holds three
documents — `servant-routes.md` (NamedRoutes records + MultiVerb response lists),
`openapi-from-types.md` (derive OpenAPI 3.1 from the route types), and
`rfc7807-problem-details.md` (the one error-body shape) — which together define how a
servant service declares its contract and its errors. Four load-bearing concerns are
still undocumented: how to wire OpenTelemetry tracing into a servant/warp service, how
to log requests in production (today the fleet reality is wai-extra's dev-only
`logStdoutDev` and no tracing — the danwa reference service runs exactly that), how to
paginate list endpoints (the `relay-pagination` library exists and is fully tested, but
no standard mandates it), and what Kubernetes liveness/readiness endpoints must look
like.

After this plan is implemented, a developer (or agent) building any of the roughly
twenty upcoming keiro-based services can open
`/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/api/` and find four new prescriptive
documents — `opentelemetry-integration.md`, `request-logging.md`, `relay-pagination.md`,
and `health-endpoints.md` — each verified symbol-by-symbol against the library source it
describes, each registered in the repository's `mori.dhall` so `mori` can discover it,
and each cross-linked from the existing API documents so the whole api/ family reads as
one standard. Success is observable: `dhall --file mori.dhall` type-checks with four new
DocRef entries, every module and function name the docs cite greps to a real definition
in its source repository, and every relative cross-link resolves to a file on disk.

The work happens entirely in `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei` (plus one
throwaway prototype in a scratch directory). This plan file lives in the coordination
repository `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns` and is the only file
this plan changes there. Commits in haskell-jitsurei follow Conventional Commits and
carry the MasterPlan/ExecPlan git trailers described in Concrete Steps.


## Progress

- [ ] Milestone 1: `api/opentelemetry-integration.md` written and symbol-verified.
- [ ] Milestone 2: request-logging middleware prototyped in the scratch directory; trace-id correlation demonstrated end to end.
- [ ] Milestone 2: `api/request-logging.md` written and symbol-verified.
- [ ] Milestone 3: `api/relay-pagination.md` written and symbol-verified.
- [ ] Milestone 4: `api/health-endpoints.md` written and symbol-verified.
- [ ] Milestone 5: four DocRef entries added to `mori.dhall`; `dhall --file mori.dhall` type-checks.
- [ ] Milestone 5: "Related Patterns" section appended to `api/servant-routes.md`; all relative links in all api/ docs resolve.
- [ ] Milestone 5: full validation pass run (symbol greps, doc-shape checks, link checks); results recorded here.
- [ ] Living sections updated; Outcomes & Retrospective written.


## Surprises & Discoveries

Findings from the research pass that shaped this plan (evidence paths inline; keep
adding entries during implementation):

- wai-extra's JSON request logger is unsafe for production as-is:
  `Network.Wai.Middleware.RequestLogger.JSON.formatAsJSON` logs the **entire request
  body** (`"body" .= decodeUtf8With lenientDecode (S8.concat reqBody)`, line 126 of
  `/Users/shinzui/Keikaku/hub/haskell/wai-project/wai/wai-extra/Network/Wai/Middleware/RequestLogger/JSON.hs`)
  and the response body for statuses >= 400; header redaction covers only
  `Cookie`/`Set-Cookie` (lines 167–179) — `Authorization` passes through in clear. The
  module's own haddock says the representation "is not an API, and may change at any
  time". This is why Milestone 2 standardizes a thin custom middleware instead.
- The hs-opentelemetry ecosystem has **no request-logging middleware**. Its
  `instrumentation/` tree ships a span-creating WAI middleware
  (`hs-opentelemetry-instrumentation-wai`) and application-logger bridges for co-log,
  katip, and monad-logger (which forward app log records into the OTel Logs pipeline
  with automatic trace correlation), but nothing that emits a per-request log line.
- `keiro-runtime-jitsurei` — the fleet's OpenTelemetry reference — has **no HTTP
  server** (no wai/warp dependency in either service's cabal file; entry points are
  CLI-driven workers). Its `HospitalCapacity.Telemetry` module is therefore the
  reference for the SDK bracket and for passing the tracer into keiro, while the WAI
  middleware half of the standard is verified directly against
  `hs-opentelemetry-instrumentation-wai` source.
- `api/servant-routes.md` currently has **no "Related Patterns" section** (it ends at
  "Anti-Patterns to Avoid"); the corpus style calls for one, and Milestone 5 adds it.
- `RelayPage`'s built-in 400 response body is `RelayPageError` (JSON, plain
  `application/json`), not an RFC 7807 problem document — a deliberate library contract
  that conflicts on the surface with `rfc7807-problem-details.md`. Resolved by a
  recorded exemption; see the Decision Log.


## Decision Log

- Decision: `api/request-logging.md` standardizes a thin, hand-written WAI middleware
  (one structured JSON line per request, trace-correlated, no body capture), written
  directly against the `wai` types rather than through wai-extra's `mkRequestLogger`.
  wai-extra remains a dependency non-requirement.
  Rationale: wai-extra's `formatAsJSON` logs full request bodies and leaks
  `Authorization` (see Surprises & Discoveries); its formatter callback interface
  (`OutputFormatterWithDetails`) is body-capture-shaped by design. The hs-opentelemetry
  ecosystem offers no request logger. With no established ecosystem choice, the fleet
  standardizes its own ~40-line middleware, prototyped in Milestone 2 before the doc is
  finalized.
  Date: 2026-07-22

- Decision: the four new DocRefs use `Schema.DocKind.Cookbook` and
  `Schema.DocAudience.Module`.
  Rationale: every existing haskell-jitsurei DocRef is `Cookbook`, and the three
  existing api-* entries are `audience = Module`; matching the siblings keeps the
  registry uniform.
  Date: 2026-07-22

- Decision: `RelayPage`'s 400 body (`RelayPageError`) is documented as a recorded
  exemption from the RFC 7807 error-body standard, and handler-produced 400s on
  paginated endpoints (rejected cursors) use `RelayPageError` too, so one endpoint has
  one 400 dialect.
  Rationale: the combinator's `HasServer` instance emits `RelayPageError` from inside
  servant's routing layer (`pageRequestError400`, before any handler runs), its codes
  are a stable library contract with a conformance golden, and
  `rfc7807-problem-details.md` already provides the exemption mechanism ("
  protocol-mandated shapes win"; exempt by name in conformance tests). Splitting the
  endpoint's 400s across two body shapes would be worse than either shape alone.
  Date: 2026-07-22

- Decision: the cross-link requirement is satisfied by appending a trailing
  `## Related Patterns` section to `api/servant-routes.md` linking all six sibling api/
  docs, plus each new doc carrying its own Related Patterns section. The two other
  existing docs (`openapi-from-types.md`, `rfc7807-problem-details.md`) are not
  restructured — they already cross-link inline and belong to EP-3/no plan's remit;
  this plan touches them not at all.
  Rationale: minimal, additive edits to existing prose; servant-routes.md is the family
  root and the mandated place for the links.
  Date: 2026-07-22

- Decision: the OpenTelemetry doc instructs services to set
  `OTEL_SEMCONV_STABILITY_OPT_IN=http` (stable HTTP semantic conventions only).
  Rationale: the WAI middleware defaults to legacy-only attribute names "until the next
  major release" (module haddock of `OpenTelemetry.Instrumentation.Wai`); the fleet is
  greenfield on this middleware and should start on the stable names rather than
  migrate later.
  Date: 2026-07-22


## Outcomes & Retrospective

(To be filled during and after implementation. Before marking the plan complete,
distill durable context: this coordination repository has no `docs/adr/` yet — if any
decision here proves durable beyond this plan, seed `docs/adr/` in
keiro-runtime-patterns per the MasterPlan's Integration Points.)


## Context and Orientation

### The repositories involved

Nothing in this section assumes prior knowledge; every path is absolute.

- `/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns` — the coordination repository.
  This plan file lives here (`docs/plans/7-…md`). **`docs/adr/` does not exist in this
  repository** — there are no ADRs to consult; the MasterPlan at
  `docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md` confirms
  this and expects this initiative to seed the first ones. No other file here changes.
- `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei` — where the work happens. A
  documentation-only repository (no Haskell code): directories `api/`, `cli/`, `core/`,
  `mori/`, and the registry file `mori.dhall` at the root. The three existing api/ docs
  are `api/servant-routes.md`, `api/openapi-from-types.md`, and
  `api/rfc7807-problem-details.md`. Read all three before writing anything: the new
  docs must extend them without repeating them, and must match their voice.
- `/Users/shinzui/Keikaku/hub/haskell/hs-opentelemetry-project/hs-opentelemetry` — the
  hs-opentelemetry source tree (packages under `api/`, `sdk/`, `exporters/otlp/`,
  `instrumentation/wai/`, all at version 1.0.0.0 in this corpus). Source of truth for
  every OpenTelemetry symbol the new docs name.
- `/Users/shinzui/Keikaku/bokuno/keiro` — the keiro framework.
  `keiro/src/Keiro/Telemetry.hs` is "the single place keiro reaches for
  hs-opentelemetry-api"; `keiro/src/Keiro/Command.hs` carries the
  `tracer :: Maybe Tracer` option field.
- `/Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei` — the fleet's OpenTelemetry
  reference service pair. `services/hospital-capacity/src/HospitalCapacity/Telemetry.hs`
  is the reference wiring this plan's doc must cite.
- `/Users/shinzui/Keikaku/bokuno/relay-pagination` — the pagination library workspace
  (four packages plus `examples/members-server`). Source of truth for Milestone 3.
- `/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku` — the kiroku event store;
  `kiroku-metrics/src/Kiroku/Metrics/{Health,Server,Config}.hs` is the health-endpoint
  prior art for Milestone 4.
- `/Users/shinzui/Keikaku/hub/haskell/wai-project/wai/wai-extra` — wai-extra source,
  cited (as the thing being replaced) in Milestone 2.
- `/Users/shinzui/Keikaku/bokuno/danwa` — the DDD reference service, cited as the
  current fleet reality: `danwa-server/src/Danwa/Server/Boot.hs` wraps its WAI app in
  `logStdoutDev` and its worker main runs `runTracingNoop` — dev logging, no tracing.

Never search `/nix/store` or the filesystem root; every dependency source above is
already on disk at the given path (locate others with `mori registry search`).

### Terms used throughout this plan

- **WAI** (Web Application Interface): the Haskell HTTP abstraction. An `Application`
  is `Request -> (Response -> IO ResponseReceived) -> IO ResponseReceived`; a
  **middleware** is `Application -> Application`, a wrapper that sees every request and
  response. warp is the production WAI server; servant compiles route types to a WAI
  `Application`.
- **Span / Tracer / TracerProvider** (OpenTelemetry): a span is one timed, attributed
  operation in a distributed trace; a tracer creates spans; the TracerProvider owns
  exporter pipelines and is the thing you initialize once per process and shut down on
  exit (flushing buffered spans).
- **W3C trace context / `traceparent`**: the standard HTTP header carrying
  trace-id/span-id across process boundaries, so a downstream span becomes a child of
  the upstream one.
- **Semconv**: OpenTelemetry semantic conventions — the standardized attribute names
  (`http.request.method`, `url.path`, …) that make telemetry queryable across services.
- **Keyset (cursor) pagination**: paging by "everything after this row's sort-key
  values" instead of OFFSET; stable under concurrent inserts. **Relay** style means the
  GraphQL-Relay wire shape: `first`/`after`/`last`/`before` parameters, and a
  `Connection` response of `edges` (node + opaque cursor) plus `pageInfo`.
- **Liveness vs readiness** (Kubernetes): liveness answers "is this process alive
  enough to keep running?" (failure ⇒ restart the container); readiness answers "should
  this pod receive traffic?" (failure ⇒ remove from endpoints, no restart).

### The documentation style contract

All four new docs follow the established haskell-jitsurei style, observable in the
three existing api/ docs: **no YAML frontmatter**; a single `#` H1 title; the opening
paragraph leads with the rule in **bold** (the "bold tagline" — see the first sentence
of `openapi-from-types.md`: "The rule is one sentence: **the OpenAPI document is
derived …**"); prescriptive, rule-first prose; code samples always in fenced blocks
with a language tag (`haskell`, `cabal`, `bash`, `json`, `yaml`, `text`), using
`-- CORRECT` / `-- WRONG` contrast pairs where a mistake is likely; relative Markdown
links between sibling docs; and a trailing `## Related Patterns` section. Docs state
versions they verified against and tell the reader to re-verify the released version on
Hackage before pinning (the local corpus may lag upstream).

### What "symbol-verified" means in this plan

Every module name, function name, type, field, default value, and file path a doc cites
must be checked against the source tree listed for it in Interfaces and Dependencies —
by opening the file, not from memory. The research below already did this once (line
numbers cited are as of 2026-07-22); the implementer re-runs the greps in Validation and
Acceptance because the sources may have moved.

### No relevant ADRs

`docs/adr/` does not exist in keiro-runtime-patterns (verified: the directory is
absent). haskell-jitsurei has no `docs/adr/` either — it has no `docs/` directory at
all. The two ADR sets that informed the research (relay-pagination's `docs/adr/1..7`,
kiroku's `docs/adr/0001-0003`) belong to those libraries and are cited inside the
relevant milestones rather than summarized here.


## Plan of Work

The work is five milestones: one per document (the request-logging one includes a
prototype), then registration, cross-linking, and validation. Milestones 1–4 are
independent of each other and may be done in any order; Milestone 5 must come last.
Each doc milestone ends with the same three checks: the doc opens with H1 + bold
tagline, every named symbol greps in its source repo, and every relative link resolves.

### Milestone 1 — `api/opentelemetry-integration.md`

Scope: write the standard for wiring hs-opentelemetry into a servant/warp service, from
process start to the outbox. At the end of this milestone the file
`/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/api/opentelemetry-integration.md`
exists, covers the six areas below, and passes the symbol greps in Validation and
Acceptance. There is nothing to run beyond the greps; acceptance is the checks passing.

The doc's bold tagline should be to the effect of: **every service initializes one
TracerProvider in a bracket in `main`, traces every request with the WAI middleware,
and hands the same tracer to keiro — so one `traceparent` connects the HTTP request to
the command to the outbox row.**

The six areas, with the verified facts the doc must state (all against
`/Users/shinzui/Keikaku/hub/haskell/hs-opentelemetry-project/hs-opentelemetry` unless
noted):

**1. The SDK bracket in `main`.** The SDK entry points live in module
`OpenTelemetry.Trace` of package `hs-opentelemetry-sdk` (1.0.0.0 in the corpus):
`initializeGlobalTracerProvider :: IO TracerProvider` (creates the provider from
environment configuration *and installs it as the process-global provider* — the global
install is what lets the WAI middleware and any instrumentation find it),
`forceFlushTracerProvider`, and `shutdownTracerProvider` (both take the provider and a
`Maybe` timeout; shutdown flushes remaining spans). The mandated shape is a `bracket`
so spans are flushed even on exceptions, and the same for the meter provider
(`OpenTelemetry.Metric.initializeGlobalMeterProvider` / `shutdownMeterProvider` from
the same package). The doc shows the pattern as code:

```haskell
main :: IO ()
main =
  bracket initializeGlobalTracerProvider flushAndShutdown $ \provider ->
    bracket OTelMetric.initializeGlobalMeterProvider
            (\mp -> void (OTelMetric.shutdownMeterProvider mp Nothing)) $ \_ -> do
      let tracer = makeTracer provider instrumentationLib tracerOptions
      otelMiddleware <- newOpenTelemetryWaiMiddleware   -- AFTER the global install
      Warp.run 8080 (otelMiddleware (requestLogMiddleware (app tracer)))
  where
    flushAndShutdown tp = void (forceFlushTracerProvider tp Nothing)
                       *> void (shutdownTracerProvider tp Nothing)
```

The fleet reference for exactly this bracket (including the flush-then-shutdown order
and the enabled/disabled switch) is
`/Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei/services/hospital-capacity/src/HospitalCapacity/Telemetry.hs`
(`withTelemetry`, `flushAndShutdownTracerProvider`; the module also shows an explicit
`TelemetryMode` toggle driven by `SEIHOU_TRACING_ENABLED` with `OTEL_SDK_DISABLED`
winning, and `withOtelServiceName` setting `OTEL_SERVICE_NAME` around initialization).
The doc must cite that file path and note one caveat: that repository is CLI/worker
shaped with **no HTTP server**, so it demonstrates everything except the WAI middleware
step.

**2. Configuration is environment-first.** The SDK reads `OTEL_SERVICE_NAME`,
`OTEL_RESOURCE_ATTRIBUTES`, `OTEL_SDK_DISABLED`, `OTEL_TRACES_SAMPLER` (documented in
the module haddock of `sdk/src/OpenTelemetry/Trace.hs`); the OTLP exporter reads
`OTEL_EXPORTER_OTLP_ENDPOINT` (default `http://localhost:4318` for HTTP),
per-signal `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`, and `OTEL_EXPORTER_OTLP_PROTOCOL`
(verified in `exporters/otlp/src/OpenTelemetry/Exporter/OTLP/Internal/Config.hs`).
Kubernetes manifests set these; code does not hardcode endpoints. One sharp edge worth
repeating from
`/Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei/docs/observability.md`: at the
pinned revision the exporter appends `/v1/traces` itself — endpoint variables must be
host URLs without that suffix.

**3. The WAI middleware and its placement.** Package
`hs-opentelemetry-instrumentation-wai` (1.0.0.0), module
`OpenTelemetry.Instrumentation.Wai`, exports exactly three things:
`newOpenTelemetryWaiMiddleware :: IO Middleware` (reads the *global* tracer and meter
providers — hence "create it after `initializeGlobalTracerProvider`"),
`newOpenTelemetryWaiMiddleware' :: TracerProvider -> Meter -> IO Middleware`, and
`requestContext :: Request -> Maybe Context` (retrieves the OTel context the middleware
stashed in the request's vault). Per request the middleware: extracts W3C context from
incoming headers via the global propagator, so `traceparent` from an upstream caller
makes the server span a child; opens a `Server`-kind span; attaches the context
thread-locally for the request's duration (bracketed, so warp's keep-alive thread reuse
cannot leak context between requests); records semconv attributes and the
`http.server.request.duration` / `http.server.active_requests` /
`http.server.request.count` metrics; injects trace context into response headers; and
marks the span `Error` on 5xx. Placement rule: the OTel middleware is the **outermost**
middleware, so everything inside — including the request logger of
`api/request-logging.md` — runs with the span context attached and can correlate.
Attribute naming: instruct services to set `OTEL_SEMCONV_STABILITY_OPT_IN=http` (stable
names only; the middleware's default is legacy names — see Decision Log).

**4. Handing the tracer to keiro.** The service builds one tracer
(`makeTracer provider …`) and passes that same value everywhere. keiro's command runner
accepts it: `RunCommandOptions` has `tracer :: Maybe Tracer`
(`/Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/Command.hs`, field at line ~237),
and every `Keiro.Telemetry` helper (`withCommandSpan`, `withProducerSpan`,
`withConsumerSpan`, `withWorkflowSpan`) degrades to a pass-through under `Nothing`, so
OTel stays opt-in. The reference: `commandOptionsWithTelemetry tracer =
defaultRunCommandOptions {Command.tracer = tracer}` in
`/Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei/services/hospital-capacity/src/HospitalCapacity/Store.hs`
(around line 531), with the tracer threaded from `withTelemetry` in
`app/HospitalCapacityWorker.hs`. Metrics ride the same options via
`Keiro.Telemetry.newKeiroMetrics meter` (see `serviceMetricsFromGlobalProvider` in the
Telemetry module). Because a servant handler runs on the request thread with the
middleware's context attached, the command span created inside `runCommand` becomes a
child of the HTTP server span with no extra plumbing — that is the payoff of "same
tracer, same thread-local context".

**5. Context flows to the outbox.** State the end-to-end guarantee and where it comes
from: keiro persists `traceparent`/`tracestate` on outbox and inbox rows, and the
integration-event envelope carries `traceContext`; `Keiro.Telemetry` provides
`traceContextFromCurrentSpan`, `traceContextFromHeaders`, and `injectTraceContext`
(export list, `/Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/Telemetry.hs` lines
~29–38). So the trace begun by the WAI middleware continues through the command, into
the outbox row, and across Kafka into the consuming service — one `traceparent` end to
end. keiro pins `hs-opentelemetry-api >=1.0 && <1.1`; a service must resolve one
consistent hs-opentelemetry version across itself and keiro.

**6. Fleet rule.** `keiro-runtime-jitsurei`'s `HospitalCapacity.Telemetry` is the
canonical wiring to copy (cite the three concrete file paths from areas 1 and 4). danwa
is the anti-reference (`runTracingNoop`, no OTel) and is being refactored.

The doc ends with a Related Patterns section linking `./servant-routes.md`,
`./request-logging.md`, and `./health-endpoints.md`.

### Milestone 2 — prototype, then `api/request-logging.md`

Scope: replace the dev-only `logStdoutDev` idiom with a production request-logging
standard. This milestone has two parts: a runnable prototype proving the recommended
middleware compiles and correlates with traces, then the document. At the end, the
prototype transcript is captured in this plan (Surprises & Discoveries or Progress
notes) and
`/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/api/request-logging.md` exists.

The doc's bold tagline: **`logStdoutDev` is for development only; a production service
emits exactly one structured JSON line per request, carrying the trace id of the span
that served it, and never logs bodies or credentials.**

**Why not the obvious candidates (the doc must show its work).** wai-extra
(`/Users/shinzui/Keikaku/hub/haskell/wai-project/wai/wai-extra`) offers
`Network.Wai.Middleware.RequestLogger` (`mkRequestLogger`, `logStdout`, `logStdoutDev`,
`OutputFormat` with `CustomOutputFormatWithDetails`) and a JSON formatter
`Network.Wai.Middleware.RequestLogger.JSON.formatAsJSON`. The doc rejects the JSON
formatter with the evidence from Surprises & Discoveries: it logs the full request body
and 4xx/5xx response bodies, redacts only `Cookie`/`Set-Cookie` (not `Authorization`),
has no trace correlation, and its own haddock disclaims format stability. The
hs-opentelemetry ecosystem ships application-logger bridges
(`hs-opentelemetry-instrumentation-co-log` / `-katip` / `-monad-logger`, each under
`instrumentation/` in the hs-opentelemetry tree) — the doc should mention them as the
standard for **application** logs (they forward log records into the OTel Logs pipeline
with automatic trace correlation) while being explicit that none of them is a request
logger. Ecosystem conclusion: no established choice exists, so the fleet standardizes a
thin custom WAI middleware, small enough to vendor into each service (or a future
shared package — the doc should not invent a package name; it prescribes the shape).

**The standardized middleware shape.** One `Middleware` that, per request: captures a
monotonic start time; calls the inner app; in the respond continuation builds one aeson
object and writes it with a newline to stdout via a single atomic emission
(`BS.hPutStr` of the fully rendered line — interleaving-safe); never reads the request
body. Fields: `time` (ISO-8601 UTC), `method`, `path` (from `rawPathInfo`), `status`,
`duration_ms`, `trace_id` and `span_id` when a span context is available, and
`user_agent`. Trace correlation mechanics (all in `hs-opentelemetry-api`):
`OpenTelemetry.Instrumentation.Wai.requestContext :: Request -> Maybe Context` (or
thread-local `OpenTelemetry.Context.ThreadLocal.getContext`), then
`OpenTelemetry.Context.lookupSpan :: Context -> Maybe Span`, then
`OpenTelemetry.Trace.Core.getSpanContext :: MonadIO m => Span -> m SpanContext`, whose
`traceId`/`spanId` fields render to lowercase hex via
`OpenTelemetry.Trace.Id.traceIdBaseEncodedText` / `spanIdBaseEncodedText` (Base16).
Placement: inside the OTel middleware (see Milestone 1 area 3), outside the servant
app. The doc includes the middleware in full as a `haskell` block — it is the standard,
so the reader copies it rather than re-deriving it.

**What to log and what never to log.** Prescriptive lists in prose: log
method/path/status/duration/trace ids/user agent; never log request or response bodies
(PII — the fleet's problem-details bodies can echo identifiers), never `Authorization`,
`Cookie`, or any header not on a short allowlist, and never the raw query string by
default (tokens land in query params; log the path only, and add specific whitelisted
params consciously). Health-probe endpoints (`/health/live`, `/health/ready`) may be
excluded from logging to avoid probe noise — the middleware takes a path predicate.

**The prototype (do this before finalizing the doc).** In the scratch directory
`/private/tmp/claude-501/-Users-shinzui-Keikaku-bokuno-keiro-runtime-patterns/de3eb3fb-e0fd-40c8-9430-4f77450f8288/scratchpad/reqlog-prototype`,
create a minimal cabal project (one `Main.hs`) that: initializes the SDK bracket,
builds `newOpenTelemetryWaiMiddleware`, wraps a trivial servant (or plain WAI) app with
otel-then-logger, and runs warp. Drive it:

```bash
curl -s -H 'traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01' \
  http://localhost:8080/hello
```

Acceptance for the prototype: the emitted log line is one JSON object whose `trace_id`
equals `4bf92f3577b34da6a3ce929d0e0e4736` (proving both the middleware ordering and the
hex encoding), and a request without a `traceparent` still logs with a fresh trace id.
If the corpus packages are awkward to resolve in a scratch project, pin them as local
`packages:` entries pointing into the hs-opentelemetry tree; the prototype is
throwaway and is never committed anywhere. Record the observed log line in this plan.
If the prototype reveals API differences (e.g., renamed exports), fix the doc *and*
update the Decision Log — the doc must describe what actually ran.

The doc's fleet-reality paragraph names danwa: `logStdoutDev` in
`danwa-server/src/Danwa/Server/Boot.hs` is the `-- WRONG` example. Related Patterns:
`./opentelemetry-integration.md`, `./servant-routes.md`, `./health-endpoints.md`
(probe-noise exclusion).

### Milestone 3 — `api/relay-pagination.md`

Scope: write THE pagination standard for list endpoints, against
`/Users/shinzui/Keikaku/bokuno/relay-pagination` (four packages, all 0.1.0.0: core
`relay-pagination`, `relay-pagination-servant`, `relay-pagination-hasql`,
`relay-pagination-conformance`, plus `examples/members-server`). All symbols below were
verified against that tree on 2026-07-22.

The bold tagline: **every list endpoint paginates with `RelayPage`, answers a
`Connection` on 200 and a `RelayPageError` on 400 via `MultiVerb`, drives the database
through a `SortSpec` keyset query — and ships a conformance test proving no row is
skipped or duplicated.**

The doc covers, in order:

**The route shape.** `RelayPage (defSize :: Nat) (maxSize :: Nat)` from
`Relay.Pagination.Servant` (e.g. `RelayPage 20 100 :> …`) declares the four Relay query
parameters `first`/`after`/`last`/`before`; its `HasServer` instance validates them and
passes an already-validated `PageRequest` to the handler (`ServerT = PageRequest ->
ServerT api m`), rejecting bad input with a 400 **before the handler runs**
(`pageRequestError400`). Validation is a strict subset of Relay: `first`+`last`
together is rejected, oversize is rejected rather than clamped
(`Relay.Pagination.Request.mkPageRequest`; error type `PageRequestError`). The terminal
verb is a `MultiVerb 'GET '[JSON]` whose response list is exactly
`'[Respond 200 … (Connection a), Respond 400 … RelayPageError]` with a **hand-written
`AsUnion`** — cite `api/servant-routes.md` for why hand-written, and show the
members-server result sum (`MemberPageOk`/`MemberPageBadRequest`, from
`examples/members-server/src/Example/Members/Api.hs`). `RelayPageError`
(`{code, message, retryable, parameter}`) has five stable codes: `invalid_integer`,
`invalid_cursor`, `mixed_pagination_directions`, `negative_page_size`,
`page_size_too_large`. State the RFC 7807 exemption and its rationale (Decision Log
entry above) explicitly in the doc, the way `rfc7807-problem-details.md` records
exemptions.

**Cursors and fingerprints.** `Cursor` is opaque unpadded base64url over a versioned
payload (`CursorPayload {version, fingerprint, keys}`); key values are the closed sum
`KeyValue` (`KvInt`/`KvText`/`KvUuid`/`KvTimestampMicros`/`KvBool`/`KvNull`) —
**deliberately no Double**; timestamps are integer microseconds UTC. The fingerprint
(`sortSpecFingerprint :: SortSpec row -> Word32`, FNV-1a over column expr + direction +
codec tag) ties every cursor to one exact sort spec: change the ORDER BY and
outstanding cursors are rejected at decode with a typed 400 (`invalid_cursor`), never
silently misread. That is a feature; the doc says so.

**The database contract.** From `Relay.Pagination.Hasql`:
`paginate :: SortSpec row -> PageRequest -> Snippet -> Decoders.Row row -> Either
CursorError (Statement () (Connection row))`. The `SortSpec` is a non-empty list of
`KeyColumn {columnExpr, sortDir, extract, codec}` with three hard rules the library
**cannot check** (the conformance suite is the proof): the last column must be unique
per row; every column NOT NULL (v1); and `columnExpr` is spliced verbatim into SQL —
**trusted developer text only, never user input** (the SQL-injection warning is in
`SortSpec.hs`). Built-in codecs: `int8Key`, `textKey`, `uuidKey`, `boolKey`,
`timestamptzKey`. The base query is a plain `SELECT … FROM … WHERE <filters>` snippet
with no ORDER BY/LIMIT; the engine wraps it (`… AS rp_base`), adds the expanded
lexicographic keyset predicate (correct for mixed Asc/Desc, unlike a row-value
comparison), orders, and fetches pageSize+1 as a probe row. Show one golden SQL line
from `relay-pagination-hasql/test/golden/` as a `text` block. Cursors are minted in
Haskell from decoded rows (`mintCursor`), never in SQL.

**The conformance requirement — mandatory per endpoint.** From
`Relay.Pagination.Conformance`: `type FetchPage row = PageRequest -> IO (Connection
row)`; `checkConformance :: (Ord key, Show key) => ConformanceConfig -> (row -> key) ->
FetchPage row -> [row] -> IO ConformanceReport` and the tasty wrapper `testConformance`
(`Tasty.hs`). The caller supplies the full expected result set in canonical order — an
**in-memory comparator that mirrors the SQL sort spec** (members-server:
`canonicalOrder :: Member -> Member -> Ordering`, built as `comparing` on
`Down createdAt` then `comparing` on `id`, in `src/Example/Members/Domain.hs`,
mirroring `ORDER BY created_at DESC, id ASC`). The
six invariants (Completeness, BackwardSymmetry, BoundaryHonesty, CursorDeterminism,
EdgeOrderInvariance, PageInfoCursorConsistency) each map to a real production failure;
name them. The fleet rule in one sentence: **an endpoint without a conformance test is
not a paginated endpoint; it is a bug generator with query parameters.**

**The end-to-end example.** Walk the members-server vertical:
`examples/members-server/src/Example/Members/{Domain,Api,Query,Handler}.hs` and
`test/Main.hs` — domain type with `canonicalOrder` next to it; `memberSort` SortSpec +
`baseQuery` snippet; handler pattern
`case paginate memberSort pageRequest baseQuery decoder of Left err ->
MemberPageBadRequest (cursorRejected …); Right stmt -> MemberPageOk <$> run stmt`; the
conformance test booting the real app over warp and driving it through the typed
servant client, plus typed 400 assertions. Cite the paths; excerpt only the endpoint
type and the handler case.

**Packaging note.** `relay-pagination-servant` depends on the `openapi-hs` /
`servant-openapi-hs` forks (OpenAPI 3.1 + `HasOpenApi` for `MultiVerb`) and is blocked
from Hackage until they publish; consume it via `source-repository-package` pins, one
tag across the cohort — same rule and same reason as `api/openapi-from-types.md`, link
it. `Relay.Pagination.Servant.OpenApi` is the canonical sole home of the OpenAPI orphan
instances; importing it is what makes the four query params and schemas appear in the
generated document.

Related Patterns: `./servant-routes.md`, `./openapi-from-types.md`,
`./rfc7807-problem-details.md`.

### Milestone 4 — `api/health-endpoints.md`

Scope: the Kubernetes liveness/readiness standard for servant services, with
kiroku-metrics as prior art. At the end
`/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/api/health-endpoints.md` exists.

Bold tagline: **every service serves `/health/live` (is the process alive) and
`/health/ready` (should it receive traffic); liveness never checks dependencies,
readiness checks exactly the dependencies whose failure this pod's restart cannot
fix.**

Content:

**Semantics first.** Liveness failing makes Kubernetes restart the container — so it
must test only that the process can respond (an in-process check with a timeout; the
kiroku-metrics precedent is "can we take a metrics snapshot within
`livenessTimeoutUs`"). Putting a DB ping in liveness turns a database outage into a
fleet-wide restart storm; this is the doc's central `-- WRONG`. Readiness failing only
removes the pod from service endpoints — so it checks the things that make requests
servable: a database ping, and for event-sourced services, subscription lag under a
threshold. Prior art to cite by path:
`/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku/kiroku-metrics/src/Kiroku/Metrics/Health.hs`
(built-in `postgresPing` issuing `SELECT 1` through the store pool; `checkReadiness`
fails on any subscription stopped by overflow or lagging beyond the threshold) and
`Config.hs` (`readinessMaxLag :: Int64`, default `10_000` events — the Kiroku analogue
of Marten's `maxEventLag`); routes `/health`, `/health/live`, `/health/ready` in
`Server.hs`. Also state what readiness must NOT check: downstream HTTP services and
Kafka brokers (the outbox absorbs broker outages; failing readiness for them just
cascades the outage).

**The NamedRoutes shape.** Consistent with `api/servant-routes.md`: a `HealthApi mode`
record mounted at `"health"` on the umbrella record, fields `live` and `ready`, each a
GET returning a small JSON status body; 200 when passing, 503 with a structured probe
body (which check failed, since when) when not. Per
`rfc7807-problem-details.md`'s "Where Applicable Ends", a 503 probe body is a **status
report, not an error** — no problem document, and the probe routes are exempted by name
in RFC 7807 conformance tests. Handlers take the checks as injected `IO` actions so
tests can force either verdict. Give the record and one handler as a `haskell` block,
and note these endpoints are excluded from request logging (link
`./request-logging.md`).

**The Kubernetes side.** A short `yaml` block showing `livenessProbe` /
`readinessProbe` `httpGet` stanzas against the two paths, with sane defaults
(`periodSeconds`, `failureThreshold`, and an `initialDelaySeconds`-versus-startupProbe
note). Then one integration paragraph: probes are the *runtime* gate; the *rollout*
gate is configuration validation at startup via settei's check-config mechanism, which
belongs to the settei/Kubernetes operational standard being written by EP-8
(`/Users/shinzui/Keikaku/bokuno/keiro-runtime-patterns/docs/plans/8-document-settei-configuration-and-kubernetes-operational-standards.md`
— reference the standard by name in the doc's prose, not by a cross-repo file link,
since EP-8's doc lives in a different repository and may not exist yet when this doc
lands).

Related Patterns: `./servant-routes.md`, `./rfc7807-problem-details.md`,
`./request-logging.md`, `./opentelemetry-integration.md`.

### Milestone 5 — registration, cross-links, validation

Scope: make the four docs discoverable and prove the corpus is consistent. At the end,
`mori.dhall` carries four new DocRefs and type-checks; `servant-routes.md` ends with a
Related Patterns section; all checks in Validation and Acceptance pass.

**mori.dhall.** Append four `Schema.DocRef::{…}` entries to the `docs` list of
`/Users/shinzui/Keikaku/bokuno/haskell-jitsurei/mori.dhall`, directly after the
`api-rfc7807-problem-details` entry, in this order and with these keys:
`api-opentelemetry-integration`, `api-request-logging`, `api-relay-pagination`,
`api-health-endpoints`. Each entry: `kind = Schema.DocKind.Cookbook`, `audience =
Schema.DocAudience.Module`, `location = Schema.DocLocation.LocalFile "api/<file>.md"`,
and a `description = Some "…"` written in the style of the existing api-* entries — a
single dense sentence naming the load-bearing rules (look at the
`api-rfc7807-problem-details` description as the template for density). Change nothing
else in the file; do not reorder existing entries.

**Cross-links.** Append to `api/servant-routes.md` (after the final
"Don't Reach for `OverloadedRecordDot`…" subsection) a new section:

```markdown
## Related Patterns

- [Generating the OpenAPI Document from Servant Types](./openapi-from-types.md)
- [RFC 7807 Problem Details for Error Bodies](./rfc7807-problem-details.md)
- [OpenTelemetry Integration](./opentelemetry-integration.md)
- [Request Logging](./request-logging.md)
- [Relay Pagination for List Endpoints](./relay-pagination.md)
- [Kubernetes Health Endpoints](./health-endpoints.md)
```

(Adjust the link texts to the H1s actually written.) No other edits to the three
existing docs.

**Validation.** Run everything in Validation and Acceptance, fix what fails, and record
the pass in Progress.


## Concrete Steps

All commands run from `/Users/shinzui/Keikaku/bokuno/haskell-jitsurei` unless stated.

1. Read the three existing docs end to end (they define voice and boundaries):

    ```bash
    ls api/
    # openapi-from-types.md  rfc7807-problem-details.md  servant-routes.md
    ```

2. For each milestone-doc, before writing, open the primary sources listed in
   Interfaces and Dependencies and confirm the symbols this plan cites still exist
   (line numbers may have drifted; names are what matter). Example for Milestone 1:

    ```bash
    grep -n "initializeGlobalTracerProvider\|shutdownTracerProvider" \
      /Users/shinzui/Keikaku/hub/haskell/hs-opentelemetry-project/hs-opentelemetry/sdk/src/OpenTelemetry/Trace.hs
    grep -n "newOpenTelemetryWaiMiddleware\|requestContext" \
      /Users/shinzui/Keikaku/hub/haskell/hs-opentelemetry-project/hs-opentelemetry/instrumentation/wai/src/OpenTelemetry/Instrumentation/Wai.hs
    grep -n "tracer :: !(Maybe Tracer)" \
      /Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/Command.hs
    ```

   Expected: each grep prints at least one matching line. A silent (empty) grep means
   the API moved — stop, re-read the source, and update the doc text and this plan's
   Decision Log before proceeding.

3. Write the docs (Milestones 1–4), one commit per document. Prototype for Milestone 2
   happens in the scratch directory before `request-logging.md` is finalized (see the
   milestone for the curl transcript and acceptance).

4. Edit `mori.dhall` and `api/servant-routes.md` (Milestone 5), then type-check:

    ```bash
    dhall --file mori.dhall > /dev/null && echo OK
    ```

   Expected output: `OK`. Any type error prints a Dhall diagnostic instead — the usual
   mistake is a missing comma before the appended entries or a typo in a union
   alternative (`Schema.DocKind.Cookbook`, `Schema.DocAudience.Module`,
   `Schema.DocLocation.LocalFile`).

5. Run the full validation pass (next section), then update this plan's Progress,
   Surprises & Discoveries, and Decision Log.

6. Commit style — Conventional Commits, in haskell-jitsurei, with both trailers per the
   MasterPlan's Decision Log (plans live in keiro-runtime-patterns; commits elsewhere
   point back at them). One commit per document plus one for registration/cross-links
   is the expected shape:

    ```text
    docs(api): add OpenTelemetry integration standard

    Standard for the SDK bracket, WAI middleware placement, semconv
    opt-in, and passing the tracer into keiro command options.

    MasterPlan: docs/masterplans/1-keiro-runtime-standards-docs-and-seihou-blueprints.md
    ExecPlan: docs/plans/7-complete-the-servant-api-standards-in-haskell-jitsurei.md
    ```

   Do not commit in keiro-runtime-patterns except to update this plan file, and never
   commit the scratch prototype. (During plan *authoring*, no commits at all — this
   step applies to implementation.)


## Validation and Acceptance

Acceptance is behavior a reviewer can observe by running commands, not attributes of
the prose.

**1. The registry type-checks and lists the new docs.** From
`/Users/shinzui/Keikaku/bokuno/haskell-jitsurei`:

```bash
dhall --file mori.dhall > /dev/null && echo TYPECHECK-OK
grep -c 'api-opentelemetry-integration\|api-request-logging\|api-relay-pagination\|api-health-endpoints' mori.dhall
```

Expected: `TYPECHECK-OK` and `4`. Optionally confirm discovery end to end with
`mori registry docs shinzui/haskell-jitsurei` (if the local mori registry syncs from
the file, the four new keys appear; if it shows stale data, the dhall check is the
authority).

**2. Every doc has the required shape.**

```bash
for f in api/opentelemetry-integration.md api/request-logging.md \
         api/relay-pagination.md api/health-endpoints.md; do
  head -1 "$f" | grep -q '^# ' && grep -q '\*\*' <(head -8 "$f") && echo "SHAPE-OK $f"
  grep -q '^## Related Patterns' "$f" && echo "RELATED-OK $f"
done
```

Expected: `SHAPE-OK` and `RELATED-OK` for all four files (H1 on line 1, bold tagline in
the opening lines, trailing Related Patterns section). Also confirm no YAML
frontmatter: `head -1` must be the H1, never `---`.

**3. Every relative cross-link resolves.**

```bash
grep -ho '](\./[^)#]*' api/*.md | sed 's/](\.\///' | sort -u | while read -r f; do
  test -f "api/$f" && echo "LINK-OK $f" || echo "LINK-BROKEN $f"
done
```

Expected: only `LINK-OK` lines (this also re-checks the pre-existing links).

**4. Every named symbol exists at its source.** Spot-check at minimum the following
(each command must print at least one line; run from anywhere):

```bash
# Milestone 1
grep -rn "newOpenTelemetryWaiMiddleware'" /Users/shinzui/Keikaku/hub/haskell/hs-opentelemetry-project/hs-opentelemetry/instrumentation/wai/src
grep -n "OTEL_EXPORTER_OTLP_ENDPOINT" /Users/shinzui/Keikaku/hub/haskell/hs-opentelemetry-project/hs-opentelemetry/exporters/otlp/src/OpenTelemetry/Exporter/OTLP/Internal/Config.hs
grep -n "withTelemetry\|flushAndShutdownTracerProvider" /Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei/services/hospital-capacity/src/HospitalCapacity/Telemetry.hs
grep -n "commandOptionsWithTelemetry" /Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei/services/hospital-capacity/src/HospitalCapacity/Store.hs
grep -n "withCommandSpan\|traceContextFromCurrentSpan" /Users/shinzui/Keikaku/bokuno/keiro/keiro/src/Keiro/Telemetry.hs
# Milestone 2
grep -n "formatAsJSON" /Users/shinzui/Keikaku/hub/haskell/wai-project/wai/wai-extra/Network/Wai/Middleware/RequestLogger/JSON.hs
grep -rn "traceIdBaseEncodedText" /Users/shinzui/Keikaku/hub/haskell/hs-opentelemetry-project/hs-opentelemetry/api/src/OpenTelemetry/Trace/Id.hs
# Milestone 3
grep -n "data RelayPage\|data RelayPageError" /Users/shinzui/Keikaku/bokuno/relay-pagination/relay-pagination-servant/src/Relay/Pagination/Servant.hs
grep -n "paginate ::" /Users/shinzui/Keikaku/bokuno/relay-pagination/relay-pagination-hasql/src/Relay/Pagination/Hasql.hs
grep -n "sortSpecFingerprint\|data KeyColumn" /Users/shinzui/Keikaku/bokuno/relay-pagination/relay-pagination-hasql/src/Relay/Pagination/Hasql/SortSpec.hs
grep -n "testConformance" /Users/shinzui/Keikaku/bokuno/relay-pagination/relay-pagination-conformance/src/Relay/Pagination/Conformance/Tasty.hs
# Milestone 4
grep -n "postgresPing\|readinessMaxLag" /Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku/kiroku-metrics/src/Kiroku/Metrics/Health.hs /Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku/kiroku-metrics/src/Kiroku/Metrics/Config.hs
```

Beyond the spot-check, the discipline is: while writing each doc, every symbol you
type gets a grep before it lands in prose.

**5. The Milestone 2 prototype demonstrated correlation.** The recorded transcript in
this plan shows a JSON log line whose `trace_id` matches the `traceparent` sent by
curl (see Milestone 2 for the exact command and expected value). This is the plan's
one runtime proof; the other milestones are documentation whose "runtime" is the
symbol greps above.

**6. The three pre-existing docs are otherwise untouched.**
`git -C /Users/shinzui/Keikaku/bokuno/haskell-jitsurei diff --stat` during review must
show `api/servant-routes.md` changed only by the appended Related Patterns section, and
`openapi-from-types.md` / `rfc7807-problem-details.md` unchanged.


## Idempotence and Recovery

Every step is additive and re-runnable. Rewriting a doc file overwrites it — safe. The
`mori.dhall` edit is append-only; if a bad edit breaks the type-check, `git -C
/Users/shinzui/Keikaku/bokuno/haskell-jitsurei checkout -- mori.dhall` restores the
last good state and the four entries are re-appended. The validation greps are
read-only. The prototype lives only in the scratch directory and can be deleted and
recreated at will; nothing depends on it after its transcript is recorded here. If
implementation is interrupted, the Progress checklist plus `git status` in
haskell-jitsurei fully determine the resume point: each milestone is one file (plus its
mori entry in Milestone 5), so a partially written doc is simply finished or rewritten.
No step is destructive; there is no migration, no generated artifact, and no ordering
hazard beyond "Milestone 5 last".


## Interfaces and Dependencies

This plan produces documentation, so its "interfaces" are the verified surfaces the
docs describe. Versions are as found in the local corpus on 2026-07-22; the docs should
tell readers to confirm released versions on Hackage before pinning.

- **hs-opentelemetry** (all 1.0.0.0), source
  `/Users/shinzui/Keikaku/hub/haskell/hs-opentelemetry-project/hs-opentelemetry`:
  - `hs-opentelemetry-sdk`, module `OpenTelemetry.Trace`:
    `initializeGlobalTracerProvider :: IO TracerProvider`,
    `withTracerProvider :: (TracerProvider -> IO a) -> IO a`,
    `forceFlushTracerProvider`, `shutdownTracerProvider` (provider + `Maybe` timeout);
    module `OpenTelemetry.Metric`: `initializeGlobalMeterProvider`,
    `shutdownMeterProvider`, `getGlobalMeterProvider`, `getMeter`.
  - `hs-opentelemetry-instrumentation-wai`, module
    `OpenTelemetry.Instrumentation.Wai`:
    `newOpenTelemetryWaiMiddleware :: IO Middleware`,
    `newOpenTelemetryWaiMiddleware' :: TracerProvider -> Meter -> IO Middleware`,
    `requestContext :: Request -> Maybe Context`.
  - `hs-opentelemetry-api`: `OpenTelemetry.Context.lookupSpan :: Context -> Maybe
    Span`; `OpenTelemetry.Trace.Core.getSpanContext` and `SpanContext
    {traceId, spanId, …}`; `OpenTelemetry.Trace.Id.traceIdBaseEncodedText` /
    `spanIdBaseEncodedText`; `makeTracer`, `tracerOptions`, `InstrumentationLibrary`.
  - `hs-opentelemetry-exporter-otlp`: env vars `OTEL_EXPORTER_OTLP_ENDPOINT`
    (default `http://localhost:4318` HTTP), `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`,
    `OTEL_EXPORTER_OTLP_PROTOCOL` (in
    `src/OpenTelemetry/Exporter/OTLP/Internal/Config.hs`).
  - Logging bridges (mention-only): `hs-opentelemetry-instrumentation-co-log`
    (`OpenTelemetry.Instrumentation.CoLog.otelLogAction`), `-katip`, `-monad-logger`.
- **keiro** (0.3.0.0), source `/Users/shinzui/Keikaku/bokuno/keiro`:
  `Keiro.Command.RunCommandOptions.tracer :: Maybe Tracer`; `Keiro.Telemetry`
  (`withCommandSpan`, `withProducerSpan`, `withConsumerSpan`, `withWorkflowSpan`,
  `traceContextFromCurrentSpan`, `traceContextFromHeaders`, `injectTraceContext`,
  `KeiroMetrics`, `newKeiroMetrics`); pin `hs-opentelemetry-api >=1.0 && <1.1`.
- **keiro-runtime-jitsurei**, source
  `/Users/shinzui/Keikaku/bokuno/keiro-runtime-jitsurei`: reference files
  `services/hospital-capacity/src/HospitalCapacity/Telemetry.hs` (`withTelemetry`,
  `TelemetryMode`, `withOtelServiceName`, `serviceMetricsFromGlobalProvider`,
  `withApplicationSpan`), `services/hospital-capacity/src/HospitalCapacity/Store.hs`
  (`commandOptionsWithTelemetry`),
  `services/hospital-capacity/app/HospitalCapacityWorker.hs`, and
  `docs/observability.md`.
- **wai-extra**, source
  `/Users/shinzui/Keikaku/hub/haskell/wai-project/wai/wai-extra`:
  `Network.Wai.Middleware.RequestLogger` (`mkRequestLogger`, `logStdout`,
  `logStdoutDev`, `OutputFormat`, `CustomOutputFormatWithDetails`) and
  `Network.Wai.Middleware.RequestLogger.JSON` (`formatAsJSON`,
  `formatAsJSONWithHeaders`, `requestToJSON`) — cited as rejected candidates.
- **relay-pagination** (all four packages 0.1.0.0), source
  `/Users/shinzui/Keikaku/bokuno/relay-pagination`: `Relay.Pagination`
  (`Connection`, `Edge`, `PageInfo`, `Cursor`, `KeyValue`, `CursorPayload`,
  `CursorError`, `encodeCursor`, `decodeCursor`, `PageConfig`, `PageRequest`,
  `Direction`, `mkPageRequest`, `PageRequestError`); `Relay.Pagination.Servant`
  (`RelayPage`, `RelayPageError`, `pageRequestError400`, `ClientPage`, `noPageArgs`,
  `forwardPage`, `backwardPage`) and `Relay.Pagination.Servant.OpenApi` (orphan
  instances, exports nothing); `Relay.Pagination.Hasql` (`paginate`, `SortSpec`,
  `KeyColumn`, `SortDirection`, `sortSpecFingerprint`, `KeyCodec`, `int8Key`,
  `textKey`, `uuidKey`, `boolKey`, `timestamptzKey`, `mintCursor`, `mkConnection`);
  `Relay.Pagination.Conformance` (`FetchPage`, `ConformanceConfig`,
  `defaultConformanceConfig`, `checkConformance`, `testConformance`, the six
  invariants in `Check.hs`); `examples/members-server` (`Domain.canonicalOrder`,
  `Api.ListMembersEndpoint`, `Query.memberSort`, `Handler.cursorRejected`).
- **kiroku-metrics** (0.1.0.1), source
  `/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku/kiroku-metrics`:
  `Kiroku.Metrics.Health` (`checkLiveness`, `checkReadiness`, `postgresPing`,
  `DependencyCheck`), `Kiroku.Metrics.Config` (`readinessMaxLag` default `10_000`,
  `livenessTimeoutUs`), routes in `Kiroku.Metrics.Server`.
- **Tooling**: `dhall` (1.42.3 on PATH) for the mori.dhall type-check; `mori` for
  registry discovery; `cabal` + GHC 9.12 for the Milestone 2 prototype only.

At the end of each doc milestone, the named surface for that milestone must appear in
the doc exactly as it exists in source — module path, function name, and signature
where a signature is quoted.
