<!--
Customize for your project — find/replace these tokens after copying:

  <ENDPOINT_*>
    URLs to probe with curl. Example list:
      http://localhost:3000
      http://localhost:8000
      http://localhost:8000/api/health
      http://localhost:5000/health

  (If you're not using Docker, drop the `docker-compose ps` step
  and rely on the endpoint table alone.)
-->

Quick health check across all services: container states + endpoint reachability, in a single compact table.

## Arguments

None. Ignore `$ARGUMENTS`.

## Steps

1. **Run two checks in parallel** (a SINGLE turn with multiple Bash calls):

   - **Container states.** Get a clean tabular list of all compose services and their current state:
     ```
     docker-compose ps --format "table {{.Service}}\t{{.State}}\t{{.Status}}"
     ```

   - **Endpoint probes.** Hit each public-facing endpoint with a short timeout and capture only the HTTP status. Run them concurrently in one shell:
     ```
     for url in <ENDPOINT_1> <ENDPOINT_2> <ENDPOINT_3> <ENDPOINT_4>; do
       code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$url" || echo "TIMEOUT")
       echo "$url $code"
     done
     ```

2. **Format a single combined report.** Render two compact tables — containers first, endpoints second:

   ```
   containers:
     SERVICE          STATE    STATUS
     backend          running  Up 2 hours
     frontend         running  Up 2 hours
     mysql            running  Up 2 hours (healthy)

   endpoints:
     URL                                  CODE   NOTE
     http://localhost:3000                200    frontend ok
     http://localhost:8000                200    backend ok
     http://localhost:8000/api/health     200    api ok

   ✓ all green
   ```

3. **Flag problems clearly.** If anything is unhealthy:
   - Container in `Exit`, `Restarting`, or `Created` (but not `running`) → mark with `✗` and put it at the top of the containers table.
   - Endpoint returned `TIMEOUT`, `000`, or any 5xx → mark with `✗`.
   - Endpoint returned 4xx → mark with `⚠` (might be expected, e.g. 404 on root or unauthenticated 401).

   End the report with a one-line summary:
   - `✓ all green` if every container is `running` AND every endpoint returned 2xx/3xx.
   - `⚠ <N> warning(s)` if there are only ⚠ marks.
   - `✗ <N> failure(s)` if anything is broken.

4. **Suggest a next step** when something's broken. Examples:
   - Container `Exit` → `next: docker-compose up -d <service>` and tail logs to see why it crashed.
   - Endpoint timeout but container running → `next: invoke the log-investigator agent with symptom "backend not responding on :8000"`.

## Notes

- This command is read-only. Never restart, rebuild, or recreate containers from `/health`. Suggest, don't do.
- Keep raw curl/docker output inside tool calls. The user sees only the formatted tables + summary.
- 3-second curl timeout is intentional — a healthy service answers in ms; a hung one shouldn't block the whole check.
