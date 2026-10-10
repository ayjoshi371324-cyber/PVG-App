"""
Deterministic Cost Model for RidePool AI (Python Engine Port).
Standard pricing: trip_cost = base_fee + (rate_per_km * distance_km)
"""
from typing import Optional


class CostModel:
    def __init__(self, base_fee: float = 20.0, rate_per_km: float = 10.0):
        self.base_fee = base_fee
        self.rate_per_km = rate_per_km

    def trip_cost(self, distance_km: float, multiplier: float = 1.0) -> float:
        if distance_km <= 0.0:
            return 0.0
        cost = (self.base_fee + (self.rate_per_km * distance_km)) * multiplier
        return round(cost, 2)
