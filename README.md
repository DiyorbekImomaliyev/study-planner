# Study Planner

One clean Telegram message every morning: today's plan, this week at a glance, what is due,
and four buttons for the daily musts. Deadlines come from the D2L calendar feed and from
messages you send the bot. Alerts arrive 3 days, 1 day and 3 hours before each deadline.

The rules are in [SPEC.md](SPEC.md).

## Set up

1. Install:
   ```
   python3 -m venv .venv
   .venv/bin/pip install -e '.[dev]'
   cp config/planner.example.toml config/planner.toml
   ```
2. Edit `config/planner.toml`: classes, exams and the daily routine.
3. Create `.env` (chmod 600) with:
   ```
   D2L_ICS_URL=https://d2l.udst.edu.qa/d2l/le/calendar/feed/user/feed.ics?token=...
   TELEGRAM_BOT_TOKEN=...
   TELEGRAM_CHAT_ID=...
   ```
   Get the feed link in D2L: Calendar, Subscribe, "All Calendars and Tasks".
4. Check everything: `.venv/bin/planner check`
5. Install the schedule on this Mac: `deploy/install_launchd.sh`
   (remove it with `deploy/install_launchd.sh --uninstall`).

## Use

| You do | What happens |
|---|---|
| tap `leetcode`, `learn`, `uni`, `push` | marks that must done for the day (tap again to undo) |
| send `garc essay due nov 2` | the bot asks to save it, then alerts you before it |
| send `os midterm nov 5 10am` | same, with a time |
| send `mizan 2h` | logs extra work; it counts as focus time |
| `/today` | sends today's message again |
| `/list` | deadlines in the next 14 days (remove your own items here) |
| `/calendar` | a calendar file to add everything to your phone |

## Commands

```
planner run            # do what is due now (launchd runs this every 30 minutes)
planner run --dry-run  # write today's image and text to data/out, send nothing
planner run --force    # send today's message now
planner preview DATE   # write the message for any day to data/out
planner bot            # the Telegram bot (launchd keeps it running)
planner check          # check config, secrets, Chrome and the bot token
```

## Tests

```
.venv/bin/pytest
.venv/bin/ruff check src tests
```

Tests never touch the real feed, the real bot or your config.

## Layout

| File | Job |
|---|---|
| `src/planner/ics.py` | read the D2L feed, write the .ics export |
| `src/planner/plan.py` | build each day from the routine, classes, exams and deadlines |
| `src/planner/render.py` | the caption, the image (HTML to PNG with headless Chrome), the weekly text |
| `src/planner/jobs.py` | the schedule: feed, daily message, alerts, weekly summary |
| `src/planner/bot.py` | buttons and messages from the owner |
| `src/planner/store.py` | SQLite storage in `data/planner.db` |
| `src/planner/data/neetcode150.txt` | the LeetCode list, in order |
