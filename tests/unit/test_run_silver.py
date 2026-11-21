import argparse
from datetime import date
import json
import subprocess
import unittest
from unittest.mock import patch

from scripts import run_silver


class SilverBackfillTests(unittest.TestCase):
    def test_passes_same_window_to_bronze_test_and_silver_merge(self):
        start = date(2026, 11, 1)
        end = date(2026, 11, 2)
        for entity in ("customers", "orders"):
            with self.subTest(entity=entity), patch.object(run_silver, "run_dbt") as dbt:
                run_silver.run_backfill("dbt", entity, start, end)
                commands = [call.args for call in dbt.call_args_list]
                self.assertEqual(
                    [command[:4] for command in commands],
                    [
                        ("dbt", "test", "--select", f"bronze_{entity}_cdc_validation"),
                        ("dbt", "run", "--select", f"silver_{entity}"),
                        ("dbt", "test", "--select", f"bronze_unique_not_null_validation_{entity}"),
                    ],
                )
                for command in commands[:2]:
                    self.assertEqual(command[4], "--vars")
                    self.assertEqual(
                        json.loads(command[5]),
                        {"silver_backfill": {"start_date": "2026-11-01", "end_date": "2026-11-02"}},
                    )

    def test_bronze_validation_failure_prevents_merge(self):
        failure = subprocess.CalledProcessError(1, "dbt test")
        with patch.object(run_silver, "run_dbt", side_effect=failure) as dbt:
            with self.assertRaises(subprocess.CalledProcessError):
                run_silver.run_backfill("dbt", "orders", date(2026, 11, 1), date(2026, 11, 2))
            dbt.assert_called_once()

    def test_business_date_requires_iso_format_and_valid_calendar_date(self):
        self.assertEqual(run_silver.business_date("2026-11-01"), date(2026, 11, 1))
        for value in ("20261101", "2026-2-01", "2026-02-30"):
            with self.subTest(value=value), self.assertRaises(argparse.ArgumentTypeError):
                run_silver.business_date(value)
