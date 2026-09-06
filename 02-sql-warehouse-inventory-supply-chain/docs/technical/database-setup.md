# Setting Up the Database on Your Own Machine

**Read time: 5 minutes. Doing it: about 30 minutes, once.**

This is the missing step between "the analysis is finished" and "I can open Power BI".

---

## What's going on, in plain English

The analysis ran on my machine. I sent you everything that matters — the SQL, the data, the results,
the documentation — but the **database itself** stayed behind and was discarded.

That sounds like a problem. It isn't. It's how the project was designed:

> **The database is a disposable output of code you keep.** Not a precious thing you have to protect.

That's why so much effort went into making the pipeline rebuild cleanly from empty, with the same
answers every time. You can recreate the whole thing in a couple of minutes, on any machine, for
as long as you own the files.

**What you have** — 15 CSV files (the raw data), 35 SQL files (all the logic), 32 result files
(the committed answers), and every document.

**What you need** — PostgreSQL installed, then those SQL files run once.

---

## Why you can't skip this and load the CSVs straight into Power BI

A reasonable question, and worth answering properly.

The CSVs are **raw transactions** — orders, receipts, stock movements. They contain no analysis.

Every finding lives inside the SQL: the opportunity hierarchy, the three availability measures, the
calibrated alignment rule, the minimum-order attribution. That's 35 files and 40 documented
decisions of logic.

Loading the CSVs into Power BI would mean rebuilding all of that in Power Query — weeks of work,
and it would break the reproducibility that makes the project credible.

**Thirty minutes of setup is much cheaper.**

---

# Step 1 — Install PostgreSQL (10 minutes)

1. Go to **https://www.postgresql.org/download/windows/**
2. Click **"Download the installer"** — this takes you to EnterpriseDB.
3. Download **PostgreSQL 16** for Windows x86-64. Not 17, not 15 — the project was written and
   validated against 16.
4. Run the installer. Accept the defaults, **except** for these two screens:

   **"Select Components"** — make sure all four are ticked:
   - ☑ PostgreSQL Server
   - ☑ pgAdmin 4 *(a visual tool — useful later)*
   - ☑ Command Line Tools *(**essential** — this is `psql`, which runs the pipeline)*
   - ☑ Stack Builder *(harmless, you can untick it)*

   **"Password"** — it asks for a password for the `postgres` superuser.
   **Write this down somewhere you'll find it.** You need it twice: once now, once in Power BI.
   Nobody can recover it for you.

5. **Port** — leave it at **5432** unless the installer says it's taken.
6. **Locale** — leave at default.
7. Let it finish. If Stack Builder opens at the end, just close it.

---

# Step 2 — Check it worked (2 minutes)

1. Press the **Windows key**, type `SQL Shell`, and open **SQL Shell (psql)**.
2. A black window appears asking four questions. **Press Enter** for each of the first four to
   accept the defaults:
   ```
   Server [localhost]:        ← Enter
   Database [postgres]:       ← Enter
   Port [5432]:               ← Enter
   Username [postgres]:       ← Enter
   Password for user postgres: ← type your password, then Enter
   ```
   *(The password won't show as you type. That's normal — it's not broken.)*

3. **You should see:**
   ```
   psql (16.x)
   Type "help" for help.

   postgres=#
   ```

**That `postgres=#` prompt means PostgreSQL is installed and running.** Biggest hurdle cleared.

> **If it says "password authentication failed"** — you mistyped it. Close the window and try again.
> **If the window flashes and closes** — the installation didn't complete. Re-run the installer.

Type `\q` and press Enter to close.

---

# Step 3 — Create the database (1 minute)

1. Open **SQL Shell (psql)** again and log in the same way.
2. At the `postgres=#` prompt, type exactly this and press Enter:

   ```sql
   CREATE DATABASE calderfield;
   ```

3. **You should see:** `CREATE DATABASE`

That's the empty container. Nothing in it yet.

4. Type `\q` to exit.

---

# Step 4 — Run the pipeline (5 minutes)

This is the part that builds everything: 15 tables, 147,589 rows, 4 preparation views, 17 analysis
files, 7 reporting views.

**The one thing that matters here: you must run it from the project folder.** The load file uses
paths like `data/synthetic/warehouse.csv`, which only work from the right starting point.

1. Open **File Explorer** and navigate to:
   ```
   C:\Users\ZBOOK 15 G4\Data Portfolio\02-sql-warehouse-inventory-supply-chain
   ```

2. Click once in the **address bar** at the top, type `cmd`, and press **Enter**.
   A black Command Prompt window opens **already in that folder** — that's the trick that gets the
   paths right.

3. Confirm you're in the right place — type `dir` and press Enter. You should see `sql`, `data`,
   `docs`, `analysis`, `README.md`.

4. Now paste this in **one line** and press Enter:

   ```
   for /r sql %f in (*.sql) do @psql -U postgres -d calderfield -v ON_ERROR_STOP=1 -q -f "%f" && echo OK %f
   ```

5. It will ask for your password — possibly several times. Type it each time.

**What you should see:** a stream of `OK` lines and some `=== section ===` headings scrolling past,
for a minute or two. Some files print result tables. That's the analysis running.

> **The `for /r` command walks folders alphabetically**, which happens to give the correct order
> here: `01_setup` → `02_validation` → `03_preparation` → `04_analysis` → `05_reporting_views`.
> Order matters — later files depend on earlier ones.

> **Tired of typing the password?** Before step 4, run `set PGPASSWORD=yourpassword` in the same
> window. It lasts until you close it. Don't put it in a saved file.

---

# Step 5 — Check it worked (2 minutes)

1. Open **SQL Shell (psql)**, but this time when it asks for the **Database**, type `calderfield`
   instead of pressing Enter.

2. At the `calderfield=#` prompt, run this:

   ```sql
   SELECT COUNT(*) FROM supply.vw_working_capital_release_opportunity;
   ```

   **Expected: `515`**

3. And this — the headline number from the whole project:

   ```sql
   SELECT ROUND(SUM(working_capital_gbp), 0) AS opportunity
   FROM   supply.vw_working_capital_release_opportunity;
   ```

   **Expected: `468897`**

4. And the check the build guide asks for — the four detail views Power BI needs:

   ```sql
   SELECT table_name FROM information_schema.views
   WHERE  table_schema = 'supply'
     AND  table_name IN ('vw_sku_value_position','vw_policy_alignment',
                         'vw_purchase_quantity_structure','vw_dual_source_gap');
   ```

   **Expected: 4 rows.**

**If all three match, you're done.** Your local database is now identical to the one the analysis
ran on. Every number in every document will reconcile.

---

# Step 6 — You're ready for Power BI

Go to `docs/technical/powerbi-build-guide.md`, Section 3, and use:

| Field | Value |
|---|---|
| **Server** | `localhost:5432` |
| **Database** | `calderfield` |
| **Username** | `postgres` |
| **Password** | the one you wrote down in Step 1 |
| **Data Connectivity mode** | **Import** |

Everything from there follows the guide.

---

## If something goes wrong

**"psql is not recognised as an internal or external command"**
The Command Line Tools weren't installed, or Windows can't find them. Re-run the PostgreSQL
installer and tick **Command Line Tools**. If they *are* installed, use the full path instead:
`"C:\Program Files\PostgreSQL\16\bin\psql"` in place of `psql`.

**"could not open file 'data/synthetic/warehouse.csv'"**
You're running from the wrong folder. Go back to Step 4 and use the `cmd`-in-the-address-bar trick.
Type `dir` first and check you can see the `data` folder.

**"database calderfield does not exist"**
Step 3 didn't run. Go back and create it.

**"relation ... does not exist" partway through**
A file ran out of order, or an earlier one failed. Easiest fix — start clean:
```sql
DROP DATABASE calderfield;
CREATE DATABASE calderfield;
```
Then redo Step 4. The pipeline is designed to be re-run from empty; that's what
`ON_ERROR_STOP=1` is for.

**Something else, or a number doesn't match**
Tell me what the screen says and I'll work it out with you. Don't start editing SQL files — they're
validated, and the problem is almost certainly environmental.

---

## What you'll have when this is done

- A working PostgreSQL 16 install — useful for every future portfolio project
- The `calderfield` database, reproducible from your own files in five minutes
- A local database Power BI can connect to
- Genuine familiarity with the setup, which is worth having when someone asks about it in an
  interview

**And the honest framing for your portfolio:** "the analysis rebuilds from empty in under five
minutes on any machine with PostgreSQL 16, and produces byte-identical results" is a stronger claim
than most candidates can make. This step is what makes it true rather than theoretical.
