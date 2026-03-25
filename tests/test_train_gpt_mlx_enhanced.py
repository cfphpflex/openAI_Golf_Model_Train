import unittest

from train_gpt_mlx_enhanced import (
    EnhancedConfig,
    exceeds_requirements,
    parse_final_metrics,
)


class TestTrainGptMlxEnhanced(unittest.TestCase):
    def test_parse_final_metrics(self):
        output = (
            "some log line\n"
            "final_int8_zlib_roundtrip_exact val_loss:3.12345678 val_bpb:1.11110000\n"
            "done\n"
        )
        parsed = parse_final_metrics(output)
        self.assertAlmostEqual(parsed["val_loss"], 3.12345678, places=8)
        self.assertAlmostEqual(parsed["val_bpb"], 1.1111, places=8)

    def test_exceeds_requirements_both_gates(self):
        self.assertTrue(
            exceeds_requirements(
                val_bpb=1.12,
                wallclock_seconds=580.0,
                baseline_val_bpb=1.2244,
                max_allowed_seconds=600.0,
            )
        )
        self.assertFalse(
            exceeds_requirements(
                val_bpb=1.23,  # worse than baseline
                wallclock_seconds=580.0,
                baseline_val_bpb=1.2244,
                max_allowed_seconds=600.0,
            )
        )
        self.assertFalse(
            exceeds_requirements(
                val_bpb=1.12,
                wallclock_seconds=620.0,  # too slow
                baseline_val_bpb=1.2244,
                max_allowed_seconds=600.0,
            )
        )

    def test_config_matches_required_command_and_exceeds_floor(self):
        cfg = EnhancedConfig(
            run_id="mlx_seed_sweep",
            iterations=450,  # exceeds requested 400
            train_batch_tokens=20000,  # exceeds requested 16384
            seeds_csv="42,123,2025",
        )
        seeds = cfg.seeds()
        self.assertEqual(cfg.run_id, "mlx_seed_sweep")
        self.assertGreaterEqual(cfg.iterations, 400)
        self.assertGreaterEqual(cfg.train_batch_tokens, 16384)
        self.assertTrue(set([42, 123, 2025]).issubset(set(seeds)))


if __name__ == "__main__":
    unittest.main()
