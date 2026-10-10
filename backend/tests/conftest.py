import pytest
from app.database import init_db, get_db_connection


@pytest.fixture(autouse=True, scope="function")
def cleanup_test_db():
    init_db()
    conn = get_db_connection()
    conn.execute("DELETE FROM users WHERE email NOT LIKE '%@ridepool.ai'")
    conn.commit()
    conn.close()
    yield
