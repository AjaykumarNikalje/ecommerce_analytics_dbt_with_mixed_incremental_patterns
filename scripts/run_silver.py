"""Run a checkpointed Silver load or backfill a range of business dates."""

import argparse
from datetime import date
import json
from pathlib import Path
import subprocess
import sys


PROJECT_DIR = Path(__file__).resolve().parents[1]
WINDOW_MARKER = "SILVER_RUN_WINDOW="


def run_dbt(dbt, *args, capture=False):
    result = subprocess.run(
        [dbt, "--no-use-colors", *args],
        cwd=PROJECT_DIR,
        text=True,
        stdout=subprocess.PIPE if capture else None,
    )
    if capture:
        print(result.stdout, end="", flush=True)
    result.check_returncode()
    return result.stdout


def run_pipeline(dbt, entity):
    pipeline_args = {"entity": entity}
    output = run_dbt(
        dbt, "run-operation", "start_silver_checkpoint",
        "--args", json.dumps(pipeline_args), capture=True,
    )
    step = "Bronze validation"
    try:
        window_line, = (
            line.split(WINDOW_MARKER, 1)[1]
            for line in output.splitlines()
            if WINDOW_MARKER in line
        )
        window = json.loads(window_line)
        run_dbt(dbt, "test", "--select", f"bronze_{entity}_cdc_validation")

        step = "Silver merge"
        run_dbt(
            dbt, "run", "--select", f"silver_{entity}",
            "--vars", json.dumps({"silver_run_window": window}),
        )

        step = "Silver validation"
        run_dbt(
            dbt, "test", "--select",
            f"bronze_unique_not_null_validation_{entity}",
        )

        step = "checkpoint finalization"
        run_dbt(
            dbt, "run-operation", "finish_silver_checkpoint",
            "--args", json.dumps({**pipeline_args, "upper_us": window["upper_us"]}),
        )
    except (OSError, subprocess.CalledProcessError, ValueError, KeyError, KeyboardInterrupt):
        try:
            run_dbt(
                dbt, "run-operation", "finish_silver_checkpoint",
                "--args", json.dumps({**pipeline_args, "failed_step": step}),
            )
        except (OSError, subprocess.CalledProcessError) as error:
            print(f"Could not record checkpoint failure: {error}", file=sys.stderr)
        raise


def run_backfill(dbt, entity, start_date, end_date):
    variables = json.dumps({
        "silver_backfill": {
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
        },
    })
    run_dbt(
        dbt, "test", "--select", f"bronze_{entity}_cdc_validation",
        "--vars", variables,
    )
    run_dbt(dbt, "run", "--select", f"silver_{entity}", "--vars", variables)
    run_dbt(
        dbt, "test", "--select", f"bronze_unique_not_null_validation_{entity}",
    )


def business_date(value):
    try:
        parsed = date.fromisoformat(value)
        if parsed.isoformat() == value:
            return parsed
    except ValueError:
        pass
    raise argparse.ArgumentTypeError("expected a business date in YYYY-MM-DD format")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("entity", choices=("customers", "orders"))
    parser.add_argument("--dbt", default="dbt", help="Path to the dbt executable")
    parser.add_argument("--start-date", type=business_date, help="First business date to include")
    parser.add_argument("--end-date", type=business_date, help="First business date to exclude")
    args = parser.parse_args()
    if (args.start_date is None) != (args.end_date is None):
        parser.error("--start-date and --end-date must be supplied together")
    if args.start_date is None:
        run_pipeline(args.dbt, args.entity)
    else:
        if args.start_date >= args.end_date:
            parser.error("--end-date must be after --start-date")
        run_backfill(args.dbt, args.entity, args.start_date, args.end_date)
