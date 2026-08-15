const pool = require('../config/db');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

// Mirrors AppState.checkBadges() thresholds from the Flutter app
const XP_BADGES = [
  { id: 'first_pass', minXp: 40 },
  { id: 'xp50', minXp: 50 },
  { id: 'xp100', minXp: 100 },
  { id: 'xp200', minXp: 200 },
];

async function awardBadgeIfMissing(client, userId, badgeId) {
  await client.query(
    `INSERT INTO user_badges (user_id, badge_id) VALUES ($1, $2)
     ON CONFLICT (user_id, badge_id) DO NOTHING`,
    [userId, badgeId]
  );
}

const getMyProgress = asyncHandler(async (req, res) => {
  const progressResult = await pool.query(
    'SELECT total_xp, streak_days, run_count, last_active_date FROM user_progress WHERE user_id = $1',
    [req.userId]
  );
  if (!progressResult.rows[0]) throw new ApiError(404, 'ไม่พบข้อมูลความคืบหน้า');

  const badgesResult = await pool.query(
    `SELECT b.id, b.title, b.description, b.icon_name, ub.earned_at
     FROM user_badges ub JOIN badges b ON b.id = ub.badge_id
     WHERE ub.user_id = $1 ORDER BY ub.earned_at ASC`,
    [req.userId]
  );

  res.json({ ...progressResult.rows[0], badges: badgesResult.rows });
});

// Applies the same streak multiplier logic as AppState.addXP() in Flutter:
// x1 normally, x2 at a 3+ day streak, x3 at a 7+ day streak.
const addXp = asyncHandler(async (req, res) => {
  const { amount } = req.body;
  if (!Number.isInteger(amount) || amount <= 0) {
    throw new ApiError(400, 'amount ต้องเป็นจำนวนเต็มบวก');
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const current = await client.query(
      'SELECT total_xp, streak_days FROM user_progress WHERE user_id = $1 FOR UPDATE',
      [req.userId]
    );
    if (!current.rows[0]) throw new ApiError(404, 'ไม่พบข้อมูลความคืบหน้า');

    const { streak_days } = current.rows[0];
    const multiplier = streak_days >= 7 ? 3 : streak_days >= 3 ? 2 : 1;
    const gained = amount * multiplier;

    const updated = await client.query(
      `UPDATE user_progress SET total_xp = total_xp + $1, updated_at = NOW()
       WHERE user_id = $2 RETURNING total_xp, streak_days, run_count`,
      [gained, req.userId]
    );

    for (const badge of XP_BADGES) {
      if (updated.rows[0].total_xp >= badge.minXp) {
        await awardBadgeIfMissing(client, req.userId, badge.id);
      }
    }

    await client.query('COMMIT');
    res.json({ gained, ...updated.rows[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

// Call this each time the user executes code in the Live Sandbox
const incrementRunCount = asyncHandler(async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const updated = await client.query(
      `UPDATE user_progress SET run_count = run_count + 1, updated_at = NOW()
       WHERE user_id = $1 RETURNING run_count`,
      [req.userId]
    );
    if (!updated.rows[0]) throw new ApiError(404, 'ไม่พบข้อมูลความคืบหน้า');

    const runCount = updated.rows[0].run_count;
    if (runCount >= 1) await awardBadgeIfMissing(client, req.userId, 'first_run');
    if (runCount >= 10) await awardBadgeIfMissing(client, req.userId, 'coder');

    await client.query('COMMIT');
    res.json({ run_count: runCount });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

module.exports = { getMyProgress, addXp, incrementRunCount };
