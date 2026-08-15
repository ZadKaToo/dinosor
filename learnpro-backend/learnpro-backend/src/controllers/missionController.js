const pool = require('../config/db');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

const listMissions = asyncHandler(async (req, res) => {
  const { track } = req.query;
  const params = [];
  let where = '';
  if (track) {
    params.push(track);
    where = 'WHERE track = $1';
  }
  const result = await pool.query(
    `SELECT id, track, title, description, xp_reward, order_index
     FROM missions ${where} ORDER BY order_index ASC`,
    params
  );
  res.json(result.rows);
});

const getMission = asyncHandler(async (req, res) => {
  const result = await pool.query('SELECT * FROM missions WHERE id = $1', [req.params.id]);
  if (!result.rows[0]) throw new ApiError(404, 'ไม่พบภารกิจนี้');
  res.json(result.rows[0]);
});

const myMissions = asyncHandler(async (req, res) => {
  const result = await pool.query(
    `SELECT m.id, m.title, m.track, m.xp_reward, um.status, um.completed_at
     FROM missions m
     LEFT JOIN user_missions um ON um.mission_id = m.id AND um.user_id = $1
     ORDER BY m.order_index ASC`,
    [req.userId]
  );
  res.json(result.rows);
});

// The Live Sandbox screen already runs the test cases client-side (see
// _runTests in LiveSandboxScreen), so this endpoint trusts the `passed` flag
// it's given and just persists the result + awards XP on first completion only.
const submitMission = asyncHandler(async (req, res) => {
  const { code, passed } = req.body;
  const missionId = req.params.id;

  const mission = await pool.query('SELECT xp_reward FROM missions WHERE id = $1', [missionId]);
  if (!mission.rows[0]) throw new ApiError(404, 'ไม่พบภารกิจนี้');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const existing = await client.query(
      'SELECT status FROM user_missions WHERE user_id = $1 AND mission_id = $2 FOR UPDATE',
      [req.userId, missionId]
    );
    const wasCompleted = existing.rows[0]?.status === 'completed';
    const status = passed ? 'completed' : 'in_progress';

    await client.query(
      `INSERT INTO user_missions (user_id, mission_id, status, submitted_code, completed_at)
       VALUES ($1, $2, $3, $4, CASE WHEN $3 = 'completed' THEN NOW() ELSE NULL END)
       ON CONFLICT (user_id, mission_id) DO UPDATE SET
         status = EXCLUDED.status,
         submitted_code = EXCLUDED.submitted_code,
         completed_at = COALESCE(user_missions.completed_at, EXCLUDED.completed_at)`,
      [req.userId, missionId, status, code]
    );

    let xpAwarded = 0;
    if (passed && !wasCompleted) {
      xpAwarded = mission.rows[0].xp_reward;
      await client.query(
        'UPDATE user_progress SET total_xp = total_xp + $1, updated_at = NOW() WHERE user_id = $2',
        [xpAwarded, req.userId]
      );
      await client.query(
        `INSERT INTO user_badges (user_id, badge_id) VALUES ($1, 'mission1')
         ON CONFLICT (user_id, badge_id) DO NOTHING`,
        [req.userId]
      );
    }

    await client.query('COMMIT');
    res.json({ status, xp_awarded: xpAwarded, first_completion: passed && !wasCompleted });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

module.exports = { listMissions, getMission, myMissions, submitMission };
