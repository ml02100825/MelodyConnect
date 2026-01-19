package com.example.api.batch;

import com.example.api.repository.WeeklyLessonsRepository;
import jakarta.annotation.PostConstruct; // 追加
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;

@Component
@RequiredArgsConstructor
public class WeeklyRankingScheduler {

    private final WeeklyLessonsRepository weeklyLessonsRepository;

    /**
     * ★追加: アプリ起動時に1回だけ実行されるメソッド
     * これにより、開発中の「今のデータ」の整合性を即座に合わせます。
     */
    @PostConstruct
    public void initDataConsistency() {
        System.out.println("🚀 [Startup] 初回データ整合性チェックを実行します...");
        resetWeeklyRankings();
    }

    /**
     * 定期実行: 毎週日曜日のAM 0:00 に実行 (UIが日曜始まりのため日曜に変更)
     * cron = "秒 分 時 日 月 曜日" (SUN = 日曜)
     */
    @Scheduled(cron = "0 0 0 * * SUN") 
    public void resetWeeklyRankings() {
        System.out.println("⏰ [Scheduler] 週間ランキングのフラグ更新を開始します...");

        LocalDateTime now = LocalDateTime.now();
        
        // ★修正: UIに合わせて「今週の日曜日 00:00」を基準にする
        // これより前のデータは「先週以前」とみなしてフラグを下ろす
        LocalDateTime thisWeekStart = now.with(TemporalAdjusters.previousOrSame(DayOfWeek.SUNDAY))
                                         .withHour(0).withMinute(0).withSecond(0).withNano(0);

        // SQL実行: 日曜0時より古いデータの weekFlag を false (0) に更新
        weeklyLessonsRepository.updateWeekFlagForOldRecords(thisWeekStart);

        System.out.println("✅ [Scheduler] " + thisWeekStart + " 以前のデータのフラグを0にリセットしました。");
    }
}