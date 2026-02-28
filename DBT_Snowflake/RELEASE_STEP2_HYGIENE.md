# Step 2 — Repo hygiene check (before GitHub push)

## Verification results

| Check | Status | Notes |
|-------|--------|-------|
| **1. profiles.yml NOT tracked** | OK | `profiles.yml` is in `.gitignore`; `git ls-files profiles.yml` returns nothing. |
| **2. .gitignore entries** | OK | All present: `profiles.yml`, `target/`, `logs/`, `dbt_packages/`, `.venv/` (plus `.env`, `scripts/set_env.sh`, etc.). |
| **3. package-lock.yml committed** | ACTION REQUIRED | File exists and is not ignored. It was untracked. **Run:** `git add package-lock.yml` (or `git add aws_dbt_snowflake_project/package-lock.yml` if your repo root is the parent folder), then commit. |
| **4. No target/ files staged** | OK | `target/` is ignored; `git ls-files target/` returns nothing. |

## .gitignore (relevant lines)

```
.venv/
logs/
target/
dbt_packages/
profiles.yml
```

## Action required

- **package-lock.yml** — Add and commit it for reproducible `dbt deps` (exact package versions). From the **dbt project directory** run: `git add package-lock.yml`. If your git root is the parent of this project, run: `git add <path-to>/aws_dbt_snowflake_project/package-lock.yml`. Do not add `package-lock.yml` to `.gitignore`.

## Before you push

1. Commit all changes, including `package-lock.yml`.
2. Confirm `profiles.yml` is never added: `git status` should not list `profiles.yml`.
3. Run once more: `dbt clean && dbt deps && dbt run && dbt test` (or `make deps && make build && make test`).
