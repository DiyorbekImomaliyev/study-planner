from datetime import datetime

import pytest
from conftest import NOW, QATAR

from planner.parse import parse_item, parse_log


@pytest.mark.parametrize("text,want", [
    ("mizan 2h", ("mizan", 2)), ("2h mizan", ("mizan", 2)), ("football 1.5h", ("football", 1.5)),
    ("mizan 90m", ("mizan", 1.5)), ("mizan 1h 30m", ("mizan", 1.5)), ("Mizan  3 hours", ("mizan", 3)),
])
def test_logs(text, want):  # IN-2
    assert parse_log(text) == want


@pytest.mark.parametrize("text", ["2h", "garc essay due nov 2", "os midterm nov 5 10am", "mizan 40h", "hello"])
def test_not_logs(text):
    assert parse_log(text) is None


def local(item):
    return item.due.astimezone(QATAR).strftime("%Y-%m-%d %H:%M")


def test_essay_with_alias_and_no_time(settings):  # IN-1
    it = parse_item("garc essay due nov 2", settings, NOW)
    assert (it.course, it.title, it.kind, local(it)) == ("garc2002", "essay", "assignment", "2026-11-02 23:59")


@pytest.mark.parametrize("text,when", [
    ("os midterm nov 5 10am", "2026-11-05 10:00"), ("os midterm 5 nov at 2pm", "2026-11-05 14:00"),
    ("os midterm november 5th 10:30", "2026-11-05 10:30"), ("os midterm tomorrow 9am", "2026-10-26 09:00"),
    ("os midterm thu", "2026-10-29 23:59"),
])
def test_dates_and_times(settings, text, when):
    it = parse_item(text, settings, NOW)
    assert (it.course, it.title, it.kind, local(it)) == ("inft2201", "midterm", "exam", when)


def test_course_code_and_past_month_rolls_to_next_year(settings):
    it = parse_item("dsai3201 project report jan 10", settings, NOW)
    assert (it.course, it.title, local(it)) == ("dsai3201", "project report", "2027-01-10 23:59")


def test_unknown_course_is_other(settings):
    it = parse_item("visa appointment nov 12 9am", settings, NOW)
    assert (it.course, it.title, it.kind) == ("other", "visa appointment", "other")


@pytest.mark.parametrize("text", ["hello there", "nov 2", "garc essay"])
def test_not_items(settings, text):
    assert parse_item(text, settings, datetime(2026, 10, 25, tzinfo=QATAR)) is None
