<script lang="ts">
import type { PGlite } from "@electric-sql/pglite";
import { onMount } from "svelte";

interface PgField {
	name: string;
	dataTypeID: number;
}

interface PgResult {
	rows: Record<string, unknown>[];
	fields: PgField[];
	affectedRows?: number;
	command?: string;
	rowCount?: number;
}

interface ResultSet {
	command: string;
	columns: string[];
	rows: Record<string, unknown>[];
	rowCount: number;
}

const DEFAULT_SQL = `DROP TABLE IF EXISTS messages;

CREATE TABLE messages (
  id SERIAL PRIMARY KEY,
  author TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO messages (author, body) VALUES
  ('alice', 'Hello from PGlite!'),
  ('bob', 'PostgreSQL running in the browser.');

SELECT id, author, body, created_at
FROM messages
ORDER BY id;`;

let sql = DEFAULT_SQL;
let status: "loading" | "ready" | "error" = "loading";
let error = "";
let running = false;
let elapsed = 0;
let resultSets: ResultSet[] = [];
let db: PGlite | null = null;

function formatCell(value: unknown): string {
	if (value === null || value === undefined) return "NULL";
	if (value instanceof Date) return value.toISOString();
	if (typeof value === "object") return JSON.stringify(value);
	return String(value);
}

function toResultSets(results: PgResult[]): ResultSet[] {
	return results
		.filter(
			(r) =>
				r &&
				((r.fields?.length ?? 0) > 0 || (r.rows?.length ?? 0) > 0 || r.command),
		)
		.map((r) => ({
			command: r.command ?? "",
			columns: (r.fields ?? []).map((f) => f.name),
			rows: r.rows ?? [],
			rowCount: r.rowCount ?? r.affectedRows ?? r.rows?.length ?? 0,
		}));
}

async function run(): Promise<void> {
	if (!db || running) return;
	running = true;
	error = "";
	const start = performance.now();
	try {
		const results = (await db.exec(sql)) as unknown as PgResult[];
		resultSets = toResultSets(results);
	} catch (e) {
		error = e instanceof Error ? e.message : String(e);
		resultSets = [];
	} finally {
		elapsed = performance.now() - start;
		running = false;
	}
}

async function init(): Promise<void> {
	status = "loading";
	try {
		const { PGlite: PGliteClass } = await import("@electric-sql/pglite");
		db = new PGliteClass();
		await db.waitReady;
		status = "ready";
		await run();
	} catch (e) {
		status = "error";
		error = e instanceof Error ? e.message : String(e);
	}
}

function resetSql(): void {
	sql = DEFAULT_SQL;
}

function onKeydown(event: KeyboardEvent): void {
	if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
		event.preventDefault();
		void run();
	}
}

onMount(() => {
	void init();
});
</script>

<div class="flex flex-col gap-4">
	<div class="flex flex-wrap items-center gap-2 text-sm">
		{#if status === "loading"}
			<span class="inline-block h-2 w-2 animate-pulse rounded-full bg-amber-500"></span>
			<span class="text-neutral-600 dark:text-neutral-400">正在加载 PGlite / WebAssembly…（首次约 16 MB）</span>
		{:else if status === "ready"}
			<span class="inline-block h-2 w-2 rounded-full bg-emerald-500"></span>
			<span class="text-neutral-600 dark:text-neutral-400">PostgreSQL 已在浏览器中就绪，数据仅存在于当前页面</span>
		{:else}
			<span class="inline-block h-2 w-2 rounded-full bg-red-500"></span>
			<span class="text-red-500">初始化失败：{error}</span>
		{/if}
	</div>

	<textarea
		bind:value={sql}
		on:keydown={onKeydown}
		spellcheck="false"
		disabled={status !== "ready"}
		class="w-full min-h-56 resize-y rounded-lg border border-black/10 bg-[var(--codeblock-bg)] p-3 font-mono text-sm leading-relaxed text-neutral-900 focus:outline-none focus:ring-2 focus:ring-[var(--primary)] disabled:opacity-60 dark:border-white/15 dark:text-neutral-100"
	></textarea>

	<div class="flex flex-wrap items-center gap-2">
		<button
			type="button"
			on:click={() => void run()}
			disabled={status !== "ready" || running}
			class="btn-regular rounded-lg px-4 py-2 text-sm font-medium disabled:pointer-events-none disabled:opacity-50"
		>
			{running ? "运行中…" : "运行 (Ctrl+Enter)"}
		</button>
		<button
			type="button"
			on:click={resetSql}
			class="btn-regular rounded-lg px-4 py-2 text-sm font-medium"
		>
			重置 SQL
		</button>
		{#if status === "ready" && !running}
			<span class="text-xs text-neutral-500 dark:text-neutral-400">耗时 {elapsed.toFixed(1)} ms</span>
		{/if}
	</div>

	{#if error && status === "ready"}
		<pre class="overflow-x-auto rounded-lg border border-red-500/30 bg-red-500/5 p-3 text-sm text-red-500">{error}</pre>
	{/if}

	{#each resultSets as result, index (index)}
		<div class="card-base border border-black/5 p-4 dark:border-white/10">
			<div class="mb-2 flex items-center gap-2 text-xs uppercase tracking-wide text-neutral-500 dark:text-neutral-400">
				<span>{result.command || "RESULT"}</span>
				{#if result.columns.length > 0}
					<span>· {result.rows.length} 行</span>
				{:else}
					<span>· 影响 {result.rowCount} 行</span>
				{/if}
			</div>

			{#if result.columns.length > 0}
				<div class="overflow-x-auto">
					<table class="w-full border-collapse text-left text-sm">
						<thead>
							<tr>
								{#each result.columns as column}
									<th class="border-b border-black/10 px-3 py-2 font-semibold whitespace-nowrap dark:border-white/15">{column}</th>
								{/each}
							</tr>
						</thead>
						<tbody>
							{#each result.rows as row}
								<tr class="border-b border-black/5 last:border-0 dark:border-white/5">
									{#each result.columns as column}
										<td class="px-3 py-2 font-mono text-xs whitespace-nowrap">{formatCell(row[column])}</td>
									{/each}
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{:else}
				<p class="text-sm text-neutral-600 dark:text-neutral-400">执行成功。</p>
			{/if}
		</div>
	{/each}
</div>
