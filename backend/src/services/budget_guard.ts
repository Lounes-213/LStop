import { Env } from '../env';

export interface ThrottleConfig {
  movingIntervalSeconds: number;
  idleIntervalSeconds: number;
  minDistanceMeters: number;
  level: 'normal' | 'moderate' | 'strict';
}

export class BudgetGuardService {
  private db: D1Database;

  constructor(db: D1Database) {
    this.db = db;
  }

  private getTodayUtc(): string {
    return new Date().toISOString().slice(0, 10);
  }

  /**
   * Increment metric counter in D1
   */
  async recordMetric(metric: string, delta = 1): Promise<number> {
    const today = this.getTodayUtc();
    try {
      await this.db
        .prepare(
          `INSERT INTO usage_counters (date_utc, metric, count)
           VALUES (?, ?, ?)
           ON CONFLICT(date_utc, metric)
           DO UPDATE SET count = count + ?`
        )
        .bind(today, metric, delta, delta)
        .run();

      const row = await this.db
        .prepare('SELECT count FROM usage_counters WHERE date_utc = ? AND metric = ?')
        .bind(today, metric)
        .first<{ count: number }>();

      return row?.count || delta;
    } catch {
      return delta;
    }
  }

  /**
   * Determine driver location update interval based on current daily DO message volume
   */
  async getDriverThrottleConfig(): Promise<ThrottleConfig> {
    const today = this.getTodayUtc();
    try {
      const row = await this.db
        .prepare('SELECT count FROM usage_counters WHERE date_utc = ? AND metric = ?')
        .bind(today, 'do_events')
        .first<{ count: number }>();

      const count = row?.count || 0;

      // Cloudflare free tier budget guard thresholds:
      if (count >= 85000) {
        return {
          movingIntervalSeconds: 12,
          idleIntervalSeconds: 35,
          minDistanceMeters: 25,
          level: 'strict'
        };
      } else if (count >= 70000) {
        return {
          movingIntervalSeconds: 8,
          idleIntervalSeconds: 25,
          minDistanceMeters: 20,
          level: 'moderate'
        };
      }

      return {
        movingIntervalSeconds: 5,
        idleIntervalSeconds: 15,
        minDistanceMeters: 15,
        level: 'normal'
      };
    } catch {
      return {
        movingIntervalSeconds: 5,
        idleIntervalSeconds: 15,
        minDistanceMeters: 15,
        level: 'normal'
      };
    }
  }
}
