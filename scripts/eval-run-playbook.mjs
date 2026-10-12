// スキル run-playbook が、依頼ごとに期待した playbook を選ぶかを確かめる。
// 使い方: node scripts/eval-run-playbook.mjs [モデル]...。省くと haiku、sonnet、opus で試す
// 終了コード: 0 はすべて期待どおり、1 は外れがある、2 は準備に失敗した
import { execFileSync, spawnSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const { cases } = JSON.parse(readFileSync(join(root, "evals/run-playbook.json"), "utf8"));
const models = process.argv.slice(2).length ? process.argv.slice(2) : ["haiku", "sonnet", "opus"];
const names = ["requirements", "feature", "prototype", "bug-fix", "refactoring", "small-change", "investigation", "opening-a-pr", "pr-follow-up", "verification-setup", "reflect", "correct", "autonomous-run", "pause-safely", "session-pickup", "design-playbook"];

const dir = join(root, ".ai-out", `eval-run-playbook-${Date.now()}`);
mkdirSync(dir, { recursive: true });
writeFileSync(
  join(dir, "apm.yml"),
  `name: eval\nversion: 0.1.0\ntargets: [claude]\ndependencies:\n  apm:\n    - ${join(root, "packages/playbooks")}\n`,
);
try {
  execFileSync("git", ["init", "-q"], { cwd: dir });
  execFileSync("apm", ["install"], { cwd: dir, stdio: "ignore" });
} catch (err) {
  console.error(`仮の利用者を用意できない: ${err.message}`);
  process.exit(2);
}

const instruction =
  "\n\nファイルは変更しない。スキル run-playbook に従って使う playbook を選び、1 行目に `PLAYBOOK: <名前>` の形で書く。" +
  "どの playbook にも当てはまらず手順を組むなら `PLAYBOOK: design-playbook` と書く。2 行目以降に、todolist に写す手順を書く。";

let failed = 0;
for (const model of models) {
  for (const c of cases) {
    const r = spawnSync("claude", ["-p", "--model", model, c.query + instruction], { cwd: dir, encoding: "utf8", timeout: 300_000 });
    // 途中で止まった実行の出力は、要求した行を含んでいても採点しない
    const finished = !r.error && r.status === 0;
    const line = finished ? ((r.stdout ?? "").split("\n").find((l) => l.includes("PLAYBOOK:")) ?? "") : "";
    const got = finished ? (names.find((n) => new RegExp(`PLAYBOOK:\\s*\`?${n}\\b`).test(line)) ?? "(不明)") : "(実行に失敗)";
    const ok = got === c.expected;
    if (!ok) failed++;
    console.log(`${ok ? "ok  " : "NG  "} ${model}\t期待 ${c.expected}\t結果 ${got}\t${c.query}`);
  }
}
console.log(`\n外れ ${failed} 件。作業用のディレクトリ: ${dir}`);
process.exit(failed ? 1 : 0);
