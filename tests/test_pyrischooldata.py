"""
Tests for pyrischooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pyrischooldata
    assert pyrischooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pyrischooldata
    assert hasattr(pyrischooldata, 'fetch_enr')
    assert callable(pyrischooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pyrischooldata
    assert hasattr(pyrischooldata, 'get_available_years')
    assert callable(pyrischooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pyrischooldata
    assert hasattr(pyrischooldata, '__version__')
    assert isinstance(pyrischooldata.__version__, str)
