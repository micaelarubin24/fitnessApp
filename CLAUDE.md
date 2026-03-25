# Trainer App

## Contexto del proyecto
Plataforma web PWA bilingüe (ES/EN) para entrenadores personales.
Stack: Next.js 14 + Supabase + Tailwind + shadcn/ui.

## MVP actual — features en scope
1. Google OAuth (Supabase Auth)
2. Plan builder: rutinas de 6 semanas con progresión de sets/reps/PSE por semana
3. YouTube embed (validación oEmbed)
4. Analytics dashboard para el entrenador

## Stack confirmado
- Next.js 14 (App Router)
- shadcn/ui — usar sus componentes antes de crear UI custom
- Tailwind CSS
- Supabase (Auth + PostgreSQL)

## Convenciones de código
- TypeScript estricto
- Componentes en /components, páginas en /app (App Router)
- Componentes UI de shadcn en /components/ui (no modificar directamente)
- Supabase client en /lib/supabase
- Variables de entorno en .env.local (nunca commitear)
- Español en comentarios y nombres de variables de dominio

## Git workflow
- `main` es la rama estable — nunca pushear directo
- Cada feature nueva va en su propia branch (ej: `feature/plan-builder`)
- No se mergea a main hasta haber testeado que todo funciona sin romper nada
- PRs requeridos antes de merge

## Base de datos
PostgreSQL via Supabase. Schema en /supabase/schema.sql
Tablas principales: users, routines, routine_weeks, routine_days,
exercise_slots, client_routines, day_logs, exercise_logs, video_embeds
