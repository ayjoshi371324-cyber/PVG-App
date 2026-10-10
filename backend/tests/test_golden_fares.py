import json
from pathlib import Path
import pytest
from app.engine.shapley_calculator import ShapleyCalculator


def test_golden_fares_fixtures():
    fixtures_path = Path(__file__).resolve().parent.parent.parent / "contracts" / "fixtures" / "golden_fares.json"
    assert fixtures_path.exists(), f"Missing fixtures file at {fixtures_path}"

    with open(fixtures_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    for case in data["cases"]:
        case_id = case["id"]
        passengers = case["passengers"]
        total_cost = case["total_cost"]
        coalition_values = case["coalition_values"]
        expected_shares = case["expected_shares"]

        players = [p["id"] for p in passengers]
        solo_fares = {p["id"]: p["solo_fare"] for p in passengers}
        party_sizes = {p["id"]: p["party_size"] for p in passengers}

        def coalition_cost(subset):
            if not subset:
                return 0.0
            # Normalize subset key (e.g. {"A", "B"} -> "A,B")
            # Try combinations or canonical keys in coalition_values
            for key, val in coalition_values.items():
                key_set = set(k.strip() for k in key.split(","))
                if key_set == set(subset):
                    return float(val)
            return float(total_cost)

        result = ShapleyCalculator.calculate(
            players=players,
            coalition_cost=coalition_cost,
            total_cost=total_cost,
            solo_fares=solo_fares,
            party_sizes=party_sizes,
        )

        # Check rounded shares equal expected shares
        for p_id, expected_val in expected_shares.items():
            assert pytest.approx(result.rounded_shares[p_id], 0.01) == expected_val, (
                f"Mismatch in {case_id} for passenger {p_id}: got {result.rounded_shares[p_id]}, expected {expected_val}"
            )

        # Check budget balance: sum of shares == total_cost exactly
        assert pytest.approx(sum(result.rounded_shares.values()), 0.001) == total_cost
