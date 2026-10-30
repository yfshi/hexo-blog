<script lang="ts">
import { type Extension, PGlite } from "@electric-sql/pglite";
import { amcheck } from "@electric-sql/pglite/contrib/amcheck";
import { bloom } from "@electric-sql/pglite/contrib/bloom";
import { btree_gin } from "@electric-sql/pglite/contrib/btree_gin";
import { btree_gist } from "@electric-sql/pglite/contrib/btree_gist";
import { citext } from "@electric-sql/pglite/contrib/citext";
import { cube } from "@electric-sql/pglite/contrib/cube";
import { earthdistance } from "@electric-sql/pglite/contrib/earthdistance";
import { fuzzystrmatch } from "@electric-sql/pglite/contrib/fuzzystrmatch";
import { hstore } from "@electric-sql/pglite/contrib/hstore";
import { intarray } from "@electric-sql/pglite/contrib/intarray";
import { ltree } from "@electric-sql/pglite/contrib/ltree";
import { pageinspect } from "@electric-sql/pglite/contrib/pageinspect";
import { pg_buffercache } from "@electric-sql/pglite/contrib/pg_buffercache";
import { pg_freespacemap } from "@electric-sql/pglite/contrib/pg_freespacemap";
import { pg_stat_statements } from "@electric-sql/pglite/contrib/pg_stat_statements";
import { pg_trgm } from "@electric-sql/pglite/contrib/pg_trgm";
import { pg_visibility } from "@electric-sql/pglite/contrib/pg_visibility";
import { pg_walinspect } from "@electric-sql/pglite/contrib/pg_walinspect";
import { pgcrypto } from "@electric-sql/pglite/contrib/pgcrypto";
import { seg } from "@electric-sql/pglite/contrib/seg";
import { tablefunc } from "@electric-sql/pglite/contrib/tablefunc";
import { unaccent } from "@electric-sql/pglite/contrib/unaccent";
import { uuid_ossp } from "@electric-sql/pglite/contrib/uuid_ossp";
import { live } from "@electric-sql/pglite/live";
import { age } from "@electric-sql/pglite-age";
import { pg_hashids } from "@electric-sql/pglite-pg_hashids";
import { pg_ivm } from "@electric-sql/pglite-pg_ivm";
import { pg_textsearch } from "@electric-sql/pglite-pg_textsearch";
import { pg_uuidv7 } from "@electric-sql/pglite-pg_uuidv7";
import { pgmq } from "@electric-sql/pglite-pgmq";
import { pgtap } from "@electric-sql/pglite-pgtap";
import { vector } from "@electric-sql/pglite-pgvector";
import { onDestroy, onMount } from "svelte";

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

interface Example {
	id: string;
	label: string;
	sql: string;
}

interface LiveResult<T> {
	rows: T[];
}

interface LiveQuery<T> {
	initialResults: LiveResult<T>;
	subscribe: (callback: (result: LiveResult<T>) => void) => void;
	unsubscribe: () => Promise<void>;
}

type PGliteWithLive = PGlite & {
	live: {
		query<T>(
			query: string,
			params?: unknown[] | null,
			callback?: (result: LiveResult<T>) => void,
		): Promise<LiveQuery<T>>;
	};
};

// PGlite 0.5.13 会把多个 shared_preload_libraries 写成未加引号的逗号列表，
// 导致 PostgreSQL 启动时报语法错误。这里先移除各自声明的预加载项，再合并为带引号的单个值注入。
function withoutSharedPreload(extension: Extension): Extension {
	return {
		...extension,
		setup: async (...args) => {
			const result = await extension.setup(...args);
			return { ...result, sharedPreloadLibraries: [] };
		},
	};
}

const combinedPreload: Extension = {
	name: "__combined_preload",
	setup: async () => ({
		sharedPreloadLibraries: ["'pg_stat_statements,pg_textsearch'"],
	}),
};

const EXTENSION_NAMES = [
	"pg_trgm",
	"pgcrypto",
	"hstore",
	"ltree",
	"uuid-ossp",
	"vector",
	"pg_uuidv7",
	"pg_ivm",
	"age",
	"pgmq",
	"live",
	"citext",
	"unaccent",
	"fuzzystrmatch",
	"intarray",
	"seg",
	"cube",
	"earthdistance",
	"tablefunc",
	"bloom",
	"btree_gin",
	"btree_gist",
	"pg_stat_statements",
	"pg_buffercache",
	"pg_freespacemap",
	"pg_visibility",
	"pg_walinspect",
	"amcheck",
	"pageinspect",
	"pg_textsearch",
	"pg_hashids",
	"pgtap",
];

const EXAMPLES: Example[] = [
	{
		id: "basic",
		label: "基础",
		sql: `DROP TABLE IF EXISTS messages;

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
ORDER BY id;`,
	},
	{
		id: "vector",
		label: "pgvector 向量检索",
		sql: `DROP TABLE IF EXISTS docs;

CREATE TABLE docs (
  id SERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  embedding vector(3)
);

INSERT INTO docs (content, embedding) VALUES
  ('cat', '[1, 0, 0]'),
  ('dog', '[0.9, 0.1, 0]'),
  ('car', '[0, 1, 0]');

SELECT content, embedding <-> '[1, 0, 0]' AS distance
FROM docs
ORDER BY distance
LIMIT 3;`,
	},
	{
		id: "trgm",
		label: "pg_trgm 模糊搜索",
		sql: `DROP TABLE IF EXISTS articles;

CREATE TABLE articles (id SERIAL PRIMARY KEY, title TEXT NOT NULL);

INSERT INTO articles (title) VALUES
  ('PostgreSQL in the browser'),
  ('PGlite playground'),
  ('Hello Postgres'),
  ('Fuzzy string search');

SELECT title, round(similarity(title, 'postgre')::numeric, 3) AS similarity
FROM articles
ORDER BY similarity DESC
LIMIT 4;`,
	},
	{
		id: "crypto",
		label: "pgcrypto / UUID",
		sql: `SELECT encode(digest('hello pglite', 'sha256'), 'hex') AS sha256;

SELECT
  gen_random_uuid() AS uuid_v4,
  uuid_generate_v5(uuid_ns_url(), 'https://pglite.dev') AS uuid_v5,
  uuid_generate_v7() AS uuid_v7;

SELECT crypt('secret', gen_salt('bf', 8)) AS bcrypt_hash;`,
	},
	{
		id: "hstore",
		label: "hstore 键值",
		sql: `SELECT 'name=>Alice, city=>Beijing, role=>admin'::hstore AS kv;

SELECT
  ('name=>Alice, city=>Beijing'::hstore) -> 'city' AS city,
  ('name=>Alice, city=>Beijing'::hstore) ? 'role' AS has_role;

SELECT * FROM each('name=>Alice, city=>Beijing'::hstore);`,
	},
	{
		id: "ltree",
		label: "ltree 树形",
		sql: `SELECT 'top.science.astro'::ltree <@ 'top.science'::ltree AS is_descendant;

SELECT
  nlevel('top.science.astro'::ltree) AS depth,
  subpath('top.science.astro'::ltree, 0, 1) AS root;

SELECT 'top.science.astro'::ltree ~ 'top.*'::lquery AS matches;`,
	},
	{
		id: "ivm",
		label: "pg_ivm 增量视图",
		sql: `DROP TABLE IF EXISTS ivm_order_total;
DROP TABLE IF EXISTS ivm_orders;

CREATE TABLE ivm_orders (
  id SERIAL PRIMARY KEY,
  amount INT NOT NULL
);

INSERT INTO ivm_orders (amount) VALUES (10), (20);

SELECT pgivm.create_immv(
  'ivm_order_total',
  'SELECT sum(amount) AS total, count(*) AS orders FROM ivm_orders'
);

INSERT INTO ivm_orders (amount) VALUES (30);

SELECT * FROM ivm_order_total;`,
	},
	{
		id: "pgmq",
		label: "pgmq 消息队列",
		sql: `SELECT pgmq.drop_queue('demo_queue');
SELECT pgmq.create('demo_queue');

SELECT * FROM pgmq.send('demo_queue', '{"msg": "hello from PGlite"}');
SELECT msg_id, message, read_ct FROM pgmq.read('demo_queue', 0, 1);`,
	},
	{
		id: "age",
		label: "Apache AGE 图查询",
		sql: `LOAD 'age';
SET search_path = ag_catalog, "$user", public;

SELECT create_graph('demo_graph')
WHERE NOT EXISTS (SELECT 1 FROM ag_catalog.ag_graph WHERE name = 'demo_graph');

SELECT * FROM cypher('demo_graph', $$
  CREATE (a:Person {name: 'Alice'})-[:KNOWS]->(b:Person {name: 'Bob'})
  RETURN a, b
$$) AS (a agtype, b agtype);

RESET search_path;`,
	},
	{
		id: "builtins",
		label: "文本 / 类型工具",
		sql: `SELECT
  'Hello'::citext = 'hello' AS case_insensitive,
  unaccent('Hôtel') AS unaccented,
  levenshtein('kitten', 'sitting') AS edit_distance,
  soundex('Robert') AS soundex;

SELECT
  icount('{1,2,3}'::int[]) AS intarray_count,
  '1..5'::seg && '3..9'::seg AS seg_overlap,
  cube_distance('(0,0)'::cube, '(3,4)'::cube) AS cube_distance;

SELECT round(earth_distance(
  ll_to_earth(39.9, 116.4),
  ll_to_earth(31.2, 121.5)
) / 1000) AS beijing_shanghai_km;

SELECT count(*) AS normal_rand_rows FROM normal_rand(5, 0, 1);`,
	},
	{
		id: "indexes",
		label: "bloom / GIN / GiST 索引",
		sql: `DROP TABLE IF EXISTS idx_demo;

CREATE TABLE idx_demo (id INT, tags TEXT, score INT);

INSERT INTO idx_demo VALUES (1, 'a', 10), (2, 'b', 20), (3, 'c', 30);

CREATE INDEX idx_demo_bloom ON idx_demo
  USING bloom (tags, score) WITH (length = 80, col1 = 2, col2 = 2);
CREATE INDEX idx_demo_gin ON idx_demo USING gin (tags);
CREATE INDEX idx_demo_gist ON idx_demo USING gist (score);

SELECT indexname FROM pg_indexes
WHERE tablename = 'idx_demo'
ORDER BY indexname;`,
	},
	{
		id: "textsearch",
		label: "pg_textsearch BM25",
		sql: `DROP TABLE IF EXISTS ts_docs;

CREATE TABLE ts_docs (
  id SERIAL PRIMARY KEY,
  content TEXT NOT NULL
);

INSERT INTO ts_docs (content) VALUES
  ('PostgreSQL full text search'),
  ('Browser database with PGlite'),
  ('BM25 ranking made simple'),
  ('Vector search and full text search');

CREATE INDEX ts_docs_bm25 ON ts_docs
  USING bm25 (content) WITH (text_config = 'english');

SELECT id, content
FROM ts_docs
ORDER BY content <@> to_bm25query('full text search', 'ts_docs_bm25')
LIMIT 5;`,
	},
	{
		id: "hashids",
		label: "pg_hashids 短 ID",
		sql: `SELECT
  id_encode(1001) AS short_id,
  id_encode(1001, 'pglite', 8) AS salted_id;

SELECT id_decode('jNl') AS decoded_ids;`,
	},
	{
		id: "pgtap",
		label: "pgTAP 测试",
		sql: `SELECT plan(3);

SELECT ok(1 + 1 = 2, 'math still works');
SELECT is('PGlite'::text, 'PGlite', 'text equality');
SELECT pass('pgTAP is running in the browser');

SELECT * FROM finish();`,
	},
];

let sql = EXAMPLES[0].sql;
let activeExample = EXAMPLES[0].id;
let status: "loading" | "ready" | "error" = "loading";
let error = "";
let running = false;
let hasRun = false;
let elapsed = 0;
let resultSets: ResultSet[] = [];
let extensionErrors: string[] = [];
let db: PGliteWithLive | null = null;

let liveCount: number | null = null;
let liveReady = false;
let liveError = "";
let liveSub: LiveQuery<{ n: number }> | null = null;

function errorMessage(value: unknown): string {
	return value instanceof Error ? value.message : String(value);
}

function formatCell(value: unknown): string {
	if (value === null || value === undefined) return "NULL";
	if (value instanceof Date) return value.toISOString();
	if (typeof value === "object") return JSON.stringify(value);
	return String(value);
}

function toResultSets(results: PgResult[]): ResultSet[] {
	return results
		.filter(
			(result) =>
				(result.fields?.length ?? 0) > 0 ||
				(result.rowCount ?? result.affectedRows ?? 0) > 0,
		)
		.map((result) => ({
			command: result.command ?? "",
			columns: (result.fields ?? []).map((field) => field.name),
			rows: result.rows ?? [],
			rowCount:
				result.rowCount ?? result.affectedRows ?? result.rows?.length ?? 0,
		}));
}

async function installExtensions(instance: PGliteWithLive): Promise<void> {
	const statements: Array<[string, string]> = [
		["pg_trgm", "CREATE EXTENSION IF NOT EXISTS pg_trgm"],
		["pgcrypto", "CREATE EXTENSION IF NOT EXISTS pgcrypto"],
		["hstore", "CREATE EXTENSION IF NOT EXISTS hstore"],
		["ltree", "CREATE EXTENSION IF NOT EXISTS ltree"],
		["uuid-ossp", 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'],
		["vector", "CREATE EXTENSION IF NOT EXISTS vector"],
		["pg_uuidv7", "CREATE EXTENSION IF NOT EXISTS pg_uuidv7"],
		["pg_ivm", "CREATE EXTENSION IF NOT EXISTS pg_ivm"],
		["age", "CREATE EXTENSION IF NOT EXISTS age"],
		["pgmq", "CREATE EXTENSION IF NOT EXISTS pgmq"],
		["citext", "CREATE EXTENSION IF NOT EXISTS citext"],
		["unaccent", "CREATE EXTENSION IF NOT EXISTS unaccent"],
		["fuzzystrmatch", "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch"],
		["intarray", "CREATE EXTENSION IF NOT EXISTS intarray"],
		["seg", "CREATE EXTENSION IF NOT EXISTS seg"],
		["cube", "CREATE EXTENSION IF NOT EXISTS cube"],
		["earthdistance", "CREATE EXTENSION IF NOT EXISTS earthdistance"],
		["tablefunc", "CREATE EXTENSION IF NOT EXISTS tablefunc"],
		["bloom", "CREATE EXTENSION IF NOT EXISTS bloom"],
		["btree_gin", "CREATE EXTENSION IF NOT EXISTS btree_gin"],
		["btree_gist", "CREATE EXTENSION IF NOT EXISTS btree_gist"],
		["pg_stat_statements", "CREATE EXTENSION IF NOT EXISTS pg_stat_statements"],
		["pg_buffercache", "CREATE EXTENSION IF NOT EXISTS pg_buffercache"],
		["pg_freespacemap", "CREATE EXTENSION IF NOT EXISTS pg_freespacemap"],
		["pg_visibility", "CREATE EXTENSION IF NOT EXISTS pg_visibility"],
		["pg_walinspect", "CREATE EXTENSION IF NOT EXISTS pg_walinspect"],
		["amcheck", "CREATE EXTENSION IF NOT EXISTS amcheck"],
		["pageinspect", "CREATE EXTENSION IF NOT EXISTS pageinspect"],
		["pg_textsearch", "CREATE EXTENSION IF NOT EXISTS pg_textsearch"],
		["pg_hashids", "CREATE EXTENSION IF NOT EXISTS pg_hashids"],
		["pgtap", "CREATE EXTENSION IF NOT EXISTS pgtap"],
	];
	const failures: string[] = [];
	for (const [name, statement] of statements) {
		try {
			await instance.exec(statement);
		} catch (caught) {
			failures.push(`${name}: ${errorMessage(caught)}`);
		}
	}
	extensionErrors = failures;
}

async function run(): Promise<void> {
	if (!db || running) return;
	running = true;
	hasRun = true;
	error = "";
	const start = performance.now();
	try {
		const results = (await db.exec(sql)) as unknown as PgResult[];
		resultSets = toResultSets(results);
	} catch (caught) {
		error = errorMessage(caught);
		resultSets = [];
	} finally {
		elapsed = performance.now() - start;
		running = false;
	}
}

async function startLive(instance: PGliteWithLive): Promise<void> {
	try {
		await instance.exec(`CREATE TABLE IF NOT EXISTS live_messages (
			id SERIAL PRIMARY KEY,
			body TEXT NOT NULL,
			created_at TIMESTAMPTZ DEFAULT now()
		);`);
		const count = await instance.query<{ n: number }>(
			"SELECT count(*)::int AS n FROM live_messages;",
		);
		if ((count.rows[0]?.n ?? 0) === 0) {
			await instance.query(
				"INSERT INTO live_messages (body) VALUES ('实时查询已连接');",
			);
		}
		const sub = await instance.live.query<{ n: number }>(
			"SELECT count(*)::int AS n FROM live_messages;",
		);
		liveCount = sub.initialResults.rows[0]?.n ?? 0;
		sub.subscribe((result) => {
			liveCount = result.rows[0]?.n ?? 0;
		});
		liveSub = sub;
		liveReady = true;
	} catch (caught) {
		liveError = errorMessage(caught);
	}
}

async function init(): Promise<void> {
	status = "loading";
	try {
		const instance = new PGlite({
			extensions: {
				pg_trgm,
				pgcrypto,
				hstore,
				ltree,
				uuid_ossp,
				live,
				vector,
				pg_uuidv7,
				age,
				pg_ivm,
				pgmq,
				citext,
				unaccent,
				fuzzystrmatch,
				intarray,
				seg,
				cube,
				earthdistance,
				tablefunc,
				bloom,
				btree_gin,
				btree_gist,
				pg_stat_statements: withoutSharedPreload(pg_stat_statements),
				pg_buffercache,
				pg_freespacemap,
				pg_visibility,
				pg_walinspect,
				amcheck,
				pageinspect,
				pg_textsearch: withoutSharedPreload(pg_textsearch),
				pg_hashids,
				pgtap,
				__combined_preload: combinedPreload,
			},
		}) as unknown as PGliteWithLive;
		db = instance;
		await instance.waitReady;
		await installExtensions(instance);
		status = "ready";
		await run();
		await startLive(instance);
	} catch (caught) {
		status = "error";
		error = errorMessage(caught);
	}
}

function selectExample(example: Example): void {
	activeExample = example.id;
	sql = example.sql;
	void run();
}

function resetSql(): void {
	sql = EXAMPLES[0].sql;
	activeExample = EXAMPLES[0].id;
}

function onEditorInput(): void {
	activeExample = "";
}

function onKeydown(event: KeyboardEvent): void {
	if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
		event.preventDefault();
		void run();
	}
}

async function addLiveRow(): Promise<void> {
	if (!db) return;
	await db.query(
		"INSERT INTO live_messages (body) VALUES ('新消息 ' || to_char(now(), 'HH24:MI:SS'));",
	);
}

async function clearLive(): Promise<void> {
	if (!db) return;
	await db.query("DELETE FROM live_messages;");
}

onMount(() => {
	void init();
});

onDestroy(() => {
	void liveSub?.unsubscribe();
	void db?.close();
});
</script>

<div class="flex flex-col gap-4">
	<div class="flex flex-wrap items-center gap-2 text-sm">
		{#if status === "loading"}
			<span class="inline-block h-2 w-2 animate-pulse rounded-full bg-amber-500"></span>
			<span class="text-neutral-600 dark:text-neutral-400">正在加载 PGlite 与扩展…（首次约 18 MB）</span>
		{:else if status === "ready"}
			<span class="inline-block h-2 w-2 rounded-full bg-emerald-500"></span>
			<span class="text-neutral-600 dark:text-neutral-400">PostgreSQL 已在浏览器中就绪，数据仅存在于当前页面</span>
		{:else}
			<span class="inline-block h-2 w-2 rounded-full bg-red-500"></span>
			<span class="text-red-500">初始化失败：{error}</span>
		{/if}
	</div>

	{#if status === "ready"}
		<div class="flex flex-wrap items-center gap-1.5">
			<span class="text-xs text-neutral-500 dark:text-neutral-400">已加载扩展：</span>
			{#each EXTENSION_NAMES as name}
				<span class="rounded bg-[var(--btn-regular-bg)] px-2 py-0.5 font-mono text-[11px] text-neutral-700 dark:text-neutral-300">{name}</span>
			{/each}
		</div>
		{#if extensionErrors.length > 0}
			<pre class="overflow-x-auto rounded-lg border border-amber-500/30 bg-amber-500/5 p-3 text-xs text-amber-600 dark:text-amber-400">{extensionErrors.join("\n")}</pre>
		{/if}

		<div class="flex flex-wrap gap-2">
			{#each EXAMPLES as example}
				<button
					type="button"
					on:click={() => selectExample(example)}
					class="rounded-full border px-3 py-1 text-xs transition {activeExample ===
					example.id
						? 'border-[var(--primary)] text-[var(--primary)]'
						: 'border-black/10 text-neutral-600 dark:border-white/15 dark:text-neutral-400'}"
				>
					{example.label}
				</button>
			{/each}
		</div>
	{/if}

	<textarea
		bind:value={sql}
		on:input={onEditorInput}
		on:keydown={onKeydown}
		spellcheck="false"
		disabled={status !== "ready"}
		class="w-full min-h-56 resize-y rounded-lg border border-black/10 bg-[var(--btn-regular-bg)] p-3 font-mono text-sm leading-relaxed text-neutral-900 focus:outline-none focus:ring-2 focus:ring-[var(--primary)] disabled:opacity-60 dark:border-white/15 dark:text-neutral-100"
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
		{#if status === "ready" && !running && hasRun}
			<span class="text-xs text-neutral-500 dark:text-neutral-400">耗时 {elapsed.toFixed(1)} ms</span>
		{/if}
	</div>

	{#if error && status === "ready"}
		<pre class="overflow-x-auto rounded-lg border border-red-500/30 bg-red-500/5 p-3 text-sm text-red-500">{error}</pre>
	{/if}

	{#if status === "ready" && hasRun && !error && resultSets.length === 0}
		<div class="card-base border border-black/5 p-4 text-sm text-neutral-600 dark:border-white/10 dark:text-neutral-400">
			执行成功（无返回结果）。
		</div>
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

	{#if status === "ready"}
		<div class="card-base border border-black/5 p-4 dark:border-white/10">
			<div class="flex flex-wrap items-start justify-between gap-4">
				<div class="min-w-0">
					<div class="text-xs uppercase tracking-wide text-neutral-500 dark:text-neutral-400">live 实时查询</div>
					<p class="mt-1 text-sm text-neutral-600 dark:text-neutral-400">
						订阅 <code class="rounded bg-[var(--inline-code-bg)] px-1">live_messages</code> 的行数，插入或清空后自动更新，无需重新查询。
					</p>
					{#if liveError}
						<p class="mt-1 text-sm text-red-500">{liveError}</p>
					{/if}
				</div>
				<div class="text-right">
					<div class="text-2xl font-bold text-[var(--primary)]">{liveCount ?? "—"}</div>
					<div class="text-xs text-neutral-500 dark:text-neutral-400">当前行数</div>
				</div>
			</div>
			<div class="mt-3 flex flex-wrap gap-2">
				<button
					type="button"
					on:click={() => void addLiveRow()}
					disabled={!liveReady}
					class="btn-regular rounded-lg px-4 py-2 text-sm font-medium disabled:pointer-events-none disabled:opacity-50"
				>
					插入一行
				</button>
				<button
					type="button"
					on:click={() => void clearLive()}
					disabled={!liveReady}
					class="btn-regular rounded-lg px-4 py-2 text-sm font-medium disabled:pointer-events-none disabled:opacity-50"
				>
					清空
				</button>
			</div>
		</div>
	{/if}
</div>
