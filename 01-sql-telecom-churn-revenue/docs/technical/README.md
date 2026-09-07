# Technical documentation

The supporting layer beneath the [case study](../case-study.md) and the [methodology](../methodology.md).

| | |
|---|---|
| [`findings-and-evidence.md`](findings-and-evidence.md) | The full evidence register. Every figure quoted anywhere in the project, traced to a committed query output, and separated into observed fact, interpretation, inference and limitation |
| [`data-quality.md`](data-quality.md) | Source selection, the five excluded fields, the checks run and the issues found and corrected |
| [`data-dictionary.md`](data-dictionary.md) | Field-level reference for all five source tables, the revenue identity, and the derived fields |
| [`technical-notes.md`](technical-notes.md) | Reproducibility, the chart pipeline, the 88-check chart validation gate and the visual review |

Run order and the exact `psql` invocations are in [`../../sql/README.md`](../../sql/README.md). The committed query outputs are in [`../../analysis/query_results/`](../../analysis/query_results/).
