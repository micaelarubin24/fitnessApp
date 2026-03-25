-- =============================================
-- Trainer App — Schema MVP v2
-- Ejecutar en Supabase SQL Editor
--
-- Estructura:
-- routine → routine_days → exercise_slots (ejercicios definidos una vez)
-- routine → routine_weeks → week_progressions (sets/reps/PSE por semana)
-- =============================================

-- -----------------------------------------------
-- video_embeds (va primero por referencia en exercise_slots)
-- -----------------------------------------------
CREATE TABLE video_embeds (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  youtube_url TEXT NOT NULL,
  youtube_id  TEXT NOT NULL,
  titulo      TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- users (entrenadores — extiende auth.users)
-- -----------------------------------------------
CREATE TABLE users (
  id         UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  nombre     TEXT,
  email      TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- routines (plan de entrenamiento, por defecto 6 semanas)
-- -----------------------------------------------
CREATE TABLE routines (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id  UUID REFERENCES users(id) ON DELETE CASCADE,
  nombre      TEXT NOT NULL,
  descripcion TEXT,
  semanas     INT  DEFAULT 6,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- routine_days (días de la rutina — definidos UNA sola vez)
-- ej: Día A — Empuje, Día B — Tirón, Día C — Piernas
-- -----------------------------------------------
CREATE TABLE routine_days (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_id UUID REFERENCES routines(id) ON DELETE CASCADE,
  nombre     TEXT NOT NULL, -- ej: "Día A — Empuje"
  orden      INT  NOT NULL, -- orden dentro de la semana
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- exercise_slots (ejercicios dentro de un día — sin sets/reps/PSE)
-- La progresión va en week_progressions
-- -----------------------------------------------
CREATE TABLE exercise_slots (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_day_id   UUID REFERENCES routine_days(id) ON DELETE CASCADE,
  video_embed_id   UUID REFERENCES video_embeds(id) ON DELETE SET NULL,
  orden            INT  NOT NULL,
  nombre_ejercicio TEXT NOT NULL,
  notas            TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- routine_weeks (semanas de la rutina — 1 a 6)
-- -----------------------------------------------
CREATE TABLE routine_weeks (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_id    UUID REFERENCES routines(id) ON DELETE CASCADE,
  numero_semana INT  NOT NULL, -- 1 a 6
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- week_progressions (sets/reps/PSE por ejercicio por semana)
-- Une exercise_slot + routine_week con la progresión específica
-- -----------------------------------------------
CREATE TABLE week_progressions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  routine_week_id  UUID REFERENCES routine_weeks(id) ON DELETE CASCADE,
  exercise_slot_id UUID REFERENCES exercise_slots(id) ON DELETE CASCADE,
  series           INT,
  repeticiones     TEXT,         -- ej: "8-10" o "AMRAP"
  pse_objetivo     NUMERIC(3,1), -- RPE / PSE target
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (routine_week_id, exercise_slot_id)
);

-- -----------------------------------------------
-- client_routines (asignación de rutina a un cliente)
-- -----------------------------------------------
CREATE TABLE client_routines (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  routine_id     UUID REFERENCES routines(id) ON DELETE SET NULL,
  cliente_nombre TEXT NOT NULL,
  cliente_email  TEXT,
  fecha_inicio   DATE,
  activa         BOOLEAN DEFAULT TRUE,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- day_logs (registro de un día completado por el cliente)
-- -----------------------------------------------
CREATE TABLE day_logs (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_routine_id UUID REFERENCES client_routines(id) ON DELETE CASCADE,
  routine_day_id    UUID REFERENCES routine_days(id) ON DELETE SET NULL,
  numero_semana     INT  NOT NULL, -- en qué semana (1-6) se registró
  fecha             DATE DEFAULT CURRENT_DATE,
  completado        BOOLEAN DEFAULT FALSE,
  notas             TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------
-- exercise_logs (registro por ejercicio dentro de un día)
-- -----------------------------------------------
CREATE TABLE exercise_logs (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_log_id               UUID REFERENCES day_logs(id) ON DELETE CASCADE,
  exercise_slot_id         UUID REFERENCES exercise_slots(id) ON DELETE SET NULL,
  series_completadas       INT,
  repeticiones_completadas TEXT,
  pse_real                 NUMERIC(3,1),
  peso                     NUMERIC(6,2),
  notas                    TEXT,
  created_at               TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- RLS (Row Level Security)
-- =============================================

ALTER TABLE users             ENABLE ROW LEVEL SECURITY;
ALTER TABLE routines          ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_days      ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_slots    ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_weeks     ENABLE ROW LEVEL SECURITY;
ALTER TABLE week_progressions ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_routines   ENABLE ROW LEVEL SECURITY;
ALTER TABLE day_logs          ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_logs     ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_embeds      ENABLE ROW LEVEL SECURITY;

-- users
CREATE POLICY "usuario ve su propio perfil"
  ON users FOR ALL
  USING (auth.uid() = id);

-- routines
CREATE POLICY "entrenador ve sus rutinas"
  ON routines FOR ALL
  USING (auth.uid() = trainer_id);

-- routine_days
CREATE POLICY "entrenador ve sus dias"
  ON routine_days FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM routines
      WHERE routines.id = routine_days.routine_id
        AND routines.trainer_id = auth.uid()
    )
  );

-- exercise_slots
CREATE POLICY "entrenador ve sus ejercicios"
  ON exercise_slots FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM routine_days
      JOIN routines ON routines.id = routine_days.routine_id
      WHERE routine_days.id = exercise_slots.routine_day_id
        AND routines.trainer_id = auth.uid()
    )
  );

-- routine_weeks
CREATE POLICY "entrenador ve sus semanas"
  ON routine_weeks FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM routines
      WHERE routines.id = routine_weeks.routine_id
        AND routines.trainer_id = auth.uid()
    )
  );

-- week_progressions
CREATE POLICY "entrenador ve sus progresiones"
  ON week_progressions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM routine_weeks
      JOIN routines ON routines.id = routine_weeks.routine_id
      WHERE routine_weeks.id = week_progressions.routine_week_id
        AND routines.trainer_id = auth.uid()
    )
  );

-- client_routines
CREATE POLICY "entrenador ve sus clientes"
  ON client_routines FOR ALL
  USING (auth.uid() = trainer_id);

-- day_logs
CREATE POLICY "entrenador ve logs de sus clientes"
  ON day_logs FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM client_routines
      WHERE client_routines.id = day_logs.client_routine_id
        AND client_routines.trainer_id = auth.uid()
    )
  );

-- exercise_logs
CREATE POLICY "entrenador ve exercise logs de sus clientes"
  ON exercise_logs FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM day_logs
      JOIN client_routines ON client_routines.id = day_logs.client_routine_id
      WHERE day_logs.id = exercise_logs.day_log_id
        AND client_routines.trainer_id = auth.uid()
    )
  );

-- video_embeds
CREATE POLICY "video embeds publicos"
  ON video_embeds FOR SELECT
  USING (true);

CREATE POLICY "entrenador puede crear video embeds"
  ON video_embeds FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
