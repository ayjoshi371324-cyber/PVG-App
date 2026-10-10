"""
Exact Shapley Value Calculator for Cooperative Cost Games (Python Engine Port).
Shared fixture compliant with contracts/fixtures/golden_fares.json
"""
import itertools
from dataclasses import dataclass
from typing import Callable, Dict, List, Optional, Set


@dataclass
class ShapleyResult:
    raw_shares: Dict[str, float]
    rounded_shares: Dict[str, float]
    per_person_shares: Dict[str, float]
    rounding_adjustments: Dict[str, float]
    savings: Dict[str, float]
    cap_triggered: Dict[str, bool]
    total_cost: float


class ShapleyCalculator:
    @staticmethod
    def calculate(
        players: List[str],
        coalition_cost: Callable[[Set[str]], float],
        total_cost: float,
        solo_fares: Dict[str, float],
        party_sizes: Optional[Dict[str, int]] = None,
    ) -> ShapleyResult:
        if not players:
            return ShapleyResult(
                raw_shares={},
                rounded_shares={},
                per_person_shares={},
                rounding_adjustments={},
                savings={},
                cap_triggered={},
                total_cost=0.0,
            )

        party_sizes = party_sizes or {}
        perms = list(itertools.permutations(players))
        num_perms = len(perms)

        # 1. Marginal contributions
        marginal_sums: Dict[str, float] = {p: 0.0 for p in players}

        for perm in perms:
            current_subset: Set[str] = set()
            prev_cost = 0.0
            for player in perm:
                current_subset.add(player)
                curr_cost = coalition_cost(frozenset(current_subset))
                marginal = curr_cost - prev_cost
                marginal_sums[player] += marginal
                prev_cost = curr_cost

        raw_shares: Dict[str, float] = {
            p: marginal_sums[p] / num_perms for p in players
        }

        # 2. Solo-fare ceiling cap enforcement and redistribution
        adjusted_shares = dict(raw_shares)
        cap_triggered: Dict[str, bool] = {p: False for p in players}

        rebalanced = True
        iteration = 0
        while rebalanced and iteration < 10:
            rebalanced = False
            iteration += 1

            excess = 0.0
            uncapped_players: List[str] = []

            for p in players:
                solo = solo_fares.get(p, float("inf"))
                current = adjusted_shares.get(p, 0.0)

                if current > solo + 1e-6:
                    excess += current - solo
                    adjusted_shares[p] = solo
                    cap_triggered[p] = True
                    rebalanced = True
                elif not cap_triggered[p]:
                    uncapped_players.append(p)

            if rebalanced and excess > 0.0 and uncapped_players:
                uncapped_sum = sum(adjusted_shares.get(p, 0.0) for p in uncapped_players)
                if uncapped_sum > 0.0:
                    for p in uncapped_players:
                        ratio = adjusted_shares.get(p, 0.0) / uncapped_sum
                        adjusted_shares[p] += excess * ratio
                else:
                    even = excess / len(uncapped_players)
                    for p in uncapped_players:
                        adjusted_shares[p] += even

        # 3. Largest-remainder rounding in integer paise (1 paise = 0.01 rupee)
        total_paise = round(total_cost * 100)
        floor_paise_map: Dict[str, int] = {}
        remainder_map: Dict[str, float] = {}

        sum_floor = 0
        for p in players:
            paise_val = adjusted_shares.get(p, 0.0) * 100
            floor_val = int(paise_val)
            floor_paise_map[p] = floor_val
            remainder_map[p] = paise_val - floor_val
            sum_floor += floor_val

        remaining_paise = total_paise - sum_floor
        # Sort by remainder descending
        sorted_by_rem = sorted(players, key=lambda p: remainder_map[p], reverse=True)

        rounded_paise_map = dict(floor_paise_map)
        for i in range(min(remaining_paise, len(sorted_by_rem))):
            p = sorted_by_rem[i]
            rounded_paise_map[p] += 1

        rounded_shares: Dict[str, float] = {}
        rounding_adjustments: Dict[str, float] = {}
        per_person_shares: Dict[str, float] = {}
        savings: Dict[str, float] = {}

        for p in players:
            share = rounded_paise_map[p] / 100.0
            rounded_shares[p] = share
            rounding_adjustments[p] = round(share - adjusted_shares.get(p, 0.0), 4)

            p_size = party_sizes.get(p, 1)
            per_person_shares[p] = round(share / (p_size if p_size > 0 else 1), 2)

            solo = solo_fares.get(p, share)
            diff = solo - share
            savings[p] = round(max(0.0, diff), 2)

        return ShapleyResult(
            raw_shares=raw_shares,
            rounded_shares=rounded_shares,
            per_person_shares=per_person_shares,
            rounding_adjustments=rounding_adjustments,
            savings=savings,
            cap_triggered=cap_triggered,
            total_cost=total_cost,
        )
